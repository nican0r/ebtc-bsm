// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.25;

import {MockAssetOracle} from "./MockAssetOracle.sol";

contract MockPriceFeed {
    MockAssetOracle internal oracle;

    constructor(MockAssetOracle _oracle) {
        oracle = _oracle;
    }

    function fetchPrice() external returns (uint256) {
        return uint256(oracle.getPrice());
    }
}