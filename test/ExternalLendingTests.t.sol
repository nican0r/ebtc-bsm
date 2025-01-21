// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.25;

import "@openzeppelin/contracts/mocks/token/ERC4626Mock.sol";
import {ERC4626AssetVault} from "../src/ERC4626AssetVault.sol";
import "./BSMTestBase.sol";

contract ExternalLendingTests is BSMTestBase {
    ERC4626Mock internal newExternalVault;
    ERC4626AssetVault internal newAssetVault;

    function setUp() public virtual override {
        super.setUp();

        newExternalVault = new ERC4626Mock(address(mockAssetToken));
        newAssetVault = new ERC4626AssetVault(
            address(newExternalVault),
            address(bsmTester.ASSET_TOKEN()),
            address(bsmTester),
            address(bsmTester.authority()),
            address(bsmTester.FEE_RECIPIENT())
        );

        vm.startPrank(defaultGovernance);
        authority.setRoleCapability(
            15,
            address(newAssetVault),
            assetVault.withdrawProfit.selector,
            true
        );
        authority.setRoleCapability(
            15,
            address(newAssetVault),
            assetVault.setLiquidityBuffer.selector,
            true
        );
        vm.stopPrank();
    }

    function testRebalance() public {

    }

    function testMigrateAssetVault_100PercOld_100PercNew() public {
        // 1% fee
        vm.prank(techOpsMultisig);
        bsmTester.setFeeToBuyEbtc(100);

        // increase minting cap
        mockEbtcToken.mint(address(testMinter), 1000e18);
        mockAssetToken.mint(address(testMinter), 1e18);

        vm.prank(testMinter);
        bsmTester.buyEbtcWithAsset(10.1e18);

        // simulate yield
        mockAssetToken.mint(address(externalVault), 0.01e18);

        uint256 oldProfit = assetVault.feeProfit();
        uint256 oldDepositAmount = assetVault.depositAmount();

        vm.prank(techOpsMultisig);
        bsmTester.updateAssetVault(address(newAssetVault));

        // profit stays in the old vault
        assertEq(assetVault.feeProfit(), oldProfit);
        // depositAmount is migrated to the new vault
        assertEq(assetVault.depositAmount(), 0);

        // new vault has old deposit amount
        assertEq(newAssetVault.depositAmount(), oldDepositAmount);
        // new vault has no profit yet
        assertEq(newAssetVault.feeProfit(), 0);
        // 100% of deposit goes into external vault
        assertEq(mockAssetToken.balanceOf(address(newAssetVault)), oldDepositAmount);

        // old profit can still be claimed from the old vault
        vm.prank(techOpsMultisig);
        assetVault.withdrawProfit();

        assertEq(mockAssetToken.balanceOf(bsmTester.FEE_RECIPIENT()), oldProfit);
    }

    function testMigrateAssetVault_0PercOld_100PercNew() public {
        // 0% liquidity buffer
        vm.prank(techOpsMultisig);
        assetVault.setLiquidityBuffer(0);
    
        // 1% fee
        vm.prank(techOpsMultisig);
        bsmTester.setFeeToBuyEbtc(100);

        // increase minting cap
        mockEbtcToken.mint(address(testMinter), 1000e18);
        mockAssetToken.mint(address(testMinter), 1e18);

        vm.prank(testMinter);
        bsmTester.buyEbtcWithAsset(10.1e18);

        // simulate yield
        mockAssetToken.mint(address(externalVault), 0.01e18);

        uint256 oldProfit = assetVault.feeProfit();
        uint256 oldDepositAmount = assetVault.depositAmount();

        vm.prank(techOpsMultisig);
        bsmTester.updateAssetVault(address(newAssetVault));

        // profit stays in the old vault
        assertEq(assetVault.feeProfit(), oldProfit);
        // depositAmount is migrated to the new vault
        assertEq(assetVault.depositAmount(), 0);

        // new vault has old deposit amount
        assertEq(newAssetVault.depositAmount(), oldDepositAmount);
        // new vault has no profit yet
        assertEq(newAssetVault.feeProfit(), 0);
        // 0% of deposit goes into external vault
        assertEq(mockAssetToken.balanceOf(address(newAssetVault)), oldDepositAmount);

        // old profit can still be claimed from the old vault
        vm.prank(techOpsMultisig);
        assetVault.withdrawProfit();

        assertEq(mockAssetToken.balanceOf(bsmTester.FEE_RECIPIENT()), oldProfit);
    }

    function testMigrateAssetVault_0PercOld_0PercNew() public {
        // 0% liquidity buffer
        vm.prank(techOpsMultisig);
        assetVault.setLiquidityBuffer(0);

        // 0% liquidity buffer
        vm.prank(techOpsMultisig);
        newAssetVault.setLiquidityBuffer(0);

        // 1% fee
        vm.prank(techOpsMultisig);
        bsmTester.setFeeToBuyEbtc(100);

        // increase minting cap
        mockEbtcToken.mint(address(testMinter), 1000e18);
        mockAssetToken.mint(address(testMinter), 1e18);

        vm.prank(testMinter);
        bsmTester.buyEbtcWithAsset(10.1e18);

        // simulate yield
        mockAssetToken.mint(address(externalVault), 0.01e18);

        uint256 oldProfit = assetVault.feeProfit();
        uint256 oldDepositAmount = assetVault.depositAmount();

        vm.prank(techOpsMultisig);
        bsmTester.updateAssetVault(address(newAssetVault));

        // profit stays in the old vault
        assertEq(assetVault.feeProfit(), oldProfit);
        // depositAmount is migrated to the new vault
        assertEq(assetVault.depositAmount(), 0);

        // new vault has old deposit amount
        assertEq(newAssetVault.depositAmount(), oldDepositAmount);
        // new vault has no profit yet
        assertEq(newAssetVault.feeProfit(), 0);
        // 100% of deposit goes into external vault
        assertEq(mockAssetToken.balanceOf(address(newAssetVault)), 0);
        assertEq(newExternalVault.balanceOf(address(newAssetVault)), oldDepositAmount);

        // old profit can still be claimed from the old vault
        vm.prank(techOpsMultisig);
        assetVault.withdrawProfit();

        assertEq(mockAssetToken.balanceOf(bsmTester.FEE_RECIPIENT()), oldProfit);
    }

    function testMigrateAssetVault_50PercOld_50PercNew() public {
        // 50% liquidity buffer
        vm.prank(techOpsMultisig);
        assetVault.setLiquidityBuffer(5000);

        // 50% liquidity buffer
        vm.prank(techOpsMultisig);
        newAssetVault.setLiquidityBuffer(5000);

        // 1% fee
        vm.prank(techOpsMultisig);
        bsmTester.setFeeToBuyEbtc(100);

        // increase minting cap
        mockEbtcToken.mint(address(testMinter), 1000e18);
        mockAssetToken.mint(address(testMinter), 1e18);

        vm.prank(testMinter);
        bsmTester.buyEbtcWithAsset(10.1e18);

        // simulate yield
        mockAssetToken.mint(address(externalVault), 0.01e18);

        uint256 oldProfit = assetVault.feeProfit();
        uint256 oldDepositAmount = assetVault.depositAmount();

        vm.prank(techOpsMultisig);
        bsmTester.updateAssetVault(address(newAssetVault));

        // profit stays in the old vault
        assertEq(assetVault.feeProfit(), oldProfit);
        // depositAmount is migrated to the new vault
        assertEq(assetVault.depositAmount(), 0);

        // new vault has old deposit amount
        assertEq(newAssetVault.depositAmount(), oldDepositAmount);
        // new vault has no profit yet
        assertEq(newAssetVault.feeProfit(), 0);
        // 50% of deposit goes into external vault
        assertEq(mockAssetToken.balanceOf(address(newAssetVault)), oldDepositAmount * 50 / 100);
        assertEq(newExternalVault.balanceOf(address(newAssetVault)), oldDepositAmount * 50 / 100);

        // old profit can still be claimed from the old vault
        vm.prank(techOpsMultisig);
        assetVault.withdrawProfit();

        assertEq(mockAssetToken.balanceOf(bsmTester.FEE_RECIPIENT()), oldProfit);
    }
}