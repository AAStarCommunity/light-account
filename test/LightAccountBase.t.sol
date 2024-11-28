// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.23;

import "forge-std/Test.sol";
import {BaseLightAccountTest} from "./base/BaseLightAccountTest.sol";

contract LightAccountBaseTest is BaseLightAccountTest {
    function setUp() public override {
        super.setUp();
    }

    function testExecuteCanBeCalledByOwner() public {
        vm.prank(eoaAddress);
        account.execute(address(0x1), 0, "");
    }

    // [其他原有功能测试...]
}
