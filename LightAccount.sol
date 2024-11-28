// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.23;

struct BLSSignatureData {
    uint256[2] signatures; // 建议改为数组以支持多签
    uint256[4][] pubkeys;
    uint256[2][] messages;
    uint256 threshold; // 需要补充阈值验证逻辑
    uint256 nodeCount; // 需要补充节点数验证
}

// 建议添加自定义错误
error InvalidBLSSignature();
error InvalidThreshold(uint256 threshold, uint256 nodeCount);
error InvalidSignatureLength();

contract LightAccount {
    function _parseBLSSignatureData(bytes memory data) internal pure returns (BLSSignatureData memory) {
        // 需要实现:
        // 1. 数据解析逻辑
        // 2. 基础验证(长度、格式等)
        // 3. 阈值与节点数合法性检查

        bool isValidBLS = true; /* todo your BLS validation logic here */

        if (!isValidBLS) {
            revert InvalidBLSSignature();
        }
    }

    function _validateBLSData(BLSSignatureData memory data) internal pure {
        if (data.pubkeys.length == 0 || data.messages.length == 0) {
            revert InvalidSignatureLength();
        }
        if (data.threshold > data.nodeCount || data.threshold == 0) {
            revert InvalidThreshold(data.threshold, data.nodeCount);
        }
        // 其他验证...
    }
}
