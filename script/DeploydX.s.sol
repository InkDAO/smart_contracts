// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import { Script, console2 } from "forge-std/Script.sol";

import { ProxyAdmin } from "@openzeppelin/contracts/proxy/transparent/ProxyAdmin.sol";
import { TransparentUpgradeableProxy } from "@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";

import { DXmaster } from "../contracts/DXmaster.sol";
import { IdXmaster } from "../contracts/interfaces/IdXmaster.sol";
import { DXconfig } from "../contracts/DXconfig.sol";
import { IdXconfig } from "../contracts/interfaces/IdXconfig.sol";
import { DXconstants } from "../contracts/utils/DXconstants.sol";
import { DXassetFactory } from "../contracts/factory/DXassetFactory.sol";

contract DeploydX is Script {
    DXmaster public dXmaster;
    DXconfig public dXconfig;
    ProxyAdmin public proxyAdmin;
    DXassetFactory public dXassetFactory;

    address admin;

    uint256 maxCommentLength;
    uint256 maxAssetTitleLength;
    uint256 maxDescriptionLength;

    function setUp() external {
        admin = 0xEBA436aE4012D8194a5b44718a8ba6ec553241bE;
        maxCommentLength = 200;
        maxAssetTitleLength = 100;
        maxDescriptionLength = 200;
    }

    function run() public {
        vm.startBroadcast();

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
        dXmaster.__DXmaster_Init(address(dXconfig), maxAssetTitleLength, maxCommentLength, maxDescriptionLength);

        DXassetFactory dXassetFactoryImpl = new DXassetFactory();
        TransparentUpgradeableProxy dXassetFactoryProxy =
            new TransparentUpgradeableProxy(address(dXassetFactoryImpl), address(proxyAdmin), "");
        dXassetFactory = DXassetFactory(address(dXassetFactoryProxy));
        dXassetFactory.__DXassetFactory_Init(address(dXconfig));

        dXconfig.grantRole(DXconstants.BOT_ROLE, admin);
        dXconfig.setUint256(DXconstants.PLATFORM_FEE, 500); // 5%
        dXconfig.setAddress(DXconstants.DXMASTER_ADDRESS, address(dXmaster));
        dXconfig.setAddress(DXconstants.ASSET_FACTORY_ADDRESS, address(dXassetFactory));

        console2.log("dXconfig deployed at: ", address(dXconfig));
        console2.log("dXmaster deployed at: ", address(dXmaster));
        console2.log("proxyAdmin deployed at: ", address(proxyAdmin));
        console2.log("dXassetFactory deployed at: ", address(dXassetFactory));

        // dXmaster.addAsset(bytes32(0), "test asset 0", "bafybeib3byag2t25vbzxjsrcc2r3amhedyxtsgynpz7gpbmdi6r3qmg53q", 0);
        // dXmaster.addAsset(bytes32(0), "test asset 1", "bafkreibex6hyc624d2gxz63i2omrrxbqbh7bmgzi6bwc6m4ib3or3eq7lq", 1 ether / 100);

        // dXmaster.buyAsset("bafybeib3byag2t25vbzxjsrcc2r3amhedyxtsgynpz7gpbmdi6r3qmg53q", 1);
        // dXmaster.buyAsset{value: 1 ether / 80}("bafkreibex6hyc624d2gxz63i2omrrxbqbh7bmgzi6bwc6m4ib3or3eq7lq", 1);

        vm.stopBroadcast();
    }
}
