// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.21;

import { Initializable } from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import { IAccessControl } from "@openzeppelin/contracts/access/IAccessControl.sol";

import { UtilLib } from "./UtilLib.sol";
import { IdXConfig } from "../interfaces/IdXConfig.sol";
import { dXConstants } from "./dXConstants.sol";

abstract contract dXRoleChecker is Initializable {

    event dXConfigUpdated(address indexed _dXConfig);

    IdXConfig public dXConfig;

    modifier onlyAdmin() {
        if (!IAccessControl(address(dXConfig)).hasRole(dXConstants.DEFAULT_ADMIN_ROLE, msg.sender)) {
            revert IdXConfig.NotAdmin();
        }
        _;
    }

    modifier onlyBot() {
        if (!IAccessControl(address(dXConfig)).hasRole(dXConstants.BOT_ROLE, msg.sender)) {
            revert IdXConfig.NotBot();
        }
        _;
    }

    function updatedXConfig(address _dXConfig) external onlyAdmin {
        UtilLib.checkNonZeroAddress(_dXConfig);

        dXConfig = IdXConfig(_dXConfig);
        emit dXConfigUpdated(_dXConfig);
    }
}
