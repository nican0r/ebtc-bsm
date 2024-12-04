// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.25;

import {BaseAssetVault} from "./BaseAssetVault.sol";
import {IERC4626} from "@openzeppelin/contracts/interfaces/IERC4626.sol";

contract ERC4626AssetVault is BaseAssetVault {
    uint256 public constant BPS = 10000;
    IERC4626 public immutable EXTERNAL_VAULT;

    uint256 public liquidityBuffer;

    event LiquidityBufferUpdated(uint256 oldBuffer, uint256 newBuffer);

    constructor(
        address _externalVault,
        address _assetToken,
        address _bsm,
        address _governance,
        address _feeRecipient
    ) BaseAssetVault(_assetToken, _bsm, _governance, _feeRecipient) {
        // 100% buffer = no external lending
        liquidityBuffer = BPS;
    }

    function _afterDeposit(
        uint256 assetAmount,
        uint256 feeAmount
    ) internal override {
        // get updated depositAmount
        super._afterDeposit(assetAmount, feeAmount);

        uint256 bufferAmount = depositAmount * liquidityBuffer / BPS;
        uint256 assetBalance = super._totalBalance();
        if (assetBalance > bufferAmount) {
            uint256 depositAmount = assetBalance - bufferAmount;
            EXTERNAL_VAULT.deposit(depositAmount, address(this));        
        }
    }

    function _beforeWithdraw(
        uint256 assetAmount,
        uint256 feeAmount
    ) internal override {
        // get updated depositAmount
        super._beforeWithdraw(assetAmount, feeAmount);

        uint256 bufferAmount = depositAmount * liquidityBuffer / BPS + assetAmount;
        uint256 assetBalance = super._totalBalance();
        
        if (assetBalance < bufferAmount) {
            uint256 withdrawAmount = bufferAmount - assetBalance;
            EXTERNAL_VAULT.withdraw(withdrawAmount, address(this), address(this));
        }
    }

    function _withdrawFee(uint256 amount) internal override returns (uint256) {
        uint256 amountBefore = ASSET_TOKEN.balanceOf(address(this));
        EXTERNAL_VAULT.withdraw(amount, address(this), address(this));
        return ASSET_TOKEN.balanceOf(address(this)) - amountBefore;
    }

    function _totalBalance() internal override view returns (uint256) {
        return EXTERNAL_VAULT.convertToAssets(EXTERNAL_VAULT.balanceOf(address(this))) + super._totalBalance();
    }

    function setLiquidityBuffer(
        uint256 _liquidityBuffer
    ) external requiresAuth {
        liquidityBuffer = _liquidityBuffer;
        emit LiquidityBufferUpdated(liquidityBuffer, _liquidityBuffer);
    }
}
