// SPDX-License-Identifier: MIT

import "./BridgeCore.sol";

pragma solidity ^0.8.0;

contract Bridge is BridgeCore {
    function contractType() external pure returns (bytes32) {
        return bytes32("Bridge");
    }

    function contractVersion() external pure returns (uint8) {
        return uint8(1);
    }
}
