// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.25;

import "./BSMTestBase.sol";

contract SellAssetTests is BSMTestBase {
    function testSellSuccess() public {
        assertEq(mockAssetToken.balanceOf(testMinter), 10e18);
        vm.prank(testMinter);
        bsmTester.sellAsset(1e18);
        assertEq(mockAssetToken.balanceOf(testMinter), 9e18);

        assertEq(
            mockAssetToken.balanceOf(address(bsmTester.assetVault())),
            1e18
        );
    }

    function testSellFeeSuccess() public {
        // 10% fee
        vm.prank(techOpsMultisig);
        bsmTester.setFeeToSell(1000);

        assertEq(mockAssetToken.balanceOf(testMinter), 10e18);
        vm.prank(testMinter);
        bsmTester.sellAsset(1e18);
        assertEq(mockAssetToken.balanceOf(testMinter), 8.9e18);

        assertEq(
            mockAssetToken.balanceOf(address(bsmTester.assetVault())),
            1e18
        );
        assertEq(assetVault.feeProfit(), 0.1e18);
        assertEq(assetVault.depositAmount(), 1e18);

        vm.prank(techOpsMultisig);
        assetVault.withdrawProfit();

        assertEq(mockAssetToken.balanceOf(defaultFeeRecipient), 0.1e18);
        assertEq(assetVault.feeProfit(), 0);
    }

    function testSellFailAboveCap() public {
        uint256 amountToMint = (mockEbtcToken.totalSupply() *
            (bsmTester.mintingCapBPS() + 1)) / bsmTester.BPS();
        uint256 maxMint = (mockEbtcToken.totalSupply() *
            bsmTester.mintingCapBPS()) / bsmTester.BPS();

        vm.prank(testMinter);
        vm.expectRevert(
            abi.encodeWithSelector(
                EbtcBSM.AboveMintingCap.selector,
                amountToMint,
                bsmTester.totalMinted() + amountToMint,
                maxMint
            )
        );
        bsmTester.sellAsset(amountToMint);
    }

    function testSellFailBadPrice() public {}

    function testSellFailRateLimit() public {}

    function testSellFailPaused() public {
        vm.expectRevert("Auth: UNAUTHORIZED");
        vm.prank(testMinter);
        bsmTester.pause();

        vm.prank(techOpsMultisig);
        bsmTester.pause();

        vm.expectRevert(Pausable.EnforcedPause.selector);
        vm.prank(testMinter);
        bsmTester.sellAsset(1e18);

        vm.expectRevert("Auth: UNAUTHORIZED");
        vm.prank(testMinter);
        bsmTester.unpause();

        vm.prank(techOpsMultisig);
        bsmTester.unpause();

        testSellSuccess();
    }
}
