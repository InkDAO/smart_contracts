// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.21;
import { Script, console2 } from "forge-std/Script.sol";

import { ProxyAdmin } from "@openzeppelin/contracts/proxy/transparent/ProxyAdmin.sol";
import { TransparentUpgradeableProxy } from "@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";

import { MasterdX } from "../contracts/MasterdX.sol";
import { IMasterdX } from "../contracts/interfaces/IMasterdX.sol";
import { dXConfig } from "../contracts/dXConfig.sol";
import { IdXConfig } from "../contracts/interfaces/IdXConfig.sol";
import { dXConstants } from "../contracts/utils/dXConstants.sol";

contract DeploydX is Script {
    ProxyAdmin public proxyAdmin;
    dXConfig public dxConfig;
    MasterdX public masterdX;

    address admin;

    uint256 postLifeTime;
    uint256 maxPostTitleLength;

    function setUp() external {
        admin = 0xEBA436aE4012D8194a5b44718a8ba6ec553241bE;
        postLifeTime = 7 days;
        maxPostTitleLength = 100;
    }

    function run() public {
        vm.startBroadcast();

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

        dxConfig.grantRole(dXConstants.BOT_ROLE, 0xEBA436aE4012D8194a5b44718a8ba6ec553241bE);

        console2.log("proxyAdmin deployed at: ", address(proxyAdmin));
        
        console2.log("dXConfig Impl deployed at: ", address(dXConfigImpl));
        console2.log("dXConfig proxy deployed at: ", address(dXConfigProxy));

        console2.log("masterdX Impl deployed at: ", address(masterdXImpl));
        console2.log("masterdX proxy deployed at: ", address(masterdXProxy));

        console2.log("Admin role: ", dxConfig.hasRole(dXConstants.DEFAULT_ADMIN_ROLE, 0xEBA436aE4012D8194a5b44718a8ba6ec553241bE));
        console2.log("Bot role: ", dxConfig.hasRole(dXConstants.BOT_ROLE, 0xEBA436aE4012D8194a5b44718a8ba6ec553241bE));

        vm.stopBroadcast();
    }
}