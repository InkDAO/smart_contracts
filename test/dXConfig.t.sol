// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import { Test, console2 } from "forge-std/Test.sol";
import { DXconfig } from "../contracts/DXconfig.sol";
import { IdXconfig } from "../contracts/interfaces/IdXconfig.sol";
import { DXconstants } from "../contracts/utils/DXconstants.sol";

import { ProxyAdmin } from "@openzeppelin/contracts/proxy/transparent/ProxyAdmin.sol";
import { TransparentUpgradeableProxy } from "@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";

// Define the event that matches the contract
event AddressSet(bytes32 indexed key, address address_);

event Uint256Set(bytes32 indexed key, uint256 value);

contract DXConfigTest is Test {
    DXconfig public dxConfig;
    ProxyAdmin public proxyAdmin;

    address public admin = makeAddr("admin");

    function setUp() external {
        vm.startPrank(admin);

        proxyAdmin = new ProxyAdmin(admin);

        DXconfig dXConfigImpl = new DXconfig();
        TransparentUpgradeableProxy dXConfigProxy =
            new TransparentUpgradeableProxy(address(dXConfigImpl), address(proxyAdmin), "");
        dxConfig = DXconfig(address(dXConfigProxy));
        dxConfig.__DXconfig_Init(admin);

        vm.stopPrank();
    }
}

contract GetSetAddressTest is DXConfigTest {
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
        vm.expectRevert(IdXconfig.NotAdmin.selector);
        dxConfig.setAddress(TEST_KEY, testAddress);
        vm.stopPrank();
    }

    function test_SetAddress_InvalidKey() public {
        vm.startPrank(admin);
        vm.expectRevert(IdXconfig.InvalidKey.selector);
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

contract GetSetUint256Test is DXConfigTest {
    bytes32 public constant TEST_KEY = keccak256("TEST_KEY");
    address public nonAdmin = makeAddr("nonAdmin");
    uint256 public testUint256 = 100;

    function test_Initialization() public view {
        assertEq(dxConfig.getUint256(TEST_KEY), 0);
    }

    function test_SetUint256() public {
        vm.startPrank(admin);
        dxConfig.setUint256(TEST_KEY, testUint256);
        assertEq(dxConfig.getUint256(TEST_KEY), testUint256);
        vm.stopPrank();
    }

    function test_SetUint256_NonAdmin() public {
        vm.startPrank(nonAdmin);
        vm.expectRevert(IdXconfig.NotAdmin.selector);
        dxConfig.setUint256(TEST_KEY, testUint256);
        vm.stopPrank();
    }

    function test_SetUint256_InvalidKey() public {
        vm.startPrank(admin);
        vm.expectRevert(IdXconfig.InvalidKey.selector);
        dxConfig.setUint256(bytes32(0), testUint256);
        vm.stopPrank();
    }

    function test_SetUint256_Event() public {
        vm.startPrank(admin);
        vm.expectEmit(true, true, true, true);
        emit Uint256Set(TEST_KEY, testUint256);
        dxConfig.setUint256(TEST_KEY, testUint256);
        vm.stopPrank();
    }
}
