// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.25;

import "./BSMTestBase.sol";

contract SellAssetTests is BSMTestBase {
    function testSellSuccess() public {
        assertEq(mockAssetToken.balanceOf(testMinter), 10e18);
        vm.prank(testMinter);
        bsmTester.sellAsset(1e18);
        assertEq(mockAssetToken.balanceOf(testMinter), 9e18);

        assertEq(mockAssetToken.balanceOf(address(bsmTester.assetVault())), 1e18);
    }

    function testSellFeeSuccess() public {
        // 10% fee
        vm.prank(techOpsMultisig);
        bsmTester.setFeeToSell(1000);

        assertEq(mockAssetToken.balanceOf(testMinter), 10e18);
        vm.prank(testMinter);
        bsmTester.sellAsset(1e18);
        assertEq(mockAssetToken.balanceOf(testMinter), 8.9e18);

        assertEq(mockAssetToken.balanceOf(address(bsmTester.assetVault())), 1e18);
        assertEq(assetVault.feeProfit(), 0.1e18);
        assertEq(assetVault.depositAmount(), 1e18);

        vm.prank(techOpsMultisig);
        assetVault.withdrawProfit();

        assertEq(mockAssetToken.balanceOf(defaultFeeRecipient), 0.1e18);
        assertEq(assetVault.feeProfit(), 0);
    }

    function testSellFailAboveCap() public {

    }

    function testSellFailBadPrice() public {

    }

    function testSellFailRateLimit() public {

    }

    function testSellFailPaused() public {

    }
}
