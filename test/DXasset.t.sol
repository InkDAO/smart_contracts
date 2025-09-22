// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import { console } from "forge-std/console.sol";

import { BaseTest } from "./BaseTest.t.sol";
import { IdXmaster } from "../contracts/interfaces/IdXmaster.sol";
import { DXasset } from "../contracts/Token/DXasset.sol";
import { DXconstants } from "../contracts/utils/DXconstants.sol";
import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";

contract DXassetTest is BaseTest {
    event CostInNativeInWeiUpdated(uint256 _costInNativeInWei);

    function test_Initialization() public view {
        assertEq(dXasset.owner(), user);
        assertEq(dXasset.name(), "DXasset");
        assertEq(dXasset.symbol(), "DXasset");
        assertEq(dXasset.assetCid(), "assetcid");
        assertEq(dXasset.costInNativeInWei(), 1 ether / 100);
        assertEq(address(dXasset.dXConfig()), address(dXconfig));
    }

    function test_SetCostInNativeInWei() public {
        vm.startPrank(user);
        dXasset.setCostInNativeInWei(2 ether / 100);
        assertEq(dXasset.costInNativeInWei(), 2 ether / 100);
        vm.stopPrank();
    }

    function test_SetCostInNativeInWei_NonAdmin() public {
        vm.startPrank(admin);
        vm.expectRevert(abi.encodeWithSelector(Ownable.OwnableUnauthorizedAccount.selector, admin));
        dXasset.setCostInNativeInWei(2 ether / 100);
        vm.stopPrank();
    }

    function test_SetCostInNativeInWei_Event() public {
        vm.startPrank(user);
        vm.expectEmit(true, true, true, true);
        emit CostInNativeInWeiUpdated(2 ether / 100);
        dXasset.setCostInNativeInWei(2 ether / 100);
        vm.stopPrank();
    }
}

contract MintTest is BaseTest {
    error NotOwnerOrDxmaster();

    function setUp() public override {
        super.setUp();

        vm.prank(user);
        dXmaster.addAsset(keccak256(abi.encodePacked("test asset")), "test asset", "assetcid", 1 ether / 100);
        IdXmaster.AssetInfo memory assetInfo = dXmaster.getAssetInfo("assetcid");
        dXasset = DXasset(assetInfo.assetAddress);
    }

    function test_Mint_Owner() public {
        vm.startPrank(user);
        dXasset.mint(user, 100);
        assertEq(dXasset.balanceOf(user), 100);
        vm.stopPrank();
    }

    function test_Mint_Dxmaster() public {
        vm.startPrank(address(dXmaster));
        dXasset.mint(bot, 100);
        assertEq(dXasset.balanceOf(bot), 100);
        vm.stopPrank();
    }

    function test_Mint_NonOwnerOrDxmaster() public {
        vm.startPrank(admin);
        vm.expectRevert(NotOwnerOrDxmaster.selector);
        dXasset.mint(admin, 100);
        vm.stopPrank();
    }
}
