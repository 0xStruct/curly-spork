// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Strings} from "@openzeppelin-contracts-5.0.1/utils/Strings.sol";

import {Proof} from "vlayer-0.1.0/Proof.sol";
import {Prover} from "vlayer-0.1.0/Prover.sol";
import {RegexLib} from "vlayer-0.1.0/Regex.sol";
import {VerifiedEmail, UnverifiedEmail, EmailProofLib} from "vlayer-0.1.0/EmailProof.sol";

import {AddressParser} from "./utils/AddressParser.sol";

import {console} from "forge-std/console.sol";

interface IExample {
    function exampleFunction() external returns (uint256);
}

contract EmailProver is Prover {
    using Strings for string;
    using RegexLib for string;
    using AddressParser for string;
    using EmailProofLib for UnverifiedEmail;

    function main(UnverifiedEmail calldata unverifiedEmail) public view returns (Proof memory, address) {
        VerifiedEmail memory email = unverifiedEmail.verify();

        string[] memory captures = email.subject.capture("^PUSH DOMAIN CONFIRMATION EMAIL \\- Namecheap\\.com$");
        require(captures.length == 1, "subject must match the expected pattern");
        require(email.from.matches("^.*@namecheap.com$"), "from must be a namecheap address");

        // check email body

        // Push to Login ID:  <username>/n
        string[] memory username_captures = email.body.capture(
            "^((.|\n)*)Push to Login ID:  ([a-zA-Z0-9]+)((.|\n)*)$");
        
        require(username_captures.length > 3, "invalid body");
        require(keccak256(abi.encodePacked(username_captures[3])) == keccak256("struct88"), "invalid username");

        // These changes apply to the following domain(s):/n<domain.com>
        string[] memory domain_captures = email.body.capture(
            "^((.|\n)*)\n([a-zA-Z0-9][a-zA-Z0-9-]{0,61}[a-zA-Z0-9](?:\\.[a-zA-Z]{2,})+)((.|\n)*)$");

        require(domain_captures.length > 3, "invalid body");
        require(keccak256(abi.encodePacked(domain_captures[3])) == keccak256("seesaw.network"), "invalid domain");
        

        // return (proof(), captures[1].parseAddress());
        return (proof(), msg.sender);
    }  
}
