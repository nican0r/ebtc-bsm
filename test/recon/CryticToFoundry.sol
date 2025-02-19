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

// forge test --match-test test_doomsday_bsmTester_updateEscrow_always_works_0 -vvv 
function test_doomsday_bsmTester_updateEscrow_always_works_0() public {

    bsmTester_sellAsset(3);

        switch_asset(1);

        asset_mint(0xc7183455a4C133Ae270771860664b6B7ec320bB1,1);

    console2.log("escrow.totalBalance()", escrow.totalBalance());
    console2.log("escrow.totalAssetsDeposited()", escrow.totalAssetsDeposited());

    escrow_depositToExternalVault_rekt(3,0);

    bsmTester_updateEscrow_always_works();

    }

    // forge test --match-test test_property_accounting_is_sound_0 -vvv 
    function test_property_accounting_is_sound_0() public {

    bsmTester_sellAsset(1);

        switch_asset(1);

        asset_mint(0xc7183455a4C133Ae270771860664b6B7ec320bB1,1);

    escrow_depositToExternalVault_rekt(1,0);

        property_accounting_is_sound();

    }

    // forge test --match-test test_inlined_withdrawProfitTest_1 -vvv 
    function test_inlined_withdrawProfitTest_1() public {

    bsmTester_sellAsset(1);

    escrow_depositToExternalVault_rekt(1,0);

    bsmTester_updateEscrow();

        inlined_withdrawProfitTest();

    }

// forge test --match-test test_property_assets_are_not_lost_0 -vvv 
function test_property_assets_are_not_lost_0() public {

    add_new_asset(0);

    bsmTester_updateEscrow();

    switch_asset(245385509657871629879163406604431959412);

    asset_mint(0xD16d567549A2a2a2005aEACf7fB193851603dd70,1);

    bsmTester_updateEscrow();

    bsmTester_updateEscrow();

    property_assets_are_not_lost();

 }

// forge test --match-test test_property_fees_profit_increases_1 -vvv 
function test_property_fees_profit_increases_1() public {

    add_new_asset(0);

    bsmTester_updateEscrow();

    switch_asset(74161108554978309850505936167242305938598684009618505165820837042431577447);

    asset_mint(0xD16d567549A2a2a2005aEACf7fB193851603dd70,26);

    bsmTester_updateEscrow();

    bsmTester_updateEscrow();

    property_fees_profit_increases();

 }

}
