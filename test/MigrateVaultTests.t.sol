// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.25;

import "./BSMTestBase.sol";
import "../src/BaseEscrow.sol";
import "../src/ERC4626Escrow.sol";
import "@openzeppelin/contracts/mocks/token/ERC4626Mock.sol";

contract MigrateAssetVaultTest is BSMTestBase {
    ERC4626Escrow internal newEscrow;
    ERC4626Mock internal newExternalVault;
    
    function setUp() public virtual override {
        super.setUp();

        newExternalVault = new ERC4626Mock(address(mockAssetToken));
        newEscrow = new ERC4626Escrow(
            address(newExternalVault),
            address(bsmTester.ASSET_TOKEN()),
            address(bsmTester),
            address(bsmTester.authority()),
            address(escrow.FEE_RECIPIENT())
        );
    }

    function testBasicScenario() public {
        vm.expectEmit();
        emit IEbtcBSM.EscrowUpdated(address(bsmTester.escrow()), address(newEscrow));
        
        vm.prank(techOpsMultisig);
        bsmTester.updateEscrow(address(newEscrow));

        assertEq(address(bsmTester.escrow()), address(newEscrow));  
    }

    function testMigrationAssets() public {
        uint256 totalAssets = 5e18;
        uint256 assetAmount = 3e18;
        uint256 endAssetAmount = totalAssets - assetAmount;
        vm.prank(testMinter);
        bsmTester.sellAsset(5e18, testMinter);

        vm.prank(testBuyer);
        assertEq(bsmTester.buyAsset(assetAmount, testBuyer), assetAmount);

        uint256 prevTotalDeposit = escrow.totalAssetsDeposited();
        uint256 prevBalance = escrow.ASSET_TOKEN().balanceOf(address(escrow));
        assertEq(prevTotalDeposit, endAssetAmount);

        vm.prank(techOpsMultisig);
        bsmTester.updateEscrow(address(newEscrow));

        uint256 crtTotalDeposit = escrow.totalAssetsDeposited();
        uint256 crtBalance = escrow.ASSET_TOKEN().balanceOf(address(escrow));
        assertEq(crtTotalDeposit, 0);
        assertEq(crtBalance, 0);

        uint256 totalDeposit = newEscrow.totalAssetsDeposited();
        uint256 balance = newEscrow.ASSET_TOKEN().balanceOf(address(newEscrow));
        assertEq(totalDeposit, endAssetAmount);
        assertEq(balance, endAssetAmount);
    }

    function testMigrationWithProfit() public {
        // increase profit
        // test _claimProfit
    }

    function testRevertScenarios() public {
        vm.expectRevert(abi.encodeWithSelector(BaseEscrow.CallerNotBSM.selector));
        escrow.onMigrateTarget(1e18);
        vm.expectRevert(abi.encodeWithSelector(BaseEscrow.CallerNotBSM.selector));
        escrow.onMigrateSource(address(newEscrow));
        
        vm.expectRevert("Auth: UNAUTHORIZED");
        bsmTester.updateEscrow(address(newEscrow));

        vm.prank(techOpsMultisig);
        vm.expectRevert();
        bsmTester.updateEscrow(address(0));

        //TODO test require(_totalBalance() >= totalAssetsDeposited); from claimProfit
    }

    function testMigrationWithExtLending() public {

    }
}