// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.25;

import "forge-std/Test.sol";
import {ChainlinkAdapter} from "../src/ChainlinkAdapter.sol";


contract ChainlinkAdapterTests is Test {

    MockAggregator internal usdtBtcAggregator;//TODO I think this is not right
    MockAggregator internal btcUsdAggregator;
    ChainlinkAdapter internal chainlinkAdapter;

    function setUp() public {
        usdtBtcAggregator = new MockAggregator(8);
        btcUsdAggregator = new MockAggregator(8);
        chainlinkAdapter = new ChainlinkAdapter(usdtBtcAggregator, btcUsdAggregator);
    }

    function testGetLatestRound() public {
        usdtBtcAggregator.setLatestRoundId(110680464442257320247);
        usdtBtcAggregator.setPrevRoundId(110680464442257320246);
        usdtBtcAggregator.setPrice(3983705362408);
        usdtBtcAggregator.setUpdateTime(1706208946);

        btcUsdAggregator.setLatestRoundId(110680464442257320665);
        btcUsdAggregator.setPrevRoundId(110680464442257320664);
        btcUsdAggregator.setPrice(221026137517);
        btcUsdAggregator.setUpdateTime(1706208947);

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
