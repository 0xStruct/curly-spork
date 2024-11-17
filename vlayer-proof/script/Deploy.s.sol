// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script, console} from "forge-std/Script.sol";
import {Auction} from "../src/Auction.sol";
import {EmailProver} from "../src/vlayer/EmailProver.sol";
import {EmailProofVerifier} from "../src/vlayer/EmailProofVerifier.sol";

contract DeployScript is Script {
    Auction public auction;
    EmailProver public prover;
    EmailProofVerifier public verifier;

    function setUp() public {}

    function run() public {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");

        vm.startBroadcast(deployerPrivateKey);

        auction = new Auction(1); // royalty fee is 1%

        prover = new EmailProver();
        verifier = new EmailProofVerifier(address(this));

        vm.stopBroadcast();
    }
}
