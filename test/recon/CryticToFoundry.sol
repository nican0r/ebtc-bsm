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

    // forge test --match-test test_doomsday_withdrawProfit_never_reverts_1 -vvv 
function test_doomsday_withdrawProfit_never_reverts_1() public {

    add_new_asset(3);

    bsmTester_addAuthorizedUser(0x0000000000000000000000000000000000000000);

    switch_asset(10000000000000000000);

    asset_mint(0x03A6a84cD762D9707A21605b548aaaB891562aAb,3);

    doomsday_withdrawProfit_never_reverts();

 }

}
