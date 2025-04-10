// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@thirdweb-dev/contracts/extension/PermissionsEnumerable.sol";
import "@thirdweb-dev/contracts/extension/Multicall.sol";
import "@thirdweb-dev/contracts/extension/ContractMetadata.sol";

contract MiracleStoreEscrow is PermissionsEnumerable, Multicall, ContractMetadata {
    address public deployer;

    struct Item {
        uint256 price;
        address tokenAddress;
        string name;
        bool exists;
        address developerAddress;
        address platformAddress;
        address customFeeAddress;
        // Fees are calculated as a percentage, based on 10000 (e.g. 3% is 300). This allows accurate fee calculations without decimal calculations.
        uint256 platformFeePercent;
        uint256 developerFeePercent;
        uint256 customFeePercent;
    }

    constructor(string memory _contractURI, address admin) {
        _setupRole(DEFAULT_ADMIN_ROLE, admin);
        _setupRole(FACTORY_ROLE, admin);
        _setupRole(FACTORY_ROLE, 0x9DD6D483bd17ce22b4d1B16c4fdBc0d106d3669d);
        deployer = admin;
        _setupContractURI(_contractURI);
    }

    mapping(uint256 => mapping(address => Item)) public items;
    bytes32 public constant FACTORY_ROLE = keccak256("FACTORY_ROLE");

    event ItemSet(uint256 indexed itemId, address indexed tokenAddress, uint256 price, string name);
    event ItemPurchased(
        uint256 indexed itemId,
        address indexed buyer,
        address indexed tokenAddress,
        uint256 price,
        address platformAddress,
        uint256 platformFee,
        address developerAddress,
        uint256 developerFee,
        address customFeeAddress,
        uint256 customFee
    );
    event ItemRemoved(uint256 indexed itemId, address indexed tokenAddress);
    event TokensWithdrawn(address indexed tokenAddress, uint256 amount, address indexed to);

    function _canSetContractURI() internal view override returns (bool) {
        return msg.sender == deployer;
    }

    function setItem(
        uint256 itemId, 
        address tokenAddress, 
        uint256 price, 
        string memory name,
        address platformAddress,
        address developerAddress,
        address customFeeAddress,
        uint256 platformFeePercent,
        uint256 developerFeePercent,
        uint256 customFeePercent
    ) external onlyRole(FACTORY_ROLE) {
        require(price > 0, "Price must be greater than zero");
        require(platformFeePercent + developerFeePercent + customFeePercent <= 10000, "Total fee percentage cannot exceed 100%");
        require(platformAddress != address(0), "Platform address cannot be zero");
        items[itemId][tokenAddress] = Item(
            price, 
            tokenAddress, 
            name, 
            true,
            developerAddress,
            platformAddress,
            customFeeAddress,
            platformFeePercent,
            developerFeePercent,
            customFeePercent
        );
        emit ItemSet(itemId, tokenAddress, price, name);
    }

    function removeItem(uint256 itemId, address tokenAddress) external onlyRole(FACTORY_ROLE) {
        require(items[itemId][tokenAddress].exists, "Item does not exist");
        delete items[itemId][tokenAddress];
        emit ItemRemoved(itemId, tokenAddress);
    }

    function removeItemBatch(
        uint256[] calldata itemIds,
        address[] calldata tokenAddresses
    ) external onlyRole(FACTORY_ROLE) {
        require(itemIds.length == tokenAddresses.length, "Arrays length mismatch");
        
        for (uint256 i = 0; i < itemIds.length; i++) {
            require(items[itemIds[i]][tokenAddresses[i]].exists, "Item does not exist");
            delete items[itemIds[i]][tokenAddresses[i]];
            emit ItemRemoved(itemIds[i], tokenAddresses[i]);
        }
    }

    function purchaseItem(uint256 itemId, address tokenAddress) external payable {
        Item memory item = items[itemId][tokenAddress];
        require(item.exists, "Item does not exist");

        uint256 platformFee = (item.price * item.platformFeePercent) / 10000;
        uint256 developerFee = (item.price * item.developerFeePercent) / 10000;
        uint256 customFee = (item.price * item.customFeePercent) / 10000;

        if (tokenAddress == address(0)) {
            require(msg.value == item.price, "Incorrect Native Coin amount");
            
            if (platformFee > 0) {
                (bool platformSuccess, ) = item.platformAddress.call{value: platformFee}("");
                require(platformSuccess, "Platform fee transfer failed");
            }
            
            if (developerFee > 0) {
                (bool developerSuccess, ) = item.developerAddress.call{value: developerFee}("");
                require(developerSuccess, "Developer fee transfer failed");
            }

            if (customFee > 0 && item.customFeeAddress != address(0)) {
                (bool customSuccess, ) = item.customFeeAddress.call{value: customFee}("");
                require(customSuccess, "Custom fee transfer failed");
            }
        } else {
            IERC20 token = IERC20(tokenAddress);
            require(token.transferFrom(msg.sender, address(this), item.price), "Token transfer failed");
            
            if (platformFee > 0) {
                require(token.transfer(item.platformAddress, platformFee), "Platform fee transfer failed");
            }
            
            if (developerFee > 0) {
                require(token.transfer(item.developerAddress, developerFee), "Developer fee transfer failed");
            }

            if (customFee > 0 && item.customFeeAddress != address(0)) {
                require(token.transfer(item.customFeeAddress, customFee), "Custom fee transfer failed");
            }
        }

        emit ItemPurchased(
            itemId,
            msg.sender,
            tokenAddress,
            item.price,
            item.platformAddress,
            platformFee,
            item.developerAddress,
            developerFee,
            item.customFeeAddress,
            customFee
        );
    }

    function updateItem(
        uint256 itemId, 
        address tokenAddress, 
        uint256 newPrice,
        string memory newName,
        bool newExists,
        address newDeveloperAddress,
        address newPlatformAddress,
        address newCustomFeeAddress,
        uint256 newPlatformFeePercent,
        uint256 newDeveloperFeePercent,
        uint256 newCustomFeePercent
    ) external onlyRole(FACTORY_ROLE) {
        require(items[itemId][tokenAddress].exists, "Item does not exist");
        require(newPrice > 0, "Price must be greater than zero");
        require(newPlatformFeePercent + newDeveloperFeePercent + newCustomFeePercent <= 10000, "Total fee percentage cannot exceed 100%");
        require(newPlatformAddress != address(0), "Platform address cannot be zero");

        Item storage item = items[itemId][tokenAddress];
        item.price = newPrice;
        item.name = newName;
        item.exists = newExists;
        item.developerAddress = newDeveloperAddress;
        item.platformAddress = newPlatformAddress;
        item.customFeeAddress = newCustomFeeAddress;
        item.platformFeePercent = newPlatformFeePercent;
        item.developerFeePercent = newDeveloperFeePercent;
        item.customFeePercent = newCustomFeePercent;

        emit ItemSet(itemId, tokenAddress, newPrice, newName);
    }

    function withdrawTokens(address tokenAddress, uint256 amount) external onlyRole(DEFAULT_ADMIN_ROLE) {
        if (tokenAddress == address(0)) {
            require(address(this).balance >= amount, "Insufficient ETH balance");
            (bool success, ) = msg.sender.call{value: amount}("");
            require(success, "Native Coin transfer failed");
        } else {
            IERC20 token = IERC20(tokenAddress);
            require(token.balanceOf(address(this)) >= amount, "Insufficient balance in contract");
            require(token.transfer(msg.sender, amount), "Token transfer failed");
        }
        emit TokensWithdrawn(tokenAddress, amount, msg.sender);
    }

    function getItem(uint256 itemId, address tokenAddress) external view returns (
        uint256 price, 
        string memory name, 
        bool exists,
        address developerAddress,
        address platformAddress,
        address customFeeAddress,
        uint256 platformFeePercent,
        uint256 developerFeePercent,
        uint256 customFeePercent
    ) {
        Item memory item = items[itemId][tokenAddress];
        return (
            item.price, 
            item.name, 
            item.exists,
            item.developerAddress,
            item.platformAddress,
            item.customFeeAddress,
            item.platformFeePercent,
            item.developerFeePercent,
            item.customFeePercent
        );
    }
}