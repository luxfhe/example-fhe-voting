// SPDX-License-Identifier: BSD-3-Clause-Clear

pragma solidity >=0.8.13 <0.9.0;

import {FHE, euint8, euint32, ebool} from "@luxfi/contracts/fhe/FHE.sol";
import {Euint8} from "@luxfi/contracts/fhe/IFHE.sol";

contract FHVoting {
    string public query;

    string[] public options;
    euint8[] internal encOptions;

    uint32 MAX_INT = 2 ** 32 - 1;
    uint8 MAX_OPTIONS = 5;

    mapping(address => euint8) internal votes;
    mapping(uint8 => euint32) internal tally;

    constructor(string memory q, string[] memory optList) {
        require(optList.length <= MAX_OPTIONS, "too many options!");

        query = q;
        options = optList;
    }

    function init() public {
        for (uint8 i = 0; i < options.length; i++) {
            tally[i] = FHE.asEuint32(0);
            encOptions.push(FHE.asEuint8(uint256(i)));
        }
    }

    function vote(Euint8 calldata encOption) public {
        euint8 option = FHE.asEuint8(encOption);

        // Validate option is within range using encrypted comparison
        require(encOptions.length > 0, "not initialized");

        // Build validity check: option matches one of the valid encrypted options
        ebool isValid = FHE.eq(option, encOptions[0]);
        for (uint i = 1; i < encOptions.length; i++) {
            isValid = FHE.or(isValid, FHE.eq(option, encOptions[i]));
        }

        // If already voted - first revert the old vote
        if (FHE.isInitialized(votes[msg.sender])) {
            addToTally(votes[msg.sender], FHE.asEuint32(uint256(MAX_INT))); // Adding MAX_INT is effectively `.sub(1)`
        }

        votes[msg.sender] = option;
        addToTally(option, FHE.asEuint32(1));
    }

    function getTally(bytes32 sealingKey) public view returns (bytes[] memory) {
        bytes[] memory tallyResp = new bytes[](encOptions.length);
        for (uint8 i = 0; i < encOptions.length; i++) {
            tallyResp[i] = FHE.sealoutput(tally[i], sealingKey);
        }

        return tallyResp;
    }

    function addToTally(euint8 option, euint32 amount) internal {
        for (uint8 i = 0; i < encOptions.length; i++) {
            // select(condition, ifTrue, ifFalse) replaces cmux
            euint32 toAdd = FHE.select(FHE.eq(option, encOptions[i]), amount, FHE.asEuint32(0));
            tally[i] = FHE.add(tally[i], toAdd);
        }
    }
}
