// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Proxy {
    bytes32 private constant _OWNER_SLOT = 0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103;
    bytes32 private constant _IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;

    event Upgraded(address indexed implementation);

    constructor(address _adminAddress) {
        bytes32 slot = _OWNER_SLOT;
        address adminAddress = _adminAddress;
        assembly {
            sstore(slot, adminAddress)
        }
    }

    function admin() public view returns (address owner) {
        bytes32 slot = _OWNER_SLOT;
        assembly {
            owner := sload(slot)
        }
    }

    function implementation() public view returns (address logicAddress) {
        bytes32 slot = _IMPLEMENTATION_SLOT;
        assembly {
            logicAddress := sload(slot)
        }
    }

    function setAdmin(address _adminAddress) external {
        require(msg.sender == admin(), "Only admin allowed");
        bytes32 slot = _OWNER_SLOT;
        address adminAddress = _adminAddress;
        assembly {
            sstore(slot, adminAddress)
        }
    }

    function upgrade(address logicAddress) external {
        require(msg.sender == admin(), "Only admin allowed");
        bytes32 slot = _IMPLEMENTATION_SLOT;
        assembly {
            sstore(slot, logicAddress)
        }
        emit Upgraded(logicAddress);
    }

    receive() external payable {}

    fallback() external payable {
        assembly {
            let ptr := mload(0x40)
            calldatacopy(ptr, 0, calldatasize())

            let result := delegatecall(gas(), sload(_IMPLEMENTATION_SLOT), ptr, calldatasize(), 0, 0)
            let size := returndatasize()
            returndatacopy(ptr, 0, size)

            switch result
            case 0 {
                revert(ptr, size)
            }
            default {
                return(ptr, size)
            }
        }
    }
}
