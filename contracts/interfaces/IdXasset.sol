// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

interface IdXasset {
    error NotOwnerOrDxmaster();

    event CostInNativeInWeiUpdated(uint256 _costInNativeInWei);

    function mint(address _to, uint256 _amount) external;
    function burn(uint256 _amount) external;
    function setCostInNativeInWei(uint256 _costInNativeInWei) external;
    function costInNativeInWei() external view returns (uint256);
}
