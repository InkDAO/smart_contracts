// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

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

    string[] public assetCids;
    mapping(address => bool) public isDxAsset;
    mapping(string => AssetInfo) public assetData;
    mapping(string => CommentInfo[]) public commentData;
    mapping(address => UserAssetInfo[]) public userAssetData;

    IdXconfig public dXConfig;
    uint256 public maxAssetTitleLength;
    uint256 public maxCommentLength;

    constructor() {
        _disableInitializers();
    }

    function __DXmaster_Init(
        address _dXConfig,
        uint256 _maxAssetTitleLength,
        uint256 _maxCommentLength
    )
        public
        initializer
    {
        __Pausable_init();
        __ReentrancyGuard_init();

        dXConfig = IdXconfig(_dXConfig);
        maxAssetTitleLength = _maxAssetTitleLength;
        maxCommentLength = _maxCommentLength;
    }

    modifier isValidAsset(string calldata _assetTitle, string calldata _assetCid) {
        if (bytes(_assetCid).length == 0) {
            revert InvalidAssetCid();
        }
        if (assetData[_assetCid].assetAddress != address(0)) {
            revert AssetAlreadyAdded();
        }
        if (bytes(_assetTitle).length == 0) {
            revert EmptyAssetTitle();
        }
        if (bytes(_assetTitle).length > maxAssetTitleLength) {
            revert AssetTitleLengthTooBig();
        }
        _;
    }

    modifier isValidComment(string memory _assetCid, string calldata _comment) {
        AssetInfo memory assetInfo = assetData[_assetCid];
        if (assetInfo.assetAddress == address(0)) {
            revert InvalidAsset();
        }
        if (bytes(_comment).length == 0) {
            revert EmptyComment();
        }
        if (bytes(_comment).length > maxCommentLength) {
            revert CommentLengthTooBig();
        }
        _;
    }

    modifier onlydXAsset() {
        if (!isDxAsset[msg.sender]) {
            revert NotdXAsset();
        }
        _;
    }

    modifier isValidBuy(string memory _assetCid, uint256 _amount) {
        if (_amount == 0) {
            revert InvalidAmount();
        }
        AssetInfo memory assetInfo = assetData[_assetCid];
        if (assetInfo.assetAddress == address(0)) {
            revert InvalidAsset();
        }
        if (IdXasset(assetInfo.assetAddress).costInNativeInWei() * _amount > msg.value) {
            revert InsufficientAmount();
        }
        _;
    }

    function totalAssets() external view returns (uint256) {
        return assetCids.length;
    }

    function getAssetInfo(string memory _assetCid) external view returns (AssetInfo memory) {
        return assetData[_assetCid];
    }

    function getAllAssets() external view returns (AssetInfo[] memory allAssetInfo) {
        allAssetInfo = new AssetInfo[](assetCids.length);
        for (uint256 i = 0; i < assetCids.length; i++) {
            allAssetInfo[i] = assetData[assetCids[i]];
        }
    }

    function getCommentsInfo(string memory _assetCid) external view returns (CommentInfo[] memory) {
        return commentData[_assetCid];
    }

    function getUserAssetData(address _user) external view returns (UserAssetInfo[] memory) {
        return userAssetData[_user];
    }

    function addAsset(
        bytes32 _salt,
        string calldata _assetTitle,
        string calldata _assetCid,
        uint256 _costInNativeInWei
    )
        external
        nonReentrant
        whenNotPaused
        isValidAsset(_assetTitle, _assetCid)
    {
        address assetFactoryAddress = dXConfig.getAddress(DXconstants.ASSET_FACTORY_ADDRESS);
        address assetAddress =
            IdXassetFactory(assetFactoryAddress).createAsset(_salt, _assetCid, _costInNativeInWei, msg.sender);

        AssetInfo storage assetInfo = assetData[_assetCid];
        assetInfo.author = msg.sender;
        assetInfo.assetTitle = _assetTitle;
        assetInfo.assetAddress = assetAddress;

        assetCids.push(_assetCid);
        isDxAsset[assetAddress] = true;
        assetData[_assetCid] = assetInfo;

        emit AssetAdded(_assetTitle, _assetCid, assetAddress, msg.sender, _costInNativeInWei);
    }

    function addComment(
        string memory _assetCid,
        string calldata _comment
    )
        external
        nonReentrant
        whenNotPaused
        isValidComment(_assetCid, _comment)
    {
        commentData[_assetCid].push(CommentInfo({ assetCid: _assetCid, comment: _comment, author: msg.sender }));

        emit CommentAdded(_assetCid, _comment, msg.sender);
    }

    function buyAsset(
        string memory _assetCid,
        uint256 _amount
    )
        external
        payable
        nonReentrant
        whenNotPaused
        isValidBuy(_assetCid, _amount)
    {
        AssetInfo memory assetInfo = assetData[_assetCid];

        _handleBuyFinances(_amount, msg.value, IdXasset(assetInfo.assetAddress).costInNativeInWei(), assetInfo.author);

        IdXasset(assetInfo.assetAddress).mint(msg.sender, _amount);

        emit AssetBought(_assetCid, _amount, msg.sender);
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

    function beforeTokenTransfer(address _from, address _to, uint256 _amount) external onlydXAsset {
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

    function _handleBuyFinances(
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
        (bool authorSuccess,) = payable(_author).call{ value: authorFee }("");
        if (!authorSuccess) revert NativeTransferFailed();
    }
}
