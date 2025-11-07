// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

library DXconstants {
    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x0;

    uint256 public constant DENOMINATOR = 10_000;
    bytes32 public constant PLATFORM_FEE = keccak256("PLATFORM_FEE");
}
