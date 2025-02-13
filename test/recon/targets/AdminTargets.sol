// SPDX-License-Identifier: GPL-2.0
pragma solidity ^0.8.0;

import {BaseTargetFunctions} from "@chimera/BaseTargetFunctions.sol";
import {OpType, BeforeAfter} from "../BeforeAfter.sol";
import {Properties} from "../Properties.sol";
import {vm} from "@chimera/Hevm.sol";

import "../../../src/ERC4626AssetVault.sol";


contract MockAlwaysTrueAuthority {
    function canCall(address user, address target, bytes4 functionSig) external view returns (bool) {
        return true;
    }
}


abstract contract AdminTargets is BaseTargetFunctions, Properties {

    /// === Asset Vault === ///
    function assetVault_depositToExternalVault_rekt(uint256 assetsToDeposit, uint256 expectedShares) public updateGhosts asTechops {
        require(ALLOWS_REKT, "Allows rekt");
        assetVault.depositToExternalVault(assetsToDeposit, expectedShares);
    }
    /// === Asset Vault === ///
    function assetVault_depositToExternalVault_not_rekt(uint256 assetsToDeposit, uint256 expectedShares) public updateGhosts {
        require(!ALLOWS_REKT, "Must not allow rekt");

        uint256 balanceB4 = assetVault.totalBalance();

        // asTechops
        vm.prank(address(techOpsMultisig));
        assetVault.depositToExternalVault(assetsToDeposit, expectedShares);

        uint256 balanceAfter = assetVault.totalBalance();

        require(balanceAfter >= balanceB4, "Prevent Self Rekt");
    }

    function assetVault_redeemFromExternalVault(uint256 sharesToRedeem, uint256 expectedAssets) public updateGhosts asTechops {
        assetVault.redeemFromExternalVault(sharesToRedeem, expectedAssets);
    }

    // @audit doesn't seem like this would ever successfully be called because the BSM is the only one that can call it
    function assetVault_setDepositAmount(uint256 amount) public updateGhosts asTechops {
        assetVault.setDepositAmount(amount);
    }

    function assetVault_claimProfit() public updateGhostsWithType(OpType.CLAIM) asTechops {
        assetVault.claimProfit();
    }

    function inlined_withdrawProfitTest() public {
        uint256 amt = assetVault.feeProfit();
        uint256 balB4AssetVault = assetVault.totalBalance();

        // Expected lower
        uint256 shares = assetVault.EXTERNAL_VAULT().convertToShares(amt);
        uint256 expected = assetVault.EXTERNAL_VAULT().previewRedeem(shares);

        uint256 balB4 = (assetVault.ASSET_TOKEN()).balanceOf(address(assetVault.FEE_RECIPIENT()));
        assetVault_claimProfit(); // The estimate should be 
        uint256 balAfter = (assetVault.ASSET_TOKEN()).balanceOf(address(assetVault.FEE_RECIPIENT()));

        // The test is a bound as some slippage loss can happen, we take the worst slippage and the exact amt and check against those
        uint256 deltaFees = balAfter - balB4;

        gte(expected, deltaFees, "Recipien got at least expected");
        lte(deltaFees, amt, "Delta fees is at most profit");

        // Total Balance of Vualt should also move correctly
        gte(assetVault.totalBalance(), balB4AssetVault - amt, "Asset Vault balance decreases at most by profit");
        lte(assetVault.totalBalance(), balB4AssetVault - expected, "Asset Vault balance decreases at least by expected");

        // Profit should be 0
        // eq(assetVault.feeProfit(), 0, "Profit should be 0"); /// @audit is it ok for it to be non-zero?
    }

    

    /// === BSM === ///
    function bsmTester_pause() public updateGhosts asTechops {
        bsmTester.pause();
    }

    function bsmTester_setFeeToBuyAsset(uint256 _feeToBuyAssetBPS) public updateGhosts asTechops {
        bsmTester.setFeeToBuyAsset(_feeToBuyAssetBPS);
    }

    function bsmTester_setFeeToBuyEbtc(uint256 _feeToBuyEbtcBPS) public updateGhosts asTechops {
        bsmTester.setFeeToBuyEbtc(_feeToBuyEbtcBPS);
    }

    function bsmTester_setMintingCap(uint256 _mintingCapBPS) public updateGhosts asTechops {
        bsmTester.setMintingCap(_mintingCapBPS);
    }

    function bsmTester_unpause() public updateGhosts asTechops {
        bsmTester.unpause();
    }

    // // Custom handler
    // TODO: Somehow this creates a stack overflow????
    // function bsmTester_updateAssetVault() public updateGhosts {
    //     // Replace
    //     vm.prank(techOpsMultisig);
    //     assetVault = new ERC4626AssetVault(
    //         address(externalVault),
    //         address(mockAssetToken),
    //         address(bsmTester),
    //         address(new MockAlwaysTrueAuthority()),
    //         bsmTester.FEE_RECIPIENT()
    //     );

    //     vm.prank(address(techOpsMultisig));
    //     bsmTester.updateAssetVault(address(assetVault));
    // }

    // Custom handler
    function bsmTester_updateAssetVault() public updateGhostsWithType(OpType.MIGRATE) {
        uint256 feeProfitBefore = assetVault.feeProfit();

        // Replace
        assetVault = new ERC4626AssetVault(
            address(externalVault),
            address(mockAssetToken),
            address(bsmTester),
            address(new MockAlwaysTrueAuthority()),
            bsmTester.FEE_RECIPIENT()
        );

        vm.prank(address(techOpsMultisig));
        bsmTester.updateAssetVault(address(assetVault));

        hasMigrated = true;

        // if the feeProfitBefore > 0, the new vault should have its totalBalance decreased by the feeProfitBefore
        if (feeProfitBefore > 0) {
            eq(assetVault.totalBalance(), _before.totalBalance - feeProfitBefore, "Asset Vault balance decreases by feeProfitBefore");
        } else {
            eq(assetVault.totalBalance(), _before.totalBalance, "Asset Vault balance stays the same in no profit");
        }
    }
    
    // Stateless test
    function doomsday_bsmTester_updateAssetVault_always_works() public {
        try this.bsmTester_updateAssetVault() {

        } catch {
            t(false, "doomsday_bsmTester_updateAssetVault_always_works");
        }

        revert("stateless");
    }
}
