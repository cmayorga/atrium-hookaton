// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

library HookMiner {
    uint160 internal constant ALL_HOOK_MASK = uint160((1 << 14) - 1);

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
        uint160 desiredMask,
        bytes memory creationCode
    ) internal view returns (address hookAddress, bytes32 salt) {
        uint256 seed = uint256(
            keccak256(
                abi.encodePacked(
                    block.timestamp,
                    block.number,
                    msg.sender,
                    tx.origin
                )
            )
        );

        for (uint256 i = 0; i < type(uint32).max; i++) {
            bytes32 s = bytes32(seed + i);
            address candidate = computeAddress(deployer, s, creationCode);
            if ((uint160(candidate) & ALL_HOOK_MASK) == desiredMask) {
                return (candidate, s);
            }
        }

        revert("HookMiner: no valid address found");
    }
}
