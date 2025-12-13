// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {BaseHook} from "v4-periphery/src/utils/BaseHook.sol";
import {Hooks} from "@uniswap/v4-core/src/libraries/Hooks.sol";
import {IPoolManager} from "@uniswap/v4-core/src/interfaces/IPoolManager.sol";
import {PoolKey} from "@uniswap/v4-core/src/types/PoolKey.sol";
import {PoolId, PoolIdLibrary} from "@uniswap/v4-core/src/types/PoolId.sol";
import {ModifyLiquidityParams} from "@uniswap/v4-core/src/types/PoolOperation.sol";

import {VolatilityOracle} from "../libraries/VolatilityOracle.sol";
import {TriPillarMath} from "../libraries/TriPillarMath.sol";

contract AutoRangeTriPillar is BaseHook {
    using PoolIdLibrary for PoolKey;

    event TriPillarComputed(
        bytes32 indexed poolId,
        int24 tick,
        int24 twapTick,
        int24 rSteps,
        ModifyLiquidityParams central,
        ModifyLiquidityParams lower,
        ModifyLiquidityParams upper
    );

    constructor(IPoolManager manager) BaseHook(manager) {}

    function getHookPermissions() public pure override returns (Hooks.Permissions memory) {
        Hooks.Permissions memory p;
        p.beforeAddLiquidity = true;
        return p;
    }

    function quoteTripillar(
        PoolKey calldata key,
        ModifyLiquidityParams calldata userParams
    )
        public
        view
        returns (ModifyLiquidityParams memory central, ModifyLiquidityParams memory lower, ModifyLiquidityParams memory upper)
    {
        bytes32 poolId = PoolId.unwrap(key.toId());

        int24 tick = _tryGetTick(poolId, userParams);
        int24 twap = _tryGetTwap(poolId, tick);

        uint256 vol = VolatilityOracle.computeVolatility(tick, twap);
        int24 rSteps = TriPillarMath.computeRSteps(vol);

        return TriPillarMath.compute(tick, key.tickSpacing, rSteps, userParams.liquidityDelta, userParams.salt);
    }

    function _beforeAddLiquidity(
        address,
        PoolKey calldata key,
        ModifyLiquidityParams calldata params,
        bytes calldata
    ) internal override returns (bytes4) {
        bytes32 poolId = PoolId.unwrap(key.toId());

        int24 tick = _tryGetTick(poolId, params);
        int24 twap = _tryGetTwap(poolId, tick);

        uint256 vol = VolatilityOracle.computeVolatility(tick, twap);
        int24 rSteps = TriPillarMath.computeRSteps(vol);

        (ModifyLiquidityParams memory c, ModifyLiquidityParams memory l, ModifyLiquidityParams memory u) =
            TriPillarMath.compute(tick, key.tickSpacing, rSteps, params.liquidityDelta, params.salt);

        emit TriPillarComputed(poolId, tick, twap, rSteps, c, l, u);

        return BaseHook.beforeAddLiquidity.selector;
    }

    function _tryGetTick(bytes32 poolId, ModifyLiquidityParams calldata params) internal view returns (int24 tick) {
        (bool ok, bytes memory ret) =
            address(poolManager).staticcall(abi.encodeWithSignature("getSlot0(bytes32)", poolId));

        if (ok && ret.length >= 128) {
            (, tick, , ) = abi.decode(ret, (uint160, int24, uint16, uint16));
        } else {
            tick = int24((int256(params.tickLower) + int256(params.tickUpper)) / 2);
        }
    }

    function _tryGetTwap(bytes32 poolId, int24 fallbackTick) internal view returns (int24 twapTick) {
        (bool ok, bytes memory ret) =
            address(poolManager).staticcall(abi.encodeWithSignature("getTwap(bytes32,uint32)", poolId, uint32(300)));

        if (ok && ret.length >= 32) {
            twapTick = abi.decode(ret, (int24));
        } else {
            twapTick = fallbackTick;
        }
    }
}
