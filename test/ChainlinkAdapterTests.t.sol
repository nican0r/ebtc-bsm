// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.25;

import "forge-std/Test.sol";
import {ChainlinkAdapter} from "../src/ChainlinkAdapter.sol";
import {MockAssetOracle} from "./mocks/MockAssetOracle.sol";


contract ChainlinkAdapterTests is Test {

    MockAssetOracle internal usdtBtcAggregator;//TODO I think this is not right
    MockAssetOracle internal btcUsdAggregator;
    ChainlinkAdapter internal chainlinkAdapter;

    function setUp() public {
        usdtBtcAggregator = new MockAssetOracle(8);
        btcUsdAggregator = new MockAssetOracle(8);
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
    function testConversionWorks() public {
        // tBTC > BTC
        // tBTC
        usdtBtcAggregator.setLatestRoundId(1);
        usdtBtcAggregator.setPrevRoundId(110680464442257320246);
        usdtBtcAggregator.setPrice(2);
        usdtBtcAggregator.setUpdateTime(1706208946);
        // BTC
        btcUsdAggregator.setLatestRoundId(1);
        btcUsdAggregator.setPrevRoundId(110680464442257320664);
        btcUsdAggregator.setPrice(1);// half the price
        btcUsdAggregator.setUpdateTime(1706208947);

        (
            ,
            int256 answer,,,
        ) = chainlinkAdapter.latestRoundData();

        assertEq(answer, 500000000000000000);// (tBTC/BTC) * ADAPTER_PRECISION

        // tBTC < BTC
        // tBTC
        usdtBtcAggregator.setLatestRoundId(1);
        usdtBtcAggregator.setPrevRoundId(110680464442257320246);
        usdtBtcAggregator.setPrice(1);
        usdtBtcAggregator.setUpdateTime(1706208946);
        // BTC
        btcUsdAggregator.setLatestRoundId(1);
        btcUsdAggregator.setPrevRoundId(110680464442257320664);
        btcUsdAggregator.setPrice(2);// double the price
        btcUsdAggregator.setUpdateTime(1706208947);

        (
            ,
            answer,,,
        ) = chainlinkAdapter.latestRoundData();

        assertEq(answer, 2000000000000000000);// (tBTC/BTC) * ADAPTER_PRECISION
    }

    function testWithReaData() public {
        // test that reading the prices work by rolling to a block in mainnet that actually we know the prices and confirm the conversion works
    }
}
