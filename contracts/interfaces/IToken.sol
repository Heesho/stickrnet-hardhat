// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

interface IToken {
    function PRECISION() external view returns (uint256);
    function FEE() external view returns (uint256);
    function FEE_AMOUNT() external view returns (uint256);
    function DIVISOR() external view returns (uint256);
    function MIN_TRADE_SIZE() external view returns (uint256);
    function core() external view returns (address);
    function quote() external view returns (address);
    function content() external view returns (address);
    function rewarder() external view returns (address);
    function quoteDecimals() external view returns (uint8);
    function quoteScale() external view returns (uint256);
    function maxSupply() external view returns (uint256);
    function reserveRealQuoteWad() external view returns (uint256);
    function reserveVirtQuoteWad() external view returns (uint256);
    function reserveTokenAmt() external view returns (uint256);
    function totalDebtRaw() external view returns (uint256);
    function account_DebtRaw(address account) external view returns (uint256);
    function getMarketPrice() external view returns (uint256);
    function getFloorPrice() external view returns (uint256);
    function getAccountCredit(address account) external view returns (uint256);
    function getAccountTransferrable(address account) external view returns (uint256);
    function rawToWad(uint256 raw) external view returns (uint256);
    function wadToRaw(uint256 wad) external view returns (uint256);

    function buy(
        uint256 amountQuoteIn,
        uint256 minAmountTokenOut,
        uint256 expireTimestamp,
        address to,
        address provider
    ) external returns (uint256 amountTokenOut);
    function sell(
        uint256 amountTokenIn,
        uint256 minAmountQuoteOut,
        uint256 expireTimestamp,
        address to,
        address provider
    ) external returns (uint256 amountQuoteOut);
    function borrow(address to, uint256 quoteRaw) external;
    function repay(address to, uint256 quoteRaw) external;
    function heal(uint256 quoteRaw) external;
    function burn(uint256 tokenAmt) external;
}
