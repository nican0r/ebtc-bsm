// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.25;

import { AuthNoOwner } from "./Dependencies/AuthNoOwner.sol";
import { IAssetVault } from "./Dependencies/IAssetVault.sol";
import { SafeERC20, IERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

contract BaseAssetVault is AuthNoOwner, IAssetVault {
    using SafeERC20 for IERC20;

    IERC20 public immutable ASSET_TOKEN;
    address public immutable BSM;
    address public immutable FEE_RECIPIENT;

    uint256 public depositAmount;

    error CallerNotBSM();

    modifier onlyBSM() {
        if (msg.sender != BSM) {
            revert CallerNotBSM();
        }
        _;
    }

    constructor(address _assetToken, address _bsm, address _governance, address _feeRecipient) {
        ASSET_TOKEN = IERC20(_assetToken);
        BSM = _bsm;
        FEE_RECIPIENT = _feeRecipient;
        _initializeAuthority(_governance);

        // allow the BSM to transfer asset tokens
        ASSET_TOKEN.approve(BSM, type(uint256).max);
    }

    function _totalBalance() internal virtual view returns (uint256) {
        return ASSET_TOKEN.balanceOf(address(this));
    }

    function _afterDeposit(uint256 assetAmount, uint256 feeAmount) internal virtual {
        depositAmount += assetAmount;
    }

    function _beforeWithdraw(uint256 assetAmount, uint256 feeAmount) internal virtual {
        depositAmount -= assetAmount;
    }

    function _withdrawProfit(uint256 profitAmount) internal virtual {
        ASSET_TOKEN.safeTransfer(FEE_RECIPIENT, profitAmount);
    }

    function _beforeMigration() internal virtual {
        // Do nothing
    }

    function totalBalance() external view returns (uint256) {
        return _totalBalance();
    }

    function afterDeposit(uint256 assetAmount, uint256 feeAmount) external onlyBSM {
        _afterDeposit(assetAmount, feeAmount);
    }

    function beforeWithdraw(uint256 assetAmount, uint256 feeAmount) external onlyBSM {
        _beforeWithdraw(assetAmount, feeAmount);
    }

    /// @notice Allows the BSM to migrate liquidity to a new vault
    function migrateTo(address newVault) external onlyBSM {
        /// @dev take profit first (totalBalance == depositAmount after)
        withdrawProfit();

        /// @dev clear depositAmount in old vault (address(this))
        depositAmount = 0;

        /// @dev perform pre-migration tasks (potentially used by derived contracts)
        _beforeMigration();

        /// @dev transfer all liquidity to new vault
        ASSET_TOKEN.safeTransfer(newVault, ASSET_TOKEN.balanceOf(address(this)));
    }

    /// @notice Allows the BSM to set the deposit amount after a vault migration
    function setDepositAmount(uint256 amount) external onlyBSM {
        depositAmount = amount;
    }

    function feeProfit() public view returns (uint256) {
        return _totalBalance() - depositAmount;
    }

    function withdrawProfit() public requiresAuth {
        uint256 profit = feeProfit();
        if (profit > 0) {
            _withdrawProfit(profit);
            // INVARIANT: total balance must be >= deposit amount
            require(_totalBalance() >= depositAmount);
        }
    }
}
