// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import { BaseTest } from "./BaseTest.t.sol";

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import { DXconstants } from "../contracts/utils/DXconstants.sol";
import { IdXmaster } from "../contracts/interfaces/IdXmaster.sol";
import { IdXasset } from "../contracts/interfaces/IdXasset.sol";
import { IdXconfig } from "../contracts/interfaces/IdXconfig.sol";
import { DXasset } from "../contracts/Token/DXasset.sol";
import { UtilLib } from "../contracts/utils/UtilLib.sol";

contract DXMasterTest is BaseTest {
    function test_Initialization() public view {
        assertEq(dXmaster.maxCommentLength(), 100);
        assertEq(dXmaster.maxAssetTitleLength(), 100);
        assertEq(dXmaster.maxDescriptionLength(), 200);

        assertEq(dXmaster.totalAssets(), 0);

        assertTrue(dXconfig.hasRole(DXconstants.BOT_ROLE, bot));
        assertTrue(dXconfig.hasRole(DXconstants.DEFAULT_ADMIN_ROLE, admin));

        assertEq(dXconfig.getUint256(DXconstants.PLATFORM_FEE), 500);
        assertEq(dXconfig.getAddress(DXconstants.DXMASTER_ADDRESS), address(dXmaster));
        assertEq(dXconfig.getAddress(DXconstants.ASSET_FACTORY_ADDRESS), address(dXassetFactory));

        assertEq(address(dXmaster.dXConfig()), address(dXconfig));
    }
}

contract AddAssetTest is BaseTest {
    event AssetAdded(
        string _assetTitle, string _assetCid, string _thumbnailCid, address _assetAddress, address _author, uint256 _costInNativeInWei
    );

    function test_RevertEmptyAssetCid() public {
        vm.startPrank(user);
        vm.expectRevert(IdXmaster.InvalidAssetCid.selector);
        dXmaster.addAsset(keccak256(abi.encodePacked("test asset")), IdXmaster.AssetInfoParams({
            assetTitle: "test asset",
            assetCid: "",
            thumbnailCid: "thumbnailcid",
            description: "description",
            costInNativeInWei: 1 ether / 100
        }));
        vm.stopPrank();
    }

    function test_RevertEmptyAssetTitle() public {
        vm.startPrank(user);
        vm.expectRevert(IdXmaster.EmptyAssetTitle.selector);
        dXmaster.addAsset(keccak256(abi.encodePacked("test asset")), IdXmaster.AssetInfoParams({
            assetTitle: "",
            assetCid: "asset title",
            thumbnailCid: "thumbnailcid",
            description: "description",
            costInNativeInWei: 1 ether / 100
        }));
        vm.stopPrank();
    }

    function test_RevertAssetAlreadyAdded() public {
        vm.startPrank(user);
        dXmaster.addAsset(keccak256(abi.encodePacked("test asset")), IdXmaster.AssetInfoParams({
            assetTitle: "asset title",
            assetCid: "assetcid",
            thumbnailCid: "thumbnailcid",
            description: "description",
            costInNativeInWei: 1 ether / 100
        }));
        vm.expectRevert(IdXmaster.AssetAlreadyAdded.selector);
        dXmaster.addAsset(keccak256(abi.encodePacked("test asset")), IdXmaster.AssetInfoParams({
            assetTitle: "asset title",
            assetCid: "assetcid",
            thumbnailCid: "thumbnailcid",
            description: "description",
            costInNativeInWei: 1 ether / 100
        }));
        vm.stopPrank();
    }

    function test_RevertAssetTitleLengthTooBig() public {
        vm.startPrank(user);
        vm.expectRevert(IdXmaster.AssetTitleLengthTooBig.selector);
        dXmaster.addAsset(keccak256(abi.encodePacked("test asset")), IdXmaster.AssetInfoParams({
            assetTitle: "abcdefghijklmnopqrstuvwxyz abcdefghijklmnopqrstuvwxyz abcdefghijklmnopqrstuvwxyz abcdefghijklmnopqrstuvwxyz",
            assetCid: "assetcid",
            thumbnailCid: "thumbnailcid",
            description: "description",
            costInNativeInWei: 1 ether / 100 // 0.01 ether
        }));
        vm.stopPrank();
    }

    function test_EmitAssetAdded() public {
        vm.prank(user);
        vm.expectEmit(true, true, true, false);
        emit AssetAdded("asset title", "assetcid", "thumbnailcid", address(0), user, 1 ether / 100);
        address assetAddress = dXmaster.addAsset(keccak256(abi.encodePacked("test asset 1")), IdXmaster.AssetInfoParams({
            assetTitle: "asset title",
            assetCid: "assetcid",
            thumbnailCid: "thumbnailcid",
            description: "description",
            costInNativeInWei: 1 ether / 100
        }));

        IdXasset.AssetInfo memory assetInfo = IdXasset(assetAddress).getAssetInfo();
        assertEq(assetInfo.author, user);
        assertEq(assetInfo.assetTitle, "asset title");
        assertEq(assetInfo.thumbnailCid, "thumbnailcid");
        assertEq(assetInfo.assetCid, "assetcid");
        assertEq(IdXasset(assetAddress).costInNativeInWei(), 1 ether / 100);

        assertEq(dXmaster.totalAssets(), 1);
    }

    function test_AddLargeAsset() public {
        vm.prank(user);
        address assetAddress = dXmaster.addAsset(keccak256(abi.encodePacked("test asset 1")), IdXmaster.AssetInfoParams({
            assetTitle: "asset title",
            assetCid: "assetcid",
            thumbnailCid: "thumbnailcid",
            description: "description",
            costInNativeInWei: 1 ether / 100
        }));

        IdXasset.AssetInfo memory postInfo = IdXasset(assetAddress).getAssetInfo();
        assertEq(postInfo.assetTitle, "asset title");
        assertEq(postInfo.assetCid, "assetcid");
        assertEq(IdXasset(assetAddress).costInNativeInWei(), 1 ether / 100);
        assertEq(dXmaster.totalAssets(), 1);

        (address[] memory allAssetAddresses, IdXasset.AssetInfo[] memory allPosts) = dXmaster.getAllAssetInfos();
        assertEq(allPosts.length, 1);
        assertEq(allPosts[0].author, user);
        assertEq(allPosts[0].assetTitle, "asset title");
        assertEq(allPosts[0].assetCid, "assetcid");
        assertEq(IdXasset(assetAddress).costInNativeInWei(), 1 ether / 100);

        assertEq(allAssetAddresses.length, 1);
        assertEq(allAssetAddresses[0], assetAddress);
    }
}

contract AddCommentTest is BaseTest {
    event CommentAdded(address _assetAddress, string _comment, address _author);
    address public assetAddress;

    function setUp() public override {
        super.setUp();

        vm.prank(user);
        assetAddress = dXmaster.addAsset(keccak256(abi.encodePacked("test asset 1")), IdXmaster.AssetInfoParams({
            assetTitle: "asset title",
            assetCid: "assetcid",
            thumbnailCid: "thumbnailcid",
            description: "description",
            costInNativeInWei: 1 ether / 100
        }));
    }

    function test_RevertInvalidAssetAddress() public {
        vm.expectRevert(IdXmaster.InvalidAssetAddress.selector);
        dXmaster.addComment(address(0), "Testing...");
    }

    function test_RevertEmptyComment() public {
        vm.expectRevert(IdXmaster.EmptyComment.selector);
        dXmaster.addComment(assetAddress, "");
    }

    function test_RevertCommentLengthTooBig() public {
        vm.expectRevert(IdXmaster.CommentLengthTooBig.selector);
        dXmaster.addComment(
            assetAddress,
            "abcdefghijklmnopqrstuvwxyz abcdefghijklmnopqrstuvwxyz abcdefghijklmnopqrstuvwxyz abcdefghijklmnopqrstuvwxyz abcdefghijklmnopqrstuvwxyz abcdefghijklmnopqrstuvwxyz abcdefghijklmnopqrstuvwxyz abcdefghijklmnopqrstuvwxyz"
        );
    }

    function test_EmitAssetComment() public {
        vm.prank(user);
        vm.expectEmit(true, true, true, true);
        emit CommentAdded(assetAddress, "Testing...", user);
        dXmaster.addComment(assetAddress, "Testing...");

        IdXmaster.CommentInfo[] memory comments = dXmaster.getCommentsInfo(assetAddress);
        assertEq(comments.length, 1);
        assertEq(comments[0].author, user);
        assertEq(comments[0].comment, "Testing...");
    }
}

contract BuyAssetTest is BaseTest {
    error NativeTransferFailed();

    event AssetBought(address _assetAddress, uint256 _amount, address _buyer);

    address public author;
    address public assetAddress;

    function setUp() public override {
        super.setUp();

        author = makeAddr("author");
        vm.prank(author);
        assetAddress = dXmaster.addAsset(keccak256(abi.encodePacked("test asset 1")), IdXmaster.AssetInfoParams({
            assetTitle: "asset title",
            assetCid: "assetcid",
            thumbnailCid: "thumbnailcid",
            description: "description",
            costInNativeInWei: 1 ether / 100
        }));

        dXasset = DXasset(assetAddress);
    }

    function test_RevertInvalidAssetCid() public {
        vm.expectRevert(IdXmaster.InvalidAssetAddress.selector);
        dXmaster.buyAsset(address(0), 1);
    }

    function test_RevertInvalidAmount() public {
        vm.expectRevert(IdXmaster.InvalidAmount.selector);
        dXmaster.buyAsset(assetAddress, 0);
    }

    function test_RevertInsufficientAmount() public {
        vm.expectRevert(IdXmaster.InsufficientAmount.selector);
        dXmaster.buyAsset(assetAddress, 1);
    }

    function test_RevertRefundableNativeTransferFailed() public {
        deal(address(dXconfig), 1 ether); // Any non-payable address

        vm.prank(address(dXconfig));
        vm.expectRevert(NativeTransferFailed.selector);
        dXmaster.buyAsset{ value: 1 ether }(assetAddress, 1);
    }

    function test_RevertAuthorNativeTransferFailed() public {
        vm.prank(address(dXconfig));
        assetAddress = dXmaster.addAsset(keccak256(abi.encodePacked("test asset 1")), IdXmaster.AssetInfoParams({
            assetTitle: "asset title",
            assetCid: "assetcid1",
            thumbnailCid: "thumbnailcid",
            description: "description",
            costInNativeInWei: 1 ether / 100
        }));

        deal(user, 1 ether);
        vm.prank(user);
        vm.expectRevert(NativeTransferFailed.selector);
        dXmaster.buyAsset{ value: 1 ether }(assetAddress, 1);
    }

    function test_EmitAssetBought() public {
        deal(user, 1 ether / 100);
        vm.prank(user);
        vm.expectEmit(true, true, true, true);
        emit AssetBought(assetAddress, 1, user);
        dXmaster.buyAsset{ value: 1 ether / 100 }(assetAddress, 1);

        assertEq(dXasset.balanceOf(user), 1);
        assertEq(address(user).balance, 0);
        assertEq(address(author).balance, 95 * 1 ether / 100 / 100);
        assertEq(address(dXmaster).balance, 5 * 1 ether / 100 / 100);

        IdXmaster.UserAssetInfo[] memory userAssetData = dXmaster.getUserAssetData(user);
        assertEq(userAssetData.length, 1);
        assertEq(userAssetData[0].assetAddress, assetAddress);
        assertEq(userAssetData[0].amount, 1);
    }

    function test_BuyAssetWithMoreThanRequiredAmount() public {
        deal(user, 1 ether);
        vm.prank(user);
        vm.expectEmit(true, true, true, true);
        emit AssetBought(assetAddress, 3, user);
        dXmaster.buyAsset{ value: 1 ether }(assetAddress, 3);

        assertEq(dXasset.balanceOf(user), 3);
        assertEq(address(user).balance, 97 ether / 100);
        assertEq(address(author).balance, 95 * 3 ether / 100 / 100);
        assertEq(address(dXmaster).balance, 5 * 3 ether / 100 / 100);

        IdXmaster.UserAssetInfo[] memory userAssetData = dXmaster.getUserAssetData(user);
        assertEq(userAssetData.length, 1);
        assertEq(userAssetData[0].assetAddress, assetAddress);
        assertEq(userAssetData[0].amount, 3);
    }
}

contract BeforeTokenTransferTest is BaseTest {
    error NotdXAsset();

    address public author;
    address public assetAddress;

    function setUp() public override {
        super.setUp();

        author = makeAddr("author");
        vm.prank(author);
        assetAddress = dXmaster.addAsset(keccak256(abi.encodePacked("test asset 1")), IdXmaster.AssetInfoParams({
            assetTitle: "asset title",
            assetCid: "assetcid",
            thumbnailCid: "thumbnailcid",
            description: "description",
            costInNativeInWei: 1 ether / 100
        }));

        dXasset = DXasset(assetAddress);
    }

    function test_RevertNotDxAsset() public {
        vm.prank(user);
        vm.expectRevert();
        dXmaster.beforeTokenTransfer(user, author, 1);
    }

    function test_AssetMint() public {
        deal(user, 1 ether / 100);
        vm.prank(user);
        dXmaster.buyAsset{ value: 1 ether / 100 }(assetAddress, 1);

        assertEq(dXasset.balanceOf(user), 1);
        assertEq(address(user).balance, 0);
        assertEq(address(author).balance, 95 * 1 ether / 100 / 100);
        assertEq(address(dXmaster).balance, 5 * 1 ether / 100 / 100);

        IdXmaster.UserAssetInfo[] memory userAssetData = dXmaster.getUserAssetData(user);
        assertEq(userAssetData.length, 1);
        assertEq(userAssetData[0].assetAddress, assetAddress);
        assertEq(userAssetData[0].amount, 1);
    }

    function test_AssetBurn() public {
        deal(user, 1 ether / 100);
        vm.prank(user);
        dXmaster.buyAsset{ value: 1 ether / 100 }(assetAddress, 1);

        assertEq(dXasset.balanceOf(user), 1);
        assertEq(address(user).balance, 0);
        assertEq(address(author).balance, 95 * 1 ether / 100 / 100);
        assertEq(address(dXmaster).balance, 5 * 1 ether / 100 / 100);

        vm.prank(user);
        dXasset.burn(1);

        assertEq(dXasset.balanceOf(user), 0);
        assertEq(address(user).balance, 0);
        assertEq(address(author).balance, 95 * 1 ether / 100 / 100);
        assertEq(address(dXmaster).balance, 5 * 1 ether / 100 / 100);

        IdXmaster.UserAssetInfo[] memory userAssetData = dXmaster.getUserAssetData(user);
        assertEq(userAssetData.length, 0);
    }

    function test_AssetTransfer() public {
        address user2 = makeAddr("user2");

        deal(user, 1 ether / 100);
        vm.prank(user);
        dXmaster.buyAsset{ value: 1 ether / 100 }(assetAddress, 1);

        assertEq(dXasset.balanceOf(user), 1);
        assertEq(address(user).balance, 0);
        assertEq(address(author).balance, 95 * 1 ether / 100 / 100);
        assertEq(address(dXmaster).balance, 5 * 1 ether / 100 / 100);

        vm.prank(user);
        dXasset.transfer(user2, 1);

        assertEq(dXasset.balanceOf(user), 0);
        assertEq(dXasset.balanceOf(user2), 1);
        assertEq(address(user).balance, 0);
        assertEq(address(user2).balance, 0);
        assertEq(address(author).balance, 95 * 1 ether / 100 / 100);
        assertEq(address(dXmaster).balance, 5 * 1 ether / 100 / 100);

        IdXmaster.UserAssetInfo[] memory userAssetData = dXmaster.getUserAssetData(user);
        assertEq(userAssetData.length, 0);
        IdXmaster.UserAssetInfo[] memory user2AssetData = dXmaster.getUserAssetData(user2);
        assertEq(user2AssetData.length, 1);
        assertEq(user2AssetData[0].assetAddress, assetAddress);
        assertEq(user2AssetData[0].amount, 1);
    }

    function test_AssetTransferAgain() public {
        address user2 = makeAddr("user2");

        deal(user, 2 ether / 100);
        vm.prank(user);
        dXmaster.buyAsset{ value: 2 ether / 100 }(assetAddress, 2);

        assertEq(dXasset.balanceOf(user), 2);
        assertEq(address(user).balance, 0);
        assertEq(address(author).balance, 95 * 2 ether / 100 / 100);
        assertEq(address(dXmaster).balance, 5 * 2 ether / 100 / 100);

        vm.prank(user);
        dXasset.transfer(user2, 1);

        assertEq(dXasset.balanceOf(user), 1);
        assertEq(dXasset.balanceOf(user2), 1);
        assertEq(address(user).balance, 0);
        assertEq(address(user2).balance, 0);
        assertEq(address(author).balance, 95 * 2 ether / 100 / 100);
        assertEq(address(dXmaster).balance, 5 * 2 ether / 100 / 100);

        IdXmaster.UserAssetInfo[] memory userAssetData = dXmaster.getUserAssetData(user);
        assertEq(userAssetData.length, 1);
        assertEq(userAssetData[0].assetAddress, assetAddress);
        assertEq(userAssetData[0].amount, 1);
        IdXmaster.UserAssetInfo[] memory user2AssetData = dXmaster.getUserAssetData(user2);
        assertEq(user2AssetData.length, 1);
        assertEq(user2AssetData[0].assetAddress, assetAddress);
        assertEq(user2AssetData[0].amount, 1);

        vm.prank(user);
        dXasset.transfer(user2, 1);

        assertEq(dXasset.balanceOf(user), 0);
        assertEq(dXasset.balanceOf(user2), 2);
        assertEq(address(user).balance, 0);
        assertEq(address(user2).balance, 0);
        assertEq(address(author).balance, 95 * 2 ether / 100 / 100);
        assertEq(address(dXmaster).balance, 5 * 2 ether / 100 / 100);

        userAssetData = dXmaster.getUserAssetData(user);
        assertEq(userAssetData.length, 0);
        user2AssetData = dXmaster.getUserAssetData(user2);
        assertEq(user2AssetData.length, 1);
        assertEq(user2AssetData[0].assetAddress, address(dXasset));
        assertEq(user2AssetData[0].amount, 2);
    }
}

contract PauseUnpauseTest is BaseTest {
    function test_PauseUnpause() public {
        vm.startPrank(admin);
        dXmaster.pause();
        assertTrue(dXmaster.paused());

        dXmaster.unpause();
        assertFalse(dXmaster.paused());
        vm.stopPrank();
    }

    function test_RevertNonOwnerPause() public {
        vm.startPrank(user);
        vm.expectRevert();
        dXmaster.pause();
        vm.stopPrank();
    }
}

contract setMaxCommentLengthTest is BaseTest {
    event MaxCommentLengthUpdated(uint256 _maxCommentLength);

    function test_RevertNotAdmin() public {
        vm.expectRevert(IdXconfig.NotAdmin.selector);
        dXmaster.setMaxCommentLength(2 days);
    }

    function test_EmitCommentLengthUpdated() public {
        vm.prank(admin);
        vm.expectEmit(true, true, true, true);
        emit MaxCommentLengthUpdated(2 days);
        dXmaster.setMaxCommentLength(2 days);

        assertEq(dXmaster.maxCommentLength(), 2 days);
    }
}

contract setMaxAssetTitleLengthTest is BaseTest {
    event MaxAssetTitleLengthUpdated(uint256 _maxAssetTitleLength);

    function test_RevertNotAdmin() public {
        vm.expectRevert(IdXconfig.NotAdmin.selector);
        dXmaster.setMaxAssetTitleLength(200);
    }

    function test_EmitMaxPostTitleLengthUpdated() public {
        vm.prank(admin);
        vm.expectEmit(true, true, true, true);
        emit MaxAssetTitleLengthUpdated(200);
        dXmaster.setMaxAssetTitleLength(200);

        assertEq(dXmaster.maxAssetTitleLength(), 200);
    }
}

contract updatedXConfigTest is BaseTest {
    event dXConfigUpdated(address _dXConfig);

    function test_RevertNotAdmin() public {
        vm.expectRevert(IdXconfig.NotAdmin.selector);
        dXmaster.updatedXConfig(address(dXconfig));
    }

    function test_RevertZeroAddressNotAllowed() public {
        vm.prank(admin);
        vm.expectRevert(UtilLib.ZeroAddressNotAllowed.selector);
        dXmaster.updatedXConfig(address(0));
    }

    function test_EmitdXConfigUpdated() public {
        vm.prank(admin);
        vm.expectEmit(true, true, true, true);
        emit dXConfigUpdated(address(1));
        dXmaster.updatedXConfig(address(1));
    }
}

contract withdrawFeeTest is BaseTest {
    error MoreThanBalance();
    error NativeTransferFailed();

    event WithdrawFee(uint256 _amount);

    function test_RevertNotAdmin() public {
        vm.expectRevert(IdXconfig.NotAdmin.selector);
        dXmaster.withdrawFee(1 ether);
    }

    function test_RevertMoreThanBalance() public {
        vm.prank(admin);
        vm.expectRevert(MoreThanBalance.selector);
        dXmaster.withdrawFee(1 ether);
    }

    function test_WithdrawFee() public {
        deal(address(dXmaster), 1 ether);
        vm.prank(admin);
        dXmaster.withdrawFee(1 ether);

        assertEq(address(admin).balance, 1 ether);
        assertEq(address(dXmaster).balance, 0);
    }

    function test_EmitWithdrawFee() public {
        deal(address(dXmaster), 1 ether);

        vm.prank(admin);
        vm.expectEmit(true, true, true, true);
        emit WithdrawFee(1 ether);
        dXmaster.withdrawFee(1 ether);
    }

    function test_RevertNativeTransferFailed() public {
        vm.prank(admin);
        dXconfig.grantRole(DXconstants.DEFAULT_ADMIN_ROLE, address(dXconfig));

        deal(address(dXmaster), 1 ether);

        vm.prank(address(dXconfig));
        vm.expectRevert(NativeTransferFailed.selector);
        dXmaster.withdrawFee(1 ether);
    }
}
