// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

interface IdXconfig {
    error NotBot();
    error NotAdmin();
    error InvalidKey();
    error NotDXMaster();
    error CallerUnauthorized();

    event AddressSet(bytes32 indexed _key, address _address);
    event Uint256Set(bytes32 indexed _key, uint256 _value);

    function getAddress(bytes32 _key) external view returns (address);

    function setAddress(bytes32 _key, address _address) external;

    function getUint256(bytes32 _key) external view returns (uint256);

    function setUint256(bytes32 _key, uint256 _value) external;
}
