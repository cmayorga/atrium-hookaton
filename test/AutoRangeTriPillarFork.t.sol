// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "forge-std/Test.sol";

import {IPoolManager} from "@uniswap/v4-core/src/interfaces/IPoolManager.sol";
import {IHooks} from "@uniswap/v4-core/src/interfaces/IHooks.sol";
import {PoolKey} from "@uniswap/v4-core/src/types/PoolKey.sol";
import {PoolId, PoolIdLibrary} from "@uniswap/v4-core/src/types/PoolId.sol";
import {Currency} from "@uniswap/v4-core/src/types/Currency.sol";
import {ModifyLiquidityParams} from "@uniswap/v4-core/src/types/PoolOperation.sol";

import {AutoRangeTriPillar} from "../src/hooks/AutoRangeTriPillar.sol";
import {TriPillarExecutor} from "../src/periphery/TriPillarExecutor.sol";

contract AutoRangeTriPillarForkTest is Test {
    using PoolIdLibrary for PoolKey;

    IPoolManager manager;
    AutoRangeTriPillar hook;
    TriPillarExecutor executor;
    PoolKey key;

    function setUp() public {
        string memory rpc = vm.envString("RPC_URL");
        vm.createSelectFork(rpc);

        manager = IPoolManager(vm.envAddress("POOL_MANAGER"));

        hook = AutoRangeTriPillar(payable(vm.envAddress("HOOK_ADDRESS")));
        executor = new TriPillarExecutor(manager, hook);

        Currency token0 = Currency.wrap(vm.envAddress("TOKEN0"));
        Currency token1 = Currency.wrap(vm.envAddress("TOKEN1"));

        if (Currency.unwrap(token0) > Currency.unwrap(token1)) {
            (token0, token1) = (token1, token0);
        }

        key = PoolKey({
            currency0: token0,
            currency1: token1,
            fee: 3000,
            tickSpacing: 60,
            hooks: IHooks(address(hook))
        });

        bytes32 poolId = PoolId.unwrap(key.toId());

        (bool ok,) = address(manager).call(
            abi.encodeWithSignature("getSlot0(bytes32)", poolId)
        );

        if (!ok) {
            manager.initialize(key, uint160(1 << 96));
        }
    }

    function test_addLiquidity_direct() public {
        ModifyLiquidityParams memory params = ModifyLiquidityParams({
            tickLower: -120,
            tickUpper: 120,
            liquidityDelta: int256(1e6),
            salt: bytes32(uint256(1))
        });

        manager.modifyLiquidity(key, params, "");
    }
}
