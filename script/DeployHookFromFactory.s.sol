// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "forge-std/Script.sol";
import {HookFactory} from "../src/HookFactory.sol";
import {MockPoolManager} from "../test/mocks/MockPoolManager.sol";

contract DeployHookFromFactory is Script {
    function run() external {
        uint256 pk = vm.envUint("PRIVATE_KEY");

        vm.startBroadcast(pk);

        MockPoolManager manager = new MockPoolManager();
        console2.log("MockPoolManager deployed at:", address(manager));

        HookFactory factory = new HookFactory();
        console2.log("HookFactory deployed at:", address(factory));

        address hook = factory.deployHook(manager, 5000);
        console2.log("AutoRangeTriPillar deployed at:", hook);

        vm.stopBroadcast();
    }
}
