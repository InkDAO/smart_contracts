// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.21;

import { Strings } from "@openzeppelin/contracts/utils/Strings.sol";
import { Initializable } from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import { PausableUpgradeable } from "@openzeppelin/contracts-upgradeable/utils/PausableUpgradeable.sol";
import { ERC6909Upgradeable } from "@openzeppelin/contracts-upgradeable/token/ERC6909/draft-ERC6909Upgradeable.sol";
import { ReentrancyGuardUpgradeable } from "@openzeppelin/contracts-upgradeable/utils/ReentrancyGuardUpgradeable.sol";
import { ERC6909TokenSupplyUpgradeable } from "@openzeppelin/contracts-upgradeable/token/ERC6909/extensions/draft-ERC6909TokenSupplyUpgradeable.sol";

import { UtilLib } from "./utils/UtilLib.sol";
import { DXconstants } from "./utils/DXconstants.sol";
import { IdXconfig } from "./interfaces/IdXconfig.sol";
import { DXroleChecker } from "./utils/DXroleChecker.sol";
import { IMarketPlace } from "./interfaces/IMarketPlace.sol";

/**
 * @title MarketPlace
 * @notice Decentralized marketplace for tokenized posts using ERC6909 multi-token standard
 * @dev Each post is represented by a unique token ID instead of separate ERC20 contracts
 */
contract MarketPlace is 
    Initializable,
    PausableUpgradeable, 
    ReentrancyGuardUpgradeable, 
    ERC6909Upgradeable, 
    ERC6909TokenSupplyUpgradeable,
    IMarketPlace
{
    IdXconfig public dXConfig;

    uint256 public nextTokenId;
    uint256 public maxPostTitleLength;
    uint256 public maxDescriptionLength;
    uint256 public maxPriceInNative;
    
    uint256[] public allTokenIds;
    mapping(uint256 => IMarketPlace.PostInfo) public postInfo;
    mapping(string => uint256) public postCidToTokenId;    
    mapping(address => uint256[]) private userTokenIds;
    
    constructor() {
        _disableInitializers();
    }

    receive() external payable {}
    
    function __MarketPlace_Init(
        address _dXConfig,
        uint256 _maxPostTitleLength,
        uint256 _maxDescriptionLength,
        uint256 _maxPriceInNative
    ) 
        public 
        initializer 
    {
        __ERC6909_init();
        __ERC6909TokenSupply_init();
        __Pausable_init();
        __ReentrancyGuard_init();

        dXConfig = IdXconfig(_dXConfig);

        nextTokenId = 1;
        maxPostTitleLength = _maxPostTitleLength;
        maxDescriptionLength = _maxDescriptionLength;
        maxPriceInNative = _maxPriceInNative;
    }
    
    modifier validPostParams(PostInfoParams calldata params) {
        if (bytes(params.postCid).length == 0) revert InvalidPostCid();
        if (postCidToTokenId[params.postCid] != 0) revert PostAlreadyExists();
        if (bytes(params.postTitle).length == 0) revert EmptyPostTitle();
        if (bytes(params.postTitle).length > maxPostTitleLength) revert PostTitleTooLong();
        if (bytes(params.thumbnailCid).length == 0) revert InvalidThumbnailCid();
        if (bytes(params.description).length > maxDescriptionLength) revert DescriptionTooLong();
        if (params.priceInNative > maxPriceInNative) revert InvalidPrice();
        _;
    }

    modifier onlydXPost(uint256 tokenId) {
        if (tokenId >= nextTokenId) revert PostDoesNotExist();
        _;
    }

    function createPost(IMarketPlace.PostInfoParams calldata params)
        external
        nonReentrant
        whenNotPaused
        validPostParams(params)
        returns (uint256 tokenId)
    {
        tokenId = nextTokenId++;

        postInfo[tokenId] = IMarketPlace.PostInfo({
            author: msg.sender,
            postCid: params.postCid,
            postTitle: params.postTitle,
            thumbnailCid: params.thumbnailCid,
            description: params.description,
            priceInNative: params.priceInNative
        });

        postCidToTokenId[params.postCid] = tokenId;
        allTokenIds.push(tokenId);

        emit PostCreated(
            tokenId,
            params.postTitle,
            params.postCid,
            params.thumbnailCid,
            msg.sender,
            params.priceInNative
        );
    }

    /**
     * @notice Subscribe to a post
     * @param tokenId The token ID of the post to subscribe to
     */
    function subscribePost(uint256 tokenId)
        external
        payable
        nonReentrant
        whenNotPaused
        onlydXPost(tokenId)
    {
        IMarketPlace.PostInfo memory info = postInfo[tokenId];

        if (msg.value < info.priceInNative) revert InsufficientPayment();

        _handlePayment(info.priceInNative, info.author);

        if (msg.value > info.priceInNative) {
            uint256 refund = msg.value - info.priceInNative;
            (bool refundSuccess, ) = payable(msg.sender).call{value: refund}("");
            if (!refundSuccess) revert NativeTransferFailed();
        }

        _mint(msg.sender, tokenId, 1);

        emit PostSubscribed(tokenId, msg.sender, info.priceInNative);
    }

    /**
     * @notice Update the price of a post (only by author)
     * @param tokenId The token ID of the post
     * @param newPrice The new price in wei
     */
    function updatePostPrice(uint256 tokenId, uint256 newPrice)
        external
        onlydXPost(tokenId)
    {
        if (postInfo[tokenId].author != msg.sender) revert NotPostAuthor();
        if (newPrice > maxPriceInNative) revert InvalidPrice();

        uint256 oldPrice = postInfo[tokenId].priceInNative;
        postInfo[tokenId].priceInNative = newPrice;

        emit PostPriceUpdated(tokenId, oldPrice, newPrice);
    }
    
    /**
     * @notice Get post information by token ID
     */
    function getPostInfo(uint256 tokenId) 
        external 
        view 
        returns (IMarketPlace.PostInfo memory) 
    {
        return postInfo[tokenId];
    }

    /**
     * @notice Get post information by CID
     */
    function getPostInfoByCid(string memory cid) 
        external 
        view 
        returns (IMarketPlace.PostInfo memory) 
    {
        uint256 tokenId = postCidToTokenId[cid];
        return postInfo[tokenId];
    }

    /**
     * @notice Get all posts information
     */
    function getAllPosts() 
        external 
        view 
        returns (IMarketPlace.PostInfo[] memory posts) 
    {
        uint256 length = allTokenIds.length;
        posts = new IMarketPlace.PostInfo[](length);

        for (uint256 i = 0; i < length; i++) {
            posts[i] = postInfo[allTokenIds[i]];
        }
    }

    /**
     * @notice Get user's post holdings
     */
    function getUserPosts(address user) 
        external 
        view 
        returns (uint256[] memory tokenIds) 
    {
        return userTokenIds[user];
    }

    /**
     * @notice Get total number of posts
     */
    function totalPosts() external view returns (uint256) {
        return allTokenIds.length;
    }
    
    /**
     * @notice Pause the contract
     */
    function pause() external {
        DXroleChecker.onlyAdmin(address(dXConfig));
        _pause();
    }

    /**
     * @notice Unpause the contract
     */
    function unpause() external {
        DXroleChecker.onlyAdmin(address(dXConfig));
        _unpause();
    }

    /**
     * @notice Update config contract
     */
    function updateDXConfig(address newConfig) external {
        DXroleChecker.onlyAdmin(address(dXConfig));
        UtilLib.checkNonZeroAddress(newConfig);
        dXConfig = IdXconfig(newConfig);
        emit ConfigUpdated(newConfig);
    }

    /**
     * @notice Update max post title length
     */
    function setMaxPostTitleLength(uint256 newLength) external {
        DXroleChecker.onlyAdmin(address(dXConfig));
        maxPostTitleLength = newLength;
        emit MaxPostTitleLengthUpdated(newLength);
    }

    /**
     * @notice Update max description length
     */
    function setMaxDescriptionLength(uint256 newLength) external {
        DXroleChecker.onlyAdmin(address(dXConfig));
        maxDescriptionLength = newLength;
        emit MaxDescriptionLengthUpdated(newLength);
    }

    /**
     * @notice Update max price in native
     */
    function setMaxPriceInNative(uint256 newPrice) external {
        DXroleChecker.onlyAdmin(address(dXConfig));
        maxPriceInNative = newPrice;
        emit MaxPriceInNativeUpdated(newPrice);
    }

    /**
     * @notice Withdraw platform fees
     */
    function withdrawFees(uint256 amount) external {
        DXroleChecker.onlyAdmin(address(dXConfig));

        if (amount > address(this).balance) revert MoreThanBalance();

        (bool success, ) = payable(msg.sender).call{value: amount}("");
        if (!success) revert NativeTransferFailed();

        emit PlatformFeeWithdrawn(amount, msg.sender);
    }

    /**
     * @notice Handle payment distribution between platform and author
     */
    function _handlePayment(uint256 totalAmount, address author) internal {
        uint256 platformFee = (totalAmount * dXConfig.getUint256(DXconstants.PLATFORM_FEE)) / DXconstants.DENOMINATOR;
        uint256 authorFee = totalAmount - platformFee;

        if (authorFee > 0) {
            (bool success, ) = payable(author).call{value: authorFee}("");
            if (!success) revert NativeTransferFailed();
        }
    }

    /**
     * @notice Override _update to track user posts
     */
    function _update(
        address from,
        address to,
        uint256 tokenId,
        uint256 amount
    ) internal virtual override(ERC6909Upgradeable, ERC6909TokenSupplyUpgradeable) {
        if (from != address(0)) {
            revert InvalidTokenTransfer();
        }
        super._update(from, to, tokenId, amount);

        uint256[] storage tokenIds = userTokenIds[to];
        for (uint256 i = 0; i < tokenIds.length; i++) {
            if (tokenIds[i] == tokenId) {
                revert PostAlreadySubscribed();
            }
        }
        tokenIds.push(tokenId);
    }
}