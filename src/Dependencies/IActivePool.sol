// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.25;

interface IActivePool {
    function observe() external returns (uint256);
}
