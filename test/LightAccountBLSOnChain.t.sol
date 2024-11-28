// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.23;

import "forge-std/Test.sol";
import {BaseLightAccountTest} from "./base/BaseLightAccountTest.sol";
import {BLSVerifier} from "../src/BLSVerifier.sol";
import {LightSwitch} from "../src/LightSwitch.sol";
import {PackedUserOperation} from "account-abstraction/interfaces/PackedUserOperation.sol";
import {BaseLightAccount} from "../src/common/BaseLightAccount.sol";

contract LightAccountBLSOnChainTest is BaseLightAccountTest {
    // string private EOA_PRIVATE_KEY;
    LightSwitch public lightSwitch;

    function setUp() public override {
        EOA_PRIVATE_KEY = vm.envString("EOA_PRIVATE_KEY");
        super.setUp();
        // 使用纯EVM模式部署验证器
        BLSVerifier verifier = new BLSVerifier(BLSVerifier.VerifyMode.PURE_EVM);
        account = createAccount(verifier);
        lightSwitch = new LightSwitch();
    }

    function testOnChainBLSValidation() public {
        PackedUserOperation memory op = _getUnsignedOp(
            abi.encodeCall(BaseLightAccount.execute, (address(lightSwitch), 0, abi.encodeCall(LightSwitch.turnOn, ())))
        );

        bytes memory blsSignature = _mockOnChainBLSData();
        op.callData = abi.encode(op.callData, blsSignature);

        // Correcting the signature assignment by using the correct function to sign the message
        op.signature = abi.encodePacked(
            BaseLightAccount.SignatureType.EOA,
            vm.sign(EOA_PRIVATE_KEY, entryPoint.getUserOpHash(op).toEthSignedMessageHash())
        );

        // Creating an array of PackedUserOperation to hold the operation
        PackedUserOperation[] memory ops = new PackedUserOperation[](1);
        // Assigning the operation to the first element of the array
        ops[0] = op;

        entryPoint.handleOps(ops, BENEFICIARY);
        assertTrue(lightSwitch.on());
    }

    function _mockOnChainBLSData() internal pure returns (bytes memory) {
        // 创建链上验证的测试数据
        uint256[2][] memory signatures = new uint256[2][](1);
        signatures[0] = [uint256(1), uint256(2)];

        uint256[4][] memory pubkeys = new uint256[4][](1);
        pubkeys[0] = [uint256(1), uint256(2), uint256(3), uint256(4)];

        uint256[2][] memory messages = new uint256[2][](1);
        messages[0] = [uint256(1), uint256(2)];

        return abi.encode(signatures, pubkeys, messages, uint256(1), uint256(1));
    }

    function _getUnsignedOp(bytes memory callData) internal view returns (PackedUserOperation memory) {
        return PackedUserOperation({
            sender: address(account),
            nonce: 0,
            initCode: "",
            callData: callData,
            accountGasLimits: bytes32(0),
            preVerificationGas: 0,
            gasFees: bytes32(0),
            paymasterAndData: "",
            signature: ""
        });
    }
}
