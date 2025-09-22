// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

library DXconstants {
    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x0;
    bytes32 public constant BOT_ROLE = keccak256("BOT_ROLE");

    bytes32 public constant ASSET_FACTORY_ADDRESS = keccak256("ASSET_FACTORY_ADDRESS");
    bytes32 public constant DXMASTER_ADDRESS = keccak256("DXMASTER_ADDRESS");

    uint256 public constant DENOMINATOR = 10_000;
    bytes32 public constant PLATFORM_FEE = keccak256("PLATFORM_FEE");
}
