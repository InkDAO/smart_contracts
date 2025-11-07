// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import { IAccessControl } from "@openzeppelin/contracts/access/IAccessControl.sol";

import { DXconstants } from "./DXconstants.sol";
import { IdXconfig } from "../interfaces/IdXconfig.sol";

library DXroleChecker {
    function onlyRole(address _dXConfig, bytes32 _role) external view {
        if (!IAccessControl(_dXConfig).hasRole(_role, msg.sender)) {
            revert IdXconfig.CallerUnauthorized();
        }
    }

    function onlyAdmin(address _dXConfig) external view {
        if (!IAccessControl(_dXConfig).hasRole(DXconstants.DEFAULT_ADMIN_ROLE, msg.sender)) {
            revert IdXconfig.NotAdmin();
        }
    }
}
