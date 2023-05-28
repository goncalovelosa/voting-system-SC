// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

import { IForwarder, ForwardRequest, BatchForwardRequest } from "../interfaces/IForwarder.sol";
import { Initializable } from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import { OwnableUpgradeable } from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import { ECDSAUpgradeable } from "@openzeppelin/contracts-upgradeable/utils/cryptography/ECDSAUpgradeable.sol";
import { EIP712Upgradeable } from "@openzeppelin/contracts-upgradeable/utils/cryptography/EIP712Upgradeable.sol";

import { UUPSUpgradeable } from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";

contract Forwarder is IForwarder, Initializable, OwnableUpgradeable, EIP712Upgradeable, UUPSUpgradeable {
    using ECDSAUpgradeable for bytes32;

    bytes32 private constant _FORWARDER_TYPEHASH =
        keccak256("Forwarder(address from,address to,uint256 value,bytes data,uint256 nonce)");

    mapping(address => uint256) private _nonces;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    /**
     * @notice Initializes the contract.
     * @dev This function should be called exactly once.
     */
    function initialize() public initializer {
        __Ownable_init();
        __UUPSUpgradeable_init();
        __EIP712_init("Forwarder", "1");
    }

    /**
     * @notice Forwards a transaction.
     * @dev The transaction must be signed by the trusted signer.
     * @param request The request to forward.
     */
    function forward(ForwardRequest calldata request, bytes calldata signature) public {
        bytes32 digest = _hashTypedDataV4(
            keccak256(
                abi.encode(
                    _FORWARDER_TYPEHASH,
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

        (bool success, ) = request.to.call{ value: request.value }(request.data);

        require(success, "Forwarder: execution failed");

        emit Forwarded(msg.sender, request.to, request.value, request.data);
    }

    /**
     * @notice Forwards multiple transactions.
     * @dev The transactions must be signed by the trusted signer.
     */
    function batchForward(BatchForwardRequest calldata batchRequests) public {
        for (uint256 i = 0; i < batchRequests.requests.length; i++) {
            forward(batchRequests.requests[i], batchRequests.signature);
        }
    }

    /**
     * @notice Gets the nonce of an account.
     * @param owner The address of the account that owns the nonce.
     * @return The nonce of the account.
     */
    function getNonce(address owner) public view returns (uint256) {
        return _nonces[owner];
    }

    uint256[49] private __gap;

    function _authorizeUpgrade(address newImplementation) internal virtual override onlyOwner {}
}
