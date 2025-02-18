// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.25;

import "forge-std/Script.sol";
import {IActivePoolObserver} from "../src/Dependencies/IActivePoolObserver.sol";
import {ActivePoolObserver} from "../src/ActivePoolObserver.sol";
import {ITwapWeightedObserver} from "../src/Dependencies/ITwapWeightedObserver.sol";
import {TwapWeightedObserver} from "../src/Dependencies/TwapWeightedObserver.sol";

// Must have the ETH_RPC_URL environment variable set
// forge script scripts/ObserveCompare.s.sol:ObserveCompare --fork
contract ObserveCompare is Script {
    address constant activePoolAddress = 0x6dBDB6D420c110290431E863A1A978AE53F69ebC;
    address constant ebtc = 0x661c70333AA1850CcDBAe82776Bb436A0fCfeEfB;
    IActivePoolObserver activePool = IActivePoolObserver(activePoolAddress);
    ITwapWeightedObserver observer;
    uint256 blocksToCheck = 5;

    function run() external {
        string memory rpcUrl = vm.envString("RPC_URL");
        uint256 forkId = vm.createFork(rpcUrl);
        vm.selectFork(forkId);
        //uint256 deployBlock = 19437199; // ActivePool was deployed at this block
        uint256 endBlock = block.number; 
        uint256 startBlock = endBlock - blocksToCheck;//ActivePool must had been deployed before this
        uint256 counter;

        vm.roll(startBlock - 1);
        observer = new TwapWeightedObserver(0);
        ActivePoolObserver activePoolObserver = new ActivePoolObserver(ITwapWeightedObserver(address(observer)));
        console.log("About to compare...");
        for(uint256 i = startBlock; i <= endBlock; i += 1){//TODO customize + 1
            vm.roll(i);
            
            uint256 resultActivePool = activePool.observe();
            uint256 resultObserver = activePoolObserver.observe();

            if(resultActivePool != resultObserver) {
                console.log("Mismatch at block: ", i);
                console.log("\t Deployed AP value: ", resultActivePool, " != APObserver: ", resultObserver);
                counter++;
            }
        }
        console.log("Finished comparison with a total of ", counter, " different results, out of ", blocksToCheck);
    }

}