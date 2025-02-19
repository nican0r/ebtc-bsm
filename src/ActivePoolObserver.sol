// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.25;

import {ITwapWeightedObserver} from "./Dependencies/ITwapWeightedObserver.sol";

contract ActivePoolObserver {
    /// @notice set this to the ActivePool
    ITwapWeightedObserver public immutable OBSERVER;

    constructor(ITwapWeightedObserver _observer) {
        OBSERVER = _observer;
    }

    /// @dev Usual Accumulator Math, (newAcc - acc0) / (now - t0)
    function _calcUpdatedAvg(ITwapWeightedObserver.PackedData memory data) internal view returns (uint128, uint128) {
        uint128 latestAcc = OBSERVER.getLatestAccumulator();
        uint128 avgValue = (latestAcc - data.observerCumuVal) /
            (uint64(block.timestamp) - data.lastObserved);
        return (avgValue, latestAcc);
    }

    function _checkUpdatePeriod(ITwapWeightedObserver.PackedData memory data, uint256 period) internal view returns (bool) {
        return block.timestamp >= (data.lastObserved + period);
    }

    function observe() external view returns (uint256) {
        ITwapWeightedObserver.PackedData memory data = OBSERVER.getData();

        // Here, we need to apply the new accumulator to skew the price in some way
        // The weight of the skew should be proportional to the time passed
        uint256 futureWeight = block.timestamp - data.lastObserved;

        if (futureWeight == 0) {
            return data.lastObservedAverage;
        }

        // A reference period is 7 days
        // For each second passed after update
        // Let's virtually sync TWAP
        // With a weight, that is higher, the more time has passed
        (uint128 virtualAvgValue, uint128 obsAcc) = _calcUpdatedAvg(data);

        uint256 period = OBSERVER.PERIOD();

        if (_checkUpdatePeriod(data, period)) {
            // Return virtual
            return virtualAvgValue;
        }

        uint256 weightedAvg = uint256(data.lastObservedAverage) *
            (uint256(period) - uint256(futureWeight));
        uint256 weightedVirtual = uint256(virtualAvgValue) * (uint256(futureWeight));

        uint256 weightedMean = (weightedAvg + weightedVirtual) / period;

        return weightedMean;
    }
}
