// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import { Test, console2 } from "forge-std/Test.sol";

import { ProxyAdmin } from "@openzeppelin/contracts/proxy/transparent/ProxyAdmin.sol";
import { TransparentUpgradeableProxy } from "@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";

import { DXconstants } from "../contracts/utils/DXconstants.sol";
import { DXmaster } from "../contracts/DXmaster.sol";
import { DXconfig } from "../contracts/DXconfig.sol";
import { DXasset } from "../contracts/Token/DXasset.sol";
import { DXassetFactory } from "../contracts/factory/DXassetFactory.sol";
import { IdXasset } from "../contracts/interfaces/IdXasset.sol";
import { IdXconfig } from "../contracts/interfaces/IdXconfig.sol";
import { IdXmaster } from "../contracts/interfaces/IdXmaster.sol";
import { IdXassetFactory } from "../contracts/interfaces/IdXassetFactory.sol";

contract BaseTest is Test {
    DXasset public dXasset;
    DXmaster public dXmaster;
    DXconfig public dXconfig;
    ProxyAdmin public proxyAdmin;
    DXassetFactory public dXassetFactory;

    address public bot;
    address public user;
    address public admin;

    uint256 public maxCommentLength;
    uint256 public maxAssetTitleLength;

    function setUp() public virtual {
        bot = makeAddr("bot");
        user = makeAddr("user");
        admin = makeAddr("admin");

        maxCommentLength = 200;
        maxAssetTitleLength = 100;

        vm.startPrank(admin);

        proxyAdmin = new ProxyAdmin(admin);

        DXconfig dXConfigImpl = new DXconfig();
        TransparentUpgradeableProxy dXConfigProxy =
            new TransparentUpgradeableProxy(address(dXConfigImpl), address(proxyAdmin), "");
        dXconfig = DXconfig(address(dXConfigProxy));
        dXconfig.__DXconfig_Init(admin);

        DXmaster dXmasterImpl = new DXmaster();
        TransparentUpgradeableProxy dXmasterProxy =
            new TransparentUpgradeableProxy(address(dXmasterImpl), address(proxyAdmin), "");
        dXmaster = DXmaster(address(dXmasterProxy));
        dXmaster.__DXmaster_Init(address(dXconfig), maxAssetTitleLength, maxCommentLength);

        DXassetFactory dXassetFactoryImpl = new DXassetFactory();
        TransparentUpgradeableProxy dXassetFactoryProxy =
            new TransparentUpgradeableProxy(address(dXassetFactoryImpl), address(proxyAdmin), "");
        dXassetFactory = DXassetFactory(address(dXassetFactoryProxy));
        dXassetFactory.__DXassetFactory_Init(address(dXconfig));

        dXasset = new DXasset("DXasset", "DXasset", user, "assetcid", "thumbnailcid", 1 ether / 100, address(dXconfig), "description");

        dXconfig.grantRole(DXconstants.BOT_ROLE, bot);
        dXconfig.setUint256(DXconstants.PLATFORM_FEE, 500); // 5%
        dXconfig.setAddress(DXconstants.DXMASTER_ADDRESS, address(dXmaster));
        dXconfig.setAddress(DXconstants.ASSET_FACTORY_ADDRESS, address(dXassetFactory));

        vm.stopPrank();
    }
}
