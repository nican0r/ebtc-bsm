// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.25;

import "./BSMTestBase.sol";

contract MigrateAssetVaultTest is BSMTestBase {
    function testBasicScenario() public {
        escrow.onMigrateSource(address(1));
    }
}