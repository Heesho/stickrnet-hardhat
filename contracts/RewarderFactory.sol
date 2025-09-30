// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import {IERC20, SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import {Math} from "@openzeppelin/contracts/utils/math/Math.sol";

contract Rewarder is ReentrancyGuard {
    using SafeERC20 for IERC20;

    uint256 public constant DURATION = 7 days;
    uint256 public constant PRECISION = 1e18;

    address public immutable content;

    address[] public rewardTokens;
    mapping(address => Reward) public token_RewardData;
    mapping(address => bool) public token_IsReward;

    mapping(address => mapping(address => uint256)) public account_Token_LastRewardPerToken;
    mapping(address => mapping(address => uint256)) public account_Token_Reward;

    uint256 public totalSupply;
    mapping(address => uint256) public account_Balance;

    struct Reward {
        uint256 periodFinish;
        uint256 rewardRate;
        uint256 lastUpdateTime;
        uint256 rewardPerTokenStored;
    }

    error Rewarder__NotContent();
    error Rewarder__RewardSmallerThanLeft();
    error Rewarder__NotRewardToken();
    error Rewarder__RewardTokenAlreadyAdded();
    error Rewarder__ZeroAmount();

    event Rewarder__RewardAdded(address indexed rewardToken);
    event Rewarder__RewardNotified(address indexed rewardToken, uint256 reward);
    event Rewarder__Deposited(address indexed user, uint256 amount);
    event Rewarder__Withdrawn(address indexed user, uint256 amount);
    event Rewarder__RewardPaid(address indexed user, address indexed rewardsToken, uint256 reward);

    modifier updateReward(address account) {
        for (uint256 i; i < rewardTokens.length; i++) {
            address token = rewardTokens[i];
            token_RewardData[token].rewardPerTokenStored = rewardPerToken(token);
            token_RewardData[token].lastUpdateTime = lastTimeRewardApplicable(token);
            if (account != address(0)) {
                account_Token_Reward[account][token] = earned(account, token);
                account_Token_LastRewardPerToken[account][token] = token_RewardData[token].rewardPerTokenStored;
            }
        }
        _;
    }

    modifier onlyContent() {
        if (msg.sender != content) {
            revert Rewarder__NotContent();
        }
        _;
    }

    modifier nonZeroInput(uint256 amount) {
        if (amount == 0) revert Rewarder__ZeroAmount();
        _;
    }

    constructor(address _content) {
        content = _content;
    }

    function getReward(address account) external nonReentrant updateReward(account) {
        for (uint256 i = 0; i < rewardTokens.length; i++) {
            address token = rewardTokens[i];
            uint256 amount = account_Token_Reward[account][token];
            if (amount > 0) {
                account_Token_Reward[account][token] = 0;
                emit Rewarder__RewardPaid(account, token, amount);

                IERC20(token).safeTransfer(account, amount);
            }
        }
    }

    function notifyRewardAmount(address token, uint256 amount) external nonReentrant updateReward(address(0)) {
        if (!token_IsReward[token]) revert Rewarder__NotRewardToken();
        uint256 leftover = left(token);
        if (amount < leftover) revert Rewarder__RewardSmallerThanLeft();

        IERC20(token).safeTransferFrom(msg.sender, address(this), amount);
        if (block.timestamp >= token_RewardData[token].periodFinish) {
            token_RewardData[token].rewardRate = amount * PRECISION / DURATION;
        } else {
            uint256 totalReward = amount + leftover;
            token_RewardData[token].rewardRate = totalReward * PRECISION / DURATION;
        }
        token_RewardData[token].lastUpdateTime = block.timestamp;
        token_RewardData[token].periodFinish = block.timestamp + DURATION;
        emit Rewarder__RewardNotified(token, amount);
    }

    function deposit(address account, uint256 amount) external onlyContent nonZeroInput(amount) updateReward(account) {
        totalSupply = totalSupply + amount;
        account_Balance[account] = account_Balance[account] + amount;
        emit Rewarder__Deposited(account, amount);
    }

    function withdraw(address account, uint256 amount)
        external
        onlyContent
        nonZeroInput(amount)
        updateReward(account)
    {
        totalSupply = totalSupply - amount;
        account_Balance[account] = account_Balance[account] - amount;
        emit Rewarder__Withdrawn(account, amount);
    }

    function addReward(address token) external onlyContent {
        if (token_IsReward[token]) revert Rewarder__RewardTokenAlreadyAdded();
        token_IsReward[token] = true;
        rewardTokens.push(token);
        emit Rewarder__RewardAdded(token);
    }

    function left(address token) public view returns (uint256 leftover) {
        if (block.timestamp >= token_RewardData[token].periodFinish) return 0;
        uint256 remaining = token_RewardData[token].periodFinish - block.timestamp;
        return remaining * token_RewardData[token].rewardRate / PRECISION;
    }

    function lastTimeRewardApplicable(address token) public view returns (uint256) {
        return Math.min(block.timestamp, token_RewardData[token].periodFinish);
    }

    function rewardPerToken(address token) public view returns (uint256) {
        if (totalSupply == 0) {
            return token_RewardData[token].rewardPerTokenStored;
        }
        return token_RewardData[token].rewardPerTokenStored
            + (
                (
                    (lastTimeRewardApplicable(token) - token_RewardData[token].lastUpdateTime)
                        * token_RewardData[token].rewardRate
                ) / totalSupply
            );
    }

    function earned(address account, address token) public view returns (uint256) {
        return (
            (account_Balance[account] * (rewardPerToken(token) - account_Token_LastRewardPerToken[account][token]))
                / PRECISION
        ) + account_Token_Reward[account][token];
    }

    function getRewardForDuration(address token) external view returns (uint256) {
        return token_RewardData[token].rewardRate * DURATION / PRECISION;
    }

}

contract RewarderFactory {
    address public lastRewarder;

    event RewarderFactory__Created(address indexed rewarder);

    function create(address content) external returns (address) {
        Rewarder rewarder = new Rewarder(content);
        lastRewarder = address(rewarder);
        emit RewarderFactory__Created(lastRewarder);
        return address(rewarder);
    }
}
