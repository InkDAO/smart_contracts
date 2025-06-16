// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.21;

import { Test, console2 } from "forge-std/Test.sol";
import { MasterdX } from "../contracts/MasterdX.sol";
import { IMasterdX } from "../contracts/interfaces/IMasterdX.sol";
import { dXConfig } from "../contracts/dXConfig.sol";
import { IdXConfig } from "../contracts/interfaces/IdXConfig.sol";
import { dXConstants } from "../contracts/utils/dXConstants.sol";
import { UtilLib } from "../contracts/utils/UtilLib.sol";

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { ProxyAdmin } from "@openzeppelin/contracts/proxy/transparent/ProxyAdmin.sol";
import { TransparentUpgradeableProxy } from "@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";

contract MasterdXTest is Test {
    ProxyAdmin public proxyAdmin;
    dXConfig public dxConfig;
    MasterdX public masterdX;

    address public admin;
    address public user;
    address public bot;

    uint256 public postLifeTime;
    uint256 public maxPostTitleLength;

    function setUp() public virtual {
        admin = makeAddr("admin");
        user = makeAddr("user");
        bot = makeAddr("bot");

        postLifeTime = 7 days;
        maxPostTitleLength = 100;

        vm.startPrank(admin);

        proxyAdmin = new ProxyAdmin(admin);

        dXConfig dXConfigImpl = new dXConfig();
        TransparentUpgradeableProxy dXConfigProxy = 
            new TransparentUpgradeableProxy(address(dXConfigImpl), address(proxyAdmin), "");
        dxConfig = dXConfig(address(dXConfigProxy));
        dxConfig.__dXConfig_Init(admin);

        MasterdX masterdXImpl = new MasterdX();
        TransparentUpgradeableProxy masterdXProxy =
            new TransparentUpgradeableProxy(address(masterdXImpl), address(proxyAdmin), "");
        masterdX = MasterdX(address(masterdXProxy));
        masterdX.__MasterdX_Init(address(dxConfig), postLifeTime, maxPostTitleLength);
        
        dxConfig.grantRole(dXConstants.BOT_ROLE, bot);

        vm.stopPrank();
    }
}

contract InitializationTest is MasterdXTest {
    function test_Initialization() public view {
        assertEq(masterdX.postLifeTime(), 7 days);
        assertEq(masterdX.maxPostTitleLength(), 100);

        assertEq(masterdX.totalPosts(), 0);

        assertTrue(dxConfig.hasRole(dXConstants.BOT_ROLE, bot));
        assertTrue(dxConfig.hasRole(dXConstants.DEFAULT_ADMIN_ROLE, admin));

        assertEq(address(masterdX.dXConfig()), address(dxConfig));
    }
}

contract AddPostTest is MasterdXTest {
    event PostAdded(bytes32 _postId, string _postTitle, string _post, address _owner, uint256 _endTime);

    function test_RevertEmptyPost() public {
        vm.startPrank(user);
        vm.expectRevert(IMasterdX.EmptyPost.selector);
        masterdX.addPost("test post", "");
        vm.stopPrank();
    }

    function test_RevertEmptypostTitle() public {
        vm.startPrank(user);
        vm.expectRevert(IMasterdX.EmptyPostTitle.selector);
        masterdX.addPost("", "post title");
        vm.stopPrank();
    }

    function test_RevertPostDuplicatepost() public {
        vm.startPrank(user);
        masterdX.addPost("post title", "test post");
        vm.expectRevert(IMasterdX.PostAlreadyShared.selector);
        masterdX.addPost("post title", "test post");
        vm.stopPrank();
    }

    function test_RevertPostTitleLengthTooBig() public {
        vm.startPrank(user);
        vm.expectRevert(IMasterdX.PostTitleLengthTooBig.selector);
        masterdX.addPost("post title post title post title post title post title post title post title post title post title post title", "test post");
        vm.stopPrank();
    }

    function test_EmitpostPosted() public {
        bytes32 postId = keccak256(abi.encodePacked("post title", "Testing..."));
        uint256 endTime = block.timestamp + postLifeTime;

        vm.prank(user);
        vm.expectEmit(true, true, true, true);
        emit PostAdded(postId, "post title", "Testing...", user, endTime);
        masterdX.addPost("post title", "Testing...");

        IMasterdX.PostInfo memory postInfo = masterdX.getPostInfo(postId);
        assertEq(postInfo.postId, postId);
        assertEq(postInfo.postBody, "Testing...");
        assertEq(postInfo.endTime, endTime);
        assertEq(masterdX.totalPosts(), 1);
    }


    function test_AddLargepost() public {
        bytes32 postId = keccak256(
            abi.encodePacked(
                "post title",
                "Hello dear, hope you are doing good. Hello dear, hope you are doing good. Hello dear, hope you are doing good. Hello dear, hope you are doing good. Hello dear, hope you are doing good. Hello dear, hope you are doing good. Hello dear, hope you are doing good. Hello dear, hope you are doing good. Hello dear, hope you are doing good. Hello dear, hope you are doing good. Hello dear, hope you are doing good. Hello dear, hope you are doing good. Hello dear, hope you are doing good. Hello dear, hope you are doing good. Hello dear, hope you are doing good. Hello dear, hope you are doing good. dX_contracts/test/MasterQA.t.sol dX_contracts/test/MasterQA.t.sol dX_contracts/test/MasterQA.t.sol dX_contracts/test/MasterQA.t.sol dX_contracts/test/MasterQA.t.sol dX_contracts/test/MasterQA.t.sol dX_contracts/test/MasterQA.t.sol dX_contracts/test/MasterQA.t.sol dX_contracts/test/MasterQA.t.sol dX_contracts/test/MasterQA.t.sol dX_contracts/test/MasterQA.t.sol dX_contracts/test/MasterQA.t.sol dX_contracts/test/MasterQA.t.sol dX_contracts/test/MasterQA.t.sol dX_contracts/test/MasterQA.t.sol dX_contracts/test/MasterQA.t.sol dX_contracts/test/MasterQA.t.sol dX_contracts/test/MasterQA.t.sol dX_contracts/test/MasterQA.t.sol dX_contracts/test/MasterQA.t.sol dX_contracts/test/MasterQA.t.sol"
            )
        );
        uint256 endTime = block.timestamp + postLifeTime;

        vm.prank(user);
        masterdX.addPost(
            "post title",
            "Hello dear, hope you are doing good. Hello dear, hope you are doing good. Hello dear, hope you are doing good. Hello dear, hope you are doing good. Hello dear, hope you are doing good. Hello dear, hope you are doing good. Hello dear, hope you are doing good. Hello dear, hope you are doing good. Hello dear, hope you are doing good. Hello dear, hope you are doing good. Hello dear, hope you are doing good. Hello dear, hope you are doing good. Hello dear, hope you are doing good. Hello dear, hope you are doing good. Hello dear, hope you are doing good. Hello dear, hope you are doing good. dX_contracts/test/MasterQA.t.sol dX_contracts/test/MasterQA.t.sol dX_contracts/test/MasterQA.t.sol dX_contracts/test/MasterQA.t.sol dX_contracts/test/MasterQA.t.sol dX_contracts/test/MasterQA.t.sol dX_contracts/test/MasterQA.t.sol dX_contracts/test/MasterQA.t.sol dX_contracts/test/MasterQA.t.sol dX_contracts/test/MasterQA.t.sol dX_contracts/test/MasterQA.t.sol dX_contracts/test/MasterQA.t.sol dX_contracts/test/MasterQA.t.sol dX_contracts/test/MasterQA.t.sol dX_contracts/test/MasterQA.t.sol dX_contracts/test/MasterQA.t.sol dX_contracts/test/MasterQA.t.sol dX_contracts/test/MasterQA.t.sol dX_contracts/test/MasterQA.t.sol dX_contracts/test/MasterQA.t.sol dX_contracts/test/MasterQA.t.sol"
        );

        IMasterdX.PostInfo memory postInfo = masterdX.getPostInfo(postId);
        assertEq(postInfo.postId, postId);
        assertEq(
            postInfo.postBody,
            "Hello dear, hope you are doing good. Hello dear, hope you are doing good. Hello dear, hope you are doing good. Hello dear, hope you are doing good. Hello dear, hope you are doing good. Hello dear, hope you are doing good. Hello dear, hope you are doing good. Hello dear, hope you are doing good. Hello dear, hope you are doing good. Hello dear, hope you are doing good. Hello dear, hope you are doing good. Hello dear, hope you are doing good. Hello dear, hope you are doing good. Hello dear, hope you are doing good. Hello dear, hope you are doing good. Hello dear, hope you are doing good. dX_contracts/test/MasterQA.t.sol dX_contracts/test/MasterQA.t.sol dX_contracts/test/MasterQA.t.sol dX_contracts/test/MasterQA.t.sol dX_contracts/test/MasterQA.t.sol dX_contracts/test/MasterQA.t.sol dX_contracts/test/MasterQA.t.sol dX_contracts/test/MasterQA.t.sol dX_contracts/test/MasterQA.t.sol dX_contracts/test/MasterQA.t.sol dX_contracts/test/MasterQA.t.sol dX_contracts/test/MasterQA.t.sol dX_contracts/test/MasterQA.t.sol dX_contracts/test/MasterQA.t.sol dX_contracts/test/MasterQA.t.sol dX_contracts/test/MasterQA.t.sol dX_contracts/test/MasterQA.t.sol dX_contracts/test/MasterQA.t.sol dX_contracts/test/MasterQA.t.sol dX_contracts/test/MasterQA.t.sol dX_contracts/test/MasterQA.t.sol"
        );
        assertEq(postInfo.endTime, endTime);
        assertEq(masterdX.totalPosts(), 1);
    }
}

contract AddCommentTest is MasterdXTest {
    bytes32 postId;

    event CommentAdded(bytes32 _postId, string _comment, address _owner);

    function setUp() public override {
        super.setUp();

        postId = keccak256(abi.encodePacked("post title", "Testing..."));

        vm.prank(user);
        masterdX.addPost("post title", "Testing...");
    }

    function test_RevertpostIsNotBorn() public {
        vm.expectRevert(IMasterdX.InvalidPost.selector);
        masterdX.addComment(bytes32("1"), "Testing...");
    }

    function test_EmitPostcomment() public {
        vm.prank(user);
        vm.expectEmit(true, true, true, true);
        emit CommentAdded(postId, "Testing...", user);
        masterdX.addComment(postId, "Testing...");

        IMasterdX.CommentInfo[] memory comments = masterdX.getCommentsInfo(postId);
        assertEq(comments.length, 1);
        assertEq(comments[0].postId, postId);
        assertEq(comments[0].comment, "Testing...");
    }
}

contract FuneralTest is MasterdXTest {
    bytes32 postId1;
    bytes32 postId2;

    event FuneralCompleted(bytes32 _postId);

    function setUp() public override {
        super.setUp();

        postId1 = keccak256(abi.encodePacked("post title", "Testing... 1"));
        postId2 = keccak256(abi.encodePacked("post title", "Testing... 2"));

        vm.startPrank(user);
        masterdX.addPost("post title", "Testing... 1");
        masterdX.addPost("post title", "Testing... 2");
        vm.stopPrank();
    }

    function test_RevertNotBot() public {
        bytes32[] memory postIds = new bytes32[](2);
        postIds[0] = postId1;
        postIds[1] = bytes32("2");

        vm.warp(block.timestamp + 5 days);

        vm.expectRevert(IdXConfig.NotBot.selector);
        masterdX.funeral(postIds);
    }

    function test_RevertInvalidPost() public {
        bytes32[] memory postIds = new bytes32[](2);
        postIds[0] = postId1;
        postIds[1] = bytes32("2");

        vm.warp(block.timestamp + 8 days);

        vm.prank(bot);
        vm.expectRevert(IMasterdX.InvalidPost.selector);
        masterdX.funeral(postIds);
    }

    function test_RevertpostSentToHeaven() public {
        bytes32[] memory postIds = new bytes32[](1);
        postIds[0] = postId1;

        vm.warp(block.timestamp + 8 days);
        vm.prank(bot);
        masterdX.funeral(postIds);

        vm.prank(bot);
        vm.expectRevert(IMasterdX.PostAlreadyArchived.selector);
        masterdX.funeral(postIds);
    }

    function test_RevertpostIsAlive() public {
        bytes32[] memory postIds = new bytes32[](1);
        postIds[0] = postId1;

        vm.prank(bot);
        vm.expectRevert(IMasterdX.PostIsAlive.selector);
        masterdX.funeral(postIds);
    }

    function test_EmitFuneralCompleted() public {
        bytes32[] memory postIds = new bytes32[](2);
        postIds[0] = postId1;
        postIds[1] = postId2;

        vm.warp(block.timestamp + 7 days);

        vm.prank(bot);
        vm.expectEmit(true, true, true, true);
        emit FuneralCompleted(postId1);
        emit FuneralCompleted(postId2);
        masterdX.funeral(postIds);

        IMasterdX.PostInfo memory postInfo1 = masterdX.getPostInfo(postId1);
        assertTrue(postInfo1.archived);
        IMasterdX.PostInfo memory postInfo2 = masterdX.getPostInfo(postId2);
        assertTrue(postInfo2.archived);
    }
}

contract PauseUnpauseTest is MasterdXTest {
    function test_PauseUnpause() public {
        vm.startPrank(admin);
        masterdX.pause();
        assertTrue(masterdX.paused());

        masterdX.unpause();
        assertFalse(masterdX.paused());
        vm.stopPrank();
    }

    function test_RevertNonOwnerPause() public {
        vm.startPrank(user);
        vm.expectRevert();
        masterdX.pause();
        vm.stopPrank();
    }
}

contract setPostLifeTimeTest is MasterdXTest {
    event PostLifeTimeUpdated(uint256 _maxpostLifeTime);

    function test_RevertNotAdmin() public {
        vm.expectRevert(IdXConfig.NotAdmin.selector);
        masterdX.setPostLifeTime(2 days);
    }

    function test_EmitPostLifeTimeUpdated() public {
        vm.prank(admin);
        vm.expectEmit(true, true, true, true);
        emit PostLifeTimeUpdated(2 days);
        masterdX.setPostLifeTime(2 days);

        assertEq(masterdX.postLifeTime(), 2 days);
    }
}

contract setMaxPostTitleLengthTest is MasterdXTest {
    event MaxPostTitleLengthUpdated(uint256 _maxPostTitleLength);

    function test_RevertNotAdmin() public {
        vm.expectRevert(IdXConfig.NotAdmin.selector);
        masterdX.setMaxPostTitleLength(200);
    }

    function test_EmitMaxPostTitleLengthUpdated() public {
        vm.prank(admin);
        vm.expectEmit(true, true, true, true);
        emit MaxPostTitleLengthUpdated(200);
        masterdX.setMaxPostTitleLength(200);

        assertEq(masterdX.maxPostTitleLength(), 200);
    }
}

contract updatedXConfigTest is MasterdXTest {
    event dXConfigUpdated(address indexed _dXConfig);

    function test_RevertNotAdmin() public {
        vm.expectRevert(IdXConfig.NotAdmin.selector);
        masterdX.updatedXConfig(address(dxConfig));
    }

    function test_RevertZeroAddressNotAllowed() public {
        vm.prank(admin);
        vm.expectRevert(UtilLib.ZeroAddressNotAllowed.selector);
        masterdX.updatedXConfig(address(0));
    }

    function test_EmitdXConfigUpdated() public {
        vm.prank(admin);
        vm.expectEmit(true, true, true, true);
        emit dXConfigUpdated(address(1));
        masterdX.updatedXConfig(address(1));
    }
}