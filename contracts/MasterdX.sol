// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.21;

import { Initializable } from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import { PausableUpgradeable } from "@openzeppelin/contracts-upgradeable/utils/PausableUpgradeable.sol";
import { ReentrancyGuardUpgradeable } from "@openzeppelin/contracts-upgradeable/utils/ReentrancyGuardUpgradeable.sol";

import { IMasterdX } from "./interfaces/IMasterdX.sol";
import { IdXConfig } from "./dXConfig.sol";
import { dXRoleChecker } from "./utils/dXRoleChecker.sol";
import { dXConstants } from "./utils/dXConstants.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

contract MasterdX is
    Initializable,
    PausableUpgradeable,
    ReentrancyGuardUpgradeable,
    IMasterdX,
    dXRoleChecker
{
    using SafeERC20 for IERC20;

    mapping(bytes32 => PostInfo) public postData;

    mapping(bytes32 => CommentInfo[]) public commentData;

    bytes32[] public postIds;

    uint256 public postLifeTime;
    uint256 public maxPostTitleLength;

    constructor() {
        _disableInitializers();
    }

    function __MasterdX_Init(address _dXConfig, uint256 _postLifeTime, uint256 _maxPostTitleLength) public initializer {
        __Pausable_init();
        __ReentrancyGuard_init();

        dXConfig = IdXConfig(_dXConfig);

        postLifeTime = _postLifeTime;
        maxPostTitleLength = _maxPostTitleLength;
    }

    modifier isValidPost(string calldata _postTitle, string calldata _postBody) {
        if (bytes(_postTitle).length == 0) {
            revert EmptyPostTitle();
        }
        if (bytes(_postBody).length == 0) {
            revert EmptyPost();
        }
        if (bytes(_postTitle).length > maxPostTitleLength) {
            revert PostTitleLengthTooBig();
        }
        _;
    }

    function totalPosts() external view returns (uint256) {
        return postIds.length;
    }

    function getPostInfo(bytes32 _postId) external view returns (PostInfo memory) {
        return postData[_postId];
    }

    function getAllPosts() external view returns (PostInfo[] memory allPostInfo) {
        allPostInfo = new PostInfo[](postIds.length);
        for (uint256 i=0; i<postIds.length; i++) {
            allPostInfo[i] = postData[postIds[i]];
        }
    }

    function getCommentsInfo(bytes32 _postId) external view returns (CommentInfo[] memory) {
        return commentData[_postId];
    }

    function addPost(
        string calldata _postTitle,
        string calldata _postBody
    )
        external
        whenNotPaused
        nonReentrant
        isValidPost(_postTitle, _postBody)
        returns (bytes32 _postId)
    {
        _postId = keccak256(abi.encodePacked(_postTitle, _postBody));
        if (postData[_postId].postId != bytes32(0)) {
            revert PostAlreadyShared();
        }

        uint256 _endTime = block.timestamp + postLifeTime;
        postData[_postId] =
            PostInfo({ postId: _postId, postTitle: _postTitle, postBody: _postBody, owner: msg.sender, endTime: _endTime, archived: false });

        postIds.push(_postId);

        emit PostAdded(_postId, _postTitle, _postBody, msg.sender, _endTime);
    }

    function addComment(bytes32 _postId, string calldata _comment) external whenNotPaused nonReentrant {
        PostInfo memory postInfo = postData[_postId];
        if (postInfo.postId != _postId) {
            revert InvalidPost();
        }

        commentData[_postId].push(CommentInfo({ postId: _postId, comment: _comment, owner: msg.sender }));

        emit CommentAdded(_postId, _comment, msg.sender);
    }

    function pause() external onlyAdmin {
        _pause();
    }

    function unpause() external onlyAdmin {
        _unpause();
    }

    function setPostLifeTime(uint256 _postLifeTime) external onlyAdmin {
        postLifeTime = _postLifeTime;

        emit PostLifeTimeUpdated(postLifeTime);
    }

    function setMaxPostTitleLength(uint256 _maxPostTitleLength) external onlyAdmin {
        maxPostTitleLength = _maxPostTitleLength;

        emit MaxPostTitleLengthUpdated(maxPostTitleLength);
    }

    function funeral(bytes32[] calldata _postIds) external whenNotPaused nonReentrant onlyBot {
        for (uint256 i; i < _postIds.length; i++) {
            _checkPostToArchive(_postIds[i]);

            PostInfo storage postInfo = postData[_postIds[i]];
            postInfo.archived = true;

            emit FuneralCompleted(_postIds[i]);
        }
    }

    function _checkPostToArchive(bytes32 _postId) internal view {
        PostInfo memory postInfo = postData[_postId];
        if (postInfo.postId != _postId) {
            revert InvalidPost();
        }
        if (postInfo.archived) {
            revert PostAlreadyArchived();
        }
        if (postInfo.endTime > block.timestamp) {
            revert PostIsAlive();
        }
    }
}
