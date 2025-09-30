// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

interface IContentFactory {
    function lastContent() external view returns (address);

    function create(
        string memory name,
        string memory symbol,
        string memory uri,
        address token,
        address quote,
        address rewarderFactory,
        address owner,
        bool isModerated
    ) external returns (address, address);
}