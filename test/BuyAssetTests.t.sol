// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.25;

import "./BSMTestBase.sol";

contract BuyAssetTests is BSMTestBase {

    function testBuySuccess() public {
        vm.prank(testMinter);
        bsmTester.sellAsset(5e18);

        assertEq(mockAssetToken.balanceOf(testBuyer), 0);
        assertEq(mockEbtcToken.balanceOf(testBuyer), 10e18);
        vm.prank(testBuyer);
        bsmTester.buyAsset(3e18);
        assertEq(mockAssetToken.balanceOf(testBuyer), 3e18);
        assertEq(mockEbtcToken.balanceOf(testBuyer), 7e18);
    }

    function testBuyFee() public {

    }

    function testBuyFailAboveDepositAmount() public {
        vm.expectRevert(abi.encodeWithSelector(EbtcBSM.InsufficientAssetTokens.selector, 1e18, assetVault.depositAmount()));
        bsmTester.buyAsset(1e18);
    }
}