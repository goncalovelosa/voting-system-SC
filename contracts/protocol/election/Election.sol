// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

import "../interfaces/IElection.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import { ERC2771ContextUpgradeable, ContextUpgradeable } from "@openzeppelin/contracts-upgradeable/metatx/ERC2771ContextUpgradeable.sol";

contract Election is IElection, ERC2771ContextUpgradeable, PausableUpgradeable, AccessControlUpgradeable {
    mapping(address => Voter) private voters;
    mapping(address => Candidate) private candidates;
    address[] private votersList;
    address[] private candidatesList;
    Period private votingPeriod;

    bytes32 public constant CAMPAIN_MANAGER = keccak256("CAMPAIN_MANAGER");
    bytes32 public constant VOTING_MANAGER = keccak256("VOTING_MANAGER");

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor(address _trustedForwarder) ERC2771ContextUpgradeable(_trustedForwarder) {
        _disableInitializers();
    }

    /**
     * @notice Initializes Election contract.
     * @dev Only called on initialization.
     */
    function initialize(ElectionInitData calldata _initData) external initializer {
        __Pausable_init();
        __AccessControl_init();
        _grantRole(DEFAULT_ADMIN_ROLE, _msgSender());

        _setRoleAdmin(VOTING_MANAGER, CAMPAIN_MANAGER);
        require(_initData.campainManagers.length > 0, "At least one campain manager is required");
        for (uint256 i = 0; i < _initData.campainManagers.length; i++) {
            _grantRole(CAMPAIN_MANAGER, _initData.campainManagers[i]);
        }
        require(_initData.votingManagers.length > 0, "At least one voting manager is required");
        for (uint256 i = 0; i < _initData.votingManagers.length; i++) {
            _grantRole(VOTING_MANAGER, _initData.votingManagers[i]);
        }
        require(_initData.start < _initData.end, "Start date must be before end date");
        _setVotingPeriod(_initData.start, _initData.end);
    }

    /**
     * @notice Sets the voting period
     * @dev Only the campain manager can call this function
     * @param _start The start of the voting period
     * @param _end The end of the voting period
     */
    function setVotingPeriod(uint32 _start, uint32 _end) external onlyRole(CAMPAIN_MANAGER) {
        _setVotingPeriod(_start, _end);
    }

    /**
     * @notice Registers a voter
     * @param _name The name of the voter
     * @param _id The id of the voter
     * @return True if the voter is registered
     */
    function registerVoter(
        string memory _name,
        string memory _id
    ) external override onlyRole(VOTING_MANAGER) whenNotPaused returns (bool) {
        require(voters[_msgSender()].voted == false, "Voter already registered");
        require(bytes(_name).length > 0, "Voter name cannot be empty");
        require(bytes(_id).length > 0, "Voter id cannot be empty");
        voters[_msgSender()] = Voter(_name, _id, false);
        votersList.push(_msgSender());
        emit VoterRegistered(_msgSender(), _name, _id);
        return true;
    }

    /**
     * @notice Votes for a candidate
     * @dev Can only vote if not paused
     * @param _candidateAddress The address of the candidate
     * @return True if the vote is casted
     */
    function vote(address _candidateAddress) external override whenNotPaused returns (bool) {
        require(voters[_msgSender()].voted == false, "Voter already voted");
        require(candidates[_candidateAddress].votes > 0, "Candidate not registered");
        require(
            votingPeriod.start < block.timestamp && votingPeriod.end > block.timestamp,
            "Voting period not started or ended"
        );
        voters[_msgSender()].voted = true;
        candidates[_candidateAddress].votes++;
        emit Voted(_msgSender(), _candidateAddress);
        return true;
    }

    /**
     * @notice Registers a candidate
     * @dev Only the campain manager can call this function
     * @param _name The name of the candidate
     * @param _candidateAddress The address of the candidate
     * @return True if the candidate is registered
     */
    function registerCandidate(
        string memory _name,
        address _candidateAddress
    ) external override whenNotPaused onlyRole(CAMPAIN_MANAGER) returns (bool) {
        require(candidates[_candidateAddress].votes == 0, "Candidate already registered");
        require(_candidateAddress != address(0), "Candidate address cannot be 0");
        require(bytes(_name).length > 0, "Candidate name cannot be empty");
        require(block.timestamp < votingPeriod.start, "Voting period already started");
        candidates[_candidateAddress] = Candidate(_name, 0);
        candidatesList.push(_candidateAddress);
        emit CandidateRegistered(_candidateAddress, _name);
        return true;
    }

    /**
     * @notice Gets the winner of the election
     * @return winner The address of the winner
     */
    function getWinner() public view override returns (address winner) {
        uint256 maxVotes = 0;
        for (uint256 i = 0; i < candidatesList.length; i++) {
            if (candidates[candidatesList[i]].votes > maxVotes) {
                maxVotes = candidates[candidatesList[i]].votes;
                winner = candidatesList[i];
            }
        }
    }

    /**
     * @notice Gets the voter
     * @dev Only the campain manager can call this function
     * @param _voterAddress The address of the voter
     * @return The name of the voter
     * @return The id of the voter
     * @return True if the voter has voted
     */
    function getVoter(
        address _voterAddress
    ) public view override onlyRole(CAMPAIN_MANAGER) returns (string memory, string memory, bool) {
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
     * @dev Only the campain manager can call this function
     * @return The list of voters
     */
    function getVoters() public view onlyRole(CAMPAIN_MANAGER) returns (address[] memory) {
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
     * @dev Only the campain manager can call this function
     * @return The number of voters
     */
    function getVoterCount() public view onlyRole(CAMPAIN_MANAGER) returns (uint256) {
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

    function supportsInterface(
        bytes4 interfaceId
    ) public view virtual override(AccessControlUpgradeable) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    function isTrustedForwarder(
        address forwarder
    ) public view virtual override(IElection, ERC2771ContextUpgradeable) returns (bool) {
        return ERC2771ContextUpgradeable.isTrustedForwarder(forwarder);
    }

    function _setVotingPeriod(uint32 _start, uint32 _end) internal {
        votingPeriod = Period(_start, _end);
        emit VotingPeriodSet(_start, _end);
    }

    function _msgSender() internal view override(ERC2771ContextUpgradeable, ContextUpgradeable) returns (address) {
        return ERC2771ContextUpgradeable._msgSender();
    }

    function _msgData() internal view override(ERC2771ContextUpgradeable, ContextUpgradeable) returns (bytes calldata) {
        return ERC2771ContextUpgradeable._msgData();
    }
}
