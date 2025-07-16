// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import "@thirdweb-dev/contracts/extension/PermissionsEnumerable.sol";
import "@thirdweb-dev/contracts/extension/Multicall.sol";

// @title Miracle Game Event
// @author Miracle
// @notice This contract is used to register score event
// @CreatedAt 2025-07-16
contract MiracleGameEvent is PermissionsEnumerable, Multicall {
  bytes32 public constant FACTORY_ROLE = keccak256("FACTORY_ROLE");

  event RegisterScore(
    uint256 indexed yyyymmdd,
    string indexed gameUid,
    string scoreData,
    uint256 timestamp
  );

  constructor() {
    _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
    _setupRole(FACTORY_ROLE, msg.sender);
  }

  function registerScore(
    uint256 yyyymmdd,
    string memory _gameUid,
    string memory _scoreData
  ) external onlyRole(FACTORY_ROLE) {
    require(yyyymmdd >= 19000101 && yyyymmdd <= 99991231, "Invalid date format");
    require(bytes(_gameUid).length > 0, "GameUid cannot be empty");
    require(bytes(_scoreData).length > 0, "ScoreData cannot be empty");

    emit RegisterScore(yyyymmdd, _gameUid, _scoreData, block.timestamp);
  }
}
