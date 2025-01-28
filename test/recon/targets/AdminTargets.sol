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

    function bsmTester_addAuthorizedUser(address _user) public updateGhosts asAdmin {
        bsmTester.addAuthorizedUser(_user);
    }


    function bsmTester_pause() public updateGhosts asAdmin {
        bsmTester.pause();
    }

    function bsmTester_removeAuthorizedUser(address _user) public updateGhosts asAdmin {
        bsmTester.removeAuthorizedUser(_user);
    }

    function bsmTester_setFeeToBuyAsset(uint256 _feeToBuyAssetBPS) public updateGhosts asAdmin {
        bsmTester.setFeeToBuyAsset(_feeToBuyAssetBPS);
    }

    function bsmTester_setFeeToBuyEbtc(uint256 _feeToBuyEbtcBPS) public updateGhosts asAdmin {
        bsmTester.setFeeToBuyEbtc(_feeToBuyEbtcBPS);
    }

    function bsmTester_setMintingCap(uint256 _mintingCapBPS) public updateGhosts asAdmin {
        bsmTester.setMintingCap(_mintingCapBPS);
    }

    function bsmTester_unpause() public updateGhosts asAdmin {
        bsmTester.unpause();
    }

    function bsmTester_updateAssetVault(address newVault) public updateGhosts asAdmin {
        bsmTester.updateAssetVault(newVault);
    }

}