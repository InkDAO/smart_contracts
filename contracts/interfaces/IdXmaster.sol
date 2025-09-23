// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

interface IdXmaster {
    struct AssetInfo {
        address author;
        string assetCid;
        string thumbnailCid;
        string assetTitle;
        string description;
        address assetAddress;
        uint256 costInNativeInWei;
    }

    struct AddAssetParams {
        bytes32 salt;
        string assetTitle;
        string assetCid;
        string thumbnailCid;
        string description;
        uint256 costInNativeInWei;
    }

    struct CommentInfo {
        string assetCid;
        string comment;
        address author;
    }

    struct UserAssetInfo {
        uint256 amount;
        address assetAddress;
    }

    error NotdXAsset();
    error EmptyComment();
    error InvalidAsset();
    error InvalidAmount();
    error InvalidAssetCid();
    error EmptyAssetTitle();
    error MoreThanBalance();
    error AssetAlreadyAdded();
    error InsufficientAmount();
    error CommentLengthTooBig();
    error NativeTransferFailed();
    error AssetTitleLengthTooBig();

    event WithdrawFee(uint256 _amount);
    event dXConfigUpdated(address _dXConfig);
    event MaxCommentLengthUpdated(uint256 _maxCommentLength);
    event MaxAssetTitleLengthUpdated(uint256 _maxAssetTitleLength);
    event AssetBought(string _assetCid, uint256 _amount, address _buyer);
    event CommentAdded(string _assetCid, string _comment, address _author);
    event AssetAdded(
        string _assetTitle, string _assetCid, string _thumbnailCid, address _assetAddress, address _author, uint256 _costInNativeInWei
    );

    function pause() external;
    function unpause() external;
    function updatedXConfig(address _dXConfig) external;
    function setMaxCommentLength(uint256 _maxCommentLength) external;
    function setMaxAssetTitleLength(uint256 _maxAssetTitleLength) external;
    function beforeTokenTransfer(address _from, address _to, uint256 _amount) external;

    function totalAssets() external view returns (uint256);
    function getAllAssets() external view returns (AssetInfo[] memory allAssetInfo);
    function getAssetInfo(string memory _assetCid) external view returns (AssetInfo memory);
    function getCommentsInfo(string memory _assetCid) external view returns (CommentInfo[] memory);
    function getUserAssetData(address _user) external view returns (UserAssetInfo[] memory);

    function withdrawFee(uint256 _amount) external;
    function addComment(string memory _assetCid, string calldata _comment) external;
    function addAsset(
        AddAssetParams calldata _params
    )
        external;
}
