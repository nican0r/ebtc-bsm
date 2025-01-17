// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.25;

import "./BSMTestBase.sol";

contract BuyAssetTests is BSMTestBase {

    function testBuySuccess() public {
        vm.prank(testMinter);
        bsmTester.sellAsset(5e18);

        assertEq(mockAssetToken.balanceOf(testBuyer), 0);
        assertEq(mockEbtcToken.balanceOf(testBuyer), 10e18);

        // TODO: test events

        vm.prank(testBuyer);
        assertEq(bsmTester.buyAsset(3e18), 3e18);

        assertEq(mockAssetToken.balanceOf(testBuyer), 3e18);
        assertEq(mockEbtcToken.balanceOf(testBuyer), 7e18);
    }

    function testBuyFee() public {
        // 1% fee
        vm.prank(techOpsMultisig);
        bsmTester.setFeeToBuy(100);

        vm.prank(testMinter);
        bsmTester.sellAsset(5e18);

        assertEq(mockAssetToken.balanceOf(testBuyer), 0);
        assertEq(mockEbtcToken.balanceOf(testBuyer), 10e18);

        // TODO: test events

        vm.prank(testBuyer);
        assertEq(bsmTester.buyAsset(1e18), 0.99e18);

        assertEq(mockAssetToken.balanceOf(testBuyer), 0.99e18);
        assertEq(mockEbtcToken.balanceOf(testBuyer), 9e18);

        assertEq(assetVault.feeProfit(), 0.01e18);
        assertEq(assetVault.depositAmount(), 4e18);

        vm.prank(techOpsMultisig);
        assetVault.withdrawProfit();

        assertEq(mockAssetToken.balanceOf(defaultFeeRecipient), 0.01e18);
        assertEq(assetVault.feeProfit(), 0);
    }

    function testBuyFeeAuthorizedUser() public {
        
    }

    function testBuyFailAboveDepositAmount() public {
        vm.expectRevert(abi.encodeWithSelector(EbtcBSM.InsufficientAssetTokens.selector, 1e18, assetVault.depositAmount()));
        bsmTester.buyAsset(1e18);
    }
}