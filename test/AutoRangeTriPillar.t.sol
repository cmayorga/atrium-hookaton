// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "forge-std/Test.sol";
import {AutoRangeTriPillar} from "../src/hooks/AutoRangeTriPillar.sol";
import {MockPoolManager} from "./mocks/MockPoolManager.sol";
import {IPoolManager} from "v4-core/interfaces/IPoolManager.sol";

contract AutoRangeTriPillarTest is Test {
    MockPoolManager manager;
    AutoRangeTriPillar hook;
    bytes32 poolId = keccak256("POOL_1");

    function setUp() public {
        manager = new MockPoolManager();
        hook = new AutoRangeTriPillar(manager);
    }

    function _callHook(int24 currentTick, int24 twapTick, int128 L)
        internal
        returns (IPoolManager.ModifyLiquidityParams memory out)
    {
        manager.setTick(currentTick);
        manager.setTwapTick(twapTick);

        IPoolManager.ModifyLiquidityParams memory params =
            IPoolManager.ModifyLiquidityParams({
                tickLower: 0,
                tickUpper: 0,
                liquidityDelta: L,
                salt: bytes32("SALT")
            });

        vm.prank(address(manager));
        out = hook.beforeAddLiquidity(address(this), poolId, params, "");
    }

    function testLowVolatilityRange3AndSplit() public {
        int24 currentTick = 100;
        int24 twapTick = 103; // diff = 3 < 10 => R = 3
        int128 L = 1000;

        _callHook(currentTick, twapTick, L);

        assertEq(manager.getOpCount(), 3);

        // 1) Central
        MockPoolManager.LiquidityOp memory central = manager.getOp(0);
        assertEq(central.tickLower, 97);
        assertEq(central.tickUpper, 103);
        assertEq(central.liquidityDelta, L / 2);

        // 2) Lower
        MockPoolManager.LiquidityOp memory lower = manager.getOp(1);
        assertEq(lower.tickLower, 97 - 6);
        assertEq(lower.tickUpper, 97);
        assertEq(lower.liquidityDelta, L / 4);

        // 3) Upper
        MockPoolManager.LiquidityOp memory upper = manager.getOp(2);
        assertEq(upper.tickLower, 103);
        assertEq(upper.tickUpper, 103 + 6);
        assertEq(upper.liquidityDelta, L / 4);
    }

    function testMediumVolatilityRange6() public {
        int24 currentTick = 200;
        int24 twapTick = 215; // diff = 15 < 30 => R = 6
        int128 L = 800;

        _callHook(currentTick, twapTick, L);

        // Central: [194, 206]
        MockPoolManager.LiquidityOp memory central = manager.getOp(0);
        assertEq(central.tickLower, 200 - 6);
        assertEq(central.tickUpper, 200 + 6);
        assertEq(central.liquidityDelta, L / 2);

        // Lower: [188, 194]
        MockPoolManager.LiquidityOp memory lower = manager.getOp(1);
        assertEq(lower.tickLower, 194 - 6);
        assertEq(lower.tickUpper, 194);
        assertEq(lower.liquidityDelta, L / 4);

        // Upper: [206, 212]
        MockPoolManager.LiquidityOp memory upper = manager.getOp(2);
        assertEq(upper.tickLower, 206);
        assertEq(upper.tickUpper, 206 + 6);
        assertEq(upper.liquidityDelta, L / 4);
    }

    function testHighVolatilityRange12() public {
        int24 currentTick = 500;
        int24 twapTick = 540; // diff = 40 >= 30 => R = 12
        int128 L = 1000;

        _callHook(currentTick, twapTick, L);

        // Central: [488, 512]
        MockPoolManager.LiquidityOp memory central = manager.getOp(0);
        assertEq(central.tickLower, 500 - 12);
        assertEq(central.tickUpper, 500 + 12);
        assertEq(central.liquidityDelta, L / 2);

        // Lower: [482, 488]
        MockPoolManager.LiquidityOp memory lower = manager.getOp(1);
        assertEq(lower.tickLower, 488 - 6);
        assertEq(lower.tickUpper, 488);
        assertEq(lower.liquidityDelta, L / 4);

        // Upper: [512, 518]
        MockPoolManager.LiquidityOp memory upper = manager.getOp(2);
        assertEq(upper.tickLower, 512);
        assertEq(upper.tickUpper, 512 + 6);
        assertEq(upper.liquidityDelta, L / 4);
    }
}
