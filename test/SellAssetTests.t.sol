// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.25;

import "./BSMTestBase.sol";

contract SellAssetTests is BSMTestBase {
    function testBuyEbtcSuccess() public {
        assertEq(mockAssetToken.balanceOf(testMinter), 10e18);
        assertEq(mockEbtcToken.balanceOf(testMinter), 0);

        uint256 fee = 1e18 * bsmTester.feeToBuyBPS() / (bsmTester.feeToBuyBPS() + bsmTester.BPS());

        vm.expectEmit();
        emit IEbtcBSM.AssetSold(1e18, 1e18, fee);

        vm.prank(testMinter);
        assertEq(bsmTester.sellAsset(1e18, testMinter), 1e18);
        
        assertEq(mockAssetToken.balanceOf(testMinter), 9e18);
        assertEq(mockEbtcToken.balanceOf(testMinter), 1e18);

        assertEq(
            mockAssetToken.balanceOf(address(bsmTester.assetVault())),
            1e18
        );
    }

    function testBuyEbtcFeeSuccess() public {
        // 1% fee
        vm.prank(techOpsMultisig);
        bsmTester.setFeeToSell(100);

        assertEq(mockAssetToken.balanceOf(testMinter), 10e18);

        vm.expectEmit();
        emit IEbtcBSM.AssetSold(1.01e18, 1e18, 0.01e18);

        vm.prank(testMinter);
        assertEq(bsmTester.sellAsset(1.01e18, testMinter), 1e18);

        assertEq(mockAssetToken.balanceOf(testMinter), 8.99e18);

        // asset vault has user deposit (1e18) + fee(0.01e18) = 1.01e18
        assertEq(
            mockAssetToken.balanceOf(address(bsmTester.assetVault())),
            1.01e18
        );
        assertEq(assetVault.feeProfit(), 0.01e18);
        assertEq(assetVault.depositAmount(), 1e18);

        vm.prank(techOpsMultisig);
        assetVault.claimProfit();

        assertEq(mockAssetToken.balanceOf(defaultFeeRecipient), 0.01e18);
        assertEq(assetVault.feeProfit(), 0);
    }

    function testBuyEbtcFeeAuthorizedUser() public {
        vm.prank(techOpsMultisig);
        bsmTester.setFeeToSell(100);

        vm.expectEmit();
        emit IEbtcBSM.AssetSold(1.01e18, 1.01e18, 0);

        vm.prank(testAuthorizedUser);
        assertEq(bsmTester.sellAssetNoFee(1.01e18, testAuthorizedUser), 1.01e18);
    }

    function testBuyEbtcFailAboveCap() public {
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
        bsmTester.sellAsset(amountToMint, testMinter);
    }

    function testBuyEbtcFailBadPrice() public {
        vm.expectRevert("Auth: UNAUTHORIZED");
        vm.prank(testMinter);
        oracleModule.setMinPrice(9000);

        // set min price to 90% (0.9 min price)
        vm.prank(techOpsMultisig);
        oracleModule.setMinPrice(9000);

        // Drop price to 0.89
        mockAssetOracle.setPrice(0.89e18);

        vm.expectRevert(abi.encodeWithSelector(EbtcBSM.BadOracleRate.selector));
        vm.prank(testMinter);
        bsmTester.sellAsset(1e18, testMinter);
    }

    function testBuyEbtcOracleTooOld() public {

        uint256 nowTime = block.timestamp;

        vm.warp(block.timestamp + oracleModule.oracleFreshnessSeconds() + 1);

        vm.expectRevert(abi.encodeWithSelector(OracleModule.StaleOraclePrice.selector, nowTime));
        vm.prank(testMinter);
        bsmTester.sellAsset(1e18, testMinter);
    }

    function testBuyEbtcFailPaused() public {
        vm.expectRevert("Auth: UNAUTHORIZED");
        vm.prank(testMinter);
        bsmTester.pause();

        vm.prank(techOpsMultisig);
        bsmTester.pause();

        vm.expectRevert(abi.encodeWithSelector(Pausable.EnforcedPause.selector));
        vm.prank(testMinter);
        bsmTester.sellAsset(1e18, testMinter);

        vm.expectRevert("Auth: UNAUTHORIZED");
        vm.prank(testMinter);
        bsmTester.unpause();

        vm.prank(techOpsMultisig);
        bsmTester.unpause();

        testBuyEbtcSuccess();
    }
}
