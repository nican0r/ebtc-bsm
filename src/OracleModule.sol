// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.25;

import {AuthNoOwner} from "./Dependencies/AuthNoOwner.sol";
import {IPriceFeed} from "./Dependencies/IPriceFeed.sol";
import {AggregatorV3Interface} from "./Dependencies/AggregatorV3Interface.sol";

contract OracleModule is AuthNoOwner {
    uint256 public constant BPS = 10000;

    IPriceFeed public immutable PRICE_FEED;
    AggregatorV3Interface public immutable ASSET_FEED;
    uint256 public immutable ASSET_FEED_PRECISION;

    uint256 public minPriceBPS;
    uint256 public oracleFreshnessSeconds;

    event MinPriceUpdated(uint256 oldMinPrice, uint256 newMinPrice);

    constructor(address _assetFeed, address _ebtcFeed, address _governance) {
        ASSET_FEED = AggregatorV3Interface(_assetFeed);
        ASSET_FEED_PRECISION = 10 ** ASSET_FEED.decimals();
        PRICE_FEED = IPriceFeed(_ebtcFeed);
        _initializeAuthority(_governance);
        minPriceBPS = BPS;
        oracleFreshnessSeconds = 1 days;
    }

    function _getAssetPrice() private view returns (uint256) {
        (, int256 answer, , uint256 updatedAt,) = ASSET_FEED.latestRoundData();
        require(answer > 0);
        require((block.timestamp - updatedAt) <= oracleFreshnessSeconds);
        return (uint256(answer) * 1e18) / ASSET_FEED_PRECISION;
    }

    function _minAcceptablePrice() private returns (uint256) {
        return PRICE_FEED.fetchPrice() * minPriceBPS / BPS;
    }

    function canMint() external returns (bool) {
        return _getAssetPrice() >= _minAcceptablePrice();
    }

    function setMinPriceBPS(uint256 _minPriceBPS) external requiresAuth {
        emit MinPriceUpdated(minPriceBPS, _minPriceBPS);
        minPriceBPS = _minPriceBPS;
    }
}
