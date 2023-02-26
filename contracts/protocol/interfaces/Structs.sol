// SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

interface Structs {
    struct Candidate {
        string name;
        uint256 votes;
    }

    struct Voter {
        string name;
        string id;
        bool voted;
    }

    struct Period {
        uint32 start;
        uint32 end;
    }
}
