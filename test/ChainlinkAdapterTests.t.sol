// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.25;

import "forge-std/Test.sol";
import {ChainlinkAdapter} from "../src/ChainlinkAdapter.sol";


contract ChainlinkAdapterTests is Test {

    MockAggregator internal usdBtcAggregator;
    MockAggregator internal ethUsdAggregator;
    ChainlinkAdapter internal chainlinkAdapter;

    function setUp() public {
        usdBtcAggregator = new MockAggregator(8);
        ethUsdAggregator = new MockAggregator(8);
        chainlinkAdapter = new ChainlinkAdapter(usdBtcAggregator, ethUsdAggregator);
    }

    function testGetLatestRound() public {
        usdBtcAggregator.setLatestRoundId(110680464442257320247);
        usdBtcAggregator.setPrevRoundId(110680464442257320246);
        usdBtcAggregator.setPrice(3983705362408);
        usdBtcAggregator.setUpdateTime(1706208946);

        ethUsdAggregator.setLatestRoundId(110680464442257320665);
        ethUsdAggregator.setPrevRoundId(110680464442257320664);
        ethUsdAggregator.setPrice(221026137517);
        ethUsdAggregator.setUpdateTime(1706208947);

        (
            uint80 roundId,
            int256 answer,
            uint256 startedAt,
            uint256 updatedAt,
            uint80 answeredInRound
        ) = chainlinkAdapter.latestRoundData();

        assertEq(answer, 55482551396170026);
        assertEq(updatedAt, 1706208946);
    }

    //test that the conversion is correct using known numbers
    // test that reading the prices work by rolling to a block in mainnet that actually we know the prices and confirm the conversion works

}
