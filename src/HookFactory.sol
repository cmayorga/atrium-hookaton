// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {IPoolManager} from "v4-core/interfaces/IPoolManager.sol";
import {AutoRangeTriPillar} from "./hooks/AutoRangeTriPillar.sol";

contract HookFactory {
    event HookDeployed(address hook, bytes32 salt);

    uint16 public constant PERMISSION_MASK = 0x0010;

    function deployHook(
        IPoolManager manager,
        uint256 maxTries
    ) external returns (address deployed) {
        require(maxTries > 0 && maxTries <= 10000, "maxTries out of range");

        bytes memory bytecode = abi.encodePacked(
            type(AutoRangeTriPillar).creationCode,
            abi.encode(manager)
        );

        for (uint256 i = 0; i < maxTries; i++) {
            bytes32 salt = keccak256(abi.encode(msg.sender, i));
            address predicted = computeAddress(salt, bytecode);

            if (uint16(uint160(predicted)) == PERMISSION_MASK) {
                deployed = deployCreate2(salt, bytecode);
                require(deployed == predicted, "HookFactory: create2 mismatch");
                emit HookDeployed(deployed, salt);
                return deployed;
            }
        }

        revert("HookFactory: no valid salt");
    }

    function deployCreate2(bytes32 salt, bytes memory bytecode)
        internal
        returns (address addr)
    {
        assembly {
            addr := create2(0, add(bytecode, 32), mload(bytecode), salt)
        }
        require(addr != address(0), "HookFactory: CREATE2 failed");
    }

    function computeAddress(bytes32 salt, bytes memory bytecode)
        public
        view
        returns (address)
    {
        bytes32 hash = keccak256(
            abi.encodePacked(
                bytes1(0xff),
                address(this),
                salt,
                keccak256(bytecode)
            )
        );
        return address(uint160(uint256(hash)));
    }
}
