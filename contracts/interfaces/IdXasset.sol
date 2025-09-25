// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

interface IdXasset {
    struct AssetInfo {
        address author;
        string assetCid;
        string assetTitle;
        string thumbnailCid;
        string description;
        uint256 costInNativeInWei;
    }

    error NotOwnerOrDxmaster();

    event CostInNativeInWeiUpdated(uint256 _costInNativeInWei);

    function mint(address _to, uint256 _amount) external;
    function burn(uint256 _amount) external;
    function setCostInNativeInWei(uint256 _costInNativeInWei) external;
    function costInNativeInWei() external view returns (uint256);
    function assetCid() external view returns (string memory);
    function thumbnailCid() external view returns (string memory);
    function assetTitle() external view returns (string memory);
    function description() external view returns (string memory);
    function getAssetInfo() external view returns (AssetInfo memory);
}
