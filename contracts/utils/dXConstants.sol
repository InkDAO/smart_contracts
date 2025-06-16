// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.21;

library dXConstants {
    bytes32 public constant BOT = keccak256("BOT");

    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x0;
    bytes32 public constant BOT_ROLE = keccak256("BOT_ROLE");
}