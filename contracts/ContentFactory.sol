// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import {ERC721, ERC721Enumerable, IERC721} from "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import {ERC721URIStorage} from "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import {IERC20, SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {IRewarderFactory} from "./interfaces/IRewarderFactory.sol";
import {IRewarder} from "./interfaces/IRewarder.sol";
import {IToken} from "./interfaces/IToken.sol";

contract Content is ERC721, ERC721Enumerable, ERC721URIStorage, ReentrancyGuard, Ownable {
    using SafeERC20 for IERC20;

    uint256 public constant FEE = 1_000;
    uint256 public constant DIVISOR = 10_000;
    uint256 public constant PRECISION = 1e18;
    uint256 public constant EPOCH_PERIOD = 30 days;
    uint256 public constant PRICE_MULTIPLIER = 2e18;
    uint256 public constant ABS_MAX_INIT_PRICE = type(uint192).max;

    address public immutable rewarder;
    address public immutable token;
    address public immutable quote;
    uint256 public immutable minInitPrice;

    string public uri;

    bool public isModerated;
    mapping(address => bool) public account_IsModerator;

    uint256 public nextTokenId;

    mapping(uint256 => uint256) public id_Stake;
    mapping(uint256 => address) public id_Creator;
    mapping(uint256 => bool) public id_IsApproved;
    mapping(uint256 => Auction) public id_Auction;

    struct Auction {
        uint16 epochId;
        uint192 initPrice;
        uint40 startTime;
    }

    error Content__ZeroTo();
    error Content__ZeroLengthUri();
    error Content__ZeroMinPrice();
    error Content__InvalidTokenId();
    error Content__Expired();
    error Content__EpochIdMismatch();
    error Content__MaxPriceExceeded();
    error Content__TransferDisabled();
    error Content__NotApproved();
    error Content__AlreadyApproved();
    error Content__NotModerator();

    event Content__Created(address indexed who, address indexed to, uint256 indexed tokenId, string uri);
    event Content__Collected(address indexed who, address indexed to, uint256 indexed tokenId, uint256 price);
    event Content__UriSet(string uri);
    event Content__IsModeratedSet(bool isModerated);
    event Content__ModeratorsSet(address indexed account, bool isModerator);
    event Content__Approved(address indexed moderator, uint256 indexed tokenId);
    event Content__RewardAdded(address indexed rewardToken);

    constructor(
        string memory name,
        string memory symbol,
        string memory _uri,
        address _token,
        address _quote,
        address rewarderFactory,
        uint256 _minInitPrice,
        bool _isModerated
    ) ERC721(name, symbol) {
        if (_minInitPrice == 0) revert Content__ZeroMinPrice();
        if (bytes(_uri).length == 0) revert Content__ZeroLengthUri();
        uri = _uri;
        token = _token;
        quote = _quote;
        minInitPrice = _minInitPrice;
        isModerated = _isModerated;
        rewarder = IRewarderFactory(rewarderFactory).create(address(this));
        IRewarder(rewarder).addReward(quote);
        IRewarder(rewarder).addReward(token);
    }

    function create(address to, string memory tokenUri) external nonReentrant returns (uint256 tokenId) {
        if (to == address(0)) revert Content__ZeroTo();
        if (bytes(tokenUri).length == 0) revert Content__ZeroLengthUri();

        tokenId = ++nextTokenId;
        id_Creator[tokenId] = to;
        if (!isModerated) id_IsApproved[tokenId] = true;

        id_Auction[tokenId] =
            Auction({epochId: 0, initPrice: uint192(minInitPrice), startTime: uint40(block.timestamp)});

        _safeMint(to, tokenId);
        _setTokenURI(tokenId, tokenUri);

        emit Content__Created(msg.sender, to, tokenId, tokenUri);
    }

    function collect(address to, uint256 tokenId, uint256 epochId, uint256 deadline, uint256 maxPrice)
        external
        nonReentrant
        returns (uint256 price)
    {
        if (to == address(0)) revert Content__ZeroTo();
        if (ownerOf(tokenId) == address(0)) revert Content__InvalidTokenId();
        if (!id_IsApproved[tokenId]) revert Content__NotApproved();
        if (block.timestamp > deadline) revert Content__Expired();

        Auction memory auction = id_Auction[tokenId];
        if (uint16(epochId) != auction.epochId) revert Content__EpochIdMismatch();

        price = getPriceFromCache(auction);
        if (price > maxPrice) revert Content__MaxPriceExceeded();

        address creator = id_Creator[tokenId];
        address prevOwner = ownerOf(tokenId);
        uint256 prevStake = id_Stake[tokenId];
        uint256 feeRaw = price * FEE / DIVISOR;
        uint256 healRaw = feeRaw / 2;

        uint256 newInitPrice = price * PRICE_MULTIPLIER / PRECISION;

        if (newInitPrice > ABS_MAX_INIT_PRICE) {
            newInitPrice = ABS_MAX_INIT_PRICE;
        } else if (newInitPrice < minInitPrice) {
            newInitPrice = minInitPrice;
        }

        unchecked {
            auction.epochId++;
        }
        auction.initPrice = uint192(newInitPrice);
        auction.startTime = uint40(block.timestamp);

        id_Auction[tokenId] = auction;
        id_Stake[tokenId] = price;

        _transfer(prevOwner, to, tokenId);

        if (price > 0) {
            IERC20(quote).safeTransferFrom(msg.sender, address(this), price);

            IERC20(quote).safeTransfer(prevOwner, price - feeRaw);
            IERC20(quote).safeTransfer(creator, feeRaw - healRaw);

            IERC20(quote).safeApprove(token, 0);
            IERC20(quote).safeApprove(token, healRaw);
            IToken(token).heal(healRaw);

            IRewarder(rewarder).deposit(to, price);
        }
        if (prevStake > 0) {
            IRewarder(rewarder).withdraw(prevOwner, prevStake);
        }

        emit Content__Collected(msg.sender, to, tokenId, price);

        return price;
    }

    function distribute() external {
        uint256 duration = IRewarder(rewarder).DURATION();

        uint256 balanceQuote = IERC20(quote).balanceOf(address(this));
        uint256 leftQuote = IRewarder(rewarder).left(quote);
        if (balanceQuote > leftQuote && balanceQuote > duration) {
            IERC20(quote).safeApprove(rewarder, 0);
            IERC20(quote).safeApprove(rewarder, balanceQuote);
            IRewarder(rewarder).notifyRewardAmount(quote, balanceQuote);
        }

        uint256 balanceToken = IERC20(token).balanceOf(address(this));
        uint256 leftToken = IRewarder(rewarder).left(token);
        if (balanceToken > leftToken && balanceToken > duration) {
            IERC20(token).safeApprove(rewarder, 0);
            IERC20(token).safeApprove(rewarder, balanceToken);
            IRewarder(rewarder).notifyRewardAmount(token, balanceToken);
        }
    }

    function approve(address, uint256) public virtual override(ERC721, IERC721) {
        revert Content__TransferDisabled();
    }

    function setApprovalForAll(address, bool) public virtual override(ERC721, IERC721) {
        revert Content__TransferDisabled();
    }

    function transferFrom(address, address, uint256) public virtual override(ERC721, IERC721) {
        revert Content__TransferDisabled();
    }

    function safeTransferFrom(address, address, uint256) public virtual override(ERC721, IERC721) {
        revert Content__TransferDisabled();
    }

    function safeTransferFrom(address, address, uint256, bytes memory) public virtual override(ERC721, IERC721) {
        revert Content__TransferDisabled();
    }

    function _beforeTokenTransfer(address from, address to, uint256 firstTokenId, uint256 batchSize)
        internal
        override(ERC721, ERC721Enumerable)
    {
        super._beforeTokenTransfer(from, to, firstTokenId, batchSize);
    }

    function setUri(string memory _uri) external onlyOwner {
        uri = _uri;
        emit Content__UriSet(_uri);
    }

    function setIsModerated(bool _isModerated) external onlyOwner {
        isModerated = _isModerated;
        emit Content__IsModeratedSet(_isModerated);
    }

    function setModerators(address[] calldata accounts, bool isModerator) external onlyOwner {
        for (uint256 i = 0; i < accounts.length; i++) {
            account_IsModerator[accounts[i]] = isModerator;
            emit Content__ModeratorsSet(accounts[i], isModerator);
        }
    }

    function approveContents(uint256[] calldata tokenIds) external {
        if (msg.sender != owner() && !account_IsModerator[msg.sender]) revert Content__NotModerator();
        for (uint256 i = 0; i < tokenIds.length; i++) {
            if (id_IsApproved[tokenIds[i]]) revert Content__AlreadyApproved();
            if (ownerOf(tokenIds[i]) == address(0)) revert Content__InvalidTokenId();
            id_IsApproved[tokenIds[i]] = true;
            emit Content__Approved(msg.sender, tokenIds[i]);
        }
    }

    function addReward(address rewardToken) external onlyOwner {
        IRewarder(rewarder).addReward(rewardToken);
        emit Content__RewardAdded(rewardToken);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC721Enumerable, ERC721URIStorage)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    function _burn(uint256 tokenId) internal override(ERC721, ERC721URIStorage) {
        super._burn(tokenId);
    }

    function getPriceFromCache(Auction memory auction) public view returns (uint256) {
        uint256 timePassed = block.timestamp - auction.startTime;

        if (timePassed > EPOCH_PERIOD) {
            return 0;
        }

        return auction.initPrice - auction.initPrice * timePassed / EPOCH_PERIOD;
    }

    function tokenURI(uint256 tokenId) public view override(ERC721, ERC721URIStorage) returns (string memory) {
        return super.tokenURI(tokenId);
    }

    function getAuction(uint256 tokenId) external view returns (Auction memory) {
        return id_Auction[tokenId];
    }

    function getPrice(uint256 tokenId) external view returns (uint256) {
        return getPriceFromCache(id_Auction[tokenId]);
    }
}

contract ContentFactory {
    address public lastContent;

    event ContentFactory__Created(address indexed content);

    function create(
        string memory name,
        string memory symbol,
        string memory uri,
        address token,
        address quote,
        address rewarderFactory,
        address owner,
        uint256 initialPrice,
        bool isModerated
    ) external returns (address, address) {
        Content content = new Content(name, symbol, uri, token, quote, rewarderFactory, initialPrice, isModerated);
        lastContent = address(content);
        content.transferOwnership(owner);
        emit ContentFactory__Created(lastContent);
        return (address(content), content.rewarder());
    }
}
