// SPDX-License-Identifier: GPL-2.0
pragma solidity ^0.8.0;

import {BaseTargetFunctions} from "@chimera/BaseTargetFunctions.sol";
import {BeforeAfter} from "../BeforeAfter.sol";
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
    function assetVault_depositToExternalVault(uint256 assetsToDeposit, uint256 expectedShares) public updateGhosts asTechops {
        assetVault.depositToExternalVault(assetsToDeposit, expectedShares);
    }

    function assetVault_redeemFromExternalVault(uint256 sharesToRedeem, uint256 expectedAssets) public updateGhosts asTechops {
        assetVault.redeemFromExternalVault(sharesToRedeem, expectedAssets);
    }

    function assetVault_setDepositAmount(uint256 amount) public updateGhosts asTechops {
        assetVault.setDepositAmount(amount);
    }

    function assetVault_withdrawProfit() public updateGhosts asTechops {
        assetVault.withdrawProfit();
    }

    function inlined_withdrawProfitTest() public {
        uint256 amt = assetVault.feeProfit();
        uint256 balB4AssetVault = assetVault.totalBalance();
        uint256 balB4 = (assetVault.ASSET_TOKEN()).balanceOf(address(assetVault.FEE_RECIPIENT()));
        assetVault_withdrawProfit();
        uint256 balAfter = (assetVault.ASSET_TOKEN()).balanceOf(address(assetVault.FEE_RECIPIENT()));

        eq(balAfter - balB4, amt, "Amt has been sent to recipient");

        // Total Balance of Vualt should also move correctly
        eq(assetVault.totalBalance(), balB4AssetVault - amt, "Asset Vault balance decreases as intended");

        // Profit should be 0
        eq(assetVault.feeProfit(), 0, "Profit should be 0");
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
    function bsmTester_updateAssetVault() public updateGhosts {
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
