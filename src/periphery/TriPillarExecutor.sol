// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {IPoolManager} from "@uniswap/v4-core/src/interfaces/IPoolManager.sol";
import {PoolKey} from "@uniswap/v4-core/src/types/PoolKey.sol";
import {ModifyLiquidityParams} from "@uniswap/v4-core/src/types/PoolOperation.sol";

import {AutoRangeTriPillar} from "../hooks/AutoRangeTriPillar.sol";

contract TriPillarExecutor {
    IPoolManager public immutable poolManager;
    AutoRangeTriPillar public immutable hook;

    constructor(IPoolManager _poolManager, AutoRangeTriPillar _hook) {
        poolManager = _poolManager;
        hook = _hook;
    }

    function addLiquidityTriPillar(
        PoolKey calldata key,
        ModifyLiquidityParams calldata userParams
    ) external {
        (ModifyLiquidityParams memory c, ModifyLiquidityParams memory l, ModifyLiquidityParams memory u) =
            hook.quoteTripillar(key, userParams);

        poolManager.modifyLiquidity(key, c, "");
        poolManager.modifyLiquidity(key, l, "");
        poolManager.modifyLiquidity(key, u, "");
    }
}
