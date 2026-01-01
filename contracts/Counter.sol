// SPDX-License-Identifier: BSD-3-Clause-Clear

pragma solidity >=0.8.13 <0.9.0;

import {FHE, euint32} from "@luxfi/contracts/fhe/FHE.sol";
import {Euint32} from "@luxfi/contracts/fhe/IFHE.sol";

contract Counter {
    euint32 private counter;

    function add(Euint32 calldata encryptedValue) public {
        euint32 value = FHE.asEuint32(encryptedValue);
        counter = FHE.add(counter, value);
    }

    function getCounter(bytes32 sealingKey) public view returns (bytes memory) {
        return FHE.sealoutput(counter, sealingKey);
    }
}
