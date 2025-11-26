// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import "@thirdweb-dev/contracts/extension/PermissionsEnumerable.sol";
import "@thirdweb-dev/contracts/extension/Multicall.sol";
import "@thirdweb-dev/contracts/extension/ContractMetadata.sol";

contract NativeTokenMultiSend is PermissionsEnumerable, Multicall, ContractMetadata {
    address public deployer;

    event TokensDistributed(
        address[] recipients, 
        uint256 totalAmount, 
        uint256 timestamp
    );
    
    event TokensDistributedVaried(
        address[] recipients, 
        uint256[] amounts, 
        uint256 totalAmount, 
        uint256 timestamp
    );

    constructor(string memory _contractURI, address _deployer) {
        _setupContractURI(_contractURI);
        _setupRole(DEFAULT_ADMIN_ROLE, _deployer);
        deployer = _deployer;
    }

    function _canSetContractURI() internal view virtual override returns (bool) {
        return msg.sender == deployer;
    }
    
    /**
     * @dev Sends equal amounts of native tokens to multiple wallet addresses
     * @param recipients Array of wallet addresses to receive tokens
     * @param amountPerWallet Amount of tokens to send to each wallet
     */
    function sendEqualTokens(address[] calldata recipients, uint256 amountPerWallet) 
        external
        payable
    {
        require(recipients.length > 0, "Recipients list cannot be empty");
        
        uint256 totalAmount = amountPerWallet * recipients.length;
        require(msg.value >= totalAmount, "Insufficient funds sent");
        
        for (uint256 i = 0; i < recipients.length; i++) {
            (bool success, ) = recipients[i].call{value: amountPerWallet}("");
            require(success, "Transfer failed");
        }
        
        // Refund excess funds if any
        uint256 remainingAmount = msg.value - totalAmount;
        if (remainingAmount > 0) {
            (bool success, ) = msg.sender.call{value: remainingAmount}("");
            require(success, "Refund failed");
        }
        
        emit TokensDistributed(recipients, totalAmount, block.timestamp);
    }
    
    /**
     * @dev Sends varying amounts of native tokens to multiple wallet addresses
     * @param recipients Array of wallet addresses to receive tokens
     * @param amounts Array of token amounts to send to each wallet
     */
    function sendVaryingTokens(address[] calldata recipients, uint256[] calldata amounts) 
        external
        payable
    {
        require(recipients.length > 0, "Recipients list cannot be empty");
        require(recipients.length == amounts.length, "Arrays length mismatch");
        
        uint256 totalAmount = 0;
        for (uint256 i = 0; i < amounts.length; i++) {
            totalAmount += amounts[i];
        }
        
        require(msg.value >= totalAmount, "Insufficient funds sent");
        
        for (uint256 i = 0; i < recipients.length; i++) {
            (bool success, ) = recipients[i].call{value: amounts[i]}("");
            require(success, "Transfer failed");
        }
        
        // Refund excess funds if any
        uint256 remainingAmount = msg.value - totalAmount;
        if (remainingAmount > 0) {
            (bool success, ) = msg.sender.call{value: remainingAmount}("");
            require(success, "Refund failed");
        }
        
        emit TokensDistributedVaried(recipients, amounts, totalAmount, block.timestamp);
    }
}
