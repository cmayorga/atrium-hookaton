// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {IPoolManagerHook} from "./IPoolManagerHook.sol";

/// @notice Interfaz simplificada de un hook beforeAddLiquidity.
interface IBeforeAddLiquidityHook {
    function beforeAddLiquidity(
        address sender,
        bytes32 poolId,
        IPoolManagerHook.ModifyLiquidityParams calldata params,
        bytes calldata data
    ) external returns (IPoolManagerHook.ModifyLiquidityParams memory newParams);
}
