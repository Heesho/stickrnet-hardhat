// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import {IERC20, SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {ICore} from "./interfaces/ICore.sol";
import {IToken} from "./interfaces/IToken.sol";
import {IContent} from "./interfaces/IContent.sol";
import {IRewarder} from "./interfaces/IRewarder.sol";

contract Router is ReentrancyGuard, Ownable {
    using SafeERC20 for IERC20;

    uint256 public constant CORE_TOKEN_AMT_REQUIRED = 1e18;

    address public immutable core;

    mapping(address => address) public account_Affiliate;

    event Router__TokenCreated(
        string name,
        string symbol,
        string uri,
        address indexed token,
        address indexed creator,
        bool isModerated,
        uint256 amountQuoteIn
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
    event Router__ContentCollected(
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
        address quote = ICore(core).quote();
        IERC20(quote).safeTransferFrom(msg.sender, address(this), amountQuoteIn);
        _safeApprove(quote, core, amountQuoteIn);
        token = ICore(core).create(name, symbol, uri, msg.sender, isModerated, amountQuoteIn, CORE_TOKEN_AMT_REQUIRED);

        emit Router__TokenCreated(name, symbol, uri, token, msg.sender, isModerated, amountQuoteIn);
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

    function collectContent(address token, uint256 tokenId, uint256 epochId, uint256 deadline, uint256 maxPrice)
        external
        nonReentrant
    {
        address content = IToken(token).content();
        address quote = ICore(core).quote();
        uint256 price = IContent(content).getPrice(tokenId);

        IERC20(quote).safeTransferFrom(msg.sender, address(this), price);
        _safeApprove(quote, content, price);

        IContent(content).collect(msg.sender, tokenId, epochId, deadline, maxPrice);

        emit Router__ContentCollected(token, content, msg.sender, price, tokenId);
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
