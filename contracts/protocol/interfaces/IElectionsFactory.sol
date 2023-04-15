// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

import { ElectionStructs } from "./ElectionStructs.sol";

interface IElectionsFactory {
    function createElection(ElectionStructs.ElectionInitData calldata _initData) external returns (address);

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
