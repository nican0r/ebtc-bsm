// SPDX-License-Identifier: GPL-2.0
pragma solidity ^0.8.0;

import {BaseTargetFunctions} from "@chimera/BaseTargetFunctions.sol";
import {BeforeAfter} from "../BeforeAfter.sol";
import {Properties} from "../Properties.sol";
import {vm} from "@chimera/Hevm.sol";

abstract contract InlinedTests is BaseTargetFunctions, Properties {
    function property_accounting_is_sound() public {
        gte(assetVault.totalBalance(), assetVault.depositAmount(), "accounting is sound");
    }

    function doomsday_withdrawProfit_never_reverts() public updateGhosts asTechops {
        try assetVault.withdrawProfit() {
            /// @audit prob missing the loss on withdrwa, which is something that can happen
        } catch {
            t(false, "doomsday_withdrawProfit_never_reverts");
        }
    }

    modifier stateless() {
        _;
        revert("stateless");
    }

    function check_set_liquidity_buffer_max() public stateless asTechops {
        try assetVault.setLiquidityBuffer(10_000) {
            /// @audit prob missing the loss on withdrwa, which is something that can happen
        } catch {
            t(false, "check_set_liquidity_buffer_max");
        }

        // Token balance of assetVault >= depositAmount since they must have withdrawn 100%
        gte(mockAssetToken.balanceOf(address(assetVault)), assetVault.depositAmount(), "All in the assetvault");
    }

    function check_set_liquidity_buffer_zero() public stateless asTechops {
        try assetVault.setLiquidityBuffer(0) {
            /// @audit prob missing the loss on withdrwa, which is something that can happen
        } catch {
            t(false, "check_set_liquidity_buffer_zero");
        }

        // Token balance of assetVault == 0 since we invest 100%
        eq(mockAssetToken.balanceOf(address(assetVault)), 0, "All invested");
    }

    // // TODO: Something about fee and migration
    // function doomsday_updateAssetVault(address newVault) public stateless asTechops {
    //     // TODO: Deploy new asset vault that is legitimate and then try migrating
    //     try bsmTester.updateAssetVault(newVault) {

    //     } catch {

    //     }

    // }
}
