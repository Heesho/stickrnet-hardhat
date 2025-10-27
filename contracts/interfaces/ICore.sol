// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

interface ICore {
    function INITIAL_SUPPLY() external view returns (uint256);
    function RESERVE_VIRT_QUOTE_RAW() external view returns (uint256);
    function quote() external view returns (address);
    function tokenFactory() external view returns (address);
    function contentFactory() external view returns (address);
    function rewarderFactory() external view returns (address);
    function treasury() external view returns (address);
    function index() external view returns (uint256);
    function index_Token(uint256 index) external view returns (address);
    function token_Index(address token) external view returns (uint256);

    function create(
        string memory name,
        string memory symbol,
        string memory uri,
        address owner,
        bool isModerated,
        uint256 quoteRawIn,
        uint256 coreTokenAmtRequired
    ) external returns (address token);
}
