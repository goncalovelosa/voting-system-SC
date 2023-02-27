// SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

import "../interfaces/IElection.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts/token/common/ERC2981.sol";

contract Election is IElection, PausableUpgradeable, AccessControlUpgradeable, ERC2981 {
    mapping(address => Voter) private voters;
    mapping(address => Candidate) private candidates;
    address[] private votersList;
    address[] private candidatesList;
    Period private votingPeriod;

    /**
     * @notice Initializes Election contract.
     * @dev Only called on initialization.
     */
    function initialize() public initializer {
        __Pausable_init();
        __AccessControl_init();
    }

    /**
     * @notice Registers a voter
     * @param _name The name of the voter
     * @param _id The id of the voter
     * @return True if the voter is registered
     */
    function registerVoter(string memory _name, string memory _id) public override whenNotPaused returns (bool) {
        require(voters[msg.sender].voted == false, "Voter already registered");
        voters[msg.sender] = Voter(_name, _id, false);
        votersList.push(msg.sender);
        emit VoterRegistered(msg.sender, _name, _id);
        return true;
    }

    /**
     * @notice Votes for a candidate
     * @param _candidateAddress The address of the candidate
     * @return True if the vote is casted
     */
    function vote(address _candidateAddress) public override whenNotPaused returns (bool) {
        require(voters[msg.sender].voted == false, "Voter already voted");
        require(candidates[_candidateAddress].votes > 0, "Candidate not registered");
        require(
            block.timestamp >= votingPeriod.start && block.timestamp <= votingPeriod.end,
            "Voting period not started or ended"
        );
        voters[msg.sender].voted = true;
        candidates[_candidateAddress].votes++;
        emit Voted(msg.sender, _candidateAddress);
        return true;
    }

    /**
     * @notice Registers a candidate
     * @param _name The name of the candidate
     * @param _candidateAddress The address of the candidate
     * @return True if the candidate is registered
     */
    function registerCandidate(
        string memory _name,
        address _candidateAddress
    ) public override whenNotPaused onlyRole(DEFAULT_ADMIN_ROLE) returns (bool) {
        require(candidates[_candidateAddress].votes == 0, "Candidate already registered");
        candidates[_candidateAddress] = Candidate(_name, 0);
        candidatesList.push(_candidateAddress);
        emit CandidateRegistered(_candidateAddress, _name);
        return true;
    }

    /**
     * @notice Gets the winner of the election
     * @return The address of the winner
     */
    function getWinner() public view override returns (address) {
        uint256 maxVotes = 0;
        address winner;
        for (uint256 i = 0; i < candidatesList.length; i++) {
            if (candidates[candidatesList[i]].votes > maxVotes) {
                maxVotes = candidates[candidatesList[i]].votes;
                winner = candidatesList[i];
            }
        }
        return winner;
    }

    /**
     * @notice Gets the voter
     * @param _voterAddress The address of the voter
     * @return The name of the voter
     * @return The id of the voter
     * @return True if the voter has voted
     */
    function getVoter(
        address _voterAddress
    ) public view override onlyRole(DEFAULT_ADMIN_ROLE) returns (string memory, string memory, bool) {
        return (voters[_voterAddress].name, voters[_voterAddress].id, voters[_voterAddress].voted);
    }

    /**
     * @notice Gets the candidate
     * @param _candidateAddress The address of the candidate
     * @return The name of the candidate
     * @return The number of votes of the candidate
     */
    function getCandidate(address _candidateAddress) public view override returns (string memory, uint256) {
        return (candidates[_candidateAddress].name, candidates[_candidateAddress].votes);
    }

    /**
     * @notice Gets the voters list
     * @return The list of voters
     */
    function getVoters() public view returns (address[] memory) {
        return votersList;
    }

    /**
     * @notice Gets the candidates list
     * @return The list of candidates
     */
    function getCandidates() public view returns (address[] memory) {
        return candidatesList;
    }

    /**
     * @notice Gets the number of voters
     * @return The number of voters
     */
    function getVoterCount() public view returns (uint256) {
        return votersList.length;
    }

    /**
     * @notice Gets the period of the election
     * @return The start of the period
     * @return The end of the period
     */
    function getVotingPeriod() public view returns (uint32, uint32) {
        return (votingPeriod.start, votingPeriod.end);
    }

    /**
     * @notice Sets the voting period
     */
    function setVotingPeriod(uint32 _start, uint32 _end) public onlyRole(DEFAULT_ADMIN_ROLE) {
        votingPeriod = Period(_start, _end);
        emit VotingPeriodSet(_start, _end);
    }

    function supportsInterface(
        bytes4 interfaceId
    ) public view virtual override(ERC2981, AccessControlUpgradeable) returns (bool) {
        return super.supportsInterface(interfaceId);
    }
}
