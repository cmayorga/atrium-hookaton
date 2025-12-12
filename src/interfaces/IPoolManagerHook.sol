// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

interface IPoolManagerHook {
    struct ModifyLiquidityParams {
        int24 tickLower;
        int24 tickUpper;
        int128 liquidityDelta;
        bytes32 salt;
    }

    struct PoolState {
        int24 tick;
    }

    function getPoolState(bytes32 poolId) external view returns (PoolState memory);

    function getTWAP(bytes32 poolId, uint32 secondsAgo) external view returns (int24 twapTick);

    function modifyLiquidity(bytes32 poolId, ModifyLiquidityParams calldata params) external;
}
