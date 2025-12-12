// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "forge-std/Script.sol";
import {AutoRangeTriPillar} from "../src/hooks/AutoRangeTriPillar.sol";
import {IPoolManager} from "v4-core/interfaces/IPoolManager.sol";

contract DeployTriPillar is Script {
    function run() external {
        uint256 pk = vm.envUint("PRIVATE_KEY");
        IPoolManager manager = IPoolManager(vm.envAddress("POOL_MANAGER"));

        vm.startBroadcast(pk);
        AutoRangeTriPillar hook = new AutoRangeTriPillar(manager);
        vm.stopBroadcast();

        console2.log("Hook deployed at:", address(hook));
    }
}
