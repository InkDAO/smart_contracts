// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import { BaseTest } from "./BaseTest.t.sol";
import { DXasset } from "../contracts/Token/DXasset.sol";
import { IdXmaster } from "../contracts/interfaces/IdXmaster.sol";
import { IdXconfig } from "../contracts/interfaces/IdXconfig.sol";
import { UtilLib } from "../contracts/utils/UtilLib.sol";

contract DXassetFactoryTest is BaseTest {
    function setUp() public override {
        super.setUp();

        vm.prank(user);
        dXmaster.addAsset(IdXmaster.AddAssetParams({
            salt: keccak256(abi.encodePacked("test asset")),
            assetTitle: "test asset",
            assetCid: "assetcid",
            thumbnailCid: "thumbnailcid",
            description: "description",
            costInNativeInWei: 1 ether / 100
        }));
        IdXmaster.AssetInfo memory assetInfo = dXmaster.getAssetInfo("assetcid");
        dXasset = DXasset(assetInfo.assetAddress);
    }

    function test_Initialization() public view {
        assertEq(address(dXassetFactory.dXConfig()), address(dXconfig));
    }
}

contract CreateAssetTest is DXassetFactoryTest {
    error NotDXMaster();

    event AssetCreated(address _assetAddress, string _assetCid, string _thumbnailCid, uint256 _costInNative, string _description);

    function test_CreateAsset() public {
        vm.prank(address(dXmaster));
        dXassetFactory.createAsset(keccak256(abi.encodePacked("test asset")), "assetcid", "thumbnailcid", 1 ether / 100, user, "description");

        assertEq(dXassetFactory.totalAssetCount(), 2);
        assertEq(dXassetFactory.getAllAssets()[0], address(dXasset));
    }

    function test_RevertNotDXMaster() public {
        vm.prank(user);
        vm.expectRevert(NotDXMaster.selector);
        dXassetFactory.createAsset(keccak256(abi.encodePacked("test asset")), "assetcid", "thumbnailcid", 1 ether / 100, user, "description");
    }

    function test_EmitAssetCreated() public {
        vm.prank(address(dXmaster));
        vm.expectEmit(false, false, false, false);
        emit AssetCreated(address(dXasset), "assetcid", "thumbnailcid", 1 ether / 100, "description");
        dXassetFactory.createAsset(keccak256(abi.encodePacked("test asset")), "assetcid", "thumbnailcid", 1 ether / 100, user, "description");
    }
}

contract PauseUnpauseTest is DXassetFactoryTest {
    function test_PauseUnpause() public {
        vm.startPrank(admin);
        dXassetFactory.pause();
        assertTrue(dXassetFactory.paused());

        dXassetFactory.unpause();
        assertFalse(dXassetFactory.paused());
        vm.stopPrank();
    }

    function test_RevertNonOwnerPause() public {
        vm.startPrank(user);
        vm.expectRevert();
        dXassetFactory.pause();
        vm.stopPrank();
    }
}

contract updatedXConfigTest is DXassetFactoryTest {
    event dXConfigUpdated(address _dXConfig);

    function test_RevertNotAdmin() public {
        vm.expectRevert(IdXconfig.NotAdmin.selector);
        dXassetFactory.updatedXConfig(address(dXconfig));
    }

    function test_RevertZeroAddressNotAllowed() public {
        vm.prank(admin);
        vm.expectRevert(UtilLib.ZeroAddressNotAllowed.selector);
        dXassetFactory.updatedXConfig(address(0));
    }

    function test_EmitdXConfigUpdated() public {
        vm.prank(admin);
        vm.expectEmit(true, true, true, true);
        emit dXConfigUpdated(address(1));
        dXassetFactory.updatedXConfig(address(1));
    }
}
