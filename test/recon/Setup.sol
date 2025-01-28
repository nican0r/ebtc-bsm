// SPDX-License-Identifier: GPL-2.0
pragma solidity ^0.8.0;

// Chimera deps
import {BaseSetup} from "@chimera/BaseSetup.sol";
import {vm} from "@chimera/Hevm.sol";

// Managers
import {ActorManager} from "./managers/ActorManager.sol";
import {AssetManager} from "./managers/AssetManager.sol";

import {BSMTestBase} from "../BSMTestBase.sol";

abstract contract Setup is BaseSetup, BSMTestBase, ActorManager, AssetManager {

    function setup() internal virtual override {
        BSMTestBase.setUp();

        // New Actor, beside address(this)
        _addActor(address(0x411c3));
        _newAsset(18); // New 18 decimals token // TODO: ADD ASSETS TO MANAGER

        // TODO: Standardize Mint and allowances to all actors
    }

    // NOTE: LIMITATION You can use these modifier only for one call, so use them for BASIC TARGETS
    modifier asAdmin {
        vm.prank(address(this));
        _;
    }

    modifier asActor {
        vm.prank(_getActor());
        _;
    }
}
