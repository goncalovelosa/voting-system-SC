// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

struct ForwardRequest {
    address from;
    address to;
    uint256 value;
    bytes data;
    uint256 nonce;
}

struct BatchForwardRequest {
    ForwardRequest[] requests;
    bytes signature;
}

interface IForwarder {
    function forward(ForwardRequest calldata req, bytes calldata signature) external;

    function batchForward(BatchForwardRequest calldata req) external;

    function getNonce(address owner) external view returns (uint256);

    event Forwarded(address indexed sender, address indexed destination, uint256 value, bytes data);
}
