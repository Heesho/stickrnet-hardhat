// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

interface IContent {
    struct Auction {
        uint16 epochId;
        uint192 initPrice;
        uint40 startTime;
    }

    function rewarder() external view returns (address);
    function token() external view returns (address);
    function quote() external view returns (address);
    function uri() external view returns (string memory);
    function isModerated() external view returns (bool);
    function account_IsModerator(address account) external view returns (bool);
    function nextTokenId() external view returns (uint256);
    function id_Stake(uint256 tokenId) external view returns (uint256);
    function id_Creator(uint256 tokenId) external view returns (address);
    function id_IsApproved(uint256 tokenId) external view returns (bool);
    function getAuction(uint256 tokenId) external view returns (Auction memory);
    function tokenURI(uint256 tokenId) external view returns (string memory);
    function getPrice(uint256 tokenId) external view returns (uint256);
    function ownerOf(uint256 tokenId) external view returns (address);
    function balanceOf(address account) external view returns (uint256);
    function owner() external view returns (address);

    function create(address to, string memory tokenUri) external returns (uint256 tokenId);
    function collect(address to, uint256 tokenId, uint256 epochId, uint256 deadline, uint256 maxPrice)
        external
        returns (uint256 price);
    function distribute() external;
}
