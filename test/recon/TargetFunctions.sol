// SPDX-License-Identifier: GPL-2.0
pragma solidity ^0.8.0;

// Chimera deps
import {vm} from "@chimera/Hevm.sol";

// Targets
// NOTE: Always import and apply them in alphabetical order, so much easier to debug!
import {AdminTargets} from "./targets/AdminTargets.sol";
import {ManagersTargets} from "./targets/ManagersTargets.sol";

abstract contract TargetFunctions is
    AdminTargets,
    ManagersTargets
{

    function bsmTester_buyAssetWithEbtc(uint256 _ebtcAmountIn) public {
        bsmTester.buyAssetWithEbtc(_ebtcAmountIn);
    }

    function bsmTester_buyEbtcWithAsset(uint256 _assetAmountIn) public {
        bsmTester.buyEbtcWithAsset(_assetAmountIn);
    }

   
}
