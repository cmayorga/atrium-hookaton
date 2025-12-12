// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {PoolManagerTypes} from "v4-core/types/PoolManagerTypes.sol";

interface IBeforeAddLiquidityHook {
    function beforeAddLiquidity(
        address sender,
        bytes32 poolId,
        PoolManagerTypes.ModifyLiquidityParams calldata params,
        bytes calldata data
    ) external returns (PoolManagerTypes.ModifyLiquidityParams memory newParams);
}
