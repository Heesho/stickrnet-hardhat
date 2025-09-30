// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {ITokenFactory} from "./interfaces/ITokenFactory.sol";
import {IToken} from "./interfaces/IToken.sol";

contract Core is Ownable {
    uint256 public constant INITIAL_SUPPLY = 1_000_000_000 * 1e18;
    uint256 public constant RESERVE_VIRT_QUOTE_RAW = 100_000 * 1e6;

    address public immutable quote;

    address public tokenFactory;
    address public contentFactory;
    address public rewarderFactory;
    address public treasury;

    uint256 public index;
    mapping(uint256 => address) public index_Token;
    mapping(address => uint256) public token_Index;

    event Core__TokenCreated(
        string name,
        string symbol,
        string uri,
        uint256 index,
        address token,
        address content,
        address rewarder,
        address indexed owner,
        bool isModerated
    );
    event Core__TreasurySet(address newTreasury);
    event Core__TokenFactorySet(address newTokenFactory);
    event Core__SaleFactorySet(address newSaleFactory);
    event Core__ContentFactorySet(address newContentFactory);
    event Core__RewarderFactorySet(address newRewarderFactory);

    constructor(address _quote, address _tokenFactory, address _contentFactory, address _rewarderFactory) Ownable() {
        quote = _quote;
        tokenFactory = _tokenFactory;
        contentFactory = _contentFactory;
        rewarderFactory = _rewarderFactory;
    }

    function create(string memory name, string memory symbol, string memory uri, address owner, bool isModerated)
        external
        returns (address token)
    {
        index++;

        token = ITokenFactory(tokenFactory).create(
            name,
            symbol,
            uri,
            address(this),
            quote,
            INITIAL_SUPPLY,
            RESERVE_VIRT_QUOTE_RAW,
            contentFactory,
            rewarderFactory,
            owner,
            isModerated
        );

        index_Token[index] = token;
        token_Index[token] = index;

        emit Core__TokenCreated(
            name, symbol, uri, index, token, IToken(token).content(), IToken(token).rewarder(), owner, isModerated
        );
    }

    function setTreasury(address _treasury) external onlyOwner {
        treasury = _treasury;
        emit Core__TreasurySet(_treasury);
    }

    function setTokenFactory(address _tokenFactory) external onlyOwner {
        tokenFactory = _tokenFactory;
        emit Core__TokenFactorySet(_tokenFactory);
    }

    function setContentFactory(address _contentFactory) external onlyOwner {
        contentFactory = _contentFactory;
        emit Core__ContentFactorySet(_contentFactory);
    }

    function setRewarderFactory(address _rewarderFactory) external onlyOwner {
        rewarderFactory = _rewarderFactory;
        emit Core__RewarderFactorySet(_rewarderFactory);
    }
}
