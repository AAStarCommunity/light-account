// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.23;

interface IBLSRegistry {
    function isRegistered(uint256 pointXC0, uint256 pointXC1) external view returns (bool);
}
