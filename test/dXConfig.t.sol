// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.21;

import { Test, console2 } from "forge-std/Test.sol";
import { dXConfig } from "../contracts/dXConfig.sol";
import { IdXConfig } from "../contracts/interfaces/IdXConfig.sol";
import { dXConstants } from "../contracts/utils/dXConstants.sol";

import { ProxyAdmin } from "@openzeppelin/contracts/proxy/transparent/ProxyAdmin.sol";
import { TransparentUpgradeableProxy } from "@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";

// Define the event that matches the contract
event AddressSet(bytes32 indexed key, address address_);

contract dXConfigTest is Test {
    dXConfig public dxConfig;
    ProxyAdmin public proxyAdmin;

    address public admin = makeAddr("admin");

    function setUp() external {
        vm.startPrank(admin);

        proxyAdmin = new ProxyAdmin(admin);

        dXConfig dXConfigImpl = new dXConfig();
        TransparentUpgradeableProxy dXConfigProxy = 
            new TransparentUpgradeableProxy(address(dXConfigImpl), address(proxyAdmin), "");
        dxConfig = dXConfig(address(dXConfigProxy));
        dxConfig.__dXConfig_Init(admin);

        vm.stopPrank();
    }
}

contract GetSetAddressTest is dXConfigTest {
    bytes32 public constant TEST_KEY = keccak256("TEST_KEY");
    address public testAddress = makeAddr("testAddress");
    address public nonAdmin = makeAddr("nonAdmin");

    function test_Initialization() public view {
        assertTrue(dxConfig.hasRole(dxConfig.DEFAULT_ADMIN_ROLE(), admin));
        assertEq(dxConfig.getAddress(TEST_KEY), address(0));
    }

    function test_SetAddress() public {
        vm.startPrank(admin);
        dxConfig.setAddress(TEST_KEY, testAddress);
        assertEq(dxConfig.getAddress(TEST_KEY), testAddress);
        vm.stopPrank();
    }

    function test_SetAddress_NonAdmin() public {
        vm.startPrank(nonAdmin);
        vm.expectRevert(
            abi.encodeWithSelector(
                bytes4(keccak256("AccessControlUnauthorizedAccount(address,bytes32)")),
                nonAdmin,
                dxConfig.DEFAULT_ADMIN_ROLE()
            )
        );
        dxConfig.setAddress(TEST_KEY, testAddress);
        vm.stopPrank();
    }

    function test_SetAddress_InvalidKey() public {
        vm.startPrank(admin);
        vm.expectRevert(IdXConfig.InvalidKey.selector);
        dxConfig.setAddress(bytes32(0), testAddress);
        vm.stopPrank();
    }

    function test_SetAddress_Event() public {
        vm.startPrank(admin);
        vm.expectEmit(true, true, true, true);
        emit AddressSet(TEST_KEY, testAddress);
        dxConfig.setAddress(TEST_KEY, testAddress);
        vm.stopPrank();
    }
}