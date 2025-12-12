# AutoRange TriPillar Hook (v4-style sandbox)

Este repo es un **sandbox mínimo en Foundry** pensado para que tengas la lógica
de tu hook tri-pilar funcionando y testeada SIN pelearte con todo Uniswap v4.

No usa `v4-core` ni `v4-periphery` reales, sino interfaces mínimas 100% bajo tu
control. Luego puedes portar la lógica al hook real de v4.

## Qué hace el hook

En cada `beforeAddLiquidity`:

- Lee `tick` y un TWAP simulado desde `IPoolManager` (mockeado en tests).
- Calcula un rango central dinámico según volatilidad = |tick - twap|:
  - vol < 10  → R = 3
  - vol < 30  → R = 6
  - vol >= 30 → R = 12
- Define 3 pilares:
  - **Central**: [tick-R, tick+R] con 50% de la liquidez
  - **Inferior**: 6 ticks por debajo, con 25%
  - **Superior**: 6 ticks por encima, con 25%
- Llama 3 veces a `modifyLiquidity` del PoolManager, una por pilar.
- Devuelve `ModifyLiquidityParams` con liquidez 0 para indicar que no quede
  nada por procesar de la operación original (toda la L ya la ha consumido).

## Archivos

- `import {IPoolManager} from "v4-core/interfaces/IPoolManager.sol";`  
  Interfaz mínima de PoolManager (getPoolState, getTWAP, modifyLiquidity).

- `src/interfaces/IBeforeAddLiquidityHook.sol`  
  Interfaz del hook `beforeAddLiquidity` (estilo v4 simplificado).

- `src/libraries/VolatilityOracle.sol`  
  Utilidad para calcular una métrica tonta de volatilidad = |tick - twap|.

- `src/hooks/AutoRangeTriPillar.sol`  
  Tu hook tri-pilar con constructor **solo (IPoolManager)**, nada de `poolId`.

- `src/HookFactory.sol`  
  Factory con CREATE2 que despliega el hook. Aquí se fuerza que los 16 bits
  bajos de la address terminen en `0x0010` (puedes quitarlo si quieres).

- `test/mocks/MockPoolManager.sol`  
  Implementación de prueba de `IPoolManager` que sólo guarda las operaciones
  de liquidez que se le van llamando.

- `test/AutoRangeTriPillar.t.sol`  
  Tests con 3 escenarios de volatilidad (baja/media/alta) y chequeo 50/25/25.

- `script/DeployHookFromFactory.s.sol`  
  Script para desplegar `MockPoolManager`, `HookFactory` y el hook en cualquier
  EVM (incluida BNB).

## Requisitos

- Foundry (`foundryup`)
- forge-std (para los tests):

```bash
forge install foundry-rs/forge-std
```

## Tests

```bash
forge test
```

## Deploy barato a BNB (solo para juguetear)

> Esto NO despliega Uniswap v4 real. Simplemente pone on-chain:
> - MockPoolManager
> - HookFactory
> - AutoRangeTriPillar

```bash
export PRIVATE_KEY=0x...
export BSC_RPC_URL="https://bsc-dataseed.binance.org"

forge script script/DeployHookFromFactory.s.sol:DeployHookFromFactory \
  --rpc-url $BSC_RPC_URL   --broadcast -vvvv
```

Verás en consola:

```text
MockPoolManager deployed at: 0x...
HookFactory deployed at:     0x...
AutoRangeTriPillar deployed at: 0x....0010
```

Luego puedes abrir las direcciones en BscScan.

## Cómo portarlo a Uniswap v4 real

1. Cambia `IPoolManager` por la interfaz de v4-core oficial.
2. Cambia la firma de `beforeAddLiquidity` para usar `PoolKey` y `Hooks`.
3. Mueve la lógica tri-pilar a un flujo `unlock()/lockAcquired` en vez de
   llamar directamente `modifyLiquidity` como se hace aquí.
4. Mantén la idea de:
   - rango central dinámico por volatilidad,
   - 50% central, 25% abajo, 25% arriba,
   - 3 “pilares” solapando con ±6 ticks.
