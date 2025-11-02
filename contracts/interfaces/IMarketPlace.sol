// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.21;

interface IMarketPlace {    
    struct PostInfo {
        address author;
        string postCid;
        string postTitle;
        string thumbnailCid;
        string description;
        uint256 priceInNative;
    }

    struct PostInfoParams {
        string postCid;
        string postTitle;
        string thumbnailCid;
        string description;
        uint256 priceInNative;
    }

    event PostCreated(
        uint256 indexed tokenId,
        string postTitle,
        string postCid,
        string thumbnailCid,
        address indexed author,
        uint256 costInNativeInWei
    );
    
    event PostSubscribed(
        uint256 indexed tokenId,
        address indexed subscriber,
        uint256 totalCost
    );   

    event PostPriceUpdated(
        uint256 indexed tokenId,
        uint256 oldPrice,
        uint256 newPrice
    );
    
    event ConfigUpdated(address indexed newConfig);
    event MaxPostTitleLengthUpdated(uint256 newLength);
    event MaxDescriptionLengthUpdated(uint256 newLength);
    event MaxPriceInNativeUpdated(uint256 newPrice);
    event PlatformFeeWithdrawn(uint256 amount, address indexed recipient);
    
    error InvalidPostCid();
    error PostAlreadyExists();
    error EmptyPostTitle();
    error PostTitleTooLong();
    error InvalidThumbnailCid();
    error DescriptionTooLong();
    error PostDoesNotExist();
    error InsufficientPayment();
    error NativeTransferFailed();
    error MoreThanBalance();
    error NotPostAuthor();
    error InvalidTokenTransfer();
    error PostAlreadySubscribed();
    error InvalidPrice();
    
    function createPost(PostInfoParams calldata params) external returns (uint256 tokenId);
    function subscribePost(uint256 tokenId) external payable;
    function updatePostPrice(uint256 tokenId, uint256 newPrice) external;
    
    function getPostInfo(uint256 tokenId) external view returns (PostInfo memory);
    function getPostInfoByCid(string memory cid) external view returns (PostInfo memory);
    function getAllPosts() external view returns (PostInfo[] memory posts);
    function getUserPosts(address user) external view returns (uint256[] memory tokenIds);
    function totalPosts() external view returns (uint256);
    
    function pause() external;
    function unpause() external;
    function updateDXConfig(address newConfig) external;
    function setMaxPostTitleLength(uint256 newLength) external;
    function setMaxDescriptionLength(uint256 newLength) external;
    function setMaxPriceInNative(uint256 newPrice) external;
    function withdrawFees(uint256 amount) external;
}