// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.21;

import { Test } from "forge-std/Test.sol";
import { console } from "forge-std/console.sol";

import { MarketPlace } from "../contracts/MarketPlace.sol";
import { IMarketPlace } from "../contracts/interfaces/IMarketPlace.sol";
import { DXconfig } from "../contracts/DXconfig.sol";
import { IdXconfig } from "../contracts/interfaces/IdXconfig.sol";
import { DXconstants } from "../contracts/utils/DXconstants.sol";
import { UtilLib } from "../contracts/utils/UtilLib.sol";
import { ERC1967Proxy } from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import { BaseTest } from "./BaseTest.t.sol";
import { IERC6909 } from "@openzeppelin/contracts/interfaces/draft-IERC6909.sol";

contract MarketPlaceCreatePostTest is BaseTest {
    event PostCreated(
        uint256 indexed tokenId,
        string assetTitle,
        string assetCid,
        string thumbnailCid,
        address indexed author,
        uint256 priceInNative
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

    function test_RevertInvalidAssetCid() public {
        vm.startPrank(user);
        IMarketPlace.PostInfoParams memory params = IMarketPlace.PostInfoParams({
            postCid: "",
            postTitle: "Test Post",
            thumbnailCid: "QmThumb123",
            description: "A test post for testing",
            priceInNative: 0.1 ether
        });
        vm.expectRevert(IMarketPlace.InvalidPostCid.selector);
        marketPlace.createPost(params);
        vm.stopPrank();
    }

    function test_RevertAssetAlreadyExists() public {
        vm.startPrank(user);
        IMarketPlace.PostInfoParams memory params = IMarketPlace.PostInfoParams({
            postCid: "QmTest123",
            postTitle: "Test Post",
            thumbnailCid: "QmThumb123",
            description: "A test post for testing",
            priceInNative: 0.1 ether
        });
        marketPlace.createPost(params);
        vm.expectRevert(IMarketPlace.PostAlreadyExists.selector);
        marketPlace.createPost(params);
        vm.stopPrank();
    }

    function test_RevertEmptyPostTitle() public {
        vm.startPrank(user);
        IMarketPlace.PostInfoParams memory params = IMarketPlace.PostInfoParams({
            postCid: "QmTest123",
            postTitle: "",
            thumbnailCid: "QmThumb123",
            description: "A test post for testing",
            priceInNative: 0.1 ether
        });
        vm.expectRevert(IMarketPlace.EmptyPostTitle.selector);
        marketPlace.createPost(params);
        vm.stopPrank();
    }

    function test_RevertPostTitleTooLong() public {
        vm.startPrank(user);
        IMarketPlace.PostInfoParams memory params = IMarketPlace.PostInfoParams({
            postCid: "QmTest123",
            postTitle: "Test Post Too Long For Testing Test Post Too Long For Testing Test Post Too Long For Testing Test Post Too Long For Testing Test Post Too Long For Testing",
            thumbnailCid: "QmThumb123",
            description: "A test post for testing",
            priceInNative: 0.1 ether
        });
        vm.expectRevert(IMarketPlace.PostTitleTooLong.selector);
        marketPlace.createPost(params);
        vm.stopPrank();
    }

    function test_RevertInvalidThumbnailCid() public {
        vm.startPrank(user);
        IMarketPlace.PostInfoParams memory params = IMarketPlace.PostInfoParams({
            postCid: "QmTest123",
            postTitle: "Test Post",
            thumbnailCid: "",
            description: "A test post for testing",
            priceInNative: 0.1 ether
        });
        vm.expectRevert(IMarketPlace.InvalidThumbnailCid.selector);
        marketPlace.createPost(params);
        vm.stopPrank();
    }

    function test_RevertDescriptionTooLong() public {
        vm.startPrank(user);
        IMarketPlace.PostInfoParams memory params = IMarketPlace.PostInfoParams({
            postCid: "QmTest123",
            postTitle: "Test Post",
            thumbnailCid: "QmThumb123",
            description: "Test Asset Too Long For Testing Test Asset Too Long For Testing Test Asset Too Long For Testing Test Asset Too Long For Testing Test Asset Too Long For Testing Test Asset Too Long For Testing Test Asset Too Long For Testing Test Asset Too Long For Testing Test Asset Too Long For Testing Test Asset Too Long For Testing",
            priceInNative: 0.1 ether
        });
        vm.expectRevert(IMarketPlace.DescriptionTooLong.selector);
        marketPlace.createPost(params);
        vm.stopPrank();
    }

    function test_RevertInvalidPrice() public {
        vm.startPrank(user);
        IMarketPlace.PostInfoParams memory params = IMarketPlace.PostInfoParams({
            postCid: "QmTest123",
            postTitle: "Test Post",
            thumbnailCid: "QmThumb123",
            description: "A test post for testing",
            priceInNative: 11 ether
        });
        vm.expectRevert(IMarketPlace.InvalidPrice.selector);
        marketPlace.createPost(params);
        vm.stopPrank();
    }

    function test_CreatePost() public {
        vm.startPrank(user);
        
        IMarketPlace.PostInfoParams memory params = IMarketPlace.PostInfoParams({
            postCid: "QmTest123",
            postTitle: "Test Post",
            thumbnailCid: "QmThumb123",
            description: "A test post for testing",
            priceInNative: 0.1 ether
        });

        vm.expectEmit(true, true, false, true);
        emit PostCreated(1, "Test Post", "QmTest123", "QmThumb123", user, 0.1 ether);
        uint256 tokenId = marketPlace.createPost(params);
        
        assertEq(tokenId, 1);
        assertEq(marketPlace.totalPosts(), 1);
        
        IMarketPlace.PostInfo memory info = marketPlace.getPostInfo(tokenId);
        assertEq(info.author, user);
        assertEq(info.postCid, "QmTest123");
        assertEq(info.postTitle, "Test Post");
        assertEq(info.priceInNative, 0.1 ether);
        
        vm.stopPrank();
    }

    function test_CreateMultiplePosts() public {
        vm.prank(user);
        IMarketPlace.PostInfoParams memory params1 = IMarketPlace.PostInfoParams({
            postCid: "QmTest1",
            postTitle: "Post 1",
            thumbnailCid: "QmThumb1",
            description: "First post",
            priceInNative: 0.1 ether
        });
        uint256 tokenId1 = marketPlace.createPost(params1);

        vm.prank(admin);
        IMarketPlace.PostInfoParams memory params2 = IMarketPlace.PostInfoParams({
            postCid: "QmTest2",
            postTitle: "Post 2",
            thumbnailCid: "QmThumb2",
            description: "Second post",
            priceInNative: 0.2 ether
        });
        uint256 tokenId2 = marketPlace.createPost(params2);

        assertEq(tokenId1, 1);
        assertEq(tokenId2, 2);
        assertEq(marketPlace.totalPosts(), 2);

        IMarketPlace.PostInfo[] memory posts = marketPlace.getAllPosts();
        assertEq(posts.length, 2);
        assertEq(posts[0].author, user);
        assertEq(posts[1].author, admin);
    }

    function test_RevertUpdatePostPrice() public {
        vm.prank(user);
        IMarketPlace.PostInfoParams memory params = IMarketPlace.PostInfoParams({
            postCid: "QmTest123",
            postTitle: "Test Post",
            thumbnailCid: "QmThumb123",
            description: "A test post",
            priceInNative: 0.1 ether
        });
        uint256 tokenId = marketPlace.createPost(params);
        vm.expectRevert(IMarketPlace.NotPostAuthor.selector);
        marketPlace.updatePostPrice(tokenId, 0.2 ether);
    }

    function test_RevertInvalidPriceUpdatePostPrice() public {
        vm.prank(user);
        IMarketPlace.PostInfoParams memory params = IMarketPlace.PostInfoParams({
            postCid: "QmTest123",
            postTitle: "Test Post",
            thumbnailCid: "QmThumb123",
            description: "A test post",
            priceInNative: 0.1 ether
        });
        uint256 tokenId = marketPlace.createPost(params);
        vm.prank(user);
        vm.expectRevert(IMarketPlace.InvalidPrice.selector);
        marketPlace.updatePostPrice(tokenId, 11 ether);
    }

    function test_RevertPostDoesNotExistUpdatePostPrice() public {
        vm.prank(user);
        IMarketPlace.PostInfoParams memory params = IMarketPlace.PostInfoParams({
            postCid: "QmTest123",
            postTitle: "Test Post",
            thumbnailCid: "QmThumb123",
            description: "A test post",
            priceInNative: 0.1 ether
        });
        uint256 tokenId = marketPlace.createPost(params);
        vm.expectRevert(IMarketPlace.PostDoesNotExist.selector);
        marketPlace.updatePostPrice(tokenId + 1, 0.2 ether);
    }

    function test_UpdatePostPrice() public {
        vm.prank(user);
        IMarketPlace.PostInfoParams memory params = IMarketPlace.PostInfoParams({
            postCid: "QmTest123",
            postTitle: "Test Post",
            thumbnailCid: "QmThumb123",
            description: "A test post",
            priceInNative: 0.1 ether
        });
        uint256 tokenId = marketPlace.createPost(params);

        vm.expectEmit(true, true, false, true);
        emit PostPriceUpdated(tokenId, 0.1 ether, 0.2 ether);
        vm.prank(user);
        marketPlace.updatePostPrice(tokenId, 0.2 ether);
        
        assertEq(marketPlace.getPostInfo(tokenId).priceInNative, 0.2 ether);
    }
}

contract MarketPlaceSubscribePostTest is BaseTest {
    event PostSubscribed(
        uint256 indexed tokenId,
        address indexed subscriber,
        uint256 totalCost
    );

    uint256 public tokenId;
    address public subscriber;

    function setUp() public override {
        super.setUp();

        vm.prank(user);
        IMarketPlace.PostInfoParams memory params = IMarketPlace.PostInfoParams({
            postCid: "QmTest123",
            postTitle: "Test Post",
            thumbnailCid: "QmThumb123",
            description: "A test post",
            priceInNative: 0.1 ether
        });
        tokenId = marketPlace.createPost(params);
        subscriber = makeAddr("subscriber");
        vm.deal(subscriber, 100 ether);
    }

    function test_RevertPostDoesNotExist() public {
        vm.startPrank(subscriber);
        vm.expectRevert(IMarketPlace.PostDoesNotExist.selector);
        marketPlace.subscribePost(tokenId + 1);
        vm.stopPrank();
    }

    function test_RevertInsufficientPayment() public {
        vm.startPrank(subscriber);
        vm.expectRevert(IMarketPlace.InsufficientPayment.selector);
        marketPlace.subscribePost{value: 0.09 ether}(tokenId);
        vm.stopPrank();
    }

    function test_RevertNativeTransferFailed() public {
        vm.prank(address(dXconfig));
        IMarketPlace.PostInfoParams memory params = IMarketPlace.PostInfoParams({
            postCid: "QmTest1234",
            postTitle: "Test Post",
            thumbnailCid: "QmThumb123",
            description: "A test post",
            priceInNative: 0.1 ether
        });
        tokenId = marketPlace.createPost(params);
        
        vm.startPrank(subscriber);
        vm.expectRevert(IMarketPlace.NativeTransferFailed.selector);
        marketPlace.subscribePost{value: 0.1 ether}(tokenId);
        vm.stopPrank();
    }

    function test_RevertPostAlreadySubscribed() public {
        vm.prank(subscriber);
        marketPlace.subscribePost{value: 0.1 ether}(tokenId);
        vm.prank(subscriber);
        vm.expectRevert(IMarketPlace.PostAlreadySubscribed.selector);
        marketPlace.subscribePost{value: 0.1 ether}(tokenId);
    }

    function test_SubscribePost() public {
        uint256 userBalanceBefore = user.balance;
        uint256 subscriberBalanceBefore = subscriber.balance;
        
        vm.startPrank(subscriber);
        
        vm.expectEmit(true, true, false, true);
        emit PostSubscribed(tokenId, subscriber, 0.1 ether);
        marketPlace.subscribePost{value: 0.1 ether}(tokenId);
        
        assertEq(marketPlace.balanceOf(subscriber, tokenId), 1);
        
        assertEq(user.balance, userBalanceBefore + 0.095 ether);
        assertEq(subscriber.balance, subscriberBalanceBefore - 0.1 ether);
        assertEq(address(marketPlace).balance, 0.005 ether);
        
        vm.stopPrank();
    }

    function test_BuyPostWithRefund() public {
        uint256 excessPayment = 0.5 ether;
        
        uint256 subscriberBalanceBefore = subscriber.balance;
        
        vm.prank(subscriber);
        marketPlace.subscribePost{value: 0.1 ether + excessPayment}(tokenId);
        
        assertEq(marketPlace.balanceOf(subscriber, tokenId), 1);
        assertEq(subscriber.balance, subscriberBalanceBefore - 0.1 ether);
    }

    function test_RevertNativeTransferFailedSubscribePostToPost() public {
        uint256 excessPayment = 0.5 ether;
        deal(address(dXconfig), 1 ether);
        
        vm.prank(address(dXconfig));
        vm.expectRevert(IMarketPlace.NativeTransferFailed.selector);
        marketPlace.subscribePost{value: 0.1 ether + excessPayment}(tokenId);
    }

    function test_SubscribePostToUser() public {
        vm.prank(subscriber);
        marketPlace.subscribePost{value: 0.1 ether}(tokenId);

        assertEq(marketPlace.balanceOf(subscriber, tokenId), 1);

        uint256[] memory subscriberTokenIds = marketPlace.getUserPosts(subscriber);
        assertEq(subscriberTokenIds.length, 1);
        assertEq(subscriberTokenIds[0], tokenId);
    }
}

contract MarketPlaceAdminFunctionsTest is BaseTest {
    event ConfigUpdated(address indexed newConfig);
    event MaxPostTitleLengthUpdated(uint256 newLength);
    event MaxDescriptionLengthUpdated(uint256 newLength);
    event MaxPriceInNativeUpdated(uint256 newPrice);
    event PlatformFeeWithdrawn(uint256 amount, address indexed recipient);

    function test_RevertNotAdminUpdateDXConfig() public {
        vm.prank(user);
        vm.expectRevert(IdXconfig.NotAdmin.selector);
        marketPlace.updateDXConfig(address(dXconfig));
    }

    function test_RevertInvalidAddressUpdateDXConfig() public {
        vm.prank(admin);
        vm.expectRevert(UtilLib.ZeroAddressNotAllowed.selector);
        marketPlace.updateDXConfig(address(0));
    }

    function test_UpdateDXConfig() public {
        vm.prank(admin);
        marketPlace.updateDXConfig(address(dXconfig));

        vm.expectEmit(true, true, true, true);
        emit ConfigUpdated(address(dXconfig));
        vm.prank(admin);
        marketPlace.updateDXConfig(address(dXconfig));
    }

    function test_RevertNotAdminSetMaxAssetTitleLength() public {
        vm.prank(user);
        vm.expectRevert(IdXconfig.NotAdmin.selector);
        marketPlace.setMaxPostTitleLength(100);
    }

    function test_SetMaxPostTitleLength() public {
        vm.expectEmit(true, true, true, true);
        emit MaxPostTitleLengthUpdated(100);
        vm.prank(admin);
        marketPlace.setMaxPostTitleLength(100);
        assertEq(marketPlace.maxPostTitleLength(), 100);
    }

    function test_RevertNotAdminSetMaxDescriptionLength() public {
        vm.prank(user);
        vm.expectRevert(IdXconfig.NotAdmin.selector);
        marketPlace.setMaxDescriptionLength(100);
    }

    function test_SetMaxDescriptionLength() public {
        vm.expectEmit(true, true, true, true);
        emit MaxDescriptionLengthUpdated(100);
        vm.prank(admin);
        marketPlace.setMaxDescriptionLength(100);
        assertEq(marketPlace.maxDescriptionLength(), 100);
    }

    function test_RevertNotAdminSetMaxPriceInNative() public {
        vm.prank(user);
        vm.expectRevert(IdXconfig.NotAdmin.selector);
        marketPlace.setMaxPriceInNative(100 ether);
    }

    function test_SetMaxPriceInNative() public {
        vm.expectEmit(true, true, true, true);
        emit MaxPriceInNativeUpdated(100 ether);
        vm.prank(admin);
        marketPlace.setMaxPriceInNative(100 ether);
        assertEq(marketPlace.maxPriceInNative(), 100 ether);
    }

    function test_RevertNotAdminWithdrawFees() public {
        vm.prank(user);
        vm.expectRevert(IdXconfig.NotAdmin.selector);
        marketPlace.withdrawFees(100 ether);
    }

    function test_RevertMoreThanBalanceWithdrawFees() public {
        vm.prank(admin);
        vm.expectRevert(IMarketPlace.MoreThanBalance.selector);
        marketPlace.withdrawFees(100 ether);
    }

    function test_RevertNativeTransferFailedWithdrawFees() public {
        vm.prank(user);
        IMarketPlace.PostInfoParams memory params = IMarketPlace.PostInfoParams({
            postCid: "QmTest123",
            postTitle: "Test Post",
            thumbnailCid: "QmThumb123",
            description: "A test post",
            priceInNative: 0.1 ether
        });
        uint256 tokenId = marketPlace.createPost(params);

        address subscriber = makeAddr("subscriber");
        vm.deal(subscriber, 100 ether);

        vm.prank(subscriber);
        marketPlace.subscribePost{value: 0.1 ether}(tokenId);

        vm.prank(admin);
        dXconfig.grantRole(DXconstants.DEFAULT_ADMIN_ROLE, address(dXconfig));

        vm.prank(address(dXconfig));
        vm.expectRevert(IMarketPlace.NativeTransferFailed.selector);
        marketPlace.withdrawFees(0.001 ether);
    }

    function test_WithdrawFees() public {
        uint256 adminBalanceBefore = admin.balance;

        vm.expectEmit(true, true, false, true);
        emit PlatformFeeWithdrawn(0, admin);

        vm.prank(admin);
        marketPlace.withdrawFees(0 ether);
        assertEq(address(marketPlace).balance, 0);
        assertEq(admin.balance, adminBalanceBefore);
    }

    function test_RevertPause() public {
        vm.prank(user);
        vm.expectRevert(IdXconfig.NotAdmin.selector);
        marketPlace.pause();
        assertEq(marketPlace.paused(), false);
    }

    function test_Pause() public {
        vm.prank(admin);
        marketPlace.pause();
        assertEq(marketPlace.paused(), true);
    }

    function test_RevertUnpause() public {
        vm.prank(user);
        vm.expectRevert(IdXconfig.NotAdmin.selector);
        marketPlace.unpause();
        assertEq(marketPlace.paused(), false);
    }

    function test_Unpause() public {
        vm.prank(admin);
        marketPlace.pause();

        vm.prank(admin);
        marketPlace.unpause();
        assertEq(marketPlace.paused(), false);
    }
}

contract MarketPlaceGetterTest is BaseTest {
    uint256 public tokenId;

    function setUp() public override { 
        super.setUp();

        vm.prank(user);
        IMarketPlace.PostInfoParams memory params = IMarketPlace.PostInfoParams({
            postCid: "QmTest123",
            postTitle: "Test Post",
            thumbnailCid: "QmThumb123",
            description: "A test post",
            priceInNative: 0.1 ether
        });
        tokenId = marketPlace.createPost(params);
    }

    function test_GetPostInfo() public {
        IMarketPlace.PostInfo memory info = marketPlace.getPostInfo(tokenId);
        assertEq(info.author, user);
        assertEq(info.postCid, "QmTest123");
        assertEq(info.postTitle, "Test Post");
        assertEq(info.priceInNative, 0.1 ether);
    }

    function test_GetPostInfoByCid() public {
        IMarketPlace.PostInfo memory info = marketPlace.getPostInfoByCid("QmTest123");
        assertEq(info.author, user);
        assertEq(info.postCid, "QmTest123");
        assertEq(info.postTitle, "Test Post");
        assertEq(info.priceInNative, 0.1 ether);
    }

    function test_GetAllPosts() public {
        IMarketPlace.PostInfo[] memory posts = marketPlace.getAllPosts();
        assertEq(posts.length, 1);
        assertEq(posts[0].author, user);
        assertEq(posts[0].postCid, "QmTest123");
        assertEq(posts[0].postTitle, "Test Post");
        assertEq(posts[0].priceInNative, 0.1 ether);
    }

    function test_GetUserPosts() public {
        vm.prank(user);
        marketPlace.subscribePost{value: 0.1 ether}(tokenId);

        uint256[] memory userTokenIds = marketPlace.getUserPosts(user);
        assertEq(userTokenIds.length, 1);
        assertEq(userTokenIds[0], tokenId);
    }

    function test_GetTotalPosts() public {
        assertEq(marketPlace.totalPosts(), 1);
    }
}

contract MarketPlaceTransferTest is BaseTest {
    uint256 public tokenId;
    address public subscriber;

    function setUp() public override { 
        super.setUp();

        vm.prank(user);
        IMarketPlace.PostInfoParams memory params = IMarketPlace.PostInfoParams({
            postCid: "QmTest123",
            postTitle: "Test Post",
            thumbnailCid: "QmThumb123",
            description: "A test post",
            priceInNative: 0.1 ether
        });
        tokenId = marketPlace.createPost(params);

        subscriber = makeAddr("subscriber");
        vm.deal(subscriber, 100 ether);

        vm.prank(subscriber);
        marketPlace.subscribePost{value: 0.1 ether}(tokenId);
    }

    function test_RevertBurnNotAllowed() public {
        vm.prank(subscriber);
        vm.expectRevert(IMarketPlace.InvalidTokenTransfer.selector);
        IERC6909(address(marketPlace)).transfer(address(1), tokenId, 1);
    }
}

    // function test_RevertTransferNotAllowed() public {
    //     // Create asset
    //     vm.prank(alice);
    //     IMarketPlace.AssetInfoParams memory params = IMarketPlace.AssetInfoParams({
    //         assetCid: "QmTest123",
    //         assetTitle: "Test Asset",
    //         thumbnailCid: "QmThumb123",
    //         description: "A test asset",
    //         priceInNative: ASSET_PRICE
    //     });
    //     uint256 tokenId = marketPlace.createPost(params);

    //     vm.prank(bob);
    //     marketPlace.subscribePost{value: ASSET_PRICE}(tokenId);

    //     // Bob tries to transfer to Charlie - should fail
    //     vm.prank(bob);
    //     vm.expectRevert(IMarketPlace.InvalidTokenTransfer.selector);
    //     marketPlace.transfer(charlie, tokenId, 1);
    // }

    // function test_UpdatePrice() public {
    //     // Create asset
    //     vm.prank(alice);
    //     IMarketPlace.AssetInfoParams memory params = IMarketPlace.AssetInfoParams({
    //         assetCid: "QmTest123",
    //         assetTitle: "Test Asset",
    //         thumbnailCid: "QmThumb123",
    //         description: "A test asset",
    //         priceInNative: ASSET_PRICE
    //     });
    //     uint256 tokenId = marketPlace.createPost(params);

    //     // Update price
    //     uint256 newPrice = 0.2 ether;
    //     vm.prank(alice);
    //     marketPlace.updatePostPrice(tokenId, newPrice);

    //     IMarketPlace.AssetInfo memory info = marketPlace.getPostInfo(tokenId);
    //     assertEq(info.priceInNative, newPrice);
    // }

    // function test_WithdrawFees() public {
    //     // Create and subscribe to asset
    //     vm.prank(alice);
    //     IMarketPlace.AssetInfoParams memory params = IMarketPlace.AssetInfoParams({
    //         assetCid: "QmTest123",
    //         assetTitle: "Test Asset",
    //         thumbnailCid: "QmThumb123",
    //         description: "A test asset",
    //         priceInNative: ASSET_PRICE
    //     });
    //     uint256 tokenId = marketPlace.createPost(params);

    //     vm.prank(bob);
    //     marketPlace.subscribePost{value: ASSET_PRICE}(tokenId);

    //     uint256 contractBalance = address(marketPlace).balance;
    //     uint256 adminBalanceBefore = admin.balance;

    //     // Withdraw fees
    //     vm.prank(admin);
    //     marketPlace.withdrawFees(contractBalance);

    //     assertEq(address(marketPlace).balance, 0);
    //     assertEq(admin.balance, adminBalanceBefore + contractBalance);
    // }

    // function test_RevertInvalidAssetCid() public {
    //     vm.prank(alice);
    //     IMarketPlace.AssetInfoParams memory params = IMarketPlace.AssetInfoParams({
    //         assetCid: "",
    //         assetTitle: "Test Asset",
    //         thumbnailCid: "QmThumb123",
    //         description: "A test asset",
    //         priceInNative: ASSET_PRICE
    //     });

    //     vm.expectRevert(IMarketPlace.InvalidAssetCid.selector);
    //     marketPlace.createPost(params);
    // }

    // function test_RevertAssetAlreadyExists() public {
    //     vm.startPrank(alice);
        
    //     IMarketPlace.AssetInfoParams memory params = IMarketPlace.AssetInfoParams({
    //         assetCid: "QmTest123",
    //         assetTitle: "Test Asset",
    //         thumbnailCid: "QmThumb123",
    //         description: "A test asset",
    //         priceInNative: ASSET_PRICE
    //     });
        
    //     marketPlace.createPost(params);

    //     vm.expectRevert(IMarketPlace.AssetAlreadyExists.selector);
    //     marketPlace.createPost(params);
        
    //     vm.stopPrank();
    // }

    // function test_RevertInsufficientPayment() public {
    //     vm.prank(alice);
    //     IMarketPlace.AssetInfoParams memory params = IMarketPlace.AssetInfoParams({
    //         assetCid: "QmTest123",
    //         assetTitle: "Test Asset",
    //         thumbnailCid: "QmThumb123",
    //         description: "A test asset",
    //         priceInNative: ASSET_PRICE
    //     });
    //     uint256 tokenId = marketPlace.createPost(params);

    //     vm.prank(bob);
    //     vm.expectRevert(IMarketPlace.InsufficientPayment.selector);
    //     marketPlace.subscribePost{value: ASSET_PRICE / 2}(tokenId);
    // }

    // function test_RevertNotAssetAuthor() public {
    //     vm.prank(alice);
    //     IMarketPlace.AssetInfoParams memory params = IMarketPlace.AssetInfoParams({
    //         assetCid: "QmTest123",
    //         assetTitle: "Test Asset",
    //         thumbnailCid: "QmThumb123",
    //         description: "A test asset",
    //         priceInNative: ASSET_PRICE
    //     });
    //     uint256 tokenId = marketPlace.createPost(params);

    //     vm.prank(bob);
    //     vm.expectRevert(IMarketPlace.NotAssetAuthor.selector);
    //     marketPlace.updatePostPrice(tokenId, 0.2 ether);
    // }

    // function test_PauseUnpause() public {
    //     vm.prank(admin);
    //     marketPlace.pause();

    //     vm.prank(alice);
    //     IMarketPlace.AssetInfoParams memory params = IMarketPlace.AssetInfoParams({
    //         assetCid: "QmTest123",
    //         assetTitle: "Test Asset",
    //         thumbnailCid: "QmThumb123",
    //         description: "A test asset",
    //         priceInNative: ASSET_PRICE
    //     });

    //     vm.expectRevert();
    //     marketPlace.createPost(params);

    //     vm.prank(admin);
    //     marketPlace.unpause();

    //     vm.prank(alice);
    //     uint256 tokenId = marketPlace.createPost(params);
    //     assertEq(tokenId, 1);
    // }
// }