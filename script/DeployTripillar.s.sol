// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "forge-std/Script.sol";
import {IPoolManager} from "@uniswap/v4-core/src/interfaces/IPoolManager.sol";
import {Hooks} from "@uniswap/v4-core/src/libraries/Hooks.sol";
import {AutoRangeTriPillar} from "../src/hooks/AutoRangeTriPillar.sol";
import {TriPillarExecutor} from "../src/periphery/TriPillarExecutor.sol";
import {HookMiner} from "../src/utils/HookMiner.sol";

contract DeployTripillar is Script {
    address constant CREATE2_DEPLOYER = 0x4e59b44847b379578588920cA78FbF26c0B4956C;

    function run() external {
        uint256 pk = vm.envUint("PRIVATE_KEY");
        address poolManagerAddr = vm.envAddress("POOL_MANAGER");
        vm.startBroadcast(pk);

        IPoolManager manager = IPoolManager(poolManagerAddr);

        uint160 flags =
            uint160(Hooks.BEFORE_INITIALIZE_FLAG) |
            uint160(Hooks.BEFORE_ADD_LIQUIDITY_FLAG);

        bytes memory creationCode = abi.encodePacked(
            type(AutoRangeTriPillar).creationCode,
            abi.encode(manager)
        );

        (address predictedHookAddr, bytes32 salt) =
            HookMiner.find(CREATE2_DEPLOYER, flags, creationCode);

        console2.log("Predicted HOOK:", predictedHookAddr);
        console2.logBytes32(salt);

        AutoRangeTriPillar hook =
            new AutoRangeTriPillar{salt: salt}(manager);

        require(address(hook) == predictedHookAddr, "Hook address mismatch");

        console2.log("HOOK deployed at:", address(hook));

        TriPillarExecutor exec = new TriPillarExecutor(manager, hook);
        console2.log("EXEC deployed at:", address(exec));

        vm.stopBroadcast();
    }
}
