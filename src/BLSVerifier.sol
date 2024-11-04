// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.23;

import {BLSOpen} from "./lib/BLSOpen.sol";
import {BLSOpen2} from "./lib/BLSOpen2.sol";
import {IBLSVerifier} from "./interfaces/IBLSVerifier.sol";

contract BLSVerifier is IBLSVerifier {
    // 验证方式选择
    enum VerifyMode {
        PRECOMPILED,  // 使用预编译合约
        PURE_EVM     // 使用纯EVM实现
    }
    
    VerifyMode public verifyMode;
    
    constructor(VerifyMode _mode) {
        verifyMode = _mode;
    }

    function verifyMultiple(
        uint256[2][] memory signatures,
        uint256[4][] memory pubkeys,
        uint256[2][] memory messages
    ) external view override returns (bool) {
        if(verifyMode == VerifyMode.PRECOMPILED) {
            return BLSOpen.verifyMultiple(signatures, pubkeys, messages);
        } else {
            return BLSOpen2.verifyMultiple(signatures, pubkeys, messages);
        }
    }
} 