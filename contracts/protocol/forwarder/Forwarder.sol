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

    event Forwarded(address indexed sender, address indexed destination, uint256 value, bytes data);
    event BatchForwarded(address indexed sender, address[] destinations, uint256[] values, bytes[] data);

    function initialize(address trustedSigner) public initializer {
        __Ownable_init();
        __EIP712_init("Forwarder", "1");
        _trustedSigner = trustedSigner;
    }

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

    function getNonce(address owner) public view returns (uint256) {
        return _nonces[owner];
    }

    function getTrustedSigner() public view returns (address) {
        return _trustedSigner;
    }

    function setTrustedSigner(address trustedSigner) public onlyOwner {
        _trustedSigner = trustedSigner;
    }

    uint256[49] private __gap;
}
