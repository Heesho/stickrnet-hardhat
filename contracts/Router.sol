// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import {IERC20, SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

interface ICore {
    function quote() external view returns (address);

    function create(string calldata name, string calldata symbol, string calldata uri, address owner, bool isModerated)
        external
        returns (address token);
}

interface IToken {
    function content() external view returns (address);

    function sale() external view returns (address);

    function rewarder() external view returns (address);

    function buy(
        uint256 amountQuoteIn,
        uint256 minAmountTokenOut,
        uint256 expireTimestamp,
        address to,
        address provider
    ) external returns (uint256 amountTokenOut);

    function sell(
        uint256 amountTokenIn,
        uint256 minAmountQuoteOut,
        uint256 expireTimestamp,
        address to,
        address provider
    ) external returns (uint256 amountQuoteOut);
}

interface IContent {
    function getNextPrice(uint256 tokenId) external view returns (uint256);

    function create(address to, string memory uri) external returns (uint256);

    function curate(address to, uint256 tokenId) external;

    function distribute() external;
}

interface IRewarder {
    function getReward(address account) external;

    function notifyRewardAmount(address token, uint256 amount) external;
}

contract Router is ReentrancyGuard, Ownable {
    using SafeERC20 for IERC20;

    address public immutable core;

    mapping(address => address) public account_Affiliate;

    event Router__TokenCreated(
        string name,
        string symbol,
        string uri,
        address indexed token,
        address indexed creator,
        bool isModerated,
        uint256 amountQuoteIn,
        uint256 amountTokenOut
    );
    event Router__Buy(
        address indexed token,
        address indexed account,
        address indexed affiliate,
        uint256 amountQuoteIn,
        uint256 amountTokenOut
    );
    event Router__Sell(
        address indexed token,
        address indexed account,
        address indexed affiliate,
        uint256 amountTokenIn,
        uint256 amountQuoteOut
    );
    event Router__ContentCreated(
        address indexed token, address indexed content, address indexed account, uint256 tokenId
    );
    event Router__ContentCurated(
        address indexed token, address indexed content, address indexed account, uint256 price, uint256 tokenId
    );
    event Router__AffiliateSet(address indexed account, address indexed affiliate);

    constructor(address _core) {
        core = _core;
    }

    function createToken(
        string calldata name,
        string calldata symbol,
        string calldata uri,
        bool isModerated,
        uint256 amountQuoteIn
    ) external nonReentrant returns (address token) {
        token = ICore(core).create(name, symbol, uri, msg.sender, isModerated);

        uint256 amountTokenOut;
        if (amountQuoteIn > 0) {
            address quote = ICore(core).quote();
            IERC20(quote).safeTransferFrom(msg.sender, address(this), amountQuoteIn);
            _safeApprove(quote, token, amountQuoteIn);
            amountTokenOut = IToken(token).buy(amountQuoteIn, 0, 0, msg.sender, address(0));

            uint256 remainingQuote = IERC20(quote).balanceOf(address(this));
            if (remainingQuote > 0) {
                IERC20(quote).safeTransfer(msg.sender, remainingQuote);
            }
        }

        emit Router__TokenCreated(name, symbol, uri, token, msg.sender, isModerated, amountQuoteIn, amountTokenOut);
    }

    function buy(
        address token,
        address affiliate,
        uint256 amountQuoteIn,
        uint256 minAmountTokenOut,
        uint256 expireTimestamp
    ) external nonReentrant {
        _setAffiliate(affiliate);

        address quote = ICore(core).quote();
        IERC20(quote).safeTransferFrom(msg.sender, address(this), amountQuoteIn);
        _safeApprove(quote, token, amountQuoteIn);

        uint256 amountTokenOut = IToken(token).buy(
            amountQuoteIn, minAmountTokenOut, expireTimestamp, msg.sender, account_Affiliate[msg.sender]
        );

        uint256 remainingQuote = IERC20(quote).balanceOf(address(this));
        if (remainingQuote > 0) {
            IERC20(quote).safeTransfer(msg.sender, remainingQuote);
        }

        _distributeFees(token);

        emit Router__Buy(token, msg.sender, affiliate, amountQuoteIn, amountTokenOut);
    }

    function sell(
        address token,
        address affiliate,
        uint256 amountTokenIn,
        uint256 minAmountQuoteOut,
        uint256 expireTimestamp
    ) external nonReentrant {
        _setAffiliate(affiliate);

        IERC20(token).safeTransferFrom(msg.sender, address(this), amountTokenIn);
        uint256 amountQuoteOut = IToken(token).sell(
            amountTokenIn, minAmountQuoteOut, expireTimestamp, msg.sender, account_Affiliate[msg.sender]
        );

        _distributeFees(token);

        emit Router__Sell(token, msg.sender, affiliate, amountTokenIn, amountQuoteOut);
    }

    function createContent(address token, string calldata uri) external nonReentrant {
        address content = IToken(token).content();
        uint256 tokenId = IContent(content).create(msg.sender, uri);

        emit Router__ContentCreated(token, content, msg.sender, tokenId);
    }

    function curateContent(address token, uint256 tokenId) external nonReentrant {
        address content = IToken(token).content();
        address quote = ICore(core).quote();
        uint256 price = IContent(content).getNextPrice(tokenId);

        IERC20(quote).safeTransferFrom(msg.sender, address(this), price);
        _safeApprove(quote, content, price);

        IContent(content).curate(msg.sender, tokenId);

        emit Router__ContentCurated(token, content, msg.sender, price, tokenId);
    }

    function getContentReward(address token) external {
        address rewarder = IToken(token).rewarder();
        IRewarder(rewarder).getReward(msg.sender);
    }

    function notifyContentRewardAmount(address token, address rewardToken, uint256 amount) external {
        address rewarder = IToken(token).rewarder();
        IERC20(rewardToken).safeTransferFrom(msg.sender, address(this), amount);
        _safeApprove(rewardToken, rewarder, amount);
        IRewarder(rewarder).notifyRewardAmount(rewardToken, amount);
    }

    function _setAffiliate(address affiliate) internal {
        if (account_Affiliate[msg.sender] == address(0) && affiliate != address(0)) {
            account_Affiliate[msg.sender] = affiliate;
            emit Router__AffiliateSet(msg.sender, affiliate);
        }
    }

    function _safeApprove(address token, address spender, uint256 amount) internal {
        IERC20(token).safeApprove(spender, 0);
        IERC20(token).safeApprove(spender, amount);
    }

    function _distributeFees(address token) internal {
        address content = IToken(token).content();
        IContent(content).distribute();
    }

    function withdrawStuckTokens(address _token, address _to) external onlyOwner {
        uint256 balance = IERC20(_token).balanceOf(address(this));
        IERC20(_token).safeTransfer(_to, balance);
    }
}
