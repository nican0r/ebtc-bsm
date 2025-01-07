// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.25;

import {BaseAssetVault} from "./BaseAssetVault.sol";
import {IERC4626} from "@openzeppelin/contracts/interfaces/IERC4626.sol";
import {SafeERC20, IERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

contract ERC4626AssetVault is BaseAssetVault {
    using SafeERC20 for IERC20;

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
        EXTERNAL_VAULT = IERC4626(_externalVault);

        // 100% buffer = no external lending
        liquidityBuffer = BPS;
    }

    function _afterDeposit(
        uint256 assetAmount,
        uint256 feeAmount
    ) internal override {
        // get updated depositAmount (assetAmount added)
        super._afterDeposit(assetAmount, feeAmount);

        _rebalance(0);
    }

    function _beforeWithdraw(
        uint256 assetAmount,
        uint256 feeAmount
    ) internal override {
        // get updated depositAmount (assetAmount removed)
        super._beforeWithdraw(assetAmount, feeAmount);

        // include assetAmount in liquid buffer for BSM withdraw request
        _rebalance(assetAmount);
    }

    function _rebalance(uint256 additionalAmountRequired) internal override {
        uint256 liquidBufferAmount = depositAmount * liquidityBuffer / BPS + additionalAmountRequired;
        uint256 liquidBalance = super._totalBalance();

        if (liquidBalance > liquidBufferAmount) {
            unchecked {
                uint256 depositAmount = liquidBalance - liquidBufferAmount;
                ASSET_TOKEN.safeIncreaseAllowance(address(EXTERNAL_VAULT), depositAmount);
                EXTERNAL_VAULT.deposit(depositAmount, address(this));     
            }
        } else if (liquidBalance < liquidBufferAmount) {
            unchecked {
                uint256 withdrawAmount = liquidBufferAmount - liquidBalance;
                EXTERNAL_VAULT.withdraw(withdrawAmount, address(this), address(this));
            }
        }
    }

    function _totalBalance() internal override view returns (uint256) {
        return EXTERNAL_VAULT.convertToAssets(EXTERNAL_VAULT.balanceOf(address(this))) + super._totalBalance();
    }

    function setLiquidityBuffer(
        uint256 _liquidityBuffer
    ) external requiresAuth {
        require(_liquidityBuffer <= BPS);

        emit LiquidityBufferUpdated(liquidityBuffer, _liquidityBuffer);
        liquidityBuffer = _liquidityBuffer;

        _rebalance(0);
    }
}
