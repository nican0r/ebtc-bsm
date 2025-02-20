// SPDX-License-Identifier: GPL-2.0
pragma solidity ^0.8.0;

import {Test} from "forge-std/Test.sol";
import {FoundryAsserts} from "@chimera/FoundryAsserts.sol";
import "forge-std/console2.sol";

import {TargetFunctions} from "./TargetFunctions.sol";

// forge test --match-contract CryticToFoundry -vv
contract CryticToFoundry is Test, TargetFunctions, FoundryAsserts {
    function setUp() public {
        setup();

        vm.label(address(mockAssetToken), "mockAssetToken");
        vm.label(address(mockEbtcToken), "mockEbtcToken");
        vm.label(address(second_actor), "second_actor");
        vm.label(address(this), "actor");
        vm.label(address(bsmTester), "bsmTester");
        vm.label(address(techOpsMultisig), "techOpsMultisig");
        vm.label(address(escrow), "escrow");
    }

    // forge test --match-test test_crytic -vvv
    function test_crytic() public {
        bsmTester_updateEscrow();
    }

    // forge test --match-test test_property_accounting_is_sound_0 -vvv
    function test_property_accounting_is_sound_0() public {
        bsmTester_sellAsset(1);

        switch_asset(1);

        asset_mint(0xc7183455a4C133Ae270771860664b6B7ec320bB1, 1);

        escrow_depositToExternalVault_rekt(1, 0);

        property_accounting_is_sound();
    }

    // forge test --match-test test_property_assets_are_not_lost_123 -vvv
    function test_property_assets_are_not_lost_123() public {
        switch_asset(1);

        asset_mint(0xD6BbDE9174b1CdAa358d2Cf4D57D1a9F7178FBfF, 1);

        asset_mint(0xc7183455a4C133Ae270771860664b6B7ec320bB1, 1);

        escrow_depositToExternalVault_rekt(1, 0);

        property_assets_are_not_lost();
    }

    // forge test --match-test test_property_fees_profit_increases_3 -vvv
    function test_property_fees_profit_increases_3() public {
        switch_asset(1);

        asset_mint(0xD6BbDE9174b1CdAa358d2Cf4D57D1a9F7178FBfF, 1);

        asset_mint(0xc7183455a4C133Ae270771860664b6B7ec320bB1, 1);

        escrow_depositToExternalVault_rekt(1, 0);

        property_fees_profit_increases();
    }
}
