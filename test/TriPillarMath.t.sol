// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "forge-std/Test.sol";
import {TriPillarMath} from "../src/libraries/TriPillarMath.sol";
import {ModifyLiquidityParams} from "@uniswap/v4-core/src/types/PoolOperation.sol";

contract TriPillarMathTest is Test {
    function test_compute_splits_and_ranges() public {
        int24 tick = 12345;
        int24 spacing = 60;
        int24 rSteps = 6;
        int256 L = 1000;
        bytes32 salt = bytes32(uint256(1));

        (ModifyLiquidityParams memory c, ModifyLiquidityParams memory l, ModifyLiquidityParams memory u) =
            TriPillarMath.compute(tick, spacing, rSteps, L, salt);

        assertEq(c.liquidityDelta, 500);
        assertEq(l.liquidityDelta, 250);
        assertEq(u.liquidityDelta, 250);

        assertEq((c.tickLower % spacing + spacing) % spacing, 0);
        assertEq((c.tickUpper % spacing + spacing) % spacing, 0);
        assertEq((l.tickLower % spacing + spacing) % spacing, 0);
        assertEq((u.tickUpper % spacing + spacing) % spacing, 0);

        assertEq(l.tickUpper, c.tickLower);
        assertEq(u.tickLower, c.tickUpper);
    }
}
