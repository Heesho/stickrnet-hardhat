// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

interface IRewarderFactory {
    function lastRewarder() external view returns (address);

    function create(address content) external returns (address);
}