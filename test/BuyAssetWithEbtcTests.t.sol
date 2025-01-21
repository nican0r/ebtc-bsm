// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.25;

import "./BSMTestBase.sol";

contract BuyAssetWithEbtcTests is BSMTestBase {

    function testBuyAssetSuccess() public {
        vm.prank(testMinter);
        bsmTester.buyEbtcWithAsset(5e18);

        assertEq(mockAssetToken.balanceOf(testBuyer), 0);
        assertEq(mockEbtcToken.balanceOf(testBuyer), 10e18);

        // TODO: test events

        vm.prank(testBuyer);
        assertEq(bsmTester.buyAssetWithEbtc(3e18), 3e18);

        assertEq(mockAssetToken.balanceOf(testBuyer), 3e18);
        assertEq(mockEbtcToken.balanceOf(testBuyer), 7e18);
    }

    function testBuyAssetFee() public {
        // 1% fee
        vm.prank(techOpsMultisig);
        bsmTester.setFeeToBuyAsset(100);

        vm.prank(testMinter);
        bsmTester.buyEbtcWithAsset(5e18);

        assertEq(mockAssetToken.balanceOf(testBuyer), 0);
        assertEq(mockEbtcToken.balanceOf(testBuyer), 10e18);

        // TODO: test events

        vm.prank(testBuyer);
        assertEq(bsmTester.buyAssetWithEbtc(1e18), 0.99e18);

        assertEq(mockAssetToken.balanceOf(testBuyer), 0.99e18);
        assertEq(mockEbtcToken.balanceOf(testBuyer), 9e18);

        assertEq(assetVault.feeProfit(), 0.01e18);
        assertEq(assetVault.depositAmount(), 4e18);

        vm.prank(techOpsMultisig);
        assetVault.withdrawProfit();

        assertEq(mockAssetToken.balanceOf(defaultFeeRecipient), 0.01e18);
        assertEq(assetVault.feeProfit(), 0);
    }

    function testBuyAssetFeeAuthorizedUser() public {
        // 1% fee
        vm.prank(techOpsMultisig);
        bsmTester.setFeeToBuyAsset(100);

        vm.prank(testMinter);
        bsmTester.buyEbtcWithAsset(5e18);

        vm.prank(techOpsMultisig);
        bsmTester.addAuthorizedUser(testAuthorizedUser);

        // TODO: test events
        vm.prank(testAuthorizedUser);
        assertEq(bsmTester.buyAssetWithEbtc(1e18), 1e18);
    }

    function testBuyAssetFailAboveDepositAmount() public {
        vm.expectRevert(abi.encodeWithSelector(EbtcBSM.InsufficientAssetTokens.selector, 1e18, assetVault.depositAmount()));
        bsmTester.buyAssetWithEbtc(1e18);
    }
}