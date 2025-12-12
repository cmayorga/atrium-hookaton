// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {IPoolManagerHook} from "../interfaces/IPoolManagerHook.sol";
import {IBeforeAddLiquidityHook} from "../interfaces/IBeforeAddLiquidityHook.sol";
import {VolatilityOracle} from "../libraries/VolatilityOracle.sol";

/// @notice Hook que:
/// - Ajusta un rango central dinámico según la volatilidad (diff entre tick y TWAP)
/// - Usa el 50% de la liquidez en el rango central
/// - Usa el 25% en un rango inferior de 6 ticks
/// - Usa el 25% en un rango superior de 6 ticks
///
contract AutoRangeTriPillar is IBeforeAddLiquidityHook {
    IPoolManagerHook public immutable manager;

    constructor(IPoolManagerHook _manager) {
        manager = _manager;
    }

    function beforeAddLiquidity(
        address /*sender*/,
        bytes32 poolId,
        IPoolManagerHook.ModifyLiquidityParams calldata params,
        bytes calldata
    ) external override returns (IPoolManagerHook.ModifyLiquidityParams memory newParams) {
        require(msg.sender == address(manager), "AutoRangeTriPillar: only manager");

        IPoolManagerHook.PoolState memory state = manager.getPoolState(poolId);
        int24 tick = state.tick;

        int24 twapTick = manager.getTWAP(poolId, 300);

        uint256 vol = VolatilityOracle.computeVolatility(tick, twapTick);

        int24 R;
        if (vol < 10) {
            R = 3;
        } else if (vol < 30) {
            R = 6;
        } else {
            R = 12;
        }

        int24 centralLower = tick - R;
        int24 centralUpper = tick + R;

        int24 lowerLower = centralLower - 6;
        int24 lowerUpper = centralLower;

        int24 upperLower = centralUpper;
        int24 upperUpper = centralUpper + 6;

        // 4. Reparto de liquidez
        int128 L = params.liquidityDelta;

        int128 Lcentral = L / 2; // 50%
        int128 Lside    = L / 4; // 25% + 25%

        manager.modifyLiquidity(
            poolId,
            IPoolManagerHook.ModifyLiquidityParams({
                tickLower: centralLower,
                tickUpper: centralUpper,
                liquidityDelta: Lcentral,
                salt: params.salt
            })
        );

        manager.modifyLiquidity(
            poolId,
            IPoolManagerHook.ModifyLiquidityParams({
                tickLower: lowerLower,
                tickUpper: lowerUpper,
                liquidityDelta: Lside,
                salt: params.salt
            })
        );

        manager.modifyLiquidity(
            poolId,
            IPoolManagerHook.ModifyLiquidityParams({
                tickLower: upperLower,
                tickUpper: upperUpper,
                liquidityDelta: Lside,
                salt: params.salt
            })
        );

        newParams = IPoolManagerHook.ModifyLiquidityParams({
            tickLower: 0,
            tickUpper: 0,
            liquidityDelta: 0,
            salt: params.salt
        });
    }
}
