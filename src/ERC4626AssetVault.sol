// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.25;

import {BaseAssetVault} from "./BaseAssetVault.sol";
import {IERC4626AssetVault} from "./Dependencies/IERC4626AssetVault.sol";
import {IERC4626} from "@openzeppelin/contracts/interfaces/IERC4626.sol";
import {SafeERC20, IERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {console} from "forge-std/console.sol";

contract ERC4626AssetVault is BaseAssetVault, IERC4626AssetVault {
    using SafeERC20 for IERC20;

    uint256 public constant BPS = 10000;
    IERC4626 public immutable EXTERNAL_VAULT;

    error TooFewSharesReceived(uint256 minShares, uint256 actualShares);
    error TooFewAssetsReceived(uint256 minAssets, uint256 actualAssets);

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
    ) internal override returns (uint256) {
        uint256 redeemedAmount = _ensureLiquidity(assetAmount);

        // remove assetAmount from depositAmount even if redeemedAmount < assetAmount
        super._beforeWithdraw(assetAmount, feeAmount);

        return redeemedAmount;
    }

    /// @notice Pull liquidity from the external lending vault if necessary
    function _ensureLiquidity(uint256 amountRequired) private returns (uint256 amountRedeemed) {
        /// @dev super._totalBalance() returns asset balance for this contract
        uint256 liquidBalance = super._totalBalance();

        amountRedeemed = amountRequired;

        if (amountRequired > liquidBalance) {
            uint256 deficit;
            unchecked {
                deficit = amountRequired - liquidBalance;
            }

            // using convertToShares here because it rounds down
            // this prevents the vault from taking on losses
            uint256 shares = EXTERNAL_VAULT.convertToShares(deficit);

            uint256 balanceBefore = ASSET_TOKEN.balanceOf(address(this));
            EXTERNAL_VAULT.redeem(shares, address(this), address(this));
            uint256 balanceAfter = ASSET_TOKEN.balanceOf(address(this));

            // amountRedeemed can be less than deficit because of rounding
            amountRedeemed = liquidBalance + (balanceAfter - balanceBefore);
        }
    }

    function _totalBalance() internal override view returns (uint256) {
        /// @dev convertToAssets is the same as previewRedeem for OZ, Aave, Euler, Morpho
        return EXTERNAL_VAULT.convertToAssets(EXTERNAL_VAULT.balanceOf(address(this))) + super._totalBalance();
    }

    function _withdrawProfit(uint256 profitAmount) internal override {
        uint256 redeemedAmount = _ensureLiquidity(profitAmount);

        super._withdrawProfit(redeemedAmount);
    }

    /// @notice Redeem all shares
    function _beforeMigration() internal override {
        EXTERNAL_VAULT.redeem(EXTERNAL_VAULT.balanceOf(address(this)), address(this), address(this));
    }

    function depositToExternalVault(uint256 assetsToDeposit, uint256 minShares) external requiresAuth {
        ASSET_TOKEN.safeIncreaseAllowance(address(EXTERNAL_VAULT), assetsToDeposit);
        uint256 shares = EXTERNAL_VAULT.deposit(depositAmount, address(this));
        if (shares < minShares) {
            revert TooFewSharesReceived(minShares, shares);
        }
    }

    function redeemFromExternalVault(uint256 sharesToRedeem, uint256 minAssets) external requiresAuth {
        uint256 assets = EXTERNAL_VAULT.redeem(sharesToRedeem, address(this), address(this));
        if (assets < minAssets) {
            revert TooFewAssetsReceived(minAssets, assets);
        }
    }
}
