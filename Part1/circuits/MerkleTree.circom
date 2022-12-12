pragma circom 2.0.0;

include "../node_modules/circomlib/circuits/poseidon.circom";

template CheckRoot(n) { // compute the root of a MerkleTree of n Levels 
    signal input leaves[2**n];
    signal output root;
    signal levels[n-1][2**(n-1)];

    var numHashes = 0;
    for (var i = 0; i < n; i++){
        numHashes = 2**i + numHashes;
    }
    component hashes[numHashes];
    var hashNum = 0;

    for (var i = 0; i < 2**(n-1); i++) {
        hashes[hashNum] = Poseidon(2);
        hashes[hashNum].inputs[0] <== leaves[i * 2];
        hashes[hashNum].inputs[1] <== leaves[i * 2 + 1];
        levels[0][i] <== hashes[hashNum].out;
        hashNum++;
    }

    for (var level = 1; level < n-1; level++) {
        for (var i = 0; i < 2**level; i++) {
            hashes[hashNum] = Poseidon(2);
            hashes[hashNum].inputs[0] <== levels[level - 1][i * 2];
            hashes[hashNum].inputs[1] <== levels[level - 1][i * 2 + 1];
            levels[level][i] <== hashes[hashNum].out;
            hashNum++;
        }
    }

    root <== levels[0][0];
}

template DualMux() {
    signal input in[2];
    signal input s;
    signal output out[2];

    s * (1 - s) === 0;
    out[0] <== (in[1] - in[0])*s + in[0];
    out[1] <== (in[0] - in[1])*s + in[1];
}

template MerkleTreeInclusionProof(n) {
    signal input leaf;
    signal input path_elements[n];
    signal input path_index[n]; // path index are 0's and 1's indicating whether the current element is on the left or right

    signal output root; // note that this is an OUTPUT signal

    component selectors[n];
    component hashes[n];

    for (var i = 0; i < n; i++) {
        selectors[i] = DualMux();
        hashes[i] = Poseidon(2);

        selectors[i].in[0] <== i == 0 ? leaf : hashes[i-1].out;
        selectors[i].in[1] <== path_elements[i];
        selectors[i].s <== path_index[i];

        hashes[i].inputs[0] <== selectors[i].out[0];
        hashes[i].inputs[1] <== selectors[i].out[1];
    }

    root <== hashes[n-1].out;
}