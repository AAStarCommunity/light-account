// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.23;

import {VmSafe} from "forge-std/Vm.sol";
import {BLSRegistry} from "../src/bls/BLSRegistry.sol";

library BLSHelper {
    VmSafe private constant vm = VmSafe(address(uint160(uint256(keccak256("hevm cheat code")))));

    function getBLSSignature(address sender, uint256 nonce) internal returns (bytes memory) {
        string[] memory inputs = new string[](6);
        inputs[0] = "bun";
        inputs[1] = "utils/BLSSign.ts";
        inputs[2] = "--address";
        inputs[3] = vm.toString(sender);
        inputs[4] = "--nonce";
        inputs[5] = vm.toString(nonce);

        bytes memory res = vm.ffi(inputs);

        return res;
    }

    function registerTestPulicKey(BLSRegistry registry) internal {
        registry.register(
            10630432570328290075474895242881751387989826399304554704250628665511229896250,
            17919728752616097025742957864412478070508797791854890034433031155819908323326
        );
        registry.register(
            7923457841262153887818694354170419502510190132739652263382492550113386035750,
            14744381739708143910283300866271129128940794651715016181561776793987922846840
        );
        registry.register(
            5734872142314347555946597326801198097785165214411356306659781733612077075988,
            8124144815748970258249326101991928396393910934205196998518324073712081390059
        );
        registry.register(
            7344515471844562496833592570439087423691606487866241200702339208650050031251,
            18719158747223591214703618119136213788205087852441668101026299159805731586523
        );
        registry.register(
            13624594866677751148561899012969063359136741639257283892579852538744835597738,
            20450241552706401139685698169459532988425315298555861950717097377845759779915
        );
    }
}
