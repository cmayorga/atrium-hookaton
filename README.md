# AutoRange TriPillar Hook (Uniswap v4)

## Overview

## What the hook does

https://github.com/user-attachments/assets/9ddd212a-dc57-4daf-8dff-3666383452be

**AutoRange TriPillar** is a Uniswap v4 hook that implements a **dynamic three-range liquidity strategy** (“tri-pillar”) driven by market volatility.

The hook is triggered on every `beforeAddLiquidity` call and computes three liquidity ranges:

- a **central dynamic range**
- a **lower side range**
- an **upper side range**

Liquidity is split **50% / 25% / 25%** across these ranges.

Due to the locking model of Uniswap v4 hooks, the hook **does not directly call `modifyLiquidity`**.  
Instead, it computes and exposes the ranges, which are then executed by a dedicated **periphery executor** contract in a single transaction.

This is the intended and safe pattern for Uniswap v4 hooks.

---

## What the hook does

On every `beforeAddLiquidity` call:

1. Reads the current pool tick (best-effort) and a TWAP (best-effort).
2. Computes volatility as:

```
volatility = |currentTick - twapTick|
```

3. Chooses a dynamic central range width `R`:

| Volatility | R (steps) |
|-----------|-----------|
| `< 10`    | 3         |
| `< 30`    | 6         |
| `>= 30`   | 12        |

4. Builds **three overlapping ranges**, aligned to `tickSpacing`:

- **Central pillar**  
  `[tick - R, tick + R]` → **50% liquidity**

- **Lower pillar**  
  6 steps below the central range → **25% liquidity**

- **Upper pillar**  
  6 steps above the central range → **25% liquidity**

5. Emits an event with the computed tri-pillar layout.
6. Allows the original liquidity operation to continue.

---

## Contracts

### Hook

- `src/hooks/AutoRangeTriPillar.sol`

### Libraries

- `src/libraries/VolatilityOracle.sol`
- `src/libraries/TriPillarMath.sol`

### Periphery Executor

- `src/periphery/TriPillarExecutor.sol`

---

## Installation

```bash
forge install uniswap/v4-periphery
forge install foundry-rs/forge-std
```

---

## Remappings

```txt
v4-periphery/=lib/v4-periphery/
@uniswap/v4-core/=lib/v4-periphery/lib/v4-core/
forge-std/=lib/forge-std/src/
```

---

## Deployment

```bash
forge script script/DeployTripillar.s.sol:DeployTripillar \
  --rpc-url $RPC_URL \
  --broadcast \
  -vv
```

---

## Testing

### Unit tests

```bash
forge test --match-path test/TriPillarMath.t.sol -vvvv
```

---

## Fork test with real PoolManager

### Test file

```
test/AutoRangeTriPillarFork.t.sol
```

### Environment variables

```env
RPC_URL=https://<your-rpc-endpoint>
POOL_MANAGER=0x...
TOKEN0=0x...
TOKEN1=0x...
```

### Run fork test

```bash
forge test --match-path test/AutoRangeTriPillarFork.t.sol -vvvv
```
