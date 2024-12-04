// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.25;

import { AuthNoOwner } from "./Dependencies/AuthNoOwner.sol";
import { SafeERC20, IERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

interface IAssetVault {
    function depositAmount() external view returns (uint256);
    function totalBalance() external view returns (uint256);
    function afterDeposit(uint256 assetAmount, uint256 feeAmount) external;
    function beforeWithdraw(uint256 assetAmount, uint256 feeAmount) external;
    function withdrawProfit() external;
}

contract BaseAssetVault is AuthNoOwner {
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

    function _withdrawFee(uint256 amount) internal virtual returns (uint256) {
        // do nothing
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

    function withdrawProfit() external requiresAuth {
        uint256 profit = _totalBalance() - depositAmount;
        if (profit > 0) {
            uint256 transferAmount = _withdrawFee(profit);
            ASSET_TOKEN.safeTransfer(FEE_RECIPIENT, transferAmount);
        }
    }
}