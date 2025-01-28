// SPDX-License-Identifier: GPL-2.0
pragma solidity ^0.8.0;

import {Test} from "forge-std/Test.sol";
import {TargetFunctions} from "./TargetFunctions.sol";
import {FoundryAsserts} from "@chimera/FoundryAsserts.sol";
import "forge-std/console2.sol";

// forge test --match-contract CryticToFoundry -vv
contract CryticToFoundry is Test, TargetFunctions, FoundryAsserts {
    function setUp() public override {
        setup();
    }

    // forge test --match-test test_crytic -vvv
    function test_crytic() public {
        // TODO: add failing property tests here for debugging
        bsmTester_buyEbtcWithAsset(100);
        bsmTester_buyAssetWithEbtc(80);

        assetVault_setLiquidityBuffer(1);
        assetVault_withdrawProfit();
    }

    // forge test --match-test test_example_loss -vvv
    function test_example_loss() public {
        externalVault.deposit(1, address(this));
    }

    // forge test --match-test test_property_accounting_is_sound_0 -vvv
    function test_property_accounting_is_sound_0() public {
        bsmTester_buyEbtcWithAsset(1);

        switch_asset(966415373052439958843432959234195543);

        asset_mint(0xc7183455a4C133Ae270771860664b6B7ec320bB1, 900744976127165460329601);

        assetVault_setLiquidityBuffer(0);

        property_accounting_is_sound();
    }

    // forge test --match-test test_doomsday_withdrawProfit_never_reverts_1 -vvv
    function test_doomsday_withdrawProfit_never_reverts_1() public {
        bsmTester_buyEbtcWithAsset(1);

        switch_asset(58038907321649131);

        assetVault_setLiquidityBuffer(0);

        asset_mint(0xc7183455a4C133Ae270771860664b6B7ec320bB1, 126561686389134552);

        doomsday_withdrawProfit_never_reverts();
    }

    // forge test --match-test test_check_set_liquidity_buffer_max_2 -vvv
    function test_check_set_liquidity_buffer_max_2() public {
        bsmTester_buyEbtcWithAsset(1);

        switch_asset(1);

        asset_mint(0xc7183455a4C133Ae270771860664b6B7ec320bB1, 8313324464767570061);

        assetVault_setLiquidityBuffer(0);

        check_set_liquidity_buffer_max();
    }
}
