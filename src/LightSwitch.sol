// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.23;

contract LightSwitch {
    bool public on;

    function turnOn() external payable {
        on = true;
    }
} 