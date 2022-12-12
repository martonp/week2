//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import { PoseidonT3 } from "./Poseidon.sol"; //an existing library to perform Poseidon hash on solidity
import "./verifier.sol"; //inherits with the MerkleTreeInclusionProof verifier contract
import "hardhat/console.sol";

contract MerkleTree is Verifier {
    uint256[] public hashes; // the Merkle tree in flattened array form
    uint256 public index = 0; // the current index of the first unfilled leaf
    uint256 public root; // the current Merkle root

    constructor() {
        for (uint i = 0; i < 8; i++) {
            hashes.push(0);
        }

        uint count = 8;
        uint offset = 0;

        while (count > 0) {
            for (uint i = 0; i < count - 1; i+=2) {
                uint256[2] memory toHash = [hashes[offset + i], hashes[offset + i + 1]];
                hashes.push(PoseidonT3.poseidon(toHash));
            }
            offset = offset + count;
            count = count / 2;
        }
    }

    function insertLeaf(uint256 hashedLeaf) public returns (uint256) {
        hashes[index] = hashedLeaf;
        uint offset = 0;
        uint count = 8;
        uint256 previousIndex = index;

        console.log(hashes.length);
        while (count > 1) {
            console.log(previousIndex);
            uint256[2] memory toHash;
            if (previousIndex % 2 == 0) {
                toHash = [hashes[previousIndex], hashes[previousIndex + 1]];
            } else {
                toHash = [hashes[previousIndex - 1], hashes[previousIndex]];
            }
            previousIndex = offset + count + (previousIndex - offset) / 2;
            hashes[previousIndex] = PoseidonT3.poseidon(toHash);
            offset += count;
            count = count / 2;
        }

        index++;
        return hashes[14];
    }

    function verify(
            uint[2] memory a,
            uint[2][2] memory b,
            uint[2] memory c,
            uint[1] memory input
        ) public view returns (bool) {
            return Verifier.verifyProof(a, b, c, input);
    }
}
