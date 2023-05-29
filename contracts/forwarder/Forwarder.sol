// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

import { AccessControlUpgradeable } from "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import { IForwarder, ForwardRequest, BatchForwardRequest } from "../interfaces/IForwarder.sol";
import { Initializable } from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import { ECDSAUpgradeable } from "@openzeppelin/contracts-upgradeable/utils/cryptography/ECDSAUpgradeable.sol";
import { EIP712Upgradeable } from "@openzeppelin/contracts-upgradeable/utils/cryptography/EIP712Upgradeable.sol";
import { UUPSUpgradeable } from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import { SafeMathUpgradeable as SafeMath } from "@openzeppelin/contracts-upgradeable/utils/math/SafeMathUpgradeable.sol";
import { ReentrancyGuardUpgradeable } from "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";

contract Forwarder is
    Initializable,
    IForwarder,
    AccessControlUpgradeable,
    ReentrancyGuardUpgradeable,
    EIP712Upgradeable,
    UUPSUpgradeable
{
    using ECDSAUpgradeable for bytes32;
    using SafeMath for uint256;

    bytes32 private constant _FORWARD_REQUEST_TYPEHASH =
        keccak256("ForwardRequest(address from,address to,uint256 value,bytes data,uint256 nonce)");
    bytes32 private constant _OPERATOR_ROLE = keccak256("OPERATOR_ROLE");

    mapping(address => uint256) private _nonces;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(_OPERATOR_ROLE, msg.sender);
        _disableInitializers();
    }

    /**
     * @notice Initializes the contract.
     * @dev This function should be called exactly once.
     */
    function initialize() public initializer {
        __EIP712_init("Forwarder", "1");
        __AccessControl_init();
        __UUPSUpgradeable_init();
        __ReentrancyGuard_init();
    }

    /**
     * @notice Forwards a transaction.
     * @dev The transaction must be signed by the trusted signer.
     * @param request The request to forward.
     */
    function forward(ForwardRequest calldata request, bytes calldata signature) external override nonReentrant {
        // Verify that the caller has the operator or sender role
        require(hasRole(_OPERATOR_ROLE, msg.sender) || request.from == msg.sender, "Forwarder: sender unauthorized");
        // Verify the nonce
        require(_nonces[request.from] == request.nonce, "Forwarder: invalid nonce");

        bytes32 digest = _hashTypedDataV4(
            keccak256(
                abi.encode(
                    _FORWARD_REQUEST_TYPEHASH,
                    request.from,
                    request.to,
                    request.value,
                    keccak256(request.data),
                    request.nonce
                )
            )
        );

        address signer = ECDSAUpgradeable.recover(digest, signature);
        require(signer == request.from, "Forwarder: invalid signature");

        // Update sender nonce
        _nonces[request.from] = _nonces[request.from].add(1);

        (bool success, ) = request.to.call{ value: request.value }(request.data);

        require(success, "Forwarder: execution failed");

        emit Forwarded(msg.sender, request.to, request.value, request.data, request.nonce);
    }

    /**
     * @notice Forwards multiple transactions.
     * @dev The transactions must be signed by the trusted signer.
     */
    function batchForward(BatchForwardRequest[] calldata batchRequests) external override nonReentrant {
        for (uint256 i = 0; i < batchRequests.length; i++) {
            this.forward(batchRequests[i].request, batchRequests[i].signature);
        }
    }

    /**
     * @notice Adds a new operator.
     * @dev The caller must have the admin role.
     * @param newOperator The address of the new operator.
     */
    function addOperator(address newOperator) external onlyRole(DEFAULT_ADMIN_ROLE) {
        grantRole(_OPERATOR_ROLE, newOperator);
    }

    /**
     * @notice Removes an operator.
     * @dev The caller must have the admin role.
     * @param operatorToRemove The address of the operator to remove.
     */
    function removeOperator(address operatorToRemove) external onlyRole(DEFAULT_ADMIN_ROLE) {
        revokeRole(_OPERATOR_ROLE, operatorToRemove);
    }

    /**
     * @notice Gets the nonce of the forwarder for a given address.
     * @param sender The address of the sender.
     * @return The nonce of the forwarder for the given address.
     */
    function getNonce(address sender) public view returns (uint256) {
        return _nonces[sender];
    }

    /**
     * @notice Upgrades the implementation of the contract.
     * @dev This function can only be called by an admin.
     * @param newImplementation The address of the new implementation.
     */
    function _authorizeUpgrade(address newImplementation) internal override onlyRole(DEFAULT_ADMIN_ROLE) {}

    uint256[49] private __gap;
}
