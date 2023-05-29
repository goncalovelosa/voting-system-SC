// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import { IAccessControlUpgradeable } from "@openzeppelin/contracts-upgradeable/access/IAccessControlUpgradeable.sol";

import { ElectionStructs } from "../ElectionStructs.sol";

interface IElection is ElectionStructs, IAccessControlUpgradeable {
    /**
     * @notice Emitted when a voter is registered
     */
    event VoterRegistered(address _voterAddress, string _name, string _id);
    /**
     * @notice Emitted when a candidate is registered
     */
    event CandidateRegistered(address _candidateAddress, string _name);
    /**
     * @notice Emitted when a voter votes
     */
    event Voted(address _voterAddress, address _candidateAddress);
    /**
     * @notice Emitted when the voting period is set
     */
    event VotingPeriodSet(uint32 _start, uint32 _end);

    /**
     * @notice Initializes the election
     * @param _initData The init data
     */
    function initialize(ElectionInitData calldata _initData) external;

    /**
     * @notice Registers a voter
     * @param _name The name of the voter
     * @param _id The id of the voter
     * @return True if the voter is registered
     */
    function registerVoter(string memory _name, string memory _id) external returns (bool);

    /**
     * @notice Votes for a candidate
     * @param _candidateAddress The address of the candidate
     * @return True if the vote is casted
     */
    function vote(address _candidateAddress) external returns (bool);

    /**
     * @notice Registers a candidate
     * @param _name The name of the candidate
     * @param _candidateAddress The address of the candidate
     * @return True if the candidate is registered
     */
    function registerCandidate(string memory _name, address _candidateAddress) external returns (bool);

    /**
     * @notice Gets the winner of the election
     * @return The address of the winner
     */
    function getWinner() external view returns (address);

    /**
     * @notice Gets the voter
     * @param _voterAddress The address of the voter
     * @return The name, id and if the voter voted
     */
    function getVoter(address _voterAddress) external view returns (string memory, string memory, bool);

    /**
     * @notice Gets the candidate
     * @param _candidateAddress The address of the candidate
     * @return The name and the votes of the candidate
     */
    function getCandidate(address _candidateAddress) external view returns (string memory, uint256);

    /**
     * @notice Gets the voters
     * @return The list of voters
     */
    function getVoters() external view returns (address[] memory);

    /**
     * @notice Gets the candidates
     * @return The list of candidates
     */
    function getCandidates() external view returns (address[] memory);

    /**
     * @notice Gets the voter count
     * @return The number of voters
     */
    function getVoterCount() external view returns (uint256);

    /**
     * @notice Gets the candidate count
     * @return The number of candidates
     */
    function getVotingPeriod() external view returns (uint32, uint32);

    /**
     * @notice Sets the voting period
     * @param _start The start of the voting period
     * @param _end The end of the voting period
     */
    function setVotingPeriod(uint32 _start, uint32 _end) external;

    function isTrustedForwarder(address forwarder) external view returns (bool);
}
