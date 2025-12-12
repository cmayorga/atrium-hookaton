// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

library VolatilityOracle {
    function computeVolatility(int24 currentTick, int24 twapTick)
        internal
        pure
        returns (uint256)
    {
        int24 diff = currentTick - twapTick;
        if (diff < 0) diff = -diff;
        return uint256(uint24(diff));
    }
}
