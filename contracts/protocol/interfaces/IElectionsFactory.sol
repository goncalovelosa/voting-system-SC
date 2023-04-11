// SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

import { Structs } from "./Structs.sol";

interface IElectionsFactory {
    function createElection(Structs.ElectionInitData calldata _initData) external returns (address);

    function setElectionImplementation(address _electionImplementation) external;

    function electionImplementation() external view returns (address);

    event ElectionCreated(
        address indexed election,
        address indexed owner,
        address electionImplementation,
        address[] campainManagers,
        address[] votingManagers,
        uint32 start,
        uint32 end
    );
}
