// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "forge-std/Script.sol";

import {IPoolManager} from "@uniswap/v4-core/src/interfaces/IPoolManager.sol";
import {AutoRangeTriPillar} from "../src/hooks/AutoRangeTriPillar.sol";
import {TriPillarExecutor} from "../src/periphery/TriPillarExecutor.sol";

contract DeployTripillar is Script {
    function run() external {
        uint256 pk = vm.envUint("PRIVATE_KEY");
        address poolManagerAddr = vm.envAddress("POOL_MANAGER");

        vm.startBroadcast(pk);

        AutoRangeTriPillar hook = new AutoRangeTriPillar(IPoolManager(poolManagerAddr));
        TriPillarExecutor exec = new TriPillarExecutor(IPoolManager(poolManagerAddr), hook);

        vm.stopBroadcast();

        console2.log("HOOK:", address(hook));
        console2.log("EXEC:", address(exec));
    }
}
