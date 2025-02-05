// SPDX-License-Identifier: GPL-2.0
pragma solidity ^0.8.0;

import {BaseTargetFunctions} from "@chimera/BaseTargetFunctions.sol";
import {BeforeAfter} from "../BeforeAfter.sol";
import {Properties} from "../Properties.sol";
import {vm} from "@chimera/Hevm.sol";

abstract contract InlinedTests is BaseTargetFunctions, Properties {
    modifier stateless() {
        _;
        revert("stateless");
    }



    function doomsday_claimProfit_never_reverts() public stateless asTechops {
        try assetVault.claimProfit() {
            /// @audit prob missing the loss on withdrwa, which is something that can happen
        } catch {
            t(false, "doomsday_claimProfit_never_reverts");
        }
    }




    // // TODO: Something about fee and migration
    // function doomsday_updateAssetVault(address newVault) public stateless asTechops {
    //     // TODO: Deploy new asset vault that is legitimate and then try migrating
    //     try bsmTester.updateAssetVault(newVault) {

    //     } catch {

    //     }

    // }


    // == BASIC STUFF == //
    function assetVault_afterDeposit(uint256 assetAmount, uint256 feeAmount) public stateless asActor {
        assetVault.afterDeposit(assetAmount, feeAmount);
        t(false, "always fail");
    }

    function assetVault_beforeWithdraw(uint256 assetAmount, uint256 feeAmount) public stateless asActor {
        assetVault.beforeWithdraw(assetAmount, feeAmount);
        t(false, "always fail");
    }
        // TODO: Revert always
    function assetVault_migrateTo(address newVault) public stateless asActor {
        assetVault.migrateTo(newVault);
        t(false, "always fail");
    }

}
