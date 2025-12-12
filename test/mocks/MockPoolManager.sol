// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {IPoolManager} from "v4-core/interfaces/IPoolManager.sol";

/// @notice Implementación simulada de IPoolManager para tests / demo on-chain.
contract MockPoolManager is IPoolManager {
    struct LiquidityOp {
        bytes32 poolId;
        int24 tickLower;
        int24 tickUpper;
        int128 liquidityDelta;
        bytes32 salt;
    }

    int24 public currentTick;
    int24 public currentTwapTick;

    LiquidityOp[] public ops;

    function setTick(int24 t) external {
        currentTick = t;
    }

    function setTwapTick(int24 t) external {
        currentTwapTick = t;
    }

    function getPoolState(bytes32) external view override returns (PoolState memory) {
        return IPoolManagerHook.PoolState({tick: currentTick});
    }

    function getTWAP(bytes32, uint32) external view override returns (int24 twapTick) {
        return currentTwapTick;
    }

    function modifyLiquidity(bytes32 poolId, ModifyLiquidityParams calldata params) external override {
        ops.push(
            LiquidityOp({
                poolId: poolId,
                tickLower: params.tickLower,
                tickUpper: params.tickUpper,
                liquidityDelta: params.liquidityDelta,
                salt: params.salt
            })
        );
    }

    function getOpCount() external view returns (uint256) {
        return ops.length;
    }

    function getOp(uint256 i) external view returns (LiquidityOp memory) {
        return ops[i];
    }
}
