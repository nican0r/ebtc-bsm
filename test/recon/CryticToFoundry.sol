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

        vm.label(address(mockAssetToken), "mockAssetToken");
        vm.label(address(mockEbtcToken), "mockEbtcToken");
        vm.label(address(second_actor), "second_actor");
        vm.label(address(this), "actor");
        vm.label(address(bsmTester), "bsmTester");
        vm.label(address(techOpsMultisig), "techOpsMultisig");
        vm.label(address(assetVault), "assetVault");
    }

    // forge test --match-test test_crytic -vvv
    function test_crytic() public {
        bsmTester_updateAssetVault();
    } 

// forge test --match-test test_doomsday_bsmTester_updateAssetVault_always_works_0 -vvv 
function test_doomsday_bsmTester_updateAssetVault_always_works_0() public {

    bsmTester_buyEbtcWithAsset(1);

    assetVault_depositToExternalVault(14133852489483710848460564300939146641398268,0);

    switch_asset(1);

    asset_mint(0xc7183455a4C133Ae270771860664b6B7ec320bB1,253358798256961833699513984708403);

    doomsday_bsmTester_updateAssetVault_always_works();

 }

// forge test --match-test test_doomsday_withdrawProfit_never_reverts_1 -vvv 
function test_doomsday_withdrawProfit_never_reverts_1() public {

    bsmTester_buyEbtcWithAsset(1);

    switch_asset(3906695303381688533779047582894992525159744194282508460421711419);

    assetVault_depositToExternalVault(889219888492666877483136380314023906328196849921462,0);

    asset_mint(0xc7183455a4C133Ae270771860664b6B7ec320bB1,18000375652284498764386457876);

    doomsday_withdrawProfit_never_reverts();

 }
}
