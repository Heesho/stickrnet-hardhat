// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

interface ITokenFactory {
    function lastToken() external view returns (address);

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
        bool isModerated
    ) external returns (address token);
}