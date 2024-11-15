// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.23;

library BLSOpen {
    // BLS12-381 curve parameters
    uint256 constant N = 0x73eda753299d7d483339d80809a1d80553bda402fffe5bfeffffffff00000001;
    
    // BLS12-381 G1 point addition precompile
    address constant POINT_ADDITION = address(0x06);
    // BLS12-381 G1 point scalar multiplication precompile
    address constant SCALAR_MUL = address(0x07);
    // BLS12-381 pairing precompile
    address constant PAIRING_CHECK = address(0x08);

    error InvalidSignatureLength();
    error InvalidPubkeyLength();
    error InvalidMessageLength();
    error ArrayLengthMismatch();

    function verifyMultiple(
        uint256[2][] memory signatures,
        uint256[4][] memory pubkeys,
        uint256[2][] memory messages
    ) internal view returns (bool) {
        // 验证输入数组长度匹配
        if(signatures.length != pubkeys.length || pubkeys.length != messages.length) {
            revert ArrayLengthMismatch();
        }

        // 验证输入数组非空
        if(signatures.length == 0) {
            revert InvalidSignatureLength();
        }

        // 准备配对检查的输入
        uint256 k = signatures.length;
        bytes memory input = new bytes(k * 288); // 每个配对点需要 6 * 32 = 192 字节
        
        for(uint256 i = 0; i < k; i++) {
            // 复制签名点 (G1)
            assembly {
                let ptr := add(add(input, 0x20), mul(i, 288))
                mstore(ptr, mload(add(signatures, mul(add(i, 1), 0x40))))
                mstore(add(ptr, 0x20), mload(add(signatures, add(mul(add(i, 1), 0x40), 0x20))))
            }
            
            // 复制公钥点 (G2)
            assembly {
                let ptr := add(add(input, 0x20), add(mul(i, 288), 0x40))
                mstore(ptr, mload(add(pubkeys, mul(add(i, 1), 0x80))))
                mstore(add(ptr, 0x20), mload(add(pubkeys, add(mul(add(i, 1), 0x80), 0x20))))
                mstore(add(ptr, 0x40), mload(add(pubkeys, add(mul(add(i, 1), 0x80), 0x40))))
                mstore(add(ptr, 0x60), mload(add(pubkeys, add(mul(add(i, 1), 0x80), 0x60))))
            }
            
            // 复制消息点 (G1)
            assembly {
                let ptr := add(add(input, 0x20), add(mul(i, 288), 0xc0))
                mstore(ptr, mload(add(messages, mul(add(i, 1), 0x40))))
                mstore(add(ptr, 0x20), mload(add(messages, add(mul(add(i, 1), 0x40), 0x20))))
            }
        }

        // 调用预编译合约进行配对检查
        address pairingCheck = PAIRING_CHECK;  // Load constant before assembly
        assembly {
            // 调用配对检查预编译
            let success := staticcall(gas(), pairingCheck, add(input, 0x20), mul(k, 288), 0x00, 0x20)
            
            // 验证调用成功
            if iszero(success) {
                revert(0, 0)
            }
            
            // 返回配对检查结果
            let result := mload(0x00)
            mstore(0x00, result)
            return(0x00, 0x20)
        }
    }
} 