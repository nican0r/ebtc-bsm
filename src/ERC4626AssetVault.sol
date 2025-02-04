// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.25;

import {BaseAssetVault} from "./BaseAssetVault.sol";
import {IERC4626AssetVault} from "./Dependencies/IERC4626AssetVault.sol";
import {IERC4626} from "@openzeppelin/contracts/interfaces/IERC4626.sol";
import {SafeERC20, IERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

contract ERC4626AssetVault is BaseAssetVault, IERC4626AssetVault {
    using SafeERC20 for IERC20;

    uint256 public constant BPS = 10000;
    IERC4626 public immutable EXTERNAL_VAULT;

    error TooFewSharesReceived(uint256 expectedShares, uint256 actualShares);
    error TooFewAssetsReceived(uint256 expectedAssets, uint256 actualAssets);

    constructor(
        address _externalVault,
        address _assetToken,
        address _bsm,
        address _governance,
        address _feeRecipient
    ) BaseAssetVault(_assetToken, _bsm, _governance, _feeRecipient) {
        EXTERNAL_VAULT = IERC4626(_externalVault);
    }

    function _beforeWithdraw(
        uint256 assetAmount,
        uint256 feeAmount
    ) internal override {
        _ensureLiquidity(assetAmount);

        super._beforeWithdraw(assetAmount, feeAmount);
    }

    /// @notice Pull liquidity from the external lending vault if necessary
    function _ensureLiquidity(uint256 amountRequired) private {
        /// @dev super._totalBalance() returns asset balance for this contract
        uint256 liquidBalance = super._totalBalance();

        if (amountRequired > liquidBalance) {
            uint256 deficit;
            unchecked {
                deficit = amountRequired - liquidBalance;
            }

            EXTERNAL_VAULT.withdraw(deficit, address(this), address(this));
        }
    }

    function _totalBalance() internal override view returns (uint256) {
        /// @dev convertToAssets is the same as previewRedeem for OZ, Aave, Euler, Morpho
        return EXTERNAL_VAULT.convertToAssets(EXTERNAL_VAULT.balanceOf(address(this))) + super._totalBalance();
    }

    function _withdrawProfit(uint256 profitAmount) internal override {
        _ensureLiquidity(profitAmount);

        super.withdrawProfit();
    }

    /// @notice Redeem all shares
    function _beforeMigration() internal override {
        EXTERNAL_VAULT.redeem(EXTERNAL_VAULT.balanceOf(address(this)), address(this), address(this));
    }

    function depositToExternalVault(uint256 assetsToDeposit, uint256 expectedShares) external requiresAuth {
        ASSET_TOKEN.safeIncreaseAllowance(address(EXTERNAL_VAULT), assetsToDeposit);
        uint256 shares = EXTERNAL_VAULT.deposit(depositAmount, address(this));
        if (shares < expectedShares) {
            revert TooFewSharesReceived(expectedShares, shares);
        }
    }

    function redeemFromExternalVault(uint256 sharesToRedeem, uint256 expectedAssets) external requiresAuth {
        uint256 assets = EXTERNAL_VAULT.redeem(sharesToRedeem, address(this), address(this));
        if (assets < expectedAssets) {
            revert TooFewAssetsReceived(expectedAssets, assets);
        }
    }
}
