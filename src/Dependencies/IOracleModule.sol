// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.25;

interface IOracleModule {
    function canMint() external returns (bool);
}
