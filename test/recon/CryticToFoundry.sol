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

    assetVault_depositToExternalVault(1,0);

    switch_asset(1);

    asset_mint(0xc7183455a4C133Ae270771860664b6B7ec320bB1,4);

    doomsday_bsmTester_updateAssetVault_always_works();

 }

// forge test --match-test test_inlined_withdrawProfitTest_1 -vvv 
function test_inlined_withdrawProfitTest_1() public {

    bsmTester_buyEbtcWithAsset(1);

    assetVault_depositToExternalVault(1,0);

    switch_asset(1);

    asset_mint(0xc7183455a4C133Ae270771860664b6B7ec320bB1,2);

    inlined_withdrawProfitTest();

 }

// forge test --match-test test_doomsday_withdrawProfit_never_reverts_2 -vvv 
function test_doomsday_withdrawProfit_never_reverts_2() public {

    bsmTester_buyEbtcWithAsset(1);

    switch_asset(1);

    assetVault_depositToExternalVault(1,0);

    asset_mint(0xc7183455a4C133Ae270771860664b6B7ec320bB1,4);

    doomsday_withdrawProfit_never_reverts();

 }
}
