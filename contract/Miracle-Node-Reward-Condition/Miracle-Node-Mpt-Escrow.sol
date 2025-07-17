// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

import "@thirdweb-dev/contracts/extension/PermissionsEnumerable.sol";
import "@thirdweb-dev/contracts/extension/Multicall.sol";
import "@thirdweb-dev/contracts/extension/ContractMetadata.sol";

struct TokenAmount {
  uint256 tokenId;
  uint256 amount;
}

interface MiracleEditionMigration {
  function getUserMigratedTokens(address _user) external view returns (TokenAmount[] memory);
}

interface IERC20 {
  function totalSupply() external view returns (uint256);
  function balanceOf(address account) external view returns (uint256);
  function allowance(address owner, address spender) external view returns (uint256);
  function transfer(address to, uint256 amount) external returns (bool);
  function transferFrom(address from, address to, uint256 amount) external returns (bool);
}

// @title Miracle Node Mpt Escrow And Reward Condition
// @author Miracle
// @notice This contract is used to escrow MPT and reward condition
// @CreatedAt 2025-07-16
contract MiracleNodeMptEscrow is PermissionsEnumerable, Multicall, ContractMetadata {
  IERC20 public immutable Token;
  bytes32 public constant FACTORY_ROLE = keccak256("FACTORY_ROLE");

  address public deployer;
  uint256 public totalEscrowAmount;
  uint256 public perNodeMptBalance;
  uint256 public lockTime; // 초 단위 (예: 30 days = 2592000 seconds)
  MiracleEditionMigration public miracleEditionMigration;

  struct Escrower {
    uint256 escrowAmount;
    uint256 lastUpdateTime;
  }

  mapping(address => uint256) private escrowerIndex;
  address[] public escrowers;
  mapping(address => Escrower) public escrowings;

  event EscrowEvent(address indexed escrower, uint256 amount);
  event WithdrawEvent(address indexed escrower, uint256 amount);

  constructor(
    string memory _contractURI,
    address _deployer,
    address _miracleEditionMigration,
    address _token,
    uint256 _perNodeMptBalance,
    uint256 _lockTime
  ) {
    _setupContractURI(_contractURI);
    deployer = _deployer;
    miracleEditionMigration = MiracleEditionMigration(_miracleEditionMigration);
    Token = IERC20(_token);
    perNodeMptBalance = _perNodeMptBalance;
    lockTime = _lockTime;

    _setupRole(DEFAULT_ADMIN_ROLE, _deployer);
    _setupRole(FACTORY_ROLE, _deployer);
  }

  function _canSetContractURI() internal view virtual override returns (bool) {
    return msg.sender == deployer;
  }

  function setMiracleEditionMigration(
    address _miracleEditionMigration
  ) external onlyRole(DEFAULT_ADMIN_ROLE) {
    miracleEditionMigration = MiracleEditionMigration(_miracleEditionMigration);
  }

  function setPerNodeMptBalance(uint256 _perNodeMptBalance) external onlyRole(DEFAULT_ADMIN_ROLE) {
    perNodeMptBalance = _perNodeMptBalance;
  }

  function setLockTime(uint256 _lockTime) external onlyRole(DEFAULT_ADMIN_ROLE) {
    lockTime = _lockTime;
  }

  function getMigratedTokens(address _user) private view returns (TokenAmount[] memory) {
    TokenAmount[] memory migratedTokens;
    try miracleEditionMigration.getUserMigratedTokens(_user) returns (TokenAmount[] memory tokens) {
      migratedTokens = tokens;
    } catch {
      migratedTokens = new TokenAmount[](0);
    }

    return migratedTokens;
  }

  function removeEscrower(address _escrower) private {
    uint256 index = escrowerIndex[_escrower];
    escrowers[index] = escrowers[escrowers.length - 1];
    escrowerIndex[escrowers[index]] = index;
    escrowers.pop();
    delete escrowerIndex[_escrower];
  }

  function escrow() external {
    require(Token.balanceOf(msg.sender) > 0, "Must escrow non-zero amount");

    TokenAmount[] memory migratedTokens = getMigratedTokens(msg.sender);
    uint256 totalMigratedAmount = 0;
    for (uint256 i = 0; i < migratedTokens.length; i++) {
      totalMigratedAmount += migratedTokens[i].amount * perNodeMptBalance;
    }
    require(
      Token.balanceOf(msg.sender) >= totalMigratedAmount,
      "Must escrow more than total migrated amount"
    );

    uint256 allowance = Token.allowance(msg.sender, address(this));
    require(allowance >= totalMigratedAmount, "Insufficient allowance");

    if (escrowings[msg.sender].escrowAmount == 0) {
      escrowerIndex[msg.sender] = escrowers.length;
      escrowers.push(msg.sender);
    }

    escrowings[msg.sender].escrowAmount += totalMigratedAmount;
    escrowings[msg.sender].lastUpdateTime = block.timestamp;
    totalEscrowAmount += totalMigratedAmount;

    Token.transferFrom(msg.sender, address(this), totalMigratedAmount);

    emit EscrowEvent(msg.sender, totalMigratedAmount);
  }

  function withdraw() external {
    uint256 withdrawAmount = escrowings[msg.sender].escrowAmount;
    require(withdrawAmount > 0, "Not enough balance");
    require(
      block.timestamp - escrowings[msg.sender].lastUpdateTime >= lockTime,
      string(abi.encodePacked("Must wait ", Strings.toString(lockTime / 1 days), " days"))
    );
    require(Token.balanceOf(address(this)) >= withdrawAmount, "Insufficient contract balance");

    escrowings[msg.sender].escrowAmount = 0;
    if (escrowings[msg.sender].escrowAmount == 0) {
      removeEscrower(msg.sender);
    }
    totalEscrowAmount -= withdrawAmount;

    Token.transfer(msg.sender, withdrawAmount);

    emit WithdrawEvent(msg.sender, withdrawAmount);
  }

  function getTotalEscrowAmount() external view returns (uint256) {
    return totalEscrowAmount;
  }

  function getTotalEscrowers() external view returns (uint256) {
    return escrowers.length;
  }

  function getEscrower(address _escrower) external view returns (uint256, uint256) {
    return (escrowings[_escrower].escrowAmount, escrowings[_escrower].lastUpdateTime);
  }

  function getEscrowAmount(address _escrower) external view returns (uint256) {
    return escrowings[_escrower].escrowAmount;
  }

  function getEscrowersBatch(
    uint256 _startIndex,
    uint256 _endIndex
  ) external view returns (address[] memory, uint256[] memory) {
    require(_startIndex < _endIndex, "Invalid range");
    require(_endIndex <= escrowers.length, "Invalid end index");

    address[] memory _escrowers = new address[](_endIndex - _startIndex);
    uint256[] memory _escrowAmounts = new uint256[](_endIndex - _startIndex);
    for (uint256 i = _startIndex; i < _endIndex; i++) {
      _escrowers[i - _startIndex] = escrowers[i];
      _escrowAmounts[i - _startIndex] = escrowings[escrowers[i]].escrowAmount;
    }

    return (_escrowers, _escrowAmounts);
  }

  function getRequiredEscrowAmount(address _escrower) public view returns (uint256) {
    TokenAmount[] memory migratedTokens = getMigratedTokens(_escrower);
    uint256 totalNodeCount = 0;
    for (uint256 i = 0; i < migratedTokens.length; i++) {
      totalNodeCount += migratedTokens[i].amount;
    }

    return totalNodeCount * perNodeMptBalance;
  }

  function isWithdrawable(address _escrower) external view returns (bool) {
    uint256 withdrawAmount = escrowings[_escrower].escrowAmount;
    uint256 timeSinceLastUpdate = block.timestamp - escrowings[_escrower].lastUpdateTime;

    return
      timeSinceLastUpdate >= lockTime &&
      withdrawAmount > 0;
  }

  function isAvailableEscrow(address _escrower) external view returns (bool) {
    TokenAmount[] memory migratedTokens = getMigratedTokens(_escrower);
    uint256 totalNodeCount = 0;
    for (uint256 i = 0; i < migratedTokens.length; i++) {
      totalNodeCount += migratedTokens[i].amount;
    }

    uint256 requiredEscrowAmount = getRequiredEscrowAmount(_escrower);
    uint256 withdrawAmount = escrowings[_escrower].escrowAmount;

    return
      totalNodeCount > 0 &&
      Token.balanceOf(_escrower) >= requiredEscrowAmount &&
      withdrawAmount == 0;
  }
}
