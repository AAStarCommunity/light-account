// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.23;

import {Test} from "forge-std/Test.sol";
import {BLS} from "../src/bls/BLS.sol";
import {BNPairingPrecompileCostEstimator} from "../src/bls/BNPairingPrecompileCostEstimator.sol";

contract TestBLS is Test {
    function testVerifySingle() public {
        uint256[2] memory signature;
        uint256[4] memory pubkey;
        uint256[2] memory message;

        signature[0] = 19905630207993566245219666677470637136587276019280656805026541833712249905852;
        signature[1] = 1019189277969543190112841909500249566962431416979225378272584036265439876939;
        message[0] = 16685283042278012095840917007996570717923989086424752750999740044674504414203;
        message[1] = 17788878714869107539255171751663809100328787430446550666907776742050292520891;
        pubkey[0] = 7137159607728178943737672879875201623317467957024905555599425697670759935618;
        pubkey[1] = 19412475625440450891342354126621544866181621154319311417682545180853231206345;
        pubkey[2] = 8507678276313774205947275247764216452821138396833793566590313090844458645479;
        pubkey[3] = 10705526904121183264899980621452804686517808992713226650268180015925185892875;

        (bool verified) = BLS.verifySingle(signature, pubkey, message);
        assertTrue(verified);
    }

    function testVerifyMultiple() public {
        uint256[2] memory signature;
        uint256[4][] memory pubkeys = new uint256[4][](2);
        uint256[2] memory message;

        signature[0] = 11982053741765309869614975650436408414480409414655419755381077188147272345557;
        signature[1] = 19628369590794600556363978835724503528200396810903557895605093589224886490819;
        message[0] = 5658683324832764476960154803703557922686354701530098027155484514076392516128;
        message[1] = 16071338799424213680761462003332656615827825997241749078141033608856239696693;
        pubkeys[0][0] = 3721969910755263118863758916660256898669206418175294296393207140516337555991;
        pubkeys[0][1] = 20569362456432828041276639280360333077158697337274262703710927105933617528203;
        pubkeys[0][2] = 1781060503439844184823416248464134409592625987585608226511453958645785327900;
        pubkeys[0][3] = 4131432457551112374708891326516360065371739638782126304588500384798791330677;
        pubkeys[1][0] = 516947159203562106368502607454719216444973161961335776825510692988935639691;
        pubkeys[1][1] = 12252239579865661806991100547229389871127513667923965331895602520575515760028;
        pubkeys[1][2] = 9873397751163904057986467315461167894899002621173631304906039191738079257173;
        pubkeys[1][3] = 8672224877889847028316140878566877035079221330884430711148074915759574884527;

        (bool verified) = BLS.verifyMultiple(signature, pubkeys, message);
        assertTrue(verified);
    }
}
