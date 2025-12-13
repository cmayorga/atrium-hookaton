// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

library HookMiner {
    function computeAddress(
        address deployer,
        bytes32 salt,
        bytes memory creationCode
    ) internal pure returns (address) {
        bytes32 hash = keccak256(
            abi.encodePacked(bytes1(0xff), deployer, salt, keccak256(creationCode))
        );
        return address(uint160(uint256(hash)));
    }

    function find(
        address deployer,
        uint160 flags,
        bytes memory creationCode
    ) internal pure returns (address hookAddress, bytes32 salt) {
        for (uint256 i = 0; i < type(uint32).max; i++) {
            bytes32 s = bytes32(uint256(i));

            address candidate = computeAddress(deployer, s, creationCode);
            if ((uint160(candidate) & flags) == flags) {
                return (candidate, s);
            }
        }

        revert("HookMiner: no valid address found");
    }
}
