// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.23;

import {Ownable2Step} from "@openzeppelin/contracts/access/Ownable2Step.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {IBLSRegistry} from "./IBLSRegistry.sol";

contract BLSRegistry is Ownable2Step, IBLSRegistry {
    mapping(uint256 pointXC0 => mapping(uint256 pointXC1 => bool)) public isRegistered;

    constructor(address initialOwner) Ownable(initialOwner) {}

    function register(uint256 pointXC0, uint256 pointXC1) external onlyOwner {
        isRegistered[pointXC0][pointXC1] = true;
    }

    function unregister(uint256 pointXC0, uint256 pointXC1) external onlyOwner {
        isRegistered[pointXC0][pointXC1] = false;
    }
}
