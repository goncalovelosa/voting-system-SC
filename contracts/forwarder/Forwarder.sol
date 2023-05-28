// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

import { IForwarder } from "../interfaces/IForwarder.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import { ECDSAUpgradeable } from "@openzeppelin/contracts-upgradeable/utils/cryptography/ECDSAUpgradeable.sol";
import { EIP712Upgradeable } from "@openzeppelin/contracts-upgradeable/utils/cryptography/EIP712Upgradeable.sol";

contract Forwarder is IForwarder, OwnableUpgradeable, EIP712Upgradeable {
    using ECDSAUpgradeable for bytes32;

    bytes32 private constant _FORWARDER_TYPEHASH =
        keccak256(
            "Forwarder(address from,address to,uint256 value,bytes data,uint256 nonce,uint256 gasPrice,uint256 gasLimit)"
        );

    mapping(address => uint256) private _nonces;
    address private _trustedSigner;

    /**
     * @notice Initializes the contract.
     * @dev This function should be called exactly once.
     * @param trustedSigner The address that is allowed to sign transactions on behalf of the forwarder.
     */
    function initialize(address trustedSigner) public initializer {
        __Ownable_init();
        __EIP712_init("Forwarder", "1");
        _trustedSigner = trustedSigner;
    }

    /**
     * @notice Forwards a transaction.
     * @dev The transaction must be signed by the trusted signer.
     * @param to The address the transaction is forwarded to.
     * @param value The amount of ETH to be forwarded.
     * @param data The data of the transaction.
     * @param gasPrice The gas price of the transaction.
     * @param gasLimit The gas limit of the transaction.
     * @param signature The signature of the transaction.
     */
    function forward(
        address to,
        uint256 value,
        bytes memory data,
        uint256 gasPrice,
        uint256 gasLimit,
        bytes memory signature
    ) public {
        require(_nonces[msg.sender] + 1 == _nonces[msg.sender], "Forwarder: nonce overflow");
        _nonces[msg.sender]++;

        bytes32 digest = _hashTypedDataV4(
            keccak256(
                abi.encode(
                    _FORWARDER_TYPEHASH,
                    msg.sender,
                    to,
                    value,
                    keccak256(data),
                    _nonces[msg.sender],
                    gasPrice,
                    gasLimit
                )
            )
        );

        address signer = ECDSAUpgradeable.recover(digest, signature);
        require(signer == _trustedSigner, "Forwarder: invalid signature");

        (bool success, ) = to.call{ value: value, gas: gasLimit }(data);

        require(success, "Forwarder: execution failed");

        emit Forwarded(msg.sender, to, value, data);
    }

    /**
     * @notice Forwards multiple transactions.
     * @dev The transactions must be signed by the trusted signer.
     * @param destinations Destination addresses
     * @param values The Value of the transaction.
     * @param data The data of the transaction.
     * @param gasPrice The gas price of the transaction.
     * @param gasLimit The gas limit of the transaction.
     * @param signatures The signatures of the transactions.
     */
    function batchForward(
        address[] memory destinations,
        uint256[] memory values,
        bytes[] memory data,
        uint256 gasPrice,
        uint256 gasLimit,
        bytes[] memory signatures
    ) public {
        require(
            destinations.length == values.length &&
                destinations.length == data.length &&
                destinations.length == signatures.length,
            "Forwarder: mismatched arrays"
        );

        for (uint256 i = 0; i < destinations.length; i++) {
            forward(destinations[i], values[i], data[i], gasPrice, gasLimit, signatures[i]);
        }

        emit BatchForwarded(msg.sender, destinations, values, data);
    }

    /**
     * @notice Gets the nonce of an account.
     * @param owner The address of the account that owns the nonce.
     * @return The nonce of the account.
     */
    function getNonce(address owner) public view returns (uint256) {
        return _nonces[owner];
    }

    /**
     * @notice Gets the trusted signer.
     * @return The trusted signer.
     */
    function getTrustedSigner() public view returns (address) {
        return _trustedSigner;
    }

    /**
     * @notice Sets the trusted signer.
     * @dev Only the owner can call this function.
     * @param trustedSigner The new trusted signer.
     */
    function setTrustedSigner(address trustedSigner) public onlyOwner {
        _trustedSigner = trustedSigner;
    }

    uint256[49] private __gap;
}
