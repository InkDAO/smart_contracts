// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;
import { IdXasset } from "./IdXasset.sol";
interface IdXassetFactory {
    event dXConfigUpdated(address _dXConfig);
    event AssetCreated(address _assetAddress, string _assetCid);

    function createAsset(
        bytes32 _salt,
        string memory _name,
        string memory _symbol,
        IdXasset.AssetInfo memory _assetInfoParams
    )
        external
        returns (address assetAddress);

    function updatedXConfig(address _dXConfig) external;
}
