// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import {ERC20, ERC20Permit, ERC20Votes} from "@openzeppelin/contracts/token/ERC20/extensions/ERC20Votes.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import {IERC20, SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {IERC20Metadata} from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import {FixedPointMathLib} from "solmate/src/utils/FixedPointMathLib.sol";
import {ICore} from "./interfaces/ICore.sol";
import {IContentFactory} from "./interfaces/IContentFactory.sol";

contract Token is ERC20, ERC20Permit, ERC20Votes, ReentrancyGuard {
    using FixedPointMathLib for uint256;
    using SafeERC20 for IERC20;

    uint256 public constant PRECISION = 1e18;
    uint256 public constant FEE = 100;
    uint256 public constant FEE_AMOUNT = 2_000;
    uint256 public constant DIVISOR = 10_000;
    uint256 public constant MIN_TRADE_SIZE = 1_000;

    address public immutable core;
    address public immutable quote;
    address public immutable content;
    address public immutable rewarder;

    uint8 public immutable quoteDecimals;
    uint256 internal immutable quoteScale;

    uint256 public maxSupply;

    uint256 public reserveRealQuoteWad;
    uint256 public reserveVirtQuoteWad;
    uint256 public reserveTokenAmt;

    uint256 public totalDebtRaw;
    mapping(address => uint256) public account_DebtRaw;

    error Token__QuoteDecimals();
    error Token__ZeroInput();
    error Token__ZeroTo();
    error Token__Expired();
    error Token__MinTradeSize();
    error Token__Slippage();
    error Token__CollateralLocked();
    error Token__CreditExceeded();
    error Token__InvalidShift();
    error Token__DivideByZero();
    error Token__ReserveUnderflow();

    event Token__Swap(
        address indexed from,
        uint256 quoteInRaw,
        uint256 tokenIn,
        uint256 quoteOutRaw,
        uint256 tokenOut,
        address indexed to
    );
    event Token__SyncReserves(uint256 reserveRealQuoteWad, uint256 reserveVirtQuoteWad, uint256 reserveTokenAmt);
    event Token__HealReserves(uint256 quoteWad, uint256 virtAddWad);
    event Token__BurnReserves(uint256 tokenAmt, uint256 reserveBurn);
    event Token__ProviderFee(address indexed to, uint256 quoteRaw, uint256 tokenAmt);
    event Token__TreasuryFee(address indexed to, uint256 quoteRaw, uint256 tokenAmt);
    event Token__ContentFee(address indexed to, uint256 quoteRaw, uint256 tokenAmt);
    event Token__Heal(address indexed who, uint256 quoteRaw);
    event Token__Burn(address indexed who, uint256 tokenAmt);
    event Token__Borrow(address indexed who, address indexed to, uint256 quoteRaw);
    event Token__Repay(address indexed who, address indexed to, uint256 quoteRaw);

    modifier notZeroInput(uint256 amount) {
        if (amount == 0) revert Token__ZeroInput();
        _;
    }

    modifier notZeroTo(address account) {
        if (account == address(0)) revert Token__ZeroTo();
        _;
    }

    modifier notExpired(uint256 expireTimestamp) {
        if (expireTimestamp != 0 && expireTimestamp < block.timestamp) {
            revert Token__Expired();
        }
        _;
    }

    modifier minTradeSize(uint256 amount) {
        if (amount < MIN_TRADE_SIZE) revert Token__MinTradeSize();
        _;
    }

    constructor(
        string memory name,
        string memory symbol,
        string memory uri,
        address _core,
        address _quote,
        uint256 _initialSupply,
        uint256 _virtQuoteRaw,
        address contentFactory,
        address rewarderFactory,
        address owner,
        uint256 minInitPrice,
        bool isModerated
    ) ERC20(name, symbol) ERC20Permit(name) {
        core = _core;
        quote = _quote;

        uint8 _quoteDecimals = IERC20Metadata(_quote).decimals();
        if (_quoteDecimals > 18) revert Token__QuoteDecimals();
        quoteDecimals = _quoteDecimals;
        quoteScale = 10 ** (18 - _quoteDecimals);

        maxSupply = _initialSupply;
        reserveTokenAmt = _initialSupply;
        reserveVirtQuoteWad = rawToWad(_virtQuoteRaw);

        (content, rewarder) = IContentFactory(contentFactory).create(
            name, symbol, uri, address(this), _quote, rewarderFactory, owner, minInitPrice, isModerated
        );
    }

    function buy(uint256 quoteRawIn, uint256 minTokenAmtOut, uint256 deadline, address to, address provider)
        external
        nonReentrant
        notZeroTo(to)
        minTradeSize(quoteRawIn)
        notExpired(deadline)
        returns (uint256 tokenAmtOut)
    {
        uint256 feeRaw;
        (tokenAmtOut, feeRaw) = _processBuy(quoteRawIn, minTokenAmtOut);

        emit Token__Swap(msg.sender, quoteRawIn, 0, 0, tokenAmtOut, to);
        IERC20(quote).safeTransferFrom(msg.sender, address(this), quoteRawIn);

        uint256 healRaw = _processBuyFees(feeRaw, provider);
        if (healRaw > 0) _healQuoteReserves(healRaw);

        _mint(to, tokenAmtOut);
    }

    function sell(uint256 tokenAmtIn, uint256 minQuoteRawOut, uint256 deadline, address to, address provider)
        external
        nonReentrant
        notZeroTo(to)
        minTradeSize(tokenAmtIn)
        notExpired(deadline)
        returns (uint256 quoteRawOut)
    {
        uint256 feeAmt;
        (quoteRawOut, feeAmt) = _processSell(tokenAmtIn, minQuoteRawOut);

        emit Token__Swap(msg.sender, 0, tokenAmtIn, quoteRawOut, 0, to);
        _burn(msg.sender, tokenAmtIn);

        uint256 burned = _processSellFees(feeAmt, provider);
        if (burned > 0) _burnTokenReserves(burned);

        IERC20(quote).safeTransfer(to, quoteRawOut);
    }

    function borrow(address to, uint256 quoteRaw) external nonReentrant notZeroTo(to) notZeroInput(quoteRaw) {
        uint256 credit = getAccountCredit(msg.sender);
        if (quoteRaw > credit) revert Token__CreditExceeded();

        totalDebtRaw += quoteRaw;
        account_DebtRaw[msg.sender] += quoteRaw;

        emit Token__Borrow(msg.sender, to, quoteRaw);
        IERC20(quote).safeTransfer(to, quoteRaw);
    }

    function repay(address to, uint256 quoteRaw) external nonReentrant notZeroTo(to) notZeroInput(quoteRaw) {
        totalDebtRaw -= quoteRaw;
        account_DebtRaw[to] -= quoteRaw;

        emit Token__Repay(msg.sender, to, quoteRaw);
        IERC20(quote).safeTransferFrom(msg.sender, address(this), quoteRaw);
    }

    function heal(uint256 quoteRaw) external nonReentrant notZeroInput(quoteRaw) {
        IERC20(quote).safeTransferFrom(msg.sender, address(this), quoteRaw);
        _healQuoteReserves(quoteRaw);
        emit Token__Heal(msg.sender, quoteRaw);
    }

    function burn(uint256 tokenAmt) external nonReentrant notZeroInput(tokenAmt) {
        _burn(msg.sender, tokenAmt);
        _burnTokenReserves(tokenAmt);
        emit Token__Burn(msg.sender, tokenAmt);
    }

    function rawToWad(uint256 raw) public view returns (uint256) {
        return raw * quoteScale;
    }

    function wadToRaw(uint256 wad) public view returns (uint256) {
        return wad / quoteScale;
    }

    function _processBuy(uint256 quoteRawIn, uint256 minTokenAmtOut)
        internal
        returns (uint256 tokenAmtOut, uint256 feeRaw)
    {
        feeRaw = (quoteRawIn * FEE) / DIVISOR;
        uint256 netRaw = quoteRawIn - feeRaw;
        uint256 netWad = rawToWad(netRaw);

        uint256 y0 = reserveTokenAmt;
        uint256 x0 = reserveVirtQuoteWad + reserveRealQuoteWad;
        uint256 x1 = x0 + netWad;
        if (x1 == 0) revert Token__DivideByZero();

        uint256 y1 = x0.mulWadUp(y0).divWadUp(x1);
        tokenAmtOut = y0 - y1;
        if (tokenAmtOut < minTokenAmtOut) revert Token__Slippage();

        reserveRealQuoteWad = x1 - reserveVirtQuoteWad;
        reserveTokenAmt = y1;

        emit Token__SyncReserves(reserveRealQuoteWad, reserveVirtQuoteWad, reserveTokenAmt);
    }

    function _processSell(uint256 tokenAmtIn, uint256 minQuoteRawOut)
        internal
        returns (uint256 quoteRawOut, uint256 feeAmt)
    {
        feeAmt = (tokenAmtIn * FEE) / DIVISOR;
        uint256 netAmt = tokenAmtIn - feeAmt;

        uint256 x0 = reserveVirtQuoteWad + reserveRealQuoteWad;
        uint256 y0 = reserveTokenAmt;
        uint256 y1 = y0 + netAmt;
        if (y1 == 0) revert Token__DivideByZero();

        uint256 x1 = x0.mulWadUp(y0).divWadUp(y1);
        uint256 quoteWadOut = x0 - x1;
        quoteRawOut = wadToRaw(quoteWadOut);

        if (quoteRawOut < minQuoteRawOut) revert Token__Slippage();
        if (x1 < reserveVirtQuoteWad) revert Token__ReserveUnderflow();

        reserveRealQuoteWad = x1 - reserveVirtQuoteWad;
        reserveTokenAmt = y1;

        emit Token__SyncReserves(reserveRealQuoteWad, reserveVirtQuoteWad, reserveTokenAmt);
    }

    function _processBuyFees(uint256 quoteRaw, address provider) internal returns (uint256 remainingRaw) {
        remainingRaw = quoteRaw;
        uint256 feeRaw = (quoteRaw * FEE_AMOUNT) / DIVISOR;

        if (provider != address(0)) {
            IERC20(quote).safeTransfer(provider, feeRaw);
            emit Token__ProviderFee(provider, feeRaw, 0);
            remainingRaw -= feeRaw;
        }

        IERC20(quote).safeTransfer(content, feeRaw);
        emit Token__ContentFee(content, feeRaw, 0);
        remainingRaw -= feeRaw;

        address treasury = ICore(core).treasury();
        if (treasury != address(0)) {
            IERC20(quote).safeTransfer(treasury, feeRaw);
            emit Token__TreasuryFee(treasury, feeRaw, 0);
            remainingRaw -= feeRaw;
        }

        return remainingRaw;
    }

    function _processSellFees(uint256 tokenAmt, address provider) internal returns (uint256 remainingAmt) {
        remainingAmt = tokenAmt;
        uint256 feeAmt = (tokenAmt * FEE_AMOUNT) / DIVISOR;

        if (provider != address(0)) {
            _mint(provider, feeAmt);
            emit Token__ProviderFee(provider, 0, feeAmt);
            remainingAmt -= feeAmt;
        }

        _mint(content, feeAmt);
        emit Token__ContentFee(content, 0, feeAmt);
        remainingAmt -= feeAmt;

        address treasury = ICore(core).treasury();
        if (treasury != address(0)) {
            _mint(treasury, feeAmt);
            emit Token__TreasuryFee(treasury, 0, feeAmt);
            remainingAmt -= feeAmt;
        }

        return remainingAmt;
    }

    function _healQuoteReserves(uint256 quoteRaw) internal {
        uint256 quoteWad = rawToWad(quoteRaw);
        uint256 m = maxSupply;
        uint256 y = reserveTokenAmt;
        if (m <= y) revert Token__InvalidShift();

        uint256 virtAddWad = y.mulWadDown(quoteWad).divWadDown(m - y);

        reserveRealQuoteWad += quoteWad;
        reserveVirtQuoteWad += virtAddWad;

        emit Token__HealReserves(quoteWad, virtAddWad);
    }

    function _burnTokenReserves(uint256 tokenAmt) internal {
        uint256 m = maxSupply;
        uint256 y = reserveTokenAmt;
        if (m <= y) revert Token__InvalidShift();

        uint256 reserveBurn = y.mulWadDown(tokenAmt).divWadDown(m - y);

        reserveTokenAmt -= reserveBurn;
        maxSupply -= (tokenAmt + reserveBurn);

        emit Token__BurnReserves(tokenAmt, reserveBurn);
    }

    function _afterTokenTransfer(address from, address to, uint256 amount) internal override(ERC20, ERC20Votes) {
        super._afterTokenTransfer(from, to, amount);
    }

    function _beforeTokenTransfer(address from, address to, uint256 amount) internal override(ERC20) {
        super._beforeTokenTransfer(from, to, amount);

        if (from != address(0) && account_DebtRaw[from] > 0) {
            uint256 transferrable = getAccountTransferrable(from);
            if (amount > transferrable) {
                revert Token__CollateralLocked();
            }
        }
    }

    function _mint(address to, uint256 amount) internal override(ERC20, ERC20Votes) {
        super._mint(to, amount);
    }

    function _burn(address account, uint256 amount) internal override(ERC20, ERC20Votes) {
        super._burn(account, amount);
    }

    function getMarketPrice() external view returns (uint256 price) {
        if (reserveTokenAmt == 0) return 0;
        uint256 totalQuoteWad = reserveVirtQuoteWad + reserveRealQuoteWad;
        return totalQuoteWad.divWadDown(reserveTokenAmt);
    }

    function getFloorPrice() external view returns (uint256 price) {
        if (maxSupply == 0) return 0;
        return reserveVirtQuoteWad.divWadDown(maxSupply);
    }

    function getAccountCredit(address account) public view returns (uint256 creditRaw) {
        uint256 balance = balanceOf(account);
        if (balance == 0) return 0;

        uint256 m = maxSupply;
        uint256 xv = reserveVirtQuoteWad;
        if (balance >= m) return 0;

        uint256 requiredWad = xv.mulWadDown(m).divWadDown(m - balance);
        uint256 creditLimitWad = requiredWad - xv;
        uint256 creditLimitRaw = wadToRaw(creditLimitWad);
        uint256 debtRaw = account_DebtRaw[account];

        creditRaw = creditLimitRaw > debtRaw ? creditLimitRaw - debtRaw : 0;
        return creditRaw;
    }

    function getAccountTransferrable(address account) public view returns (uint256 tokenAmt) {
        uint256 debtRaw = account_DebtRaw[account];
        uint256 balance = balanceOf(account);
        if (debtRaw == 0) return balance;

        uint256 m = maxSupply;
        uint256 xv = reserveVirtQuoteWad;
        if (xv == 0) return 0;

        uint256 debtWad = rawToWad(debtRaw);
        uint256 requiredWad = xv + debtWad;
        if (requiredWad == 0) return 0;
        uint256 nonLocked = xv.mulWadDown(m).divWadDown(requiredWad);
        uint256 locked = m - nonLocked;

        tokenAmt = balance > locked ? balance - locked : 0;
        return tokenAmt;
    }
}

contract TokenFactory {
    address public lastToken;

    event TokenFactory__Created(address indexed token);

    function create(
        string memory name,
        string memory symbol,
        string memory uri,
        address core,
        address quote,
        uint256 initialSupply,
        uint256 reserveVirtQuoteRaw,
        address contentFactory,
        address rewarderFactory,
        address owner,
        uint256 minInitPrice,
        bool isModerated
    ) external returns (address token) {
        token = address(
            new Token(
                name,
                symbol,
                uri,
                core,
                quote,
                initialSupply,
                reserveVirtQuoteRaw,
                contentFactory,
                rewarderFactory,
                owner,
                minInitPrice,
                isModerated
            )
        );
        lastToken = token;
        emit TokenFactory__Created(token);
    }
}
