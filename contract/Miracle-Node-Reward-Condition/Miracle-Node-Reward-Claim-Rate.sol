// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

import "@thirdweb-dev/contracts/extension/PermissionsEnumerable.sol";
import "@thirdweb-dev/contracts/extension/Multicall.sol";
import "@thirdweb-dev/contracts/extension/ContractMetadata.sol";

struct RewardRateInfo {
  uint256 rate;
  uint256 nodeCount;
  uint256 lastUpdateTime;
}

struct UserToken {
  uint256 tokenId;
  uint256 amount;
}

interface MiracleEditionMigration {
  /**
   * @notice 유저가 보유하고 있는 노드 정보 조회
   * @return UserToken[] 유저가 보유하고 있는 노드 정보
   */
  function getUserMigratedTokens(address _user) external view returns (UserToken[] memory);
}

/**
 * @title Miracle Node Reward Claim Rate
 * @author Miracle
 * @notice This contract is used to set the reward rate for the Miracle Node
 * @custom:created 2025-07-18
 * @custom:version 1.0.0
 */
contract MiracleNodeRewardClaimRate is PermissionsEnumerable, Multicall, ContractMetadata {
  address public deployer;
  MiracleEditionMigration public miracleEditionMigration;
  /** @notice 실시간으로 유저가 비율 계산에 참여한 비율 총 합 */
  mapping(uint256 => uint256) public totalRewardRate;
  /** @notice 실시간으로 비율 계산에 참여한 노드 총 개수 */
  mapping(uint256 => uint256) public totalNodeCount;
  uint256 public maxRewardRate;

  // { yearMonth: { address: RewardRateInfo }, yearMonth: { address: RewardRateInfo } }
  mapping(uint256 => mapping(address => RewardRateInfo)) public rewardRateInfo;
  // { yearMonth: [address, address, address], yearMonth: [address, address, address] }
  mapping(uint256 => address[]) public registeredUsers;

  // 비율 등록 이벤트
  event RewardRateRegistered(
    address indexed user,
    uint256 indexed yearMonth,
    uint256 rate,
    uint256 nodeCount
  );

  constructor(
    string memory _contractURI,
    address _deployer,
    address _migration,
    uint256 _maxRewardRate
  ) {
    _setupContractURI(_contractURI);
    _setupRole(DEFAULT_ADMIN_ROLE, _deployer);
    deployer = _deployer;
    miracleEditionMigration = MiracleEditionMigration(_migration);
    maxRewardRate = _maxRewardRate;
  }

  function _canSetContractURI() internal view virtual override returns (bool) {
    return msg.sender == deployer;
  }

  /**
   * @notice 노드를 가지고 있는 유저가 해당 날짜(_yearMonth)에 비율 등록이 가능한지 확인
   * @param _yearMonth 예: 202407
   * @param _user 예: 0x1234567890123456789012345678901234567890
   * @return 등록 가능하면 true, 이미 등록되어 있으면 false
   */
  function canRegisterRewardRate(uint256 _yearMonth, address _user) public view returns (bool) {
    // 이미 등록한 이력이 있으면 false
    if (rewardRateInfo[_yearMonth][_user].lastUpdateTime != 0) {
      return false;
    }

    // 유저가 보유하고 있는 노드 총 개수 조회
    uint256 userTotalNodeCount = getUserTotalNodeCount(_user);

    // 노드가 1개 이상 있어야 true
    return userTotalNodeCount > 0;
  }

  /**
   * @notice Miracle Edition Migration 주소 설정
   * @param _user 예: 0x1234567890123456789012345678901234567890
   */
  function setMiracleEditionMigration(address _user) external onlyRole(DEFAULT_ADMIN_ROLE) {
    miracleEditionMigration = MiracleEditionMigration(_user);
  }

  /**
   * @notice 최대 비율 설정
   * @param _maxRewardRate 예: 150
   */
  function setMaxRewardRate(uint256 _maxRewardRate) external onlyRole(DEFAULT_ADMIN_ROLE) {
    maxRewardRate = _maxRewardRate;
  }

  /**
   * @notice 최대 비율 조회
   * @return uint256 최대 비율
   */
  function getMaxRewardRate() external view returns (uint256) {
    return maxRewardRate;
  }

  /**
   * @notice 유저가 보유하고 있는 노드 정보 조회
   * @param _user 예: 0x1234567890123456789012345678901234567890
   * @return UserToken[] 유저가 보유하고 있는 노드 정보
   */
  function getUserNodeInfo(address _user) private view returns (UserToken[] memory) {
    UserToken[] memory userTokens;
    try miracleEditionMigration.getUserMigratedTokens(_user) returns (UserToken[] memory tokens) {
      userTokens = tokens;
    } catch {
      userTokens = new UserToken[](3);
      userTokens[0] = UserToken({ tokenId: 0, amount: 0 });
      userTokens[1] = UserToken({ tokenId: 1, amount: 0 });
      userTokens[2] = UserToken({ tokenId: 2, amount: 0 });
    }
    return userTokens;
  }

  /**
   * @notice 유저가 보유하고 있는 노드 총 개수 조회
   * @param _user 예: 0x1234567890123456789012345678901234567890
   * @return uint256 유저가 보유하고 있는 노드 총 개수
   */
  function getUserTotalNodeCount(address _user) public view returns (uint256) {
    // 유저의 노드 정보 가져오기
    UserToken[] memory userTokens = getUserNodeInfo(_user);
    uint256 userTotalNodeCount = 0;

    // 노드 총 개수 계산
    for (uint256 i = 0; i < userTokens.length; i++) {
      userTotalNodeCount += userTokens[i].amount;
    }
    return userTotalNodeCount;
  }

  /**
   * @notice 날짜(_yearMonth)와 비율(rate)을 등록
   * @param _yearMonth 예: 202407
   * @param _rate 등록할 비율 값
   */
  function registerRewardRate(uint256 _yearMonth, uint256 _rate) external {
    // 이미 등록한 이력이 있거나 노드 보유를 하지 않았으면 등록불가
    require(canRegisterRewardRate(_yearMonth, msg.sender), "Already registered");
    // 비율은 최대 비율을 초과할 수 없음
    require(_rate <= maxRewardRate, "Reward rate must be less than or equal to max reward rate");
    // 비율은 0보다 커야 함
    require(_rate > 0, "Rate must be greater than 0");

    // 유저가 보유하고 있는 노드 총 개수 조회
    uint256 userTotalNodeCount = getUserTotalNodeCount(msg.sender);

    rewardRateInfo[_yearMonth][msg.sender] = RewardRateInfo({
      rate: _rate,
      nodeCount: userTotalNodeCount,
      lastUpdateTime: block.timestamp
    });

    // 실시간 평균 계산을 위한 누적값 업데이트 (오버플로우 방지)
    uint256 newTotalRewardRate = totalRewardRate[_yearMonth] + (_rate * userTotalNodeCount);
    uint256 newTotalNodeCount = totalNodeCount[_yearMonth] + userTotalNodeCount;

    // 오버플로우 체크
    require(newTotalRewardRate >= totalRewardRate[_yearMonth], "Overflow in total reward rate");
    require(newTotalNodeCount >= totalNodeCount[_yearMonth], "Overflow in total node count");

    totalRewardRate[_yearMonth] = newTotalRewardRate;
    totalNodeCount[_yearMonth] = newTotalNodeCount;

    registeredUsers[_yearMonth].push(msg.sender);

    emit RewardRateRegistered(msg.sender, _yearMonth, _rate, userTotalNodeCount);
  }

  /**
   * @notice 특정 유저의 특정 월 보상 비율 정보 조회
   * @param _yearMonth 예: 202501
   * @param _user 예: 0x1234567890123456789012345678901234567890
   * @return RewardRateInfo 유저의 보상 비율 정보
   */
  function getRewardRate(
    uint256 _yearMonth,
    address _user
  ) external view returns (RewardRateInfo memory) {
    return rewardRateInfo[_yearMonth][_user];
  }

  /**
   * @notice 특정 월 보상 비율 평균 조회
   * @param _yearMonth 예: 202501
   * @return uint256 평균 보상 비율 예: 43.21 -> 4321
   */
  function getAverageRewardRate(uint256 _yearMonth) external view returns (uint256) {
    uint256 _totalRewardRate = totalRewardRate[_yearMonth];
    uint256 _totalNodeCount = totalNodeCount[_yearMonth];

    if (_totalNodeCount == 0) {
      return 0;
    }

    // 소수점 2자리까지 정확하게 계산
    return (_totalRewardRate * 100) / _totalNodeCount;
  }
}
