// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@thirdweb-dev/contracts/extension/PermissionsEnumerable.sol";
import "@thirdweb-dev/contracts/extension/Multicall.sol";
import "@openzeppelin/contracts/utils/Context.sol";

contract TrixTokenERC20 is ERC20, PermissionsEnumerable, Multicall {
    uint8 private _decimals;
    string private _imageURI;
    address public admin;

    bytes32 internal constant MINTER_ROLE = keccak256("MINTER_ROLE");

    function _msgSender() internal view virtual override(Context, Multicall) returns (address) {
        return Multicall._msgSender();
    }

    constructor(
        string memory name_,
        string memory symbol_,
        uint8 decimals_,
        string memory imageURI_,
        address _admin
    ) ERC20(name_, symbol_) {
        _decimals = decimals_;
        _imageURI = imageURI_;
        admin = _admin;
        _setupRole(DEFAULT_ADMIN_ROLE, _admin);
        _setupRole(MINTER_ROLE, _admin);
    }

    function mint(address to, uint256 amount) public onlyRole(DEFAULT_ADMIN_ROLE) {
        _mint(to, amount);
    }

    function decimals() public view virtual override returns (uint8) {
        return _decimals;
    }

    function imageURI() public view returns (string memory) {
        return _imageURI;
    }

    function setImageURI(string memory newImageURI) public onlyRole(DEFAULT_ADMIN_ROLE) {
        _imageURI = newImageURI;
    }
}
