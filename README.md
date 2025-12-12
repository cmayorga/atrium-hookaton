# AutoRange TriPillar Hook

## What the hook does

On every `beforeAddLiquidity` call:

- It reads the current `tick` and a TWAP from `IPPoolManager`
- It computes a dynamic central range based on volatility = |tick - twap|:
  - vol < 10  → R = 3
  - vol < 30 → R = 6
  - vol ≥ 30 → R = 12
- It defines 3 pillars:
  - **Central**: [tick - R, tick + R] with 50% of liquidity
  - **Lower**: 6 ticks below, with 25%
  - **Upper**: 6 ticks above, with 25%
- It calls `modifyLiquidity` three times on the PoolManager (one per pillar).
- It returns `ModifyLiquidityParams` with zero liquidity, meaning nothing from the
  original operation remains to be processed (the hook consumed all liquidity).

## Files

- `import {IPoolManager} from "v4-core/interfaces/IPoolManager.sol";`  
  Minimal PoolManager interface (getPoolState, getTWAP, modifyLiquidity).

- `src/interfaces/IBeforeAddLiquidityHook.sol`  
  Simplified v4-style interface for the `beforeAddLiquidity` hook.

- `src/libraries/VolatilityOracle.sol`  
  Utility computing a basic volatility metric = |tick - twap|.

- `src/hooks/AutoRangeTriPillar.sol`  
  Your tri‑pillar hook with constructor **only (IPoolManager)** — no `poolId`.

- `src/HookFactory.sol`  
  CREATE2 factory that deploys the hook. It forces the lowest 16 bits of the
  address to end in `0x0010` (optional).

- `test/mocks/MockPoolManager.sol`  
  Test implementation of `IPoolManager` that simply stores all liquidity ops.

- `test/AutoRangeTriPillar.t.sol`  
  Tests for 3 volatility scenarios (low/medium/high) and 50/25/25 validation.

- `script/DeployHookFromFactory.s.sol`  
  Script that deploys `MockPoolManager`, `HookFactory`, and the hook on any EVM
  chain (including BNB).

## Requirements

- Foundry (`foundryup`)
- forge-std (for tests):

```bash
forge install foundry-rs/forge-std
```

## Tests

```bash
forge test
```

## Cheap deployment to BNB (for experimentation)

> This does NOT deploy real Uniswap v4. It only deploys:
> - MockPoolManager  
> - HookFactory  
> - AutoRangeTriPillar

```bash
export PRIVATE_KEY=0x...
export BSC_RPC_URL="https://bsc-dataseed.binance.org"

forge script script/DeployHookFromFactory.s.sol:DeployHookFromFactory   --rpc-url $BSC_RPC_URL --broadcast -vvvv
```

Console output example:

```
MockPoolManager deployed at: 0x...
HookFactory deployed at:     0x...
AutoRangeTriPillar deployed at: 0x....0010
```

You can then view these addresses on BscScan.

## How to port this to real Uniswap v4

1. Replace `IPoolManager` with the official v4-core interface.
2. Update the `beforeAddLiquidity` signature to use `PoolKey` and `Hooks`.
3. Move the tri‑pillar logic into the `unlock()/lockAcquired` flow instead of
   calling `modifyLiquidity` directly.
4. Keep the main structure:
   - dynamic central range based on volatility,
   - 50% central, 25% lower, 25% upper,
   - 3 pillars overlapping by ±6 ticks.
