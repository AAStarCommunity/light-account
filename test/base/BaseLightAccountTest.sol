// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.23;

import "forge-std/Test.sol";
import {LightAccount} from "../../src/LightAccount.sol";
import {BLSVerifier} from "../../src/BLSVerifier.sol";
import {EntryPoint} from "account-abstraction/core/EntryPoint.sol";

abstract contract BaseLightAccountTest is Test {
    uint256 public constant EOA_PRIVATE_KEY = 1;
    address payable public constant BENEFICIARY = payable(address(0xbe9ef1c1a2ee));
    
    address public eoaAddress;
    LightAccount public account;
    EntryPoint public entryPoint;
    LightSwitch public lightSwitch;
    
    function setUp() public virtual {
        eoaAddress = vm.addr(EOA_PRIVATE_KEY);
        entryPoint = new EntryPoint();
        lightSwitch = new LightSwitch();
    }
    
    function createAccount(BLSVerifier verifier) internal returns (LightAccount) {
        LightAccount newAccount = new LightAccount(verifier);
        vm.deal(address(newAccount), 1 << 128);
        return newAccount;
    }

    // [共用的辅助函数...]
}

contract LightSwitch {
    bool public on;
    function turnOn() external payable {
        on = true;
    }
} 