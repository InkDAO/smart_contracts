// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { ERC20 } from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import { IdXasset } from "../interfaces/IdXasset.sol";
import { IdXconfig } from "../interfaces/IdXconfig.sol";
import { DXconstants } from "../utils/DXconstants.sol";
import { IdXmaster } from "../interfaces/IdXmaster.sol";

contract DXasset is ERC20, IdXasset, Ownable {
    using SafeERC20 for ERC20;

    string public assetTitle;
    string public thumbnailCid;
    string public description;
    uint256 public costInNativeInWei;
    
    string public assetCid;
    
    IdXconfig public dXConfig;

    constructor(
        string memory name,
        string memory symbol,
        AssetInfo memory _assetInfoParams,
        address _dXConfig
    )
        ERC20(name, symbol)
        Ownable(_assetInfoParams.author)
    {
        assetCid = _assetInfoParams.assetCid;
        assetTitle = _assetInfoParams.assetTitle;
        thumbnailCid = _assetInfoParams.thumbnailCid;
        costInNativeInWei = _assetInfoParams.costInNativeInWei;
        description = _assetInfoParams.description;
        
        dXConfig = IdXconfig(_dXConfig);
    }

    modifier onlyOwnerOrDxmaster() {
        if (msg.sender != owner() && msg.sender != dXConfig.getAddress(DXconstants.DXMASTER_ADDRESS)) {
            revert NotOwnerOrDxmaster();
        }
        _;
    }

    function getAssetInfo() external view returns (AssetInfo memory) {
        return AssetInfo({
            assetCid: assetCid,
            assetTitle: assetTitle,
            thumbnailCid: thumbnailCid,
            description: description,
            costInNativeInWei: costInNativeInWei,
            author: owner()
        });
    }

    function mint(address _to, uint256 _amount) external onlyOwnerOrDxmaster {
        _update(address(0), _to, _amount);
    }

    function burn(uint256 _amount) external {
        _update(msg.sender, address(0), _amount);
    }

    function setCostInNativeInWei(uint256 _costInNativeInWei) external onlyOwner {
        costInNativeInWei = _costInNativeInWei;

        emit CostInNativeInWeiUpdated(costInNativeInWei);
    }

    function _update(address from, address to, uint256 amount) internal override {
        address dXmaster = dXConfig.getAddress(DXconstants.DXMASTER_ADDRESS);
        IdXmaster(dXmaster).beforeTokenTransfer(from, to, amount);
        super._update(from, to, amount);
    }
}
