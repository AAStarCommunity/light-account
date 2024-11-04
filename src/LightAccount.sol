// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.23;

import {ECDSA} from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import {MessageHashUtils} from "@openzeppelin/contracts/utils/cryptography/MessageHashUtils.sol";
import {SignatureChecker} from "@openzeppelin/contracts/utils/cryptography/SignatureChecker.sol";
import {SIG_VALIDATION_FAILED} from "account-abstraction/core/Helpers.sol";
import {IEntryPoint} from "account-abstraction/interfaces/IEntryPoint.sol";
import {PackedUserOperation} from "account-abstraction/interfaces/PackedUserOperation.sol";
import {BaseLightAccount} from "./common/BaseLightAccount.sol";
import {CustomSlotInitializable} from "./common/CustomSlotInitializable.sol";
import {BLSOpen} from "../lib/BLSOpen.sol";
import {BLSVerifier} from "./BLSVerifier.sol";

contract LightAccount is BaseLightAccount {
    // 自定义错误
    error InvalidBLSSignature();
    error InvalidThreshold(uint256 threshold, uint256 nodeCount);
    error InvalidSignatureLength();

    // BLS验证器
    BLSVerifier public immutable blsVerifier;

    // BLS签名数据结构
    struct BLSSignatureData {
        uint256[2][] signatures;
        uint256[4][] pubkeys;
        uint256[2][] messages;
        uint256 threshold;
        uint256 nodeCount;
    }

    constructor(BLSVerifier _verifier) {
        blsVerifier = _verifier;
    }

    // BLS签名解析函数
    function _parseBLSSignatureData(bytes memory data) internal pure returns (BLSSignatureData memory blsData) {
        (blsData.signatures, blsData.pubkeys, blsData.messages, blsData.threshold, blsData.nodeCount) =
            abi.decode(data, (uint256[2][], uint256[4][], uint256[2][], uint256, uint256));

        _validateBLSData(blsData);
        return blsData;
    }

    // BLS数据验证
    function _validateBLSData(BLSSignatureData memory data) internal pure {
        if (data.pubkeys.length == 0 || data.messages.length == 0) {
            revert InvalidSignatureLength();
        }
        if (data.threshold > data.nodeCount || data.threshold == 0) {
            revert InvalidThreshold(data.threshold, data.nodeCount);
        }
    }

    // BLS签名验证
    function _isValidBLSSignature(BLSSignatureData memory blsData) internal view returns (bool) {
        return blsVerifier.verifyMultiple(blsData.signatures, blsData.pubkeys, blsData.messages);
    }

    // 重写validateUserOp以支持BLS验证
    function validateUserOp(PackedUserOperation calldata userOp, bytes32 userOpHash, uint256 missingAccountFunds)
        external
        override
        returns (uint256 validationData)
    {
        // 1. 首先验证BLS签名（如果存在）
        (, bytes memory signature3) = abi.decode(userOp.callData, (bytes, bytes));

        if (signature3.length > 0) {
            BLSSignatureData memory blsData = _parseBLSSignatureData(signature3);
            bool isValidBLS = _isValidBLSSignature(blsData);
            if (!isValidBLS) {
                revert InvalidBLSSignature();
            }
        }

        // 2. 然后验证常规签名
        validationData = _validateSignature(userOp, userOpHash);

        // 3. 验证和更新nonce
        _validateAndUpdateNonce(userOp);

        // 4. 处理预付款
        _payPrefund(missingAccountFunds);

        return validationData;
    }
}
