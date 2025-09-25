// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import { IdXasset } from "./IdXasset.sol";
interface IdXmaster {
    struct AssetInfoParams {
        string assetCid;
        string assetTitle;
        string thumbnailCid;
        string description;
        uint256 costInNativeInWei;
    }

    struct CommentInfo {
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
    error InvalidThumbnailCid();
    error DescriptionTooBig();
    error InvalidAssetAddress();

    event WithdrawFee(uint256 _amount);
    event dXConfigUpdated(address _dXConfig);
    event MaxCommentLengthUpdated(uint256 _maxCommentLength);
    event MaxAssetTitleLengthUpdated(uint256 _maxAssetTitleLength);
    event AssetBought(address _assetAddress, uint256 _amount, address _buyer);
    event CommentAdded(address _assetAddress, string _comment, address _author);
    event AssetAdded(
        string _assetTitle, string _assetCid, string _thumbnailCid, address _assetAddress, address _author, uint256 _costInNativeInWei
    );
    event MaxDescriptionLengthUpdated(uint256 _maxDescriptionLength);

    function pause() external;
    function unpause() external;
    function updatedXConfig(address _dXConfig) external;
    function setMaxCommentLength(uint256 _maxCommentLength) external;
    function setMaxAssetTitleLength(uint256 _maxAssetTitleLength) external;
    function setMaxDescriptionLength(uint256 _maxDescriptionLength) external;
    function beforeTokenTransfer(address _from, address _to, uint256 _amount) external;

    function totalAssets() external view returns (uint256);
    function getAllAssetInfos() external view returns (address[] memory allAssetAddresses, IdXasset.AssetInfo[] memory allAssetInfo);
    function getAssetInfo(string memory _assetCid) external view returns (IdXasset.AssetInfo memory);
    function getCommentsInfo(address _assetAddress) external view returns (CommentInfo[] memory);
    function getUserAssetData(address _user) external view returns (UserAssetInfo[] memory);

    function withdrawFee(uint256 _amount) external;
    function addComment(address _assetAddress, string calldata _comment) external;
    function addAsset(
        bytes32 _salt,
        AssetInfoParams calldata _assetInfoParams
    )
        external
        returns (address assetAddress);
}
