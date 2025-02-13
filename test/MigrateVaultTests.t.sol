// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.25;

import "./BSMTestBase.sol";
import "../src/BaseEscrow.sol";

contract MigrateAssetVaultTest is BSMTestBase {
    address newEscrow = address(1);//TODO: actually have a valid new escrow in a setup function

    function testBasicScenario() public {
        
        
        address originalEscrow = address(bsmTester.escrow());
        vm.expectEmit();
        emit IEbtcBSM.EscrowUpdated(originalEscrow, newEscrow);
        
        vm.prank(techOpsMultisig);
        bsmTester.updateEscrow(newEscrow);

        assertEq(originalEscrow, newEscrow);  
        // test _beforeMigration
        
    }

    function testMigrationAssets() public {
        // increase totalAssetsDeposited
        // test totalAssetsDeposited
        // test ASSET_TOKEN.safeTransfer(_newEscrow, ASSET_TOKEN.balanceOf(address(this)));
    }

    function testMigrationWithProfit() public {
        // increase profit
        // test _claimProfit
    }

    function testRevertScenarios() public {
        vm.expectRevert(abi.encodeWithSelector(BaseEscrow.CallerNotBSM.selector));
        escrow.onMigrateSource(newEscrow);
        
        vm.expectRevert("Auth: UNAUTHORIZED");
        bsmTester.updateEscrow(newEscrow);

        vm.prank(techOpsMultisig);
        vm.expectRevert();
        bsmTester.updateEscrow(address(0));
    }

    function testMigrationWithExtLending() public {

    }
}