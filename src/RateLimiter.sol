// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.25;

import {AuthNoOwner} from "./Dependencies/AuthNoOwner.sol";

contract RateLimiter is AuthNoOwner {
    address public immutable GOVERNANCE =
        0x2A095d44831C26cFB6aCb806A6531AE3CA32DBc1;

    struct LimiterContext {
        uint256 priceLimitBPS;
    }

    mapping(address => LimiterContext) internal limiterContext;

    constructor() {
        _initializeAuthority(GOVERNANCE);
    }

    function canMint(uint256 amount) external returns (bool) {
        return true;
    }
}