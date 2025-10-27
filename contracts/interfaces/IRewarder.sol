// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

interface IRewarder {
    function DURATION() external view returns (uint256);
    function PRECISION() external view returns (uint256);
    function content() external view returns (address);
    function rewardTokens() external view returns (address[] memory);
    function token_RewardData(address token)
        external
        view
        returns (uint256 periodFinish, uint256 rewardRate, uint256 lastUpdateTime, uint256 rewardPerTokenStored);
    function token_IsReward(address token) external view returns (bool);
    function account_Token_LastRewardPerToken(address account, address token) external view returns (uint256);
    function account_Token_Reward(address account, address token) external view returns (uint256);
    function totalSupply() external view returns (uint256);
    function account_Balance(address account) external view returns (uint256);
    function left(address token) external view returns (uint256);
    function lastTimeRewardApplicable(address token) external view returns (uint256);
    function rewardPerToken(address token) external view returns (uint256);
    function earned(address account, address token) external view returns (uint256);
    function getRewardForDuration(address token) external view returns (uint256);
    function getRewardTokens() external view returns (address[] memory);

    function getReward(address account) external;
    function notifyRewardAmount(address token, uint256 amount) external;
    function deposit(address account, uint256 amount) external;
    function withdraw(address account, uint256 amount) external;
    function addReward(address token) external;
}
