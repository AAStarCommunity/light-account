// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import "forge-std/Script.sol";
import {BLSRegistry} from "../src/bls/BLSRegistry.sol";

contract Deploy_BLSRegistry is Script {
    function run() public returns (BLSRegistry registry) {
        vm.startBroadcast();
        registry = new BLSRegistry(address(0xd5cBad9f25ffF7571baBc413721BA983E35F62cd));
        vm.stopBroadcast();
    }
}
