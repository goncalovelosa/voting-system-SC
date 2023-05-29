// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

import { IAccessControlUpgradeable } from "@openzeppelin/contracts-upgradeable/access/IAccessControlUpgradeable.sol";

struct ForwardRequest {
    address from;
    address to;
    uint256 value;
    bytes data;
    uint256 nonce;
}

struct BatchForwardRequest {
    ForwardRequest request;
    bytes signature;
}

interface IForwarder is IAccessControlUpgradeable {
    function forward(ForwardRequest calldata request, bytes calldata signature) external;

    function batchForward(BatchForwardRequest[] calldata batchRequests) external;

    function addOperator(address newOperator) external;

    function removeOperator(address operatorToRemove) external;

    function getNonce(address sender) external view returns (uint256);

    event Forwarded(address indexed sender, address indexed destination, uint256 value, bytes data, uint256 nonce);
}
