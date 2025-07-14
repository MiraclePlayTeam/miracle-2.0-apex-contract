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

contract MiracleNodeRewardRate is PermissionsEnumerable, Multicall, ContractMetadata {
  address public deployer;
  MiracleEditionMigration public miracleEditionMigration;

  struct RewardRate {
    uint256 rate;
    uint256 nodeCount;
    uint256 lastUpdateTime;
  }
  mapping(uint256 => mapping(address => RewardRate)) public rewardRates;

  event RewardRateSet(
    address indexed user,
    uint256 indexed yearMonth,
    uint256 rate,
    uint256 lastUpdateTime
  );

  constructor(string memory _contractURI, address _deployer, address _miracleEditionMigration) {
    deployer = _deployer;
    _setupRole(DEFAULT_ADMIN_ROLE, _deployer);
    _setupContractURI(_contractURI);
    miracleEditionMigration = MiracleEditionMigration(_miracleEditionMigration);
  }

  function setMiracleEditionMigration(
    address _miracleEditionMigration
  ) external onlyRole(DEFAULT_ADMIN_ROLE) {
    miracleEditionMigration = MiracleEditionMigration(_miracleEditionMigration);
  }

  function _canSetContractURI() internal view virtual override returns (bool) {
    return msg.sender == deployer;
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

  function setRewardRate(uint256 _yearMonth, uint256 _rewardRate) external {
    require(rewardRates[_yearMonth][msg.sender].rate == 0, "Already set");

    TokenAmount[] memory migratedTokens = getMigratedTokens(msg.sender);
    uint256 totalNodeCount = 0;
    for (uint256 i = 0; i < migratedTokens.length; i++) {
      totalNodeCount += migratedTokens[i].amount;
    }

    require(totalNodeCount > 0, "Must have at least one node");

    rewardRates[_yearMonth][msg.sender] = RewardRate({
      rate: _rewardRate,
      nodeCount: totalNodeCount,
      lastUpdateTime: block.timestamp
    });

    emit RewardRateSet(msg.sender, _yearMonth, _rewardRate, block.timestamp);
  }

  function getRewardRate(
    uint256 _yearMonth,
    address _user
  ) external view returns (uint256, uint256, uint256) {
    return (
      rewardRates[_yearMonth][_user].rate,
      rewardRates[_yearMonth][_user].nodeCount,
      rewardRates[_yearMonth][_user].lastUpdateTime
    );
  }

  function isAvailableRewardRate(uint256 _yearMonth, address _user) external view returns (bool) {
    TokenAmount[] memory migratedTokens = getMigratedTokens(_user);
    uint256 totalNodeCount = 0;
    for (uint256 i = 0; i < migratedTokens.length; i++) {
      totalNodeCount += migratedTokens[i].amount;
    }

    return totalNodeCount > 0 && rewardRates[_yearMonth][_user].rate == 0;
  }
}
