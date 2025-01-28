// SPDX-License-Identifier: GPL-2.0
pragma solidity ^0.8.0;

import {BaseTargetFunctions} from "@chimera/BaseTargetFunctions.sol";
import {BeforeAfter} from "../BeforeAfter.sol";
import {Properties} from "../Properties.sol";
import {vm} from "@chimera/Hevm.sol";

abstract contract AdminTargets is
    BaseTargetFunctions,
    Properties
{
    function assetVault_setLiquidityBuffer(uint256 _liquidityBuffer) public updateGhosts asTechops {
        assetVault.setLiquidityBuffer(_liquidityBuffer);
    }

    function assetVault_withdrawProfit() public updateGhosts asTechops {
        assetVault.withdrawProfit(); // TODO: Inlined test, when you do x then this happens
    } // Real test is: The profit value is either claimed or correct | ERC4626 tester yield not tested = Bad | ERC4626 yield loss not tested either

    function bsmTester_addAuthorizedUser(address _user) public updateGhosts asTechops {
        bsmTester.addAuthorizedUser(_user);
    }


    function bsmTester_pause() public updateGhosts asTechops {
        bsmTester.pause();
    }

    function bsmTester_removeAuthorizedUser(address _user) public updateGhosts asTechops {
        bsmTester.removeAuthorizedUser(_user);
    }

    function bsmTester_setFeeToBuyAsset(uint256 _feeToBuyAssetBPS) public updateGhosts asTechops {
        bsmTester.setFeeToBuyAsset(_feeToBuyAssetBPS);
    }

    function bsmTester_setFeeToBuyEbtc(uint256 _feeToBuyEbtcBPS) public updateGhosts asTechops {
        bsmTester.setFeeToBuyEbtc(_feeToBuyEbtcBPS);
    }

    function bsmTester_setMintingCap(uint256 _mintingCapBPS) public updateGhosts asTechops {
        bsmTester.setMintingCap(_mintingCapBPS);
    }

    function bsmTester_unpause() public updateGhosts asTechops {
        bsmTester.unpause();
    }

    function bsmTester_updateAssetVault(address newVault) public updateGhosts asTechops {
        bsmTester.updateAssetVault(newVault);
    }

}