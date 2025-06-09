// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@thirdweb-dev/contracts/extension/PermissionsEnumerable.sol";
import "@thirdweb-dev/contracts/extension/Multicall.sol";

contract MiracleNftLearning is PermissionsEnumerable, Multicall {
    bytes32 public constant FACTORY_ROLE = keccak256("FACTORY_ROLE");

    event TournamentNftLearningData(
        string indexed gameItemId,
        string tournamentId,
        string matchId,
        string learningData,
        uint256 timestamp
    );

    constructor() {
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(FACTORY_ROLE, msg.sender);
    }

    function tournamentNftLearningData(
        string memory gameItemId,
        string memory tournamentId,
        string memory matchId,
        string memory learningData
    ) external onlyRole(FACTORY_ROLE) {
        require(bytes(gameItemId).length > 0, "gameItemId cannot be empty");
        require(bytes(matchId).length > 0, "matchId cannot be empty");
        require(bytes(tournamentId).length > 0, "tournamentId cannot be empty");
        require(bytes(learningData).length > 0, "learningData cannot be empty");
        
        emit TournamentNftLearningData(gameItemId, tournamentId, matchId, learningData, block.timestamp);
    }
}
