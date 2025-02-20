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




 // forge test --match-test test_property_accounting_is_sound_123 -vvv 
function test_property_accounting_is_sound_123() public {

    vm.roll(block.number + 17331);
    vm.warp(block.timestamp + 8999);
    property_accounting_of_profit_is_sound();

    vm.warp(block.timestamp + 981709);

    vm.roll(block.number + 160458);

    vm.roll(block.number + 41024);
    vm.warp(block.timestamp + 256);
    escrow_claimProfit();

    vm.warp(block.timestamp + 446957);

    vm.roll(block.number + 58099);

    vm.roll(block.number + 2511);
    vm.warp(block.timestamp + 52987);
    property_assets_are_not_lost();

    vm.warp(block.timestamp + 925987);

    vm.roll(block.number + 34504);

    vm.roll(block.number + 4989);
    vm.warp(block.timestamp + 320374);
    property_fees_profit_increases();

    vm.warp(block.timestamp + 27);

    vm.roll(block.number + 3907);

    vm.roll(block.number + 15368);
    vm.warp(block.timestamp + 322346);
    property_fees_profit_increases();

    vm.warp(block.timestamp + 371523);

    vm.roll(block.number + 30256);

    vm.roll(block.number + 4924);
    vm.warp(block.timestamp + 38059);
    inlined_withdrawProfitTest();

    vm.warp(block.timestamp + 1514840);

    vm.roll(block.number + 193686);

    vm.roll(block.number + 21599);
    vm.warp(block.timestamp + 33605);
    property_fees_profit_increases();

    vm.warp(block.timestamp + 421684);

    vm.roll(block.number + 59649);

    vm.roll(block.number + 5237);
    vm.warp(block.timestamp + 61773);
    inlined_withdrawProfitTest();

    vm.roll(block.number + 39620);
    vm.warp(block.timestamp + 600848);
    switch_asset(16459217019003098912176239135563580415436880724280189511304606026338652986309);

    vm.roll(block.number + 4768);
    vm.warp(block.timestamp + 338931);
    inlined_withdrawProfitTest();

    vm.warp(block.timestamp + 430053);

    vm.roll(block.number + 4997);

    vm.roll(block.number + 1999);
    vm.warp(block.timestamp + 470325);
    property_fees_profit_increases();

    vm.warp(block.timestamp + 566108);

    vm.roll(block.number + 48210);

    vm.roll(block.number + 23404);
    vm.warp(block.timestamp + 360624);
    bsmTester_pause();

    vm.roll(block.number + 45261);
    vm.warp(block.timestamp + 322247);
    property_fees_profit_increases();

    vm.roll(block.number + 30256);
    vm.warp(block.timestamp + 281821);
    property_assets_are_not_lost();

    vm.roll(block.number + 37380);
    vm.warp(block.timestamp + 338931);
    property_accounting_of_profit_is_sound();

    vm.roll(block.number + 4987);
    vm.warp(block.timestamp + 150273);
    bsmTester_unpause();

    vm.warp(block.timestamp + 948545);

    vm.roll(block.number + 98066);

    vm.roll(block.number + 16940);
    vm.warp(block.timestamp + 457356);
    bsmTester_pause();

    vm.roll(block.number + 58057);
    vm.warp(block.timestamp + 40552);
    asset_mint(0x00000000000000000000000000000000FFFFfFFF,8999999999999999999);

    vm.roll(block.number + 51004);
    vm.warp(block.timestamp + 435361);
    bsmTester_setFeeToBuy(25);

    vm.roll(block.number + 39587);
    vm.warp(block.timestamp + 95199);
    asset_approve(0x00000000000000000000000000000002fFffFffD,99);

    vm.warp(block.timestamp + 116073);

    vm.roll(block.number + 53349);

    vm.roll(block.number + 56081);
    vm.warp(block.timestamp + 562352);
    inlined_withdrawProfitTest();

    vm.roll(block.number + 26801);
    vm.warp(block.timestamp + 16378);
    switch_asset(64849816017536245215696517546782339410509907518519348333637167749841795);

    vm.roll(block.number + 63);
    vm.warp(block.timestamp + 209716);
    property_assets_are_not_lost();

    vm.roll(block.number + 2000);
    vm.warp(block.timestamp + 135921);
    asset_mint(0x27cc01A4676C73fe8b6d0933Ac991BfF1D77C4da,317128547571140030630501633644133223054);

    vm.warp(block.timestamp + 785645);

    vm.roll(block.number + 56497);

    vm.roll(block.number + 4961);
    vm.warp(block.timestamp + 407328);
    asset_mint(0xc7183455a4C133Ae270771860664b6B7ec320bB1,8999);

    vm.roll(block.number + 56082);
    vm.warp(block.timestamp + 364822);
    property_accounting_is_sound();

    vm.roll(block.number + 54809);
    vm.warp(block.timestamp + 227175);
    switchActor(28);

    vm.warp(block.timestamp + 296068);

    vm.roll(block.number + 2);

    vm.roll(block.number + 17331);
    vm.warp(block.timestamp + 364822);
    inlined_withdrawProfitTest();

    vm.roll(block.number + 59983);
    vm.warp(block.timestamp + 414579);
    property_assets_are_not_lost();

    vm.roll(block.number + 12076);
    vm.warp(block.timestamp + 227177);
    property_assets_are_not_lost();

    vm.roll(block.number + 15);
    vm.warp(block.timestamp + 326329);
    property_assets_are_not_lost();

    vm.roll(block.number + 255);
    vm.warp(block.timestamp + 322356);
    asset_mint(0x00000000000000000000000000000002fFffFffD,16815530759673272);

    vm.warp(block.timestamp + 83001);

    vm.roll(block.number + 45852);

    vm.roll(block.number + 3905);
    vm.warp(block.timestamp + 511822);
    add_new_asset(19);

    vm.roll(block.number + 58055);
    vm.warp(block.timestamp + 86400);
    asset_mint(0x00000000000000000000000000000001fffffffE,192);

    vm.warp(block.timestamp + 1212330);

    vm.roll(block.number + 256764);

    vm.roll(block.number + 28273);
    vm.warp(block.timestamp + 249334);
    property_accounting_is_sound();

 }

 // forge test --match-test test_property_assets_are_not_lost_123 -vvv 
function test_property_assets_are_not_lost_123() public {

    switch_asset(1);

    asset_mint(0xD6BbDE9174b1CdAa358d2Cf4D57D1a9F7178FBfF,1);

    asset_mint(0xc7183455a4C133Ae270771860664b6B7ec320bB1,1);

    escrow_depositToExternalVault_rekt(1,0);

    property_assets_are_not_lost();

 }

 // forge test --match-test test_inlined_withdrawProfitTest_123 -vvv 
function test_inlined_withdrawProfitTest_123() public {

    switch_asset(1);

    asset_mint(0xD6BbDE9174b1CdAa358d2Cf4D57D1a9F7178FBfF,1);

    asset_mint(0xc7183455a4C133Ae270771860664b6B7ec320bB1,1);

    uint256 amt = escrow.feeProfit();
    console2.log("escrow.EXTERNAL_VAULT().balanceOf(address(escrow));", escrow.EXTERNAL_VAULT().balanceOf(address(escrow)));
    
    uint256 balB4Escrow = escrow.totalBalance();

    // Expected lower
    uint256 shares = escrow.EXTERNAL_VAULT().convertToShares(amt);
    uint256 expected = escrow.EXTERNAL_VAULT().previewRedeem(shares);

    console2.log("amt", amt);
    console2.log("balB4Escrow", balB4Escrow);
    console2.log("shares", shares);
    console2.log("expected", expected);

    uint256 balB4 = (escrow.ASSET_TOKEN()).balanceOf(address(escrow.FEE_RECIPIENT()));

    inlined_withdrawProfitTest();

    uint256 balAfter = (escrow.ASSET_TOKEN()).balanceOf(address(escrow.FEE_RECIPIENT()));

    console2.log("balB4", balB4);
    console2.log("balAfter", balAfter);

 }

 // forge test --match-test test_property_fees_profit_increases_3 -vvv 
function test_property_fees_profit_increases_3() public {

    switch_asset(1);

    asset_mint(0xD6BbDE9174b1CdAa358d2Cf4D57D1a9F7178FBfF,1);

    asset_mint(0xc7183455a4C133Ae270771860664b6B7ec320bB1,1);

    escrow_depositToExternalVault_rekt(1,0);

    property_fees_profit_increases();

 }
}
