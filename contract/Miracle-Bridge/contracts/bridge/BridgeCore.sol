// SPDX-License-Identifier: MIT

import "@thirdweb-dev/contracts/extension/PermissionsEnumerable.sol";

import {ErcType, AdminERC1155Order, AdminERC20Order, Order, ChainType} from "./libs/Structs.sol";
import "@thirdweb-dev/contracts/prebuilts/drop/DropERC1155.sol";
import "@thirdweb-dev/contracts/prebuilts/token/TokenERC20.sol";
pragma solidity ^0.8.0;

contract BridgeCore is Initializable, PermissionsEnumerable {
    string public name;
    bytes32 private minterAndBurnerRole;
    address public feeRecipient;
    ChainType public chainType;

    mapping(address => mapping(address => mapping(ChainType => mapping(ChainType => uint256)))) public txInfos;
    event ChangedFeeRecipient(address indexed oldFeeRecipient, address indexed newFeeRecipient);
    event Exchange(
        address indexed token,
        address indexed from,
        address indexed to,
        uint256 tokenId,
        uint256 amount,
        ChainType fromChain,
        ChainType toChain,
        bytes32 metadata
    );

    modifier isValidAmount(uint256 amount) {
        require(amount > 0, "Bridge: amount must be greater than 0");
        _;
    }

    modifier onlyMinterAndBurner() {
        require(hasRole(minterAndBurnerRole, msg.sender), "Bridge: Must have minter role to mint");
        _;
    }
    modifier onlyAdmin() {
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "Bridge: Must have admin role to execute");
        _;
    }

    constructor() initializer {}

    function initialize(
        string memory _name,
        address _admin,
        ChainType _chainType,
        address _feeRecipient,
        address _minterAndBurner
    ) public initializer {
        bytes32 _minterAndBurnerRole = keccak256("MINTER_AND_BURNER_ROLE");

        _setupRole(DEFAULT_ADMIN_ROLE, _admin);
        _setupRole(_minterAndBurnerRole, _minterAndBurner);

        minterAndBurnerRole = _minterAndBurnerRole;
        name = _name;
        feeRecipient = _feeRecipient;
        chainType = _chainType;
    }

    function changeFeeRecipient(address _feeRecipient) external onlyAdmin {
        emit ChangedFeeRecipient(feeRecipient, _feeRecipient);
        feeRecipient = _feeRecipient;
    }

    function exchange(Order calldata order) external {
        _exchange(order);
    }

    function sendERC1155ToUser(AdminERC1155Order calldata order) external onlyMinterAndBurner {
        _setTxInfosByBridgeAdmin(order.receiver, order.fromChain, order.token);
        _sendERC1155ToUser(order);
    }

    function sendERC20ToUser(AdminERC20Order calldata order) external onlyMinterAndBurner {
        _setTxInfosByBridgeAdmin(order.receiver, order.fromChain, order.token);
        _sendERC20ToUser(order);
        _sendERC20ToFeeRecipient(order.token, order.feeAmount, order.fromChain);
    }

    function _setChainExchangeInfoByUser(ChainType toChain, address token) internal {
        txInfos[msg.sender][token][chainType][toChain] += 1;
    }

    function _setTxInfosByBridgeAdmin(address user, ChainType fromChain, address token) internal {
        txInfos[user][token][fromChain][chainType] += 1;
    }

    function _sendERC20ToFeeRecipient(address token, uint256 feeAmount, ChainType fromChain) internal {
        _mintERC20(token, feeRecipient, feeAmount);
        emit Exchange(token, address(0), feeRecipient, 0, feeAmount, fromChain, chainType, bytes32(0));
    }

    function _sendERC20ToUser(AdminERC20Order calldata order) internal {
        _mintERC20(order.token, order.receiver, order.amount);
        emit Exchange(
            order.token,
            address(0),
            order.receiver,
            0,
            order.amount,
            order.fromChain,
            chainType,
            order.metadata
        );
    }

    function _sendERC1155ToUser(AdminERC1155Order calldata order) internal {
        _mintERC1155(order);
        emit Exchange(
            order.token,
            address(0),
            order.receiver,
            order.tokenId,
            order.amount,
            order.fromChain,
            chainType,
            order.metadata
        );
    }

    function _exchange(Order calldata order) internal {
        _burnTokensFromUserBalance(order.ercType, order.token, msg.sender, order.tokenId, order.amount);
        _setChainExchangeInfoByUser(order.toChain, order.token);
        emit Exchange(
            order.token,
            msg.sender,
            address(0),
            order.tokenId,
            order.amount,
            chainType,
            order.toChain,
            order.metadata
        );
    }

    function _burnERC20(address token, address account, uint256 amount) internal isValidAmount(amount) {
        require(TokenERC20(token).balanceOf(account) >= amount, "Bridge: insufficient balance");
        require(TokenERC20(token).allowance(account, address(this)) >= amount, "Bridge: insufficient allowance");
        TokenERC20(token).burnFrom(account, amount);
    }

    function _burnERC1155(
        address token,
        address account,
        uint256 tokenId,
        uint256 amount
    ) internal isValidAmount(amount) {
        require(DropERC1155(token).isApprovedForAll(account, address(this)), "Bridge: not approved");
        require(DropERC1155(token).balanceOf(account, tokenId) >= amount, "Bridge: insufficient balance");

        uint256[] memory tokenIds = new uint256[](1);
        uint256[] memory amounts = new uint256[](1);

        tokenIds[0] = tokenId;
        amounts[0] = amount;
        DropERC1155(token).burnBatch(account, tokenIds, amounts);
    }

    function _burnTokensFromUserBalance(
        ErcType ercType,
        address token,
        address account,
        uint256 tokenId,
        uint256 amount
    ) internal {
        if (ercType == ErcType.ERC20) {
            _burnERC20(token, account, amount);
        } else if (ercType == ErcType.ERC1155) {
            _burnERC1155(token, account, tokenId, amount);
        } else {
            revert("Bridge: Unsupported token type");
        }
    }

    function _mintERC20(address token, address account, uint256 amount) internal isValidAmount(amount) {
        TokenERC20(token).mintTo(account, amount);
    }

    function _mintERC1155(AdminERC1155Order calldata order) internal isValidAmount(order.amount) {
        DropERC1155(order.token).claim(
            order.receiver,
            order.tokenId,
            order.amount,
            order.currency,
            order.pricePerToken,
            order.allowlistProof,
            order.data
        );
    }
}
