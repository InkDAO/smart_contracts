// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.21;

interface IMasterdX {
    struct PostInfo {
        bytes32 postId;
        string postTitle;
        string postcid;
        string imagecid;
        address owner;
        uint256 endTime;
        bool archived;
    }

    struct CommentInfo {
        bytes32 postId;
        string commentcid;
        address owner;
    }

    error PostAlreadyShared();
    error InvalidPost();
    error InvalidPostCidOrImageCid();
    error PostIsAlive();
    error EmptyPostTitle();
    error PostTitleLengthTooBig();
    error PostAlreadyArchived();


    event FuneralCompleted(bytes32 _postId);
    event PostAdded(bytes32 _postId, string _postTitle, string _postcid, string _imagecid, address _owner, uint256 _endTime);
    event CommentAdded(bytes32 _postId, string _commentcid, address _owner);
    event PostLifeTimeUpdated(uint256 _maxPostLifeTime);
    event MaxPostTitleLengthUpdated(uint256 _maxPostTitleLength);
    event FreeWindowOpenUpdated(bool _freeWindowOpen);
    event TokenRequiredPerPostUpdated(uint256 _tokenRequiredPerPost);
}
