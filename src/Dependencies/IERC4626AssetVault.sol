// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.25;

import {IAssetVault} from "./IAssetVault.sol";

interface IERC4626AssetVault is IAssetVault {
    function depositToExternalVault(uint256 assetsToDeposit, uint256 expectedShares) external;
    function redeemFromExternalVault(uint256 sharesToRedeem, uint256 expectedAssets) external;
}
