// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import {IERC20, IERC20Metadata} from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import {FixedPointMathLib} from "solmate/src/utils/FixedPointMathLib.sol";

interface IToken {
    function quote() external view returns (address);

    function sale() external view returns (address);

    function content() external view returns (address);

    function rewarder() external view returns (address);

    function open() external view returns (bool);

    function wadToRaw(uint256 wad) external view returns (uint256);

    function rawToWad(uint256 raw) external view returns (uint256);

    function reserveVirtQuoteWad() external view returns (uint256);

    function reserveRealQuoteWad() external view returns (uint256);

    function reserveTokenAmt() external view returns (uint256);

    function maxSupply() external view returns (uint256);

    function getMarketPrice() external view returns (uint256);

    function getFloorPrice() external view returns (uint256);

    function account_DebtRaw(address account) external view returns (uint256);

    function getAccountCredit(address account) external view returns (uint256);

    function getAccountTransferrable(address account) external view returns (uint256);
}

interface ICore {
    function token_Index(address token) external view returns (uint256);
}

interface IRewarder {
    function totalSupply() external view returns (uint256);

    function getRewardForDuration(address token) external view returns (uint256);

    function account_Balance(address account) external view returns (uint256);

    function earned(address account, address token) external view returns (uint256);
}

interface IContent {
    function owner() external view returns (address);

    function balanceOf(address account) external view returns (uint256);

    function id_Creator(uint256 tokenId) external view returns (address);

    function id_Price(uint256 tokenId) external view returns (uint256);

    function id_IsApproved(uint256 tokenId) external view returns (bool);

    function getNextPrice(uint256 tokenId) external view returns (uint256);

    function uri() external view returns (string memory);

    function isModerated() external view returns (bool);

    function account_IsModerator(address account) external view returns (bool);
}

contract Multicall {
    using FixedPointMathLib for uint256;

    uint256 public constant FEE = 100;
    uint256 public constant DIVISOR = 10_000;
    uint256 public constant PRECISION = 1e18;
    uint256 public constant MIN_TRADE_AMOUNT = 1000;

    address public immutable core;

    struct TokenData {
        uint256 index;
        address token;
        address quote;
        address content;
        address rewarder;
        address owner;
        string name;
        string symbol;
        string uri;
        bool isModerated;
        uint256 marketCap;
        uint256 liquidity;
        uint256 floorPrice;
        uint256 marketPrice;
        uint256 circulatingSupply;
        uint256 maxSupply;
        uint256 contentApr;
        uint256 accountQuoteBalance;
        uint256 accountTokenBalance;
        uint256 accountDebt;
        uint256 accountCredit;
        uint256 accountTransferrable;
        uint256 accountContentOwned;
        uint256 accountContentStaked;
        uint256 accountQuoteEarned;
        uint256 accountTokenEarned;
        bool accountIsModerator;
    }

    struct ContentData {
        uint256 tokenId;
        uint256 price;
        uint256 nextPrice;
        uint256 rewardForDuration;
        address creator;
        address owner;
        string uri;
        bool isApproved;
    }

    constructor(address _core) {
        core = _core;
    }

    function getTokenData(address token, address account) external view returns (TokenData memory data) {
        address quote = IToken(token).quote();
        address content = IToken(token).content();
        address rewarder = IToken(token).rewarder();

        uint256 index = ICore(core).token_Index(token);
        string memory uri = IContent(content).uri();

        data.index = index;

        data.token = token;
        data.quote = quote;
        data.content = content;
        data.rewarder = rewarder;
        data.owner = IContent(content).owner();

        data.name = IERC20Metadata(token).name();
        data.symbol = IERC20Metadata(token).symbol();
        data.uri = uri;
        data.isModerated = IContent(content).isModerated();

        data.marketCap =
            IToken(token).wadToRaw(IToken(token).maxSupply().mulDivDown(IToken(token).getMarketPrice(), PRECISION));
        data.liquidity =
            IToken(token).wadToRaw(IToken(token).reserveRealQuoteWad() + IToken(token).reserveVirtQuoteWad()) * 2;
        data.floorPrice = IToken(token).getFloorPrice();
        data.marketPrice = IToken(token).getMarketPrice();
        data.circulatingSupply = IERC20(token).totalSupply();
        data.maxSupply = IToken(token).maxSupply();

        uint256 totalContentStaked = IToken(token).rawToWad(IRewarder(rewarder).totalSupply());
        uint256 accountContentStaked = IToken(token).rawToWad(IRewarder(rewarder).account_Balance(account));

        uint256 contentQuoteRewardForDuration =
            totalContentStaked == 0 ? 0 : IToken(token).rawToWad(IRewarder(rewarder).getRewardForDuration(quote));
        uint256 contentTokenRewardForDuration =
            totalContentStaked == 0 ? 0 : IRewarder(rewarder).getRewardForDuration(token);
        uint256 contentApr = totalContentStaked == 0
            ? 0
            : (
                (
                    contentQuoteRewardForDuration
                        + ((contentTokenRewardForDuration * IToken(token).getMarketPrice()) / PRECISION)
                ) * 365 * 100 * PRECISION
            ) / (7 * totalContentStaked);

        data.contentApr = contentApr;

        if (account != address(0)) {
            data.accountQuoteBalance = IERC20(quote).balanceOf(account);
            data.accountTokenBalance = IERC20(token).balanceOf(account);
            data.accountDebt = IToken(token).account_DebtRaw(account);
            data.accountCredit = IToken(token).getAccountCredit(account);
            data.accountTransferrable = IToken(token).getAccountTransferrable(account);
            data.accountContentOwned = IContent(content).balanceOf(account);
            data.accountContentStaked = accountContentStaked;
            data.accountQuoteEarned = IRewarder(rewarder).earned(account, quote);
            data.accountTokenEarned = IRewarder(rewarder).earned(account, token);
            data.accountIsModerator =
                IContent(content).owner() == account || IContent(content).account_IsModerator(account);
        }

        return data;
    }

    function getContentData(address token, uint256 tokenId) external view returns (ContentData memory data) {
        address content = IToken(token).content();
        address rewarder = IToken(token).rewarder();
        address quote = IToken(token).quote();

        uint256 totalContentStaked = IRewarder(rewarder).totalSupply();

        uint256 contentQuoteRewardForDuration =
            totalContentStaked == 0 ? 0 : IToken(token).rawToWad(IRewarder(rewarder).getRewardForDuration(quote));
        uint256 contentTokenRewardForDuration =
            totalContentStaked == 0 ? 0 : IRewarder(rewarder).getRewardForDuration(token);
        uint256 rewardForDuration = totalContentStaked == 0
            ? 0
            : (
                contentQuoteRewardForDuration
                    + ((contentTokenRewardForDuration * IToken(token).getMarketPrice()) / PRECISION)
            );

        data.tokenId = tokenId;
        data.price = IContent(content).id_Price(tokenId);
        data.nextPrice = IContent(content).getNextPrice(tokenId);
        data.rewardForDuration = IContent(content).id_Price(tokenId) == 0
            ? 0
            : rewardForDuration * IContent(content).id_Price(tokenId) / totalContentStaked;
        data.creator = IContent(content).id_Creator(tokenId);
        data.owner = IContent(content).owner();
        data.uri = IContent(content).uri();
        data.isApproved = IContent(content).id_IsApproved(tokenId);

        return data;
    }

    function buyQuoteIn(address token, uint256 quoteRawIn, uint256 slippageTolerance)
        external
        view
        returns (uint256 tokenAmtOut, uint256 slippage, uint256 minTokenAmtOut, uint256 autoMinTokenAmtOut)
    {
        if (quoteRawIn < MIN_TRADE_AMOUNT) return (0, 0, 0, 0);

        uint256 xr = IToken(token).reserveRealQuoteWad();
        uint256 xv = IToken(token).reserveVirtQuoteWad();

        uint256 quoteWadIn = IToken(token).rawToWad(quoteRawIn);
        uint256 feeWad = (quoteWadIn * FEE) / DIVISOR;
        uint256 netWad = quoteWadIn - feeWad;

        uint256 x0 = xv + xr;
        uint256 x1 = x0 + netWad;
        uint256 y0 = IToken(token).reserveTokenAmt();
        uint256 y1 = x0.mulWadUp(y0).divWadUp(x1);

        if (y1 >= y0) return (0, 0, 0, 0);

        tokenAmtOut = y0 - y1;
        slippage = 100 * (PRECISION - (tokenAmtOut.mulDivDown(IToken(token).getMarketPrice(), quoteWadIn)));
        minTokenAmtOut =
            quoteWadIn.mulDivDown(PRECISION, IToken(token).getMarketPrice()).mulDivDown(slippageTolerance, DIVISOR);
        autoMinTokenAmtOut = quoteWadIn.mulDivDown(PRECISION, IToken(token).getMarketPrice()).mulDivDown(
            (DIVISOR * PRECISION) - ((slippage + PRECISION / 10) * 100), DIVISOR * PRECISION
        );
    }

    function buyTokenOut(address token, uint256 tokenAmtOut, uint256 slippageTolerance)
        external
        view
        returns (uint256 quoteRawIn, uint256 slippage, uint256 minTokenAmtOut, uint256 autoMinTokenAmtOut)
    {
        uint256 xv = IToken(token).reserveVirtQuoteWad();
        uint256 xr = IToken(token).reserveRealQuoteWad();
        uint256 x0 = xv + xr;
        uint256 y0 = IToken(token).reserveTokenAmt();

        if (tokenAmtOut > y0) return (0, 0, 0, 0);

        uint256 quoteWadIn = DIVISOR.mulDivDown(x0.mulDivDown(y0, y0 - tokenAmtOut) - x0, DIVISOR - FEE);

        if (quoteWadIn < MIN_TRADE_AMOUNT) return (0, 0, 0, 0);

        quoteRawIn = IToken(token).wadToRaw(quoteWadIn);

        if (quoteRawIn == 0) return (0, 0, 0, 0);

        slippage = 100 * (PRECISION - (tokenAmtOut.mulDivDown(IToken(token).getMarketPrice(), quoteWadIn)));
        minTokenAmtOut = tokenAmtOut.mulDivDown(slippageTolerance, DIVISOR);
        autoMinTokenAmtOut =
            tokenAmtOut.mulDivDown((DIVISOR * PRECISION) - ((slippage + PRECISION / 10) * 100), DIVISOR * PRECISION);
    }

    function sellTokenIn(address token, uint256 tokenAmtIn, uint256 slippageTolerance)
        external
        view
        returns (uint256 quoteRawOut, uint256 slippage, uint256 minQuoteRawOut, uint256 autoMinQuoteRawOut)
    {
        if (tokenAmtIn < MIN_TRADE_AMOUNT) return (0, 0, 0, 0);
        if (tokenAmtIn > IToken(token).maxSupply()) return (0, 0, 0, 0);

        uint256 xr = IToken(token).reserveRealQuoteWad();
        uint256 xv = IToken(token).reserveVirtQuoteWad();

        uint256 feeAmt = (tokenAmtIn * FEE) / DIVISOR;
        uint256 netAmt = tokenAmtIn - feeAmt;

        uint256 y0 = IToken(token).reserveTokenAmt();
        uint256 y1 = y0 + netAmt;
        uint256 x0 = xv + xr;
        uint256 x1 = x0.mulDivDown(y0, y1);

        if (x1 >= x0) return (0, 0, 0, 0);

        uint256 quoteWadOut = x0 - x1;
        quoteRawOut = IToken(token).wadToRaw(quoteWadOut);

        if (quoteRawOut == 0) return (0, 0, 0, 0);

        slippage = 100
            * (
                PRECISION
                    - (quoteWadOut.mulDivDown(PRECISION, tokenAmtIn.mulDivDown(IToken(token).getMarketPrice(), PRECISION)))
            );
        uint256 minQuoteWadOut =
            tokenAmtIn.mulDivDown(IToken(token).getMarketPrice(), PRECISION).mulDivDown(slippageTolerance, DIVISOR);
        minQuoteRawOut = IToken(token).wadToRaw(minQuoteWadOut);
        uint256 autoMinQuoteWadOut = tokenAmtIn.mulDivDown(IToken(token).getMarketPrice(), PRECISION).mulDivDown(
            (DIVISOR * PRECISION) - ((slippage + PRECISION / 10) * 100), DIVISOR * PRECISION
        );
        autoMinQuoteRawOut = IToken(token).wadToRaw(autoMinQuoteWadOut);
    }

    function sellQuoteOut(address token, uint256 quoteRawOut, uint256 slippageTolerance)
        external
        view
        returns (uint256 tokenAmtIn, uint256 slippage, uint256 minQuoteRawOut, uint256 autoMinQuoteRawOut)
    {
        uint256 xv = IToken(token).reserveVirtQuoteWad();
        uint256 xr = IToken(token).reserveRealQuoteWad();
        uint256 x0 = xv + xr;
        uint256 y0 = IToken(token).reserveTokenAmt();

        uint256 quoteWadOut = IToken(token).rawToWad(quoteRawOut);

        if (quoteWadOut > xr) return (0, 0, 0, 0);

        tokenAmtIn = DIVISOR.mulDivDown((x0.mulDivUp(y0, x0 - quoteWadOut)) - y0, DIVISOR - FEE);

        if (tokenAmtIn < MIN_TRADE_AMOUNT) return (0, 0, 0, 0);

        slippage = 100
            * (
                PRECISION
                    - (quoteWadOut.mulDivDown(PRECISION, (tokenAmtIn.mulDivDown(IToken(token).getMarketPrice(), PRECISION))))
            );
        uint256 minQuoteWadIn = quoteWadOut.mulDivDown(slippageTolerance, DIVISOR);
        minQuoteRawOut = IToken(token).wadToRaw(minQuoteWadIn);
        uint256 autoMinQuoteWadIn =
            quoteWadOut.mulDivDown((DIVISOR * PRECISION) - ((slippage + PRECISION / 10) * 100), DIVISOR * PRECISION);
        autoMinQuoteRawOut = IToken(token).wadToRaw(autoMinQuoteWadIn);
    }
}
