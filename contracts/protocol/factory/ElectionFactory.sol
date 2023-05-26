// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

import { ERC2771Context, Context } from "@openzeppelin/contracts/metatx/ERC2771Context.sol";
import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { Clones } from "@openzeppelin/contracts/proxy/Clones.sol";
import "../ElectionStructs.sol";
import "../election/Election.sol";
import "../interfaces/IElection.sol";
import "../interfaces/IElectionsFactory.sol";

contract ElectionFactory is IElectionsFactory, Ownable, ERC2771Context {
    address[] public elections;
    address public electionImplementation;

    constructor(address _trustedForwarder) ERC2771Context(_trustedForwarder) {
        electionImplementation = address(new Election(_trustedForwarder));
    }

    /**
     * @notice Creates a new election
     * @dev Only the owner can call this function
     * @param _initData The data to initialize the election
     * @return The address of the created election
     */
    function createElection(ElectionStructs.ElectionInitData calldata _initData) external onlyOwner returns (address) {
        address election = Clones.clone(electionImplementation);
        IElection(election).initialize(_initData);

        elections.push(election);

        emit ElectionCreated(
            election,
            _msgSender(),
            electionImplementation,
            _initData.campainManagers,
            _initData.votingManagers,
            _initData.start,
            _initData.end
        );

        return election;
    }

    /**
     * @notice Returns the number of elections
     * @dev Only the owner can call this function
     * @param _electionImplementation The address of the election implementation
     */
    function setElectionImplementation(address _electionImplementation) external onlyOwner {
        electionImplementation = _electionImplementation;
    }

    function _msgSender() internal view override(ERC2771Context, Context) returns (address) {
        return ERC2771Context._msgSender();
    }

    function _msgData() internal view override(ERC2771Context, Context) returns (bytes calldata) {
        return ERC2771Context._msgData();
    }
}
