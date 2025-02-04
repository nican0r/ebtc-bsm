// SPDX-License-Identifier: GPL-2.0
pragma solidity ^0.8.0;

import {Asserts} from "@chimera/Asserts.sol";
import {BeforeAfter} from "./BeforeAfter.sol";

abstract contract Properties is BeforeAfter, Asserts {
    function property_accounting_is_sound() public {
        gte(assetVault.totalBalance(), assetVault.depositAmount(), "accounting is sound");
    }

}
