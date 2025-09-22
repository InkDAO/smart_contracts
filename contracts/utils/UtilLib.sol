// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

library UtilLib {
    error ZeroAddressNotAllowed();

    function checkNonZeroAddress(address _address) external pure {
        if (_address == address(0)) {
            revert ZeroAddressNotAllowed();
        }
    }
}
