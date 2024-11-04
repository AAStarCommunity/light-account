// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.23;

interface IBLSVerifier {
    function verifyMultiple(
        uint256[2][] memory signatures,
        uint256[4][] memory pubkeys,
        uint256[2][] memory messages
    ) external view returns (bool);
} 