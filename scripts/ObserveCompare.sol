// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.25;

import "forge-std/Script.sol";
import {ActivePoolObserver} from "../src/ActivePoolObserver.sol";

// Must have the ETH_RPC_URL environment variable set
contract ObserveCompare is Script {
    address constant activePoolAddress = 0x6dBDB6D420c110290431E863A1A978AE53F69ebC;

    function run() external {
        vm.createFork("mainnet"); // Create a fork of mainnet

        //uint256 startBlock = 19437199; // ActivePool was deployed at this block
        uint256 endBlock = block.number; 
        uint256 startBlock = endBlock - 49000;

        for(uint256 i = startBlock; i <= endBlock; i += 1){//TODO customize + 1
            vm.roll(i);

            bytes memory resultActivePool = activePool.observe();
            bytes memory resultObserver = activePoolObserver.observe();

            if(keccak256(resultActivePool) != keccak256(resultObserver)) {
                console.log("Mismatch at: ", i);
            }
        }
    }

}