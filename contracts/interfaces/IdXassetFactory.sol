// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

interface IdXassetFactory {
    event dXConfigUpdated(address _dXConfig);
    event AssetCreated(address _assetAddress, string _assetCid, string _thumbnailCid, uint256 _costInNative, string _description);

    function createAsset(
        bytes32 _salt,
        string memory _assetCid,
        string memory _thumbnailCid,
        uint256 _costInNativeInWei,
        address _owner,
        string memory _description
    )
        external
        returns (address assetAddress);

    function getAllAssets() external view returns (address[] memory);

    function totalAssetCount() external view returns (uint256);

    function updatedXConfig(address _dXConfig) external;
}
