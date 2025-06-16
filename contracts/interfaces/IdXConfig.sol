// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.21;

interface IdXConfig {
    error InvalidKey();
    error NotAdmin();
    error NotBot();

    event AddressSet(bytes32 indexed _key, address _address);

    function getAddress(bytes32 _key) external returns (address);

    function setAddress(bytes32 _key, address _address) external;
}
