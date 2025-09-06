// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import {ERC721, ERC721Enumerable, IERC721} from "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import {ERC721URIStorage} from "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import {IERC20, SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

interface IRewarderFactory {
    function create(address content) external returns (address);
}

interface IRewarder {
    function duration() external view returns (uint256);

    function left(address token) external view returns (uint256);

    function notifyRewardAmount(address token, uint256 amount) external;

    function deposit(address account, uint256 amount) external;

    function withdraw(address account, uint256 amount) external;

    function addReward(address token) external;
}

interface IToken {
    function heal(uint256 amount) external;
}

contract Content is ERC721, ERC721Enumerable, ERC721URIStorage, ReentrancyGuard, Ownable {
    using SafeERC20 for IERC20;

    address public immutable rewarder;
    address public immutable token;
    address public immutable quote;

    string public uri;

    bool public isModerated;
    mapping(address => bool) public account_IsModerator;

    uint256 public nextTokenId;

    mapping(uint256 => uint256) public id_Price;
    mapping(uint256 => address) public id_Creator;
    mapping(uint256 => bool) public id_IsApproved;

    error Content__ZeroTo();
    error Content__NotCreator();
    error Content__InvalidTokenId();
    error Content__TransferDisabled();
    error Content__NotApproved();
    error Content__AlreadyApproved();
    error Content__NotModerator();

    event Content__Created(address indexed who, address indexed to, uint256 indexed tokenId, string uri);
    event Content__Curated(address indexed who, address indexed to, uint256 indexed tokenId, uint256 price);
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
        bool _isModerated
    ) ERC721(name, symbol) {
        uri = _uri;
        token = _token;
        quote = _quote;
        isModerated = _isModerated;
        rewarder = IRewarderFactory(rewarderFactory).create(address(this));
        IRewarder(rewarder).addReward(quote);
        IRewarder(rewarder).addReward(token);
    }

    function create(address to, string memory tokenUri) external nonReentrant returns (uint256 tokenId) {
        if (to == address(0)) revert Content__ZeroTo();

        tokenId = ++nextTokenId;
        id_Creator[tokenId] = to;
        if (!isModerated) id_IsApproved[tokenId] = true;

        _safeMint(to, tokenId);
        _setTokenURI(tokenId, tokenUri);

        emit Content__Created(msg.sender, to, tokenId, tokenUri);
    }

    function curate(address to, uint256 tokenId) external nonReentrant {
        if (to == address(0)) revert Content__ZeroTo();
        if (ownerOf(tokenId) == address(0)) revert Content__InvalidTokenId();
        if (!id_IsApproved[tokenId]) revert Content__NotApproved();

        address creator = id_Creator[tokenId];
        uint256 prevPrice = id_Price[tokenId];
        address prevOwner = ownerOf(tokenId);
        uint256 nextPrice = getNextPrice(tokenId);
        uint256 surplus = nextPrice - prevPrice;

        id_Price[tokenId] = nextPrice;
        _transfer(prevOwner, to, tokenId);

        IERC20(quote).safeTransferFrom(msg.sender, address(this), nextPrice);

        IERC20(quote).safeTransfer(prevOwner, prevPrice + ((surplus * 3) / 9));
        IERC20(quote).safeTransfer(creator, (surplus * 3) / 9);

        IERC20(quote).safeApprove(token, 0);
        IERC20(quote).safeApprove(token, (surplus * 3) / 9);
        IToken(token).heal((surplus * 3) / 9);

        if (prevPrice > 0) {
            IRewarder(rewarder).withdraw(prevOwner, prevPrice);
        }
        IRewarder(rewarder).deposit(to, nextPrice);

        emit Content__Curated(msg.sender, to, tokenId, nextPrice);
    }

    function distribute() external {
        uint256 duration = IRewarder(rewarder).duration();

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

    function tokenURI(uint256 tokenId) public view override(ERC721, ERC721URIStorage) returns (string memory) {
        return super.tokenURI(tokenId);
    }

    function getNextPrice(uint256 tokenId) public view returns (uint256) {
        return (id_Price[tokenId] * 11) / 10 + 1e6;
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
        bool isModerated
    ) external returns (address, address) {
        Content content = new Content(name, symbol, uri, token, quote, rewarderFactory, isModerated);
        lastContent = address(content);
        content.transferOwnership(owner);
        emit ContentFactory__Created(lastContent);
        return (address(content), content.rewarder());
    }
}
