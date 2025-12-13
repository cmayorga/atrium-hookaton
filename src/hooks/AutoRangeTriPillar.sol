// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {BaseHook} from "v4-periphery/src/utils/BaseHook.sol";
import {Hooks} from "@uniswap/v4-core/src/libraries/Hooks.sol";
import {IPoolManager} from "@uniswap/v4-core/src/interfaces/IPoolManager.sol";
import {IHooks} from "@uniswap/v4-core/src/interfaces/IHooks.sol";
import {PoolKey} from "@uniswap/v4-core/src/types/PoolKey.sol";
import {PoolId, PoolIdLibrary} from "@uniswap/v4-core/src/types/PoolId.sol";
import {ModifyLiquidityParams} from "@uniswap/v4-core/src/types/PoolOperation.sol";

contract AutoRangeTriPillar is BaseHook {
    using PoolIdLibrary for PoolKey;

    event TriPillarComputed(
        bytes32 indexed poolId,
        int24 tickLower,
        int24 tickUpper,
        int256 liquidityDelta
    );

    constructor(IPoolManager manager) BaseHook(manager) {}

    function getHookPermissions()
        public
        pure
        override
        returns (Hooks.Permissions memory)
    {
        Hooks.Permissions memory p;
        p.beforeAddLiquidity = true;
        return p;
    }

    function _beforeAddLiquidity(
        address,
        PoolKey calldata key,
        ModifyLiquidityParams calldata params,
        bytes calldata
    ) internal override returns (bytes4) {
        bytes32 poolId = PoolId.unwrap(key.toId());

        emit TriPillarComputed(
            poolId,
            params.tickLower,
            params.tickUpper,
            params.liquidityDelta
        );

        return BaseHook.beforeAddLiquidity.selector;
    }
}
