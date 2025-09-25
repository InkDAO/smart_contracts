// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import { Strings } from "@openzeppelin/contracts/utils/Strings.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import { Initializable } from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import { PausableUpgradeable } from "@openzeppelin/contracts-upgradeable/utils/PausableUpgradeable.sol";
import { ReentrancyGuardUpgradeable } from "@openzeppelin/contracts-upgradeable/utils/ReentrancyGuardUpgradeable.sol";

import { UtilLib } from "./utils/UtilLib.sol";
import { IdXasset } from "./interfaces/IdXasset.sol";
import { DXconstants } from "./utils/DXconstants.sol";
import { IdXconfig } from "./interfaces/IdXconfig.sol";
import { IdXmaster } from "./interfaces/IdXmaster.sol";
import { DXroleChecker } from "./utils/DXroleChecker.sol";
import { IdXassetFactory } from "./interfaces/IdXassetFactory.sol";

contract DXmaster is Initializable, PausableUpgradeable, ReentrancyGuardUpgradeable, IdXmaster {
    using SafeERC20 for IERC20;

    address[] public assetAddresses;
    mapping(string => address) public assetData;
    mapping(address => CommentInfo[]) public commentData;
    mapping(address => UserAssetInfo[]) public userAssetData;

    IdXconfig public dXConfig;
    uint256 public maxCommentLength;
    uint256 public maxAssetTitleLength;
    uint256 public maxDescriptionLength;

    constructor() {
        _disableInitializers();
    }

    function __DXmaster_Init(
        address _dXConfig,
        uint256 _maxCommentLength,
        uint256 _maxAssetTitleLength,
        uint256 _maxDescriptionLength
    )
        public
        initializer
    {
        __Pausable_init();
        __ReentrancyGuard_init();

        dXConfig = IdXconfig(_dXConfig);
        maxCommentLength = _maxCommentLength;
        maxAssetTitleLength = _maxAssetTitleLength;
        maxDescriptionLength = _maxDescriptionLength;
    }

    modifier isValidAsset(AssetInfoParams calldata _assetInfoParams) {
        if (bytes(_assetInfoParams.assetCid).length == 0) {
            revert InvalidAssetCid();
        }
        if (assetData[_assetInfoParams.assetCid] != address(0)) {
            revert AssetAlreadyAdded();
        }
        if (bytes(_assetInfoParams.assetTitle).length == 0) {
            revert EmptyAssetTitle();
        }
        if (bytes(_assetInfoParams.assetTitle).length > maxAssetTitleLength) {
            revert AssetTitleLengthTooBig();
        }
        if (bytes(_assetInfoParams.thumbnailCid).length == 0) {
            revert InvalidThumbnailCid();
        }
        if (bytes(_assetInfoParams.description).length > maxDescriptionLength) {
            revert DescriptionTooBig();
        }
        _;
    }

    modifier isValidComment(address _assetAddress, string calldata _comment) {
        if (bytes(_comment).length == 0) {
            revert EmptyComment();
        }
        if (bytes(_comment).length > maxCommentLength) {
            revert CommentLengthTooBig();
        }
        _;
    }

    modifier onlydXAsset(address _assetAddress) {
        if (_assetAddress == address(0)) {
            revert InvalidAssetAddress();
        }
        string memory assetCid = IdXasset(_assetAddress).assetCid();
        if (assetData[assetCid] != _assetAddress) {
            revert NotdXAsset();
        }
        _;
    }

    modifier isValidBuy(address _assetAddress, uint256 _amount) {
        if (_amount == 0) {
            revert InvalidAmount();
        }
        if (IdXasset(_assetAddress).costInNativeInWei() * _amount > msg.value) {
            revert InsufficientAmount();
        }
        _;
    }

    function totalAssets() external view returns (uint256) {
        return assetAddresses.length;
    }

    function getAssetInfo(string memory _assetCid) public view returns (IdXasset.AssetInfo memory) {
        return IdXasset(assetData[_assetCid]).getAssetInfo();
    }

    function getAllAssetInfos() external view returns (address[] memory allAssetAddresses, IdXasset.AssetInfo[] memory allAssetInfo) {
        allAssetInfo = new IdXasset.AssetInfo[](assetAddresses.length);
        for (uint256 i = 0; i < assetAddresses.length; i++) {
            allAssetInfo[i] = IdXasset(assetAddresses[i]).getAssetInfo();
        }
        allAssetAddresses = assetAddresses;
    }

    function getCommentsInfo(address _assetAddress) external view returns (CommentInfo[] memory) {
        return commentData[_assetAddress];
    }

    function getUserAssetData(address _user) external view returns (UserAssetInfo[] memory) {
        return userAssetData[_user];
    }

    function addAsset(
        bytes32 _salt,
        AssetInfoParams calldata _assetInfoParams
    )
        external
        nonReentrant
        whenNotPaused
        isValidAsset(_assetInfoParams)
        returns (address assetAddress)
    {

        string memory name = string.concat("decentralizedXAsset", Strings.toString(assetAddresses.length));
        string memory symbol = string.concat("dXAsset", Strings.toString(assetAddresses.length));

        address assetFactoryAddress = dXConfig.getAddress(DXconstants.ASSET_FACTORY_ADDRESS);
        assetAddress =
            IdXassetFactory(assetFactoryAddress).createAsset(_salt, name, symbol, IdXasset.AssetInfo({
                author: msg.sender,
                assetCid: _assetInfoParams.assetCid,
                assetTitle: _assetInfoParams.assetTitle,
                thumbnailCid: _assetInfoParams.thumbnailCid,
                description: _assetInfoParams.description,
                costInNativeInWei: _assetInfoParams.costInNativeInWei
            }));

        assetAddresses.push(assetAddress);
        assetData[_assetInfoParams.assetCid] = assetAddress;

        emit AssetAdded(_assetInfoParams.assetTitle, _assetInfoParams.assetCid, _assetInfoParams.thumbnailCid, assetAddress, msg.sender, _assetInfoParams.costInNativeInWei);
    }

    function addComment(
        address _assetAddress,
        string calldata _comment
    )
        external
        nonReentrant
        whenNotPaused
        onlydXAsset(_assetAddress)
        isValidComment(_assetAddress, _comment)
    {
        commentData[_assetAddress].push(CommentInfo({ comment: _comment, author: msg.sender }));

        emit CommentAdded(_assetAddress, _comment, msg.sender);
    }

    function buyAsset(
        address _assetAddress,
        uint256 _amount
    )
        external
        payable
        nonReentrant
        whenNotPaused
        onlydXAsset(_assetAddress)
        isValidBuy(_assetAddress, _amount)
    {
        IdXasset.AssetInfo memory assetInfo = IdXasset(_assetAddress).getAssetInfo();

        _handleTransfer(_amount, msg.value, assetInfo.costInNativeInWei, assetInfo.author);

        IdXasset(_assetAddress).mint(msg.sender, _amount);

        emit AssetBought(_assetAddress, _amount, msg.sender);
    }

    function pause() external {
        DXroleChecker.onlyAdmin(address(dXConfig));
        _pause();
    }

    function unpause() external {
        DXroleChecker.onlyAdmin(address(dXConfig));
        _unpause();
    }

    function setMaxAssetTitleLength(uint256 _maxAssetTitleLength) external {
        DXroleChecker.onlyAdmin(address(dXConfig));
        maxAssetTitleLength = _maxAssetTitleLength;

        emit MaxAssetTitleLengthUpdated(maxAssetTitleLength);
    }

    function setMaxCommentLength(uint256 _maxCommentLength) external {
        DXroleChecker.onlyAdmin(address(dXConfig));
        maxCommentLength = _maxCommentLength;

        emit MaxCommentLengthUpdated(maxCommentLength);
    }

    function setMaxDescriptionLength(uint256 _maxDescriptionLength) external {
        DXroleChecker.onlyAdmin(address(dXConfig));
        maxDescriptionLength = _maxDescriptionLength;

        emit MaxDescriptionLengthUpdated(maxDescriptionLength);
    }

    function updatedXConfig(address _dXConfig) external {
        DXroleChecker.onlyAdmin(address(dXConfig));
        UtilLib.checkNonZeroAddress(_dXConfig);
        dXConfig = IdXconfig(_dXConfig);

        emit dXConfigUpdated(address(dXConfig));
    }

    function withdrawFee(uint256 _amount) external {
        DXroleChecker.onlyAdmin(address(dXConfig));

        if (_amount > address(this).balance) {
            revert MoreThanBalance();
        }

        (bool success,) = payable(msg.sender).call{ value: _amount }("");
        if (!success) revert NativeTransferFailed();

        emit WithdrawFee(_amount);
    }

    function beforeTokenTransfer(address _from, address _to, uint256 _amount) external onlydXAsset(msg.sender) {
        if (_from != address(0)) {
            UserAssetInfo[] storage _userAssetData = userAssetData[_from];
            for (uint256 i = 0; i < _userAssetData.length; i++) {
                if (_userAssetData[i].assetAddress == msg.sender) {
                    _userAssetData[i].amount -= _amount;
                    if (_userAssetData[i].amount == 0) {
                        _userAssetData[i] = _userAssetData[_userAssetData.length - 1];
                        _userAssetData.pop();
                    }
                    break;
                }
            }
        }

        if (_to != address(0)) {
            bool isFound = false;
            UserAssetInfo[] storage _userAssetData = userAssetData[_to];
            for (uint256 i = 0; i < _userAssetData.length; i++) {
                if (_userAssetData[i].assetAddress == msg.sender) {
                    _userAssetData[i].amount += _amount;
                    isFound = true;
                    break;
                }
            }
            if (!isFound) {
                _userAssetData.push(UserAssetInfo({ assetAddress: msg.sender, amount: _amount }));
            }
        }
    }

    function _handleTransfer(
        uint256 _amount,
        uint256 _msgValue,
        uint256 _costInNativeInWei,
        address _author
    )
        internal
    {
        uint256 totalAmount = _costInNativeInWei * _amount;

        uint256 refundableAmount = _msgValue - totalAmount;
        if (refundableAmount > 0) {
            (bool refundableSuccess,) = payable(msg.sender).call{ value: refundableAmount }("");
            if (!refundableSuccess) revert NativeTransferFailed();
        }

        uint256 platformFee = totalAmount * dXConfig.getUint256(DXconstants.PLATFORM_FEE) / DXconstants.DENOMINATOR;
        uint256 authorFee = totalAmount - platformFee;
        if (authorFee > 0) {
            (bool authorSuccess,) = payable(_author).call{ value: authorFee }("");
            if (!authorSuccess) revert NativeTransferFailed();
        }
    }
}
