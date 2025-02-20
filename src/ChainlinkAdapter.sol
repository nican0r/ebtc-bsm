// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import {AggregatorV3Interface} from "./Dependencies/AggregatorV3Interface.sol";

/**
 * @title ChainlinkAdapter contract
 * @notice Helps convert tBTC to BTC prices by combining two different oracle readings.
 */
contract ChainlinkAdapter is AggregatorV3Interface {
    uint8 public constant override decimals = 18;
    uint256 public constant override version = 1;

    /**
     * @notice Maximum number of resulting and feed decimals
     */
    uint8 public constant MAX_DECIMALS = 18;

    /// @notice PriceFeed always fetches current and previous rounds. It's ok to
    /// hardcode round IDs as long as they are greater than 0.
    uint80 public constant CURRENT_ROUND = 2;
    uint80 public constant PREVIOUS_ROUND = 1;
    int256 internal constant ADAPTER_PRECISION = int256(10 ** decimals);

    /**
     * @notice Price feed for (TBTC / USD) pair
     */
    AggregatorV3Interface public immutable TBTC_USD_CL_FEED;

    /**
     * @notice Price feed for (BTC / USD) pair
     */
    AggregatorV3Interface public immutable BTC_USD_CL_FEED;

    int256 internal immutable TBTC_USD_PRECISION;
    int256 internal immutable BTC_USD_PRECISION;

    /**
     * @notice Contract constructor
     * @param _tBtcUsdClFeed AggregatorV3Interface contract feed for tBTC -> USD
     * @param _btcUsdClFeed AggregatorV3Interface contract feed for BTC -> USD
     */
    constructor(AggregatorV3Interface _tBtcUsdClFeed, AggregatorV3Interface _btcUsdClFeed) {
        TBTC_USD_CL_FEED = AggregatorV3Interface(_tBtcUsdClFeed);
        BTC_USD_CL_FEED = AggregatorV3Interface(_btcUsdClFeed);

        require(TBTC_USD_CL_FEED.decimals() <= MAX_DECIMALS);
        require(BTC_USD_CL_FEED.decimals() <= MAX_DECIMALS);

        TBTC_USD_PRECISION = int256(10 ** TBTC_USD_CL_FEED.decimals());
        BTC_USD_PRECISION = int256(10 ** BTC_USD_CL_FEED.decimals());
    }

    function description() external view returns (string memory) {
        return "tBTC/BTC Chainlink Adapter";
    }

    function _min(uint256 _a, uint256 _b) private pure returns (uint256) {
        return _a < _b ? _a : _b;
    }

    function _convertAnswer(int256 btcUsdPrice, int256 tBtcUsdPrice) private view returns (int256) {
        return
            (btcUsdPrice * TBTC_USD_PRECISION * ADAPTER_PRECISION) /
            (BTC_USD_PRECISION * tBtcUsdPrice);
    }

    function _getRoundData(
        AggregatorV3Interface _feed,
        uint80 _roundId
    ) private view returns (int256 answer, uint256 updatedAt) {
        uint80 feedRoundId;
        if (_roundId == CURRENT_ROUND) {
            (feedRoundId, answer, , updatedAt, ) = _feed.latestRoundData();
        } else {
            (uint80 latestRoundId, , , , ) = _feed.latestRoundData();
            (feedRoundId, answer, , updatedAt, ) = _feed.getRoundData(latestRoundId - 1);
        }
        require(feedRoundId > 0);
        require(answer > 0);
    }

    function _latestRoundData(
        AggregatorV3Interface _feed
    ) private view returns (int256 answer, uint256 updatedAt) {
        uint80 feedRoundId;
        (feedRoundId, answer, , updatedAt, ) = _feed.latestRoundData();
        require(feedRoundId > 0);
        require(answer > 0);
    }

    // getRoundData and latestRoundData should both raise "No data present"
    // if they do not have data to report, instead of returning unset values
    // which could be misinterpreted as actual reported values. //TODO?
    function getRoundData(
        uint80 _roundId
    )
        external
        view
        returns (
            uint80 roundId,
            int256 answer,
            uint256 startedAt,
            uint256 updatedAt,
            uint80 answeredInRound
        )
    {
        require(_roundId == CURRENT_ROUND || _roundId == PREVIOUS_ROUND);

        (int256 tBtcUsdPrice, uint256 tBtcUsdUpdatedAt) = _getRoundData(TBTC_USD_CL_FEED, _roundId);
        (int256 btcUsdPrice, uint256 btcUsdUpdatedAt) = _getRoundData(BTC_USD_CL_FEED, _roundId);

        roundId = _roundId;
        updatedAt = _min(tBtcUsdUpdatedAt, btcUsdUpdatedAt);
        answer = _convertAnswer(btcUsdPrice, tBtcUsdPrice);
    }

    function latestRoundData()
        external
        view
        returns (
            uint80 roundId,
            int256 answer,
            uint256 startedAt,
            uint256 updatedAt,
            uint80 answeredInRound
        )
    {
        (int256 tBtcUsdPrice, uint256 tBtcUsdUpdatedAt) = _latestRoundData(TBTC_USD_CL_FEED);
        (int256 btcUsdPrice, uint256 btcUsdUpdatedAt) = _latestRoundData(BTC_USD_CL_FEED);

        roundId = CURRENT_ROUND;
        updatedAt = _min(tBtcUsdUpdatedAt, btcUsdUpdatedAt);
        answer = _convertAnswer(btcUsdPrice, tBtcUsdPrice);
    }
}