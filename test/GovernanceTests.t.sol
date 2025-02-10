// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.25;

import "./BSMTestBase.sol";

contract GovernanceTests is BSMTestBase {

    function testClaimProfit() public {
        vm.expectRevert("Auth: UNAUTHORIZED");
        vm.prank(testMinter);
        assetVault.claimProfit();

        vm.prank(techOpsMultisig);
        assetVault.claimProfit();
    }

    function testSetBuyAssetFee() public {
        vm.expectRevert("Auth: UNAUTHORIZED");
        vm.prank(testMinter);
        bsmTester.setFeeToBuy(1);

        uint256 maxFee = bsmTester.MAX_FEE();

        vm.expectRevert();
        vm.prank(techOpsMultisig);
        bsmTester.setFeeToBuy(maxFee + 1);
    }

    function testSetBuyEbtcFee() public {
        vm.expectRevert("Auth: UNAUTHORIZED");
        vm.prank(testMinter);
        bsmTester.setFeeToSell(1);

        uint256 maxFee = bsmTester.MAX_FEE();

        vm.expectRevert();
        vm.prank(techOpsMultisig);
        bsmTester.setFeeToSell(maxFee + 1);
    }

    function testSetMintingCap() public {
        vm.expectRevert("Auth: UNAUTHORIZED");
        vm.prank(testMinter);
        bsmTester.setMintingCap(0);
    }

    function testUpdateAssetVault() public {
        vm.expectRevert("Auth: UNAUTHORIZED");
        vm.prank(testMinter);
        bsmTester.updateAssetVault(address(0));
    }

    function testSetMinPrice() public {
        uint256 bps = bsmTester.BPS();

        vm.expectRevert("Auth: UNAUTHORIZED");
        vm.prank(testMinter);
        oracleModule.setMinPrice(bps);

        vm.expectRevert();
        vm.prank(techOpsMultisig);
        oracleModule.setMinPrice(bps + 1);
    }

    function testSetOracleFreshness() public {
        vm.expectRevert("Auth: UNAUTHORIZED");
        vm.prank(testMinter);
        oracleModule.setOracleFreshness(1000);
    }
}