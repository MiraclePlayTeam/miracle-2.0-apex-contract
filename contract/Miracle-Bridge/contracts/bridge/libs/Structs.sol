// SPDX-License-Identifier: MIT
import "@thirdweb-dev/contracts/extension/interface/IDrop1155.sol";
pragma solidity ^0.8.0;

enum ErcType {
    ERC20,
    ERC1155
}

enum ChainType {
    Polygon,
    Avalanche,
    Base,
    opBNB
}

struct Order {
    ChainType toChain;
    address token;
    uint256 tokenId;
    uint256 amount;
    ErcType ercType;
    bytes32 metadata;
}

struct AdminERC1155Order {
    ChainType fromChain;
    address token;
    uint256 tokenId;
    address receiver;
    uint256 amount;
    bytes32 metadata;
    IDrop1155.AllowlistProof allowlistProof;
    address currency;
    uint256 pricePerToken;
    bytes data;
}

struct AdminERC20Order {
    ChainType fromChain;
    address token;
    address receiver;
    uint256 amount;
    uint256 feeAmount;
    bytes32 metadata;
}
