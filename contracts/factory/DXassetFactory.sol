// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import { Create2 } from "@openzeppelin/contracts/utils/Create2.sol";
import { Strings } from "@openzeppelin/contracts/utils/Strings.sol";
import { Initializable } from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import { PausableUpgradeable } from "@openzeppelin/contracts-upgradeable/utils/PausableUpgradeable.sol";
import { ReentrancyGuardUpgradeable } from "@openzeppelin/contracts-upgradeable/utils/ReentrancyGuardUpgradeable.sol";

import { DXasset } from "../Token/DXasset.sol";
import { UtilLib } from "../utils/UtilLib.sol";
import { IdXconfig } from "../interfaces/IdXconfig.sol";
import { DXroleChecker } from "../utils/DXroleChecker.sol";
import { IdXassetFactory } from "../interfaces/IdXassetFactory.sol";

contract DXassetFactory is Initializable, PausableUpgradeable, ReentrancyGuardUpgradeable, IdXassetFactory {
    IdXconfig public dXConfig;
    address[] public assetAddresses;

    constructor() {
        _disableInitializers();
    }

    function __DXassetFactory_Init(address _dXConfig) public initializer {
        __Pausable_init();
        __ReentrancyGuard_init();

        dXConfig = IdXconfig(_dXConfig);
    }

    function totalAssetCount() external view returns (uint256) {
        return assetAddresses.length;
    }

    function getAllAssets() external view returns (address[] memory) {
        return assetAddresses;
    }

    function createAsset(
        bytes32 _salt,
        string memory _assetCid,
        string memory _thumbnailCid,
        uint256 _costInNative,
        address _owner,
        string memory _description
    )
        external
        nonReentrant
        whenNotPaused
        returns (address assetAddress)
    {
        DXroleChecker.onlyDXMaster(address(dXConfig));

        uint256 totalAssets = assetAddresses.length;
        string memory name = string.concat("decentralizedXAsset", Strings.toString(totalAssets));
        string memory symbol = string.concat("dXAsset", Strings.toString(totalAssets));

        assetAddress = Create2.deploy(
            0,
            _salt,
            abi.encodePacked(
                type(DXasset).creationCode,
                abi.encode(name, symbol, _owner, _assetCid, _thumbnailCid, _costInNative, address(dXConfig), _description)
            )
        );
        assetAddresses.push(assetAddress);

        emit AssetCreated(assetAddress, _assetCid, _thumbnailCid, _costInNative, _description);
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
