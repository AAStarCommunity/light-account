// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.23;

import "forge-std/Test.sol";
import {BaseLightAccountTest} from "./base/BaseLightAccountTest.sol";
import {LightSwitch} from "../src/LightSwitch.sol";

contract LightAccountBaseTest is BaseLightAccountTest {
    function setUp() public override {
        super.setUp();
    }

    function testExecuteCanBeCalledByOwner() public {
        vm.prank(eoaAddress);
        account.execute(address(lightSwitch), 0, abi.encodeCall(LightSwitch.turnOn, ()));
        assertTrue(lightSwitch.on());
    }

    // [其他原有功能测试...]
}
