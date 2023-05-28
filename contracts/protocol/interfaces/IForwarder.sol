// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

interface IForwarder {
    function forward(
        address to,
        uint256 value,
        bytes calldata data,
        uint256 gasPrice,
        uint256 gasLimit,
        bytes calldata signature
    ) external;

    function batchForward(
        address[] calldata destinations,
        uint256[] calldata values,
        bytes[] calldata data,
        uint256 gasPrice,
        uint256 gasLimit,
        bytes[] calldata signatures
    ) external;

    function getNonce(address owner) external view returns (uint256);

    function getTrustedSigner() external view returns (address);

    function setTrustedSigner(address trustedSigner) external;
}
