// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import "@thirdweb-dev/contracts/extension/PermissionsEnumerable.sol";
import "@thirdweb-dev/contracts/extension/Multicall.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract ERC20TokenMultiSend is PermissionsEnumerable, Multicall {
    IERC20 public immutable erc20;

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

    constructor(address tokenAddress) {
        require(tokenAddress != address(0), "Token address cannot be zero");
        erc20 = IERC20(tokenAddress);
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    function sendEqualTokens(
        address[] calldata recipients,
        uint256 amountPerWallet
    ) external {
        require(recipients.length > 0, "Recipients list cannot be empty");

        uint256 totalAmount = amountPerWallet * recipients.length;
        require(
            erc20.balanceOf(address(this)) >= totalAmount,
            "Insufficient contract token balance"
        );

        for (uint256 i = 0; i < recipients.length; i++) {
            require(erc20.transfer(recipients[i], amountPerWallet), "Transfer failed");
        }

        emit TokensDistributed(recipients, totalAmount, block.timestamp);
    }

    function sendVaryingTokens(
        address[] calldata recipients,
        uint256[] calldata amounts
    ) external {
        require(recipients.length > 0, "Recipients list cannot be empty");
        require(recipients.length == amounts.length, "Arrays length mismatch");

        uint256 totalAmount = 0;
        for (uint256 i = 0; i < amounts.length; i++) {
            totalAmount += amounts[i];
        }

        require(
            erc20.balanceOf(address(this)) >= totalAmount,
            "Insufficient contract token balance"
        );

        for (uint256 i = 0; i < recipients.length; i++) {
            require(erc20.transfer(recipients[i], amounts[i]), "Transfer failed");
        }

        emit TokensDistributedVaried(recipients, amounts, totalAmount, block.timestamp);
    }
}
