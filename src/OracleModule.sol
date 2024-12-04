// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.25;

import {AuthNoOwner} from "./Dependencies/AuthNoOwner.sol";
import {IPriceFeed} from "./Dependencies/IPriceFeed.sol";
import {AggregatorV3Interface} from "./Dependencies/AggregatorV3Interface.sol";

contract OracleModule is AuthNoOwner {
    IPriceFeed public constant PRICE_FEED =
        IPriceFeed(0xa9a65B1B1dDa8376527E89985b221B6bfCA1Dc9a);
    address public constant GOVERNANCE =
        0x2A095d44831C26cFB6aCb806A6531AE3CA32DBc1;
    uint256 public constant BPS = 10000;

    AggregatorV3Interface public immutable ASSET_FEED;
    uint256 public immutable ASSET_FEED_PRECISION;

    uint256 public minPriceBPS;

    event MinPriceUpdated(uint256 oldMinPrice, uint256 newMinPrice);

    constructor(address _assetFeed) {
        ASSET_FEED = AggregatorV3Interface(_assetFeed);
        ASSET_FEED_PRECISION = 10 ** ASSET_FEED.decimals();
        _initializeAuthority(GOVERNANCE);
    }

    function _getAssetPrice() private view returns (uint256) {
        (, int256 answer, , uint256 updatedAt,) = ASSET_FEED.latestRoundData();
        require(answer > 0);
        // TODO: check updatedAt
        return (uint256(answer) * 1e18) / ASSET_FEED_PRECISION;
    }

    function _minAcceptablePrice() private returns (uint256) {
        return PRICE_FEED.fetchPrice() * minPriceBPS / BPS;
    }

    function canMint() external returns (bool) {
        uint256 assetPrice = _getAssetPrice();

        return assetPrice >= _minAcceptablePrice();
    }

    function setMinPriceBPS(uint256 _minPriceBPS) external requiresAuth {
        emit MinPriceUpdated(minPriceBPS, _minPriceBPS);
        minPriceBPS = _minPriceBPS;
    }
}
