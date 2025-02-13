// SPDX-License-Identifier: GPL-2.0
pragma solidity ^0.8.0;

import {Asserts} from "@chimera/Asserts.sol";
import {OpType, BeforeAfter} from "./BeforeAfter.sol";

abstract contract Properties is BeforeAfter, Asserts {
    function property_accounting_is_sound() public {
        gte(assetVault.totalBalance(), assetVault.depositAmount(), "accounting is sound");
    }

    function property_fees_profit_increases() public {
        if (currentOperation == OpType.CLAIM || currentOperation == OpType.MIGRATE) {
            // claims are all of total profit, there are no partial claims 
            // migrations also claim profit
            eq(assetVault.feeProfit(), 0, "Profit should be 0");
        } else {
            // any other operation should increase the profit or stay the same
            gte(_after.feesProfit, _before.feesProfit, "Profit should only increase");
        }
    }

    function property_assets_are_not_lost() public {
        if(currentOperation != OpType.MIGRATE && currentOperation != OpType.CLAIM && currentOperation != OpType.BUY_ASSET_WITH_EBTC) {
            eq(_before.totalBalance, _after.totalBalance, "Assets should not be lost");
        }
    }
}
