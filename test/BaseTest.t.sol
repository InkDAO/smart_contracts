// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import { Test, console2 } from "forge-std/Test.sol";

import { ProxyAdmin } from "@openzeppelin/contracts/proxy/transparent/ProxyAdmin.sol";
import { TransparentUpgradeableProxy } from "@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";

import { DXconfig } from "../contracts/DXconfig.sol";
import { MarketPlace } from "../contracts/MarketPlace.sol";
import { DXconstants } from "../contracts/utils/DXconstants.sol";
import { IdXconfig } from "../contracts/interfaces/IdXconfig.sol";

contract BaseTest is Test {
    MarketPlace public marketPlace;
    DXconfig public dXconfig;
    ProxyAdmin public proxyAdmin;

    address public bot;
    address public user;
    address public admin;

    uint256 public maxAssetTitleLength;
    uint256 public maxDescriptionLength;
    uint256 public maxPriceInNative;

    function setUp() public virtual {
        bot = makeAddr("bot");
        user = makeAddr("user");
        admin = makeAddr("admin");

        maxAssetTitleLength = 100;
        maxDescriptionLength = 200;
        maxPriceInNative = 10 ether;

        vm.startPrank(admin);

        proxyAdmin = new ProxyAdmin(admin);

        DXconfig dXConfigImpl = new DXconfig();
        TransparentUpgradeableProxy dXConfigProxy =
            new TransparentUpgradeableProxy(address(dXConfigImpl), address(proxyAdmin), "");
        dXconfig = DXconfig(address(dXConfigProxy));
        dXconfig.__DXconfig_Init(admin);
        
        // Set platform fee (5%)
        dXconfig.setUint256(DXconstants.PLATFORM_FEE, 500);

        MarketPlace marketPlaceImpl = new MarketPlace();
        TransparentUpgradeableProxy marketPlaceProxy =
            new TransparentUpgradeableProxy(address(marketPlaceImpl), address(proxyAdmin), "");
        marketPlace = MarketPlace(payable(address(marketPlaceProxy)));
        marketPlace.__MarketPlace_Init(address(dXconfig), maxAssetTitleLength, maxDescriptionLength, maxPriceInNative);

        vm.stopPrank();
        
        // Fund test accounts
        vm.deal(user, 100 ether);
        vm.deal(bot, 100 ether);
        vm.deal(admin, 100 ether);
    }
}
