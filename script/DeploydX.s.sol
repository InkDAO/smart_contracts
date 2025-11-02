// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import { Script, console2 } from "forge-std/Script.sol";

import { ProxyAdmin } from "@openzeppelin/contracts/proxy/transparent/ProxyAdmin.sol";
import { TransparentUpgradeableProxy } from "@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";

import { DXconfig } from "../contracts/DXconfig.sol";
import { IdXconfig } from "../contracts/interfaces/IdXconfig.sol";
import { DXconstants } from "../contracts/utils/DXconstants.sol";
import { MarketPlace } from "../contracts/MarketPlace.sol";

contract DeploydX is Script {
    MarketPlace public marketPlace;
    DXconfig public dXconfig;
    ProxyAdmin public proxyAdmin;

    address admin;

    uint256 maxPostTitleLength;
    uint256 maxDescriptionLength;
    uint256 maxPriceInNative;

    function setUp() external {
        admin = 0xEBA436aE4012D8194a5b44718a8ba6ec553241bE;
        maxPostTitleLength = 100;
        maxDescriptionLength = 200;
        maxPriceInNative = 1 ether;
    }

    function run() public {
        vm.startBroadcast();

        proxyAdmin = new ProxyAdmin(admin);

        DXconfig dXConfigImpl = new DXconfig();
        TransparentUpgradeableProxy dXConfigProxy =
            new TransparentUpgradeableProxy(address(dXConfigImpl), address(proxyAdmin), "");
        dXconfig = DXconfig(address(dXConfigProxy));
        dXconfig.__DXconfig_Init(admin);

        MarketPlace marketPlaceImpl = new MarketPlace();
        TransparentUpgradeableProxy marketPlaceProxy =
            new TransparentUpgradeableProxy(address(marketPlaceImpl), address(proxyAdmin), "");
        marketPlace = MarketPlace(payable(address(marketPlaceProxy)));
        marketPlace.__MarketPlace_Init(address(dXconfig), maxPostTitleLength, maxDescriptionLength, maxPriceInNative);

        dXconfig.grantRole(DXconstants.BOT_ROLE, admin);
        dXconfig.setUint256(DXconstants.PLATFORM_FEE, 500); // 5%

        console2.log("proxyAdmin deployed at: ", address(proxyAdmin));
        console2.log("dXconfig deployed at: ", address(dXconfig));
        console2.log("marketPlace deployed at: ", address(marketPlace));

        vm.stopBroadcast();
    }
}
