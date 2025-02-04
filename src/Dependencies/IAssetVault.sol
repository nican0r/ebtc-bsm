// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.25;

interface IAssetVault {
    function depositAmount() external view returns (uint256);
    function totalBalance() external view returns (uint256);
    function afterDeposit(uint256 assetAmount, uint256 feeAmount) external;
    function beforeWithdraw(uint256 assetAmount, uint256 feeAmount) external;
    function withdrawProfit() external;
    function migrateTo(address newVault) external;
    function setDepositAmount(uint256 amount) external;
}
