// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.25;

import "@openzeppelin/contracts/mocks/token/ERC20Mock.sol";

contract MockActivePool {
    ERC20Mock internal mockEbtcToken;

    constructor(ERC20Mock _mockEbtcToken) {
        mockEbtcToken = _mockEbtcToken;
    }

    function observe() external returns (uint256) {
        return mockEbtcToken.totalSupply();
    }
}