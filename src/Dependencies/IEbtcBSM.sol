// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.25;

interface IEbtcBSM {
    event AssetVaultUpdated(address indexed oldVault, address indexed newVault);
    event MintingCapUpdated(uint256 oldCap, uint256 newCap);
    event FeeToBuyEbtcUpdated(uint256 oldFee, uint256 newFee);
    event FeeToBuyAssetUpdated(uint256 oldFee, uint256 newFee);
    event OracleModuleUpdated(address oldOracle, address newOracle);
    event BoughtEbtcWithAsset(uint256 assetAmountIn, uint256 ebtcAmountOut, uint256 feeAmount);
    event BoughtAssetWithEbtc(uint256 ebtcAmountIn, uint256 assetAmountOut, uint256 feeAmount);

    function buyEbtcWithAsset(uint256 _assetAmountIn) external returns (uint256 _ebtcAmountOut);
    function buyAssetWithEbtc(uint256 _ebtcAmountIn) external returns (uint256 _assetAmountOut);
}