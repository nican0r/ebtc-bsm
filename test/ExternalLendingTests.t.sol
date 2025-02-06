// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.25;

import "@openzeppelin/contracts/mocks/token/ERC4626Mock.sol";
import {ERC4626AssetVault} from "../src/ERC4626AssetVault.sol";
import "./BSMTestBase.sol";
import {console} from "forge-std/console.sol";//TODO remove

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
            assetVault.claimProfit.selector,
            true
        );
        authority.setRoleCapability(
            15,
            address(newAssetVault),
            assetVault.depositToExternalVault.selector,
            true
        );

         authority.setRoleCapability(
            15,
            address(newAssetVault),
            assetVault.redeemFromExternalVault.selector,
            true
        );
        vm.stopPrank();

        mockAssetToken.mint(techOpsMultisig, 10e18);
    }
    
    function testBasicExternalDeposit() public {
        uint256 assetsToDeposit = 1e18;
        vm.expectRevert("Auth: UNAUTHORIZED");
        newAssetVault.depositToExternalVault(assetsToDeposit, 1);
        
        vm.startPrank(techOpsMultisig);
        vm.expectRevert(abi.encodeWithSelector(ERC4626AssetVault.TooFewSharesReceived.selector, 1, 0));
        newAssetVault.depositToExternalVault(assetsToDeposit, 1);

        uint256 beforeExternalVaultBalance = mockAssetToken.balanceOf(address(newExternalVault));
        uint256 beforeBalance = mockAssetToken.balanceOf(techOpsMultisig);
        uint256 shares = newExternalVault.previewDeposit(assetsToDeposit);
        
        mockAssetToken.approve(address(newAssetVault), assetsToDeposit);
        mockAssetToken.transfer(address(newAssetVault), assetsToDeposit);

        newAssetVault.depositToExternalVault(assetsToDeposit, shares);

        uint256 afterExternalVaultBalance = mockAssetToken.balanceOf(address(newExternalVault));
        uint256 afterBalance = mockAssetToken.balanceOf(techOpsMultisig);

        //test post operation variables including allowance accounting + shares check
        vm.stopPrank();

        assertGt(afterExternalVaultBalance, beforeExternalVaultBalance);
        assertGt(beforeBalance, afterBalance);
    }
    
    function testBasicExternalRedeem() public {
        vm.expectRevert("Auth: UNAUTHORIZED");
        newAssetVault.redeemFromExternalVault(1e18, 1);

        vm.startPrank(techOpsMultisig);
        // Redeem before making deposit
        vm.expectRevert();
        newAssetVault.redeemFromExternalVault(1e18, 1);
        vm.stopPrank();
    }

    function testInvalidExternalDeposit() public {
        //invalid shares amount
        //test deposit also decreased the allowance
    }

    function testInvalidExternalRedeem() public {
        //invalid asset amount
    }

    //tests complex scenarios including test claim profit after
}