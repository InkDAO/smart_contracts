// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import { Create2 } from "@openzeppelin/contracts/utils/Create2.sol";
import { Initializable } from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import { PausableUpgradeable } from "@openzeppelin/contracts-upgradeable/utils/PausableUpgradeable.sol";
import { ReentrancyGuardUpgradeable } from "@openzeppelin/contracts-upgradeable/utils/ReentrancyGuardUpgradeable.sol";

import { DXasset } from "../Token/DXasset.sol";
import { UtilLib } from "../utils/UtilLib.sol";
import { IdXasset } from "../interfaces/IdXasset.sol";
import { IdXconfig } from "../interfaces/IdXconfig.sol";
import { DXroleChecker } from "../utils/DXroleChecker.sol";
import { IdXassetFactory } from "../interfaces/IdXassetFactory.sol";

contract DXassetFactory is Initializable, PausableUpgradeable, ReentrancyGuardUpgradeable, IdXassetFactory {
    IdXconfig public dXConfig;

    constructor() {
        _disableInitializers();
    }

    function __DXassetFactory_Init(address _dXConfig) public initializer {
        __Pausable_init();
        __ReentrancyGuard_init();

        dXConfig = IdXconfig(_dXConfig);
    }

    function createAsset(
        bytes32 _salt,
        string memory _name,
        string memory _symbol,
        IdXasset.AssetInfo calldata _assetInfoParams
    )
        external
        nonReentrant
        whenNotPaused
        returns (address assetAddress)
    {
        DXroleChecker.onlyDXMaster(address(dXConfig));

        assetAddress = Create2.deploy(
            0,
            _salt,
            abi.encodePacked(
                type(DXasset).creationCode,
                abi.encode(_name, _symbol, _assetInfoParams, address(dXConfig))
            )
        );

        emit AssetCreated(assetAddress, _assetInfoParams.assetCid);
    }

    function pause() external {
        DXroleChecker.onlyAdmin(address(dXConfig));
        _pause();
    }

    function unpause() external {
        DXroleChecker.onlyAdmin(address(dXConfig));
        _unpause();
    }

    function updatedXConfig(address _dXConfig) external {
        DXroleChecker.onlyAdmin(address(dXConfig));
        UtilLib.checkNonZeroAddress(_dXConfig);
        dXConfig = IdXconfig(_dXConfig);

        emit dXConfigUpdated(address(dXConfig));
    }
}
