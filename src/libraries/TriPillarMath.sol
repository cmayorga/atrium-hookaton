// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {ModifyLiquidityParams} from "@uniswap/v4-core/src/types/PoolOperation.sol";

library TriPillarMath {
    function computeRSteps(uint256 vol) internal pure returns (int24) {
        if (vol < 10) return 3;
        if (vol < 30) return 6;
        return 12;
    }

    function floorToSpacing(int24 tick, int24 tickSpacing) internal pure returns (int24) {
        int24 r = tick % tickSpacing;
        if (r < 0) r += tickSpacing;
        return tick - r;
    }

    function compute(
        int24 tick,
        int24 tickSpacing,
        int24 rSteps,
        int256 liquidityDelta,
        bytes32 salt
    )
        internal
        pure
        returns (
            ModifyLiquidityParams memory central,
            ModifyLiquidityParams memory lower,
            ModifyLiquidityParams memory upper
        )
    {
        int24 sideSteps = 6;

        int24 t = floorToSpacing(tick, tickSpacing);

        int24 R = rSteps * tickSpacing;
        int24 S = sideSteps * tickSpacing;

        int24 centralLower = t - R;
        int24 centralUpper = t + R;

        int24 lowerLower = centralLower - S;
        int24 lowerUpper = centralLower;

        int24 upperLower = centralUpper;
        int24 upperUpper = centralUpper + S;

        int256 Lcentral = liquidityDelta / 2;
        int256 Lside = liquidityDelta / 4;

        central = ModifyLiquidityParams({
            tickLower: centralLower,
            tickUpper: centralUpper,
            liquidityDelta: Lcentral,
            salt: salt
        });

        lower = ModifyLiquidityParams({
            tickLower: lowerLower,
            tickUpper: lowerUpper,
            liquidityDelta: Lside,
            salt: salt
        });

        upper = ModifyLiquidityParams({
            tickLower: upperLower,
            tickUpper: upperUpper,
            liquidityDelta: Lside,
            salt: salt
        });
    }
}
