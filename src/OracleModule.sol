// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.25;

import {AuthNoOwner} from "./Dependencies/AuthNoOwner.sol";

contract OracleModule is AuthNoOwner {
    address public immutable GOVERNANCE =
        0x2A095d44831C26cFB6aCb806A6531AE3CA32DBc1;

    constructor() {
        _initializeAuthority(GOVERNANCE);
    }

    function canMint() external returns (bool) {
        return true;
    }
}
