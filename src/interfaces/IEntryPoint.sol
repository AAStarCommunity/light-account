// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.23;

struct PackedUserOperation {
    address sender;
    uint256 nonce;
    bytes callData;
    bytes signature;
} 