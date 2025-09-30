// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

interface IContent {
    function rewarder() external view returns (address);
    function token() external view returns (address);
    function quote() external view returns (address);
    function uri() external view returns (string memory);
    function isModerated() external view returns (bool);
    function account_IsModerator(address account) external view returns (bool);
    function nextTokenId() external view returns (uint256);
    function id_Price(uint256 tokenId) external view returns (uint256);
    function id_Creator(uint256 tokenId) external view returns (address);
    function id_IsApproved(uint256 tokenId) external view returns (bool);
    function tokenURI(uint256 tokenId) external view returns (string memory);
    function getNextPrice(uint256 tokenId) external view returns (uint256);
    function owner() external view returns (address);
    function balanceOf(address account) external view returns (uint256);

    function create(address to, string memory tokenUri) external returns (uint256 tokenId);
    function collect(address to, uint256 tokenId, uint256 maxPrice) external;
    function distribute() external;
}