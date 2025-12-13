// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "forge-std/Test.sol";

import {IPoolManager} from "@uniswap/v4-core/src/interfaces/IPoolManager.sol";
import {IHooks} from "@uniswap/v4-core/src/interfaces/IHooks.sol";
import {PoolKey} from "@uniswap/v4-core/src/types/PoolKey.sol";
import {Currency} from "@uniswap/v4-core/src/types/Currency.sol";
import {ModifyLiquidityParams} from "@uniswap/v4-core/src/types/PoolOperation.sol";

import {AutoRangeTriPillar} from "../src/hooks/AutoRangeTriPillar.sol";

contract AutoRangeTriPillarForkTest is Test {
    IPoolManager poolManager;
    AutoRangeTriPillar hook;
    PoolKey poolKey;

    function setUp() public {
        vm.createSelectFork(vm.rpcUrl("sepolia"));

        poolManager = IPoolManager(vm.envAddress("POOL_MANAGER"));
        hook = new AutoRangeTriPillar(poolManager);

        poolKey = PoolKey({
            currency0: Currency.wrap(vm.envAddress("TOKEN0")),
            currency1: Currency.wrap(vm.envAddress("TOKEN1")),
            fee: 3000,
            tickSpacing: 60,
            hooks: IHooks(address(hook))
        });
    }

    function test_compiles_and_runs() public {
        ModifyLiquidityParams memory params = ModifyLiquidityParams({
            tickLower: -120,
            tickUpper: 120,
            liquidityDelta: int256(1e6),
            salt: bytes32(0)
        });

        poolManager.modifyLiquidity(poolKey, params, "");
    }
}
