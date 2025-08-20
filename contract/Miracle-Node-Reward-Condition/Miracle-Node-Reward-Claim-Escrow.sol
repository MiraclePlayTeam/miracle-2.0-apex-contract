// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

import "@thirdweb-dev/contracts/extension/PermissionsEnumerable.sol";
import "@thirdweb-dev/contracts/extension/Multicall.sol";
import "@thirdweb-dev/contracts/extension/ContractMetadata.sol";

// @title Miracle Node Native Token Escrow And Reward Condition
// @author Miracle
// @notice This contract is used to escrow native tokens (ETH, MATIC, etc.) and reward condition
// @CreatedAt 2025-07-16
contract MiracleNodeRewardClaimEscrow is PermissionsEnumerable, Multicall, ContractMetadata {
  bytes32 public constant FACTORY_ROLE = keccak256("FACTORY_ROLE");

  address public deployer;

  struct Escrower {
    uint256 month;
    uint256 escrowAmount;
    uint256 lastUpdateTime;
  }

  mapping(uint256 => uint256) public totalEscrowAmount;
  mapping(uint256 => mapping(address => uint256)) private escrowerIndex;
  mapping(uint256 => address[]) public escrowers;
  mapping(uint256 => mapping(address => Escrower)) public escrowings;

  event EscrowEvent(uint256 indexed month, address indexed escrower, uint256 amount);
  event WithdrawEvent(uint256 indexed month, address indexed escrower, uint256 amount);

  constructor(string memory _contractURI, address _deployer) {
    _setupContractURI(_contractURI);
    deployer = _deployer;

    _setupRole(DEFAULT_ADMIN_ROLE, _deployer);
    _setupRole(FACTORY_ROLE, _deployer);
  }

  function _canSetContractURI() internal view virtual override returns (bool) {
    return msg.sender == deployer;
  }

  function removeEscrower(uint256 _month, address _escrower) private {
    uint256 index = escrowerIndex[_month][_escrower];
    uint256 lastIndex = escrowers[_month].length - 1;

    if (index != lastIndex) {
      address lastEscrower = escrowers[_month][lastIndex];
      escrowers[_month][index] = lastEscrower;
      escrowerIndex[_month][lastEscrower] = index;
    }

    escrowers[_month].pop();
    delete escrowerIndex[_month][_escrower];
  }

  function escrow(uint256 _month) external payable {
    require(msg.value > 0, "Must escrow non-zero amount");
    require(escrowings[_month][msg.sender].escrowAmount == 0, "Already escrowed");

    if (escrowings[_month][msg.sender].escrowAmount == 0) {
      escrowerIndex[_month][msg.sender] = escrowers[_month].length;
      escrowers[_month].push(msg.sender);
    }

    escrowings[_month][msg.sender].escrowAmount = msg.value;
    escrowings[_month][msg.sender].lastUpdateTime = block.timestamp;
    totalEscrowAmount[_month] += msg.value;

    emit EscrowEvent(_month, msg.sender, msg.value);
  }

  function withdraw(uint256 _month) external {
    uint256 withdrawAmount = escrowings[_month][msg.sender].escrowAmount;
    require(withdrawAmount > 0, "Already withdrawn");
    require(address(this).balance >= withdrawAmount, "Insufficient contract balance");

    escrowings[_month][msg.sender].escrowAmount = 0;
    removeEscrower(_month, msg.sender);
    totalEscrowAmount[_month] -= withdrawAmount;

    (bool success, ) = payable(msg.sender).call{ value: withdrawAmount }("");
    require(success, "Transfer failed");

    emit WithdrawEvent(_month, msg.sender, withdrawAmount);
  }

  function forceWithdrawAll(uint256 _month) external onlyRole(DEFAULT_ADMIN_ROLE) {
    // 배열의 복사본을 만들어서 수정 중 인덱스 문제를 방지
    address[] memory escrowersToProcess = new address[](escrowers[_month].length);
    for (uint256 i = 0; i < escrowers[_month].length; i++) {
      escrowersToProcess[i] = escrowers[_month][i];
    }

    for (uint256 i = 0; i < escrowersToProcess.length; i++) {
      address escrower = escrowersToProcess[i];
      uint256 withdrawAmount = escrowings[_month][escrower].escrowAmount;

      if (withdrawAmount > 0) {
        escrowings[_month][escrower].escrowAmount = 0;
        totalEscrowAmount[_month] -= withdrawAmount;

        (bool success, ) = payable(escrower).call{ value: withdrawAmount }("");
        require(success, "Transfer failed");

        emit WithdrawEvent(_month, escrower, withdrawAmount);
      }
    }

    // 모든 escrower를 제거
    delete escrowers[_month];
    // 모든 escrowerIndex를 제거
    for (uint256 i = 0; i < escrowersToProcess.length; i++) {
      delete escrowerIndex[_month][escrowersToProcess[i]];
    }
  }

  function getTotalEscrowAmount(uint256 _month) external view returns (uint256) {
    return totalEscrowAmount[_month];
  }

  function getTotalEscrowers(uint256 _month) external view returns (uint256) {
    return escrowers[_month].length;
  }

  function getEscrower(uint256 _month, address _escrower) external view returns (Escrower memory) {
    return escrowings[_month][_escrower];
  }

  function getEscrowAmount(uint256 _month, address _escrower) external view returns (uint256) {
    return escrowings[_month][_escrower].escrowAmount;
  }

  function getEscrowersBatch(
    uint256 _month,
    uint256 _startIndex,
    uint256 _endIndex
  ) external view returns (address[] memory, uint256[] memory) {
    require(_startIndex < _endIndex, "Invalid range");
    require(_endIndex <= escrowers[_month].length, "Invalid end index");

    address[] memory _escrowers = new address[](_endIndex - _startIndex);
    uint256[] memory _escrowAmounts = new uint256[](_endIndex - _startIndex);
    for (uint256 i = _startIndex; i < _endIndex; i++) {
      _escrowers[i - _startIndex] = escrowers[_month][i];
      _escrowAmounts[i - _startIndex] = escrowings[_month][escrowers[_month][i]].escrowAmount;
    }

    return (_escrowers, _escrowAmounts);
  }

  function isWithdrawable(uint256 _month, address _escrower) external view returns (bool) {
    uint256 withdrawAmount = escrowings[_month][_escrower].escrowAmount;

    return withdrawAmount > 0;
  }
}
