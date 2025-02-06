// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.25;

import "./BSMTestBase.sol";
import {IEbtcBSM} from "../src/Dependencies/IEbtcBSM.sol";

contract BuyAssetWithEbtcTests is BSMTestBase {

    event BoughtAssetWithEbtc(uint256 ebtcAmountIn, uint256 assetAmountOut, uint256 feeAmount);
    event FeeToBuyAssetUpdated(uint256 oldFee, uint256 newFee);

    function testBuyAssetSuccess() public {
        vm.prank(testMinter);
        bsmTester.buyEbtcWithAsset(5e18);

        assertEq(mockAssetToken.balanceOf(testBuyer), 0);
        assertEq(mockEbtcToken.balanceOf(testBuyer), 10e18);

        vm.recordLogs();
        vm.prank(testBuyer);

        assertEq(bsmTester.buyAssetWithEbtc(3e18), 3e18);
        Vm.Log[] memory entries = vm.getRecordedLogs();

        assertEq(entries[0].topics[0], keccak256("Transfer(address,address,uint256)"));
        assertEq(entries[1].topics[0], keccak256("Transfer(address,address,uint256)"));
        assertEq(entries[2].topics[0], keccak256("BoughtAssetWithEbtc(uint256,uint256,uint256)"));
        assertEq(mockAssetToken.balanceOf(testBuyer), 3e18);
        assertEq(mockEbtcToken.balanceOf(testBuyer), 7e18);
    }

    function testBuyAssetFee() public {
        // 1% fee
        vm.prank(techOpsMultisig);
        vm.expectEmit(false, true, false, false);
        emit FeeToBuyAssetUpdated(0, 100);
        bsmTester.setFeeToBuyAsset(100);

        vm.recordLogs();
        vm.prank(testMinter);
        bsmTester.buyEbtcWithAsset(5e18);

        Vm.Log[] memory entries = vm.getRecordedLogs();

        assertEq(entries[0].topics[0], keccak256("Transfer(address,address,uint256)"));
        assertEq(entries[1].topics[0], keccak256("Transfer(address,address,uint256)"));
        assertEq(entries[2].topics[0], keccak256("BoughtEbtcWithAsset(uint256,uint256,uint256)"));
        assertEq(mockAssetToken.balanceOf(testBuyer), 0);
        assertEq(mockEbtcToken.balanceOf(testBuyer), 10e18);

        vm.prank(testBuyer);
        vm.expectEmit(true, false, false, false);
        emit BoughtAssetWithEbtc(1e18, 0, 0);

        assertEq(bsmTester.buyAssetWithEbtc(1e18), 0.99e18);

        assertEq(mockAssetToken.balanceOf(testBuyer), 0.99e18);
        assertEq(mockEbtcToken.balanceOf(testBuyer), 9e18);

        assertEq(assetVault.feeProfit(), 0.01e18);
        assertEq(assetVault.depositAmount(), 4e18);

        vm.prank(techOpsMultisig);
        assetVault.claimProfit();

        assertEq(mockAssetToken.balanceOf(defaultFeeRecipient), 0.01e18);
        assertEq(assetVault.feeProfit(), 0);
    }

    function testBuyAssetFeeAuthorizedUser() public {
        // 1% fee
        vm.prank(techOpsMultisig);
        bsmTester.setFeeToBuyAsset(100);

        vm.prank(testMinter);
        bsmTester.buyEbtcWithAsset(5e18);

        vm.expectEmit();
        emit IEbtcBSM.BoughtAssetWithEbtc(1e18, 1e18, 0);

        vm.prank(testAuthorizedUser);
        assertEq(bsmTester.buyAssetWithEbtcNoFee(1e18), 1e18);
    }

    function testBuyAssetFailAboveDepositAmount() public {
        vm.expectRevert(abi.encodeWithSelector(EbtcBSM.InsufficientAssetTokens.selector, 1e18, assetVault.depositAmount()));
        bsmTester.buyAssetWithEbtc(1e18);
    }
}