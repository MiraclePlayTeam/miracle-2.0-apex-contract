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

contract MiracleNodeMptEscrow is PermissionsEnumerable, Multicall, ContractMetadata {
  bytes32 public constant FACTORY_ROLE = keccak256("FACTORY_ROLE");
  uint256 private constant MONTH = 30 days; // 30 days = 2592000 seconds

  address public deployer;
  uint256 public totalEscrowAmount;
  uint256 public perNodeMptBalance;
  MiracleEditionMigration public miracleEditionMigration;

  struct Escrower {
    uint256 escrowAmount;
    uint256 lastUpdateTime;
  }

  mapping(address => uint256) private escrowerIndex;
  address[] public escrowers;
  mapping(address => Escrower) public escrowings;

  event Escrow(address indexed escrower, uint256 amount);
  event Withdraw(address indexed escrower, uint256 amount);

  constructor(
    string memory _contractURI,
    address _deployer,
    address _miracleEditionMigration,
    uint256 _perNodeMptBalance
  ) {
    deployer = _deployer;
    _setupRole(DEFAULT_ADMIN_ROLE, _deployer);
    _setupRole(FACTORY_ROLE, _deployer);
    _setupContractURI(_contractURI);
    miracleEditionMigration = MiracleEditionMigration(_miracleEditionMigration);
    perNodeMptBalance = _perNodeMptBalance;
  }

  function _canSetContractURI() internal view virtual override returns (bool) {
    return msg.sender == deployer;
  }

  function setMiracleEditionMigration(
    address _miracleEditionMigration
  ) external onlyRole(DEFAULT_ADMIN_ROLE) {
    miracleEditionMigration = MiracleEditionMigration(_miracleEditionMigration);
  }

  function setPerNodeMptBalance(uint256 _perNodeMptBalance) external onlyRole(FACTORY_ROLE) {
    perNodeMptBalance = _perNodeMptBalance;
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

  function escrow() external payable {
    require(msg.value > 0, "Must escrow non-zero amount");

    TokenAmount[] memory migratedTokens = getMigratedTokens(msg.sender);
    uint256 totalMigratedAmount = 0;
    for (uint256 i = 0; i < migratedTokens.length; i++) {
      totalMigratedAmount += migratedTokens[i].amount * perNodeMptBalance;
    }
    require(msg.value >= totalMigratedAmount, "Must escrow more than total migrated amount");

    if (escrowings[msg.sender].escrowAmount == 0) {
      escrowerIndex[msg.sender] = escrowers.length;
      escrowers.push(msg.sender);
    }

    escrowings[msg.sender].escrowAmount += msg.value;
    escrowings[msg.sender].lastUpdateTime = block.timestamp;
    totalEscrowAmount += msg.value;

    emit Escrow(msg.sender, msg.value);
  }

  function withdraw(uint256 amount) external {
    require(escrowings[msg.sender].escrowAmount >= amount, "Not enough balance");
    require(block.timestamp - escrowings[msg.sender].lastUpdateTime >= MONTH, "Must wait 30 days");

    escrowings[msg.sender].escrowAmount -= amount;
    if (escrowings[msg.sender].escrowAmount == 0) {
      removeEscrower(msg.sender);
    }
    totalEscrowAmount -= amount;

    (bool success, ) = msg.sender.call{ value: amount }("");
    require(success, "Transfer failed");

    emit Withdraw(msg.sender, amount);
  }

  function removeEscrower(address _escrower) private {
    uint256 index = escrowerIndex[_escrower];
    escrowers[index] = escrowers[escrowers.length - 1];
    escrowerIndex[escrowers[index]] = index;
    escrowers.pop();
    delete escrowerIndex[_escrower];
  }

  function getTotalEscrowAmount() external view returns (uint256) {
    return totalEscrowAmount;
  }

  function getEscrower(address _escrower) external view returns (uint256, uint256) {
    return (escrowings[_escrower].escrowAmount, escrowings[_escrower].lastUpdateTime);
  }

  function getEscrowerBalance(address _escrower) external view returns (uint256) {
    return escrowings[_escrower].escrowAmount;
  }

  function getTotalEscrowers() external view returns (uint256) {
    return escrowers.length;
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

  function getRequiredEscrowAmount(address _escrower) external view returns (uint256) {
    TokenAmount[] memory migratedTokens = getMigratedTokens(_escrower);
    uint256 totalNodeCount = 0;
    for (uint256 i = 0; i < migratedTokens.length; i++) {
      totalNodeCount += migratedTokens[i].amount;
    }

    return totalNodeCount * perNodeMptBalance;
  }

  function isAvailableEscrow(address _escrower) external view returns (bool) {
    TokenAmount[] memory migratedTokens = getMigratedTokens(_escrower);
    uint256 totalNodeCount = 0;
    for (uint256 i = 0; i < migratedTokens.length; i++) {
      totalNodeCount += migratedTokens[i].amount;
    }

    return totalNodeCount > 0 && escrowings[_escrower].escrowAmount == 0;
  }
}
