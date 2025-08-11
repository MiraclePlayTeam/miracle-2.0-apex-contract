// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.11;

import "@openzeppelin/contracts-upgradeable/token/ERC1155/ERC1155Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/MulticallUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/StringsUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/interfaces/IERC2981Upgradeable.sol";
import "../openzeppelin-presets/metatx/ERC2771ContextUpgradeable.sol";
import "../lib/CurrencyTransferLib.sol";
import "../extension/ContractMetadata.sol";
import "../extension/PlatformFee.sol";
import "../extension/Royalty.sol";
import "../extension/PrimarySale.sol";
import "../extension/Ownable.sol";
import "../extension/LazyMint.sol";
import "../extension/PermissionsEnumerable.sol";
import "../extension/Drop1155.sol";
import "../extension/DefaultOperatorFiltererUpgradeable.sol";

contract DropERC1155 is
    Initializable,
    ContractMetadata,
    PlatformFee,
    Royalty,
    PrimarySale,
    Ownable,
    LazyMint,
    PermissionsEnumerable,
    Drop1155,
    ERC2771ContextUpgradeable,
    MulticallUpgradeable,
    DefaultOperatorFiltererUpgradeable,
    ERC1155Upgradeable
{
    using StringsUpgradeable for uint256;
    string public name;
    string public symbol;
    bytes32 private transferRole;
    bytes32 private minterRole;
    uint256 private constant MAX_BPS = 10_000;
    mapping(uint256 => uint256) public totalSupply;
    mapping(uint256 => uint256) public maxTotalSupply;
    mapping(uint256 => address) public saleRecipient;
    event MaxTotalSupplyUpdated(uint256 tokenId, uint256 maxTotalSupply);
    event SaleRecipientForTokenUpdated(uint256 indexed tokenId, address saleRecipient);

    constructor() initializer {}

    function initialize(
        address _defaultAdmin,
        string memory _name,
        string memory _symbol,
        string memory _contractURI,
        address[] memory _trustedForwarders,
        address _saleRecipient,
        address _royaltyRecipient,
        uint128 _royaltyBps,
        uint128 _platformFeeBps,
        address _platformFeeRecipient
    ) external initializer {
        bytes32 _transferRole = keccak256("TRANSFER_ROLE");
        bytes32 _minterRole = keccak256("MINTER_ROLE");

        // Initialize inherited contracts, most base-like -> most derived.
        __ERC2771Context_init(_trustedForwarders);
        __ERC1155_init_unchained("");
        __DefaultOperatorFilterer_init();

        // Initialize this contract's state.
        _setupContractURI(_contractURI);
        _setupOwner(_defaultAdmin);
        _setOperatorRestriction(true);

        _setupRole(DEFAULT_ADMIN_ROLE, _defaultAdmin);
        _setupRole(_minterRole, _defaultAdmin);
        _setupRole(_transferRole, _defaultAdmin);
        _setupRole(_transferRole, address(0));

        _setupPlatformFeeInfo(_platformFeeRecipient, _platformFeeBps);
        _setupDefaultRoyaltyInfo(_royaltyRecipient, _royaltyBps);
        _setupPrimarySaleRecipient(_saleRecipient);

        transferRole = _transferRole;
        minterRole = _minterRole;
        name = _name;
        symbol = _symbol;
    }

    function uri(uint256 _tokenId) public view override returns (string memory) {
        string memory batchUri = _getBaseURI(_tokenId);
        return string(abi.encodePacked(batchUri, _tokenId.toString()));
    }

    function supportsInterface(
        bytes4 interfaceId
    ) public view virtual override(ERC1155Upgradeable, IERC165) returns (bool) {
        return super.supportsInterface(interfaceId) || type(IERC2981Upgradeable).interfaceId == interfaceId;
    }

    function contractType() external pure returns (bytes32) {
        return bytes32("DropERC1155");
    }

    function contractVersion() external pure returns (uint8) {
        return uint8(4);
    }

    function setMaxTotalSupply(uint256 _tokenId, uint256 _maxTotalSupply) external onlyRole(DEFAULT_ADMIN_ROLE) {
        maxTotalSupply[_tokenId] = _maxTotalSupply;
        emit MaxTotalSupplyUpdated(_tokenId, _maxTotalSupply);
    }

    function setSaleRecipientForToken(uint256 _tokenId, address _saleRecipient) external onlyRole(DEFAULT_ADMIN_ROLE) {
        saleRecipient[_tokenId] = _saleRecipient;
        emit SaleRecipientForTokenUpdated(_tokenId, _saleRecipient);
    }

    function _beforeClaim(
        uint256 _tokenId,
        address,
        uint256 _quantity,
        address,
        uint256,
        AllowlistProof calldata,
        bytes memory
    ) internal view override {
        require(
            maxTotalSupply[_tokenId] == 0 || totalSupply[_tokenId] + _quantity <= maxTotalSupply[_tokenId],
            "exceed max total supply"
        );
    }

    function collectPriceOnClaim(
        uint256 _tokenId,
        address _primarySaleRecipient,
        uint256 _quantityToClaim,
        address _currency,
        uint256 _pricePerToken
    ) internal override {
        if (_pricePerToken == 0) {
            return;
        }

        (address platformFeeRecipient, uint16 platformFeeBps) = getPlatformFeeInfo();

        address _saleRecipient = _primarySaleRecipient == address(0)
            ? (saleRecipient[_tokenId] == address(0) ? primarySaleRecipient() : saleRecipient[_tokenId])
            : _primarySaleRecipient;

        uint256 totalPrice = _quantityToClaim * _pricePerToken;
        uint256 platformFees = (totalPrice * platformFeeBps) / MAX_BPS;

        if (_currency == CurrencyTransferLib.NATIVE_TOKEN) {
            if (msg.value != totalPrice) {
                revert("!Price");
            }
        }

        CurrencyTransferLib.transferCurrency(_currency, _msgSender(), platformFeeRecipient, platformFees);
        CurrencyTransferLib.transferCurrency(_currency, _msgSender(), _saleRecipient, totalPrice - platformFees);
    }

    function transferTokensOnClaim(address _to, uint256 _tokenId, uint256 _quantityBeingClaimed) internal override {
        _mint(_to, _tokenId, _quantityBeingClaimed, "");
    }

    function _canSetPlatformFeeInfo() internal view override returns (bool) {
        return hasRole(DEFAULT_ADMIN_ROLE, _msgSender());
    }

    function _canSetPrimarySaleRecipient() internal view override returns (bool) {
        return hasRole(DEFAULT_ADMIN_ROLE, _msgSender());
    }

    function _canSetOwner() internal view override returns (bool) {
        return hasRole(DEFAULT_ADMIN_ROLE, _msgSender());
    }

    function _canSetRoyaltyInfo() internal view override returns (bool) {
        return hasRole(DEFAULT_ADMIN_ROLE, _msgSender());
    }

    function _canSetContractURI() internal view override returns (bool) {
        return hasRole(DEFAULT_ADMIN_ROLE, _msgSender());
    }

    function _canSetClaimConditions() internal view override returns (bool) {
        return hasRole(DEFAULT_ADMIN_ROLE, _msgSender());
    }

    function _canLazyMint() internal view virtual override returns (bool) {
        return hasRole(minterRole, _msgSender());
    }

    function _canSetOperatorRestriction() internal virtual override returns (bool) {
        return hasRole(DEFAULT_ADMIN_ROLE, _msgSender());
    }

    function nextTokenIdToMint() external view returns (uint256) {
        return nextTokenIdToLazyMint;
    }

    function burnBatch(address account, uint256[] memory ids, uint256[] memory values) public virtual {
        require(
            account == _msgSender() || isApprovedForAll(account, _msgSender()),
            "ERC1155: caller is not owner nor approved."
        );

        _burnBatch(account, ids, values);
    }

    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual override {
        super._beforeTokenTransfer(operator, from, to, ids, amounts, data);

        // if transfer is restricted on the contract, we still want to allow burning and minting
        if (!hasRole(transferRole, address(0)) && from != address(0) && to != address(0)) {
            require(hasRole(transferRole, from) || hasRole(transferRole, to), "restricted to TRANSFER_ROLE holders.");
        }

        if (from == address(0)) {
            for (uint256 i = 0; i < ids.length; ++i) {
                totalSupply[ids[i]] += amounts[i];
            }
        }

        if (to == address(0)) {
            for (uint256 i = 0; i < ids.length; ++i) {
                totalSupply[ids[i]] -= amounts[i];
            }
        }
    }

    /// @dev See {ERC1155-setApprovalForAll}
    function setApprovalForAll(address operator, bool approved) public override onlyAllowedOperatorApproval(operator) {
        super.setApprovalForAll(operator, approved);
    }

    /**
     * @dev See {IERC1155-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) public override(ERC1155Upgradeable) onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, id, amount, data);
    }

    /**
     * @dev See {IERC1155-safeBatchTransferFrom}.
     */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) public override(ERC1155Upgradeable) onlyAllowedOperator(from) {
        super.safeBatchTransferFrom(from, to, ids, amounts, data);
    }

    function _dropMsgSender() internal view virtual override returns (address) {
        return _msgSender();
    }

    function _msgSender()
        internal
        view
        virtual
        override(ContextUpgradeable, ERC2771ContextUpgradeable)
        returns (address sender)
    {
        return ERC2771ContextUpgradeable._msgSender();
    }

    function _msgData()
        internal
        view
        virtual
        override(ContextUpgradeable, ERC2771ContextUpgradeable)
        returns (bytes calldata)
    {
        return ERC2771ContextUpgradeable._msgData();
    }
}
