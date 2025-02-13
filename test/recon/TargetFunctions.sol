// SPDX-License-Identifier: GPL-2.0
pragma solidity ^0.8.0;

// Chimera deps
import {vm} from "@chimera/Hevm.sol";

// Targets
// NOTE: Always import and apply them in alphabetical order, so much easier to debug!
import {AdminTargets} from "./targets/AdminTargets.sol";
import {InlinedTests} from "./targets/InlinedTests.sol";
import {ManagersTargets} from "./targets/ManagersTargets.sol";

abstract contract TargetFunctions is AdminTargets, InlinedTests, ManagersTargets {
    function bsmTester_buyAsset(uint256 _ebtcAmountIn) public updateGhosts asActor {
        bsmTester.buyAsset(_ebtcAmountIn, _getActor());
    }

    function bsmTester_sellAsset(uint256 _assetAmountIn) public updateGhosts asActor {
        bsmTester.sellAsset(_assetAmountIn, _getActor());
    }
}
