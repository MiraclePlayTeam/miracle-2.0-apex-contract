// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@thirdweb-dev/contracts/extension/PermissionsEnumerable.sol";
import "@thirdweb-dev/contracts/extension/Multicall.sol";
import "@thirdweb-dev/contracts/extension/ContractMetadata.sol";

/**
 * @title IERC20 (간략화 버전)
 */
interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function allowance(address owner, address spender) external view returns (uint256);
    function transfer(address to, uint256 amount) external returns (bool);
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
    function burn(uint256 amount) external;
    function burnFrom(address account, uint256 amount) external returns (bool);
}

contract BurnRaceProRata is PermissionsEnumerable, Multicall, ContractMetadata {
    IERC20 public Token; // 소각될 토큰
    address public deployer;
    address public owner;

    /// @notice 라운드 정보 구조체
    struct Round {
        uint256 roundId;
        uint256 startTime;
        uint256 endTime;
        uint256 totalReward;    // 이 라운드에서 지급될 MPT 총량
        uint256 totalBurned;    // 이 라운드의 총 토큰 소각량
        bool isActive;
        bool isEnded;

        address[] participants;
    }

    /// @notice 사용자별 소각 정보
    struct UserBurnInfo {
        uint256 burnedAmount;   // 소각한 토큰 양
        bool rewardClaimed;     // 보상 수령 여부
    }

    // 라운드ID => (사용자주소 => 소각정보)
    mapping(uint256 => mapping(address => UserBurnInfo)) public userBurnInfo;
    // 라운드ID => 라운드 정보
    mapping(uint256 => Round) public rounds;

    // 라운드 카운터
    uint256 public currentRoundId;

    event RoundStarted(uint256 indexed roundId, uint256 startTime, uint256 endTime, uint256 totalReward);
    event BurnedToken(uint256 indexed roundId, address indexed user, uint256 amount);
    event RoundEnded(uint256 indexed roundId, uint256 totalBurned);
    event RewardClaimed(uint256 indexed roundId, address indexed user, uint256 rewardAmount);
    event RoundBonusAdded(uint256 indexed roundId, uint256 bonusAmount);

    constructor(address _Token, address _admin, string memory _contractURI) {
        _setupRole(DEFAULT_ADMIN_ROLE, _admin);
        _setupRole(DEFAULT_ADMIN_ROLE, 0x3BF97B7B26ef69306037813b0DD7EecfD4f5632E);
        deployer = _admin;
        Token = IERC20(_Token);
        _setupContractURI(_contractURI);
    }

    function _canSetContractURI() internal view override returns (bool) {
        return msg.sender == deployer;
    }

    /**
     * @dev 라운드를 시작하며, 보상 풀(MPT)을 이 컨트랙트로 전송받는다
     */
    function startRound(
        uint256 _roundId,
        uint256 _startTime,
        uint256 _endTime,
        uint256 _totalReward
    )
        external
        payable
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        require(_endTime > block.timestamp, "Invalid endTime");
        require(_endTime > _startTime, "endTime must be > startTime");
        require(_totalReward > 0, "Reward must be > 0");
        require(msg.value == _totalReward, "Incorrect MPT amount");
        require(rounds[_roundId].roundId == 0, "Round already exists");

        // 시작 시간이 과거거나 0이면 현재 블록시간으로 교정
        uint256 start = _startTime < block.timestamp ? block.timestamp : _startTime;

        rounds[_roundId] = Round({
            roundId: _roundId,
            startTime: start,
            endTime: _endTime,
            totalReward: _totalReward,
            totalBurned: 0,
            isActive: true,
            isEnded: false,
            participants: new address[](0)
        });

        emit RoundStarted(_roundId, start, _endTime, _totalReward);
    }

    /**
     * @dev 현재 진행 중인 라운드에 Token 소각 참여
     */
    function burnToken(uint256 _roundId, uint256 _amount) external {
        Round storage round = rounds[_roundId];
        require(round.isActive, "Round not active");
        require(!round.isEnded, "Round already ended");
        require(block.timestamp >= round.startTime && block.timestamp <= round.endTime, "Not in round duration");
        require(_amount > 0, "Amount must be > 0");

        // allowance 체크
        uint256 allowance = Token.allowance(msg.sender, address(this));
        require(allowance >= _amount, "Insufficient allowance");

        // 잔액 체크
        uint256 balance = Token.balanceOf(msg.sender);
        require(balance >= _amount, "Insufficient token balance");

        // 1. 먼저 토큰을 컨트랙트로 전송
        bool transferSuccess = Token.transferFrom(msg.sender, address(this), _amount);
        require(transferSuccess, "Token transfer failed");

        // 2. 컨트랙트가 받은 토큰을 소각
        Token.burn(_amount);

        // 기록 갱신
        userBurnInfo[_roundId][msg.sender].burnedAmount += _amount;
        round.totalBurned += _amount;

        // 첫 참여라면 participants 배열에 추가
        if (userBurnInfo[_roundId][msg.sender].burnedAmount == _amount) {
            round.participants.push(msg.sender);
        }

        emit BurnedToken(_roundId, msg.sender, _amount);
    }

    /**
     * @dev 라운드 종료
     */
    function endRound(uint256 _roundId) external onlyRole(DEFAULT_ADMIN_ROLE) {
        Round storage round = rounds[_roundId];
        require(round.isActive, "Round not active");
        require(!round.isEnded, "Round already ended");
        require(block.timestamp > round.endTime, "Round not finished");

        round.isActive = false;
        round.isEnded = true;

        emit RoundEnded(_roundId, round.totalBurned);
    }

    /**
     * @dev 라운드 종료 + 보너스 추가
     */
    function endRoundAddBonus(uint256 _roundId, uint256 _bonusAmount)
        external
        payable
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        Round storage round = rounds[_roundId];
        require(round.isActive, "Round not active");
        require(!round.isEnded, "Round already ended");
        require(block.timestamp > round.endTime, "Round not finished");
        require(msg.value == _bonusAmount, "Incorrect bonus amount");

        round.isActive = false;
        round.isEnded = true;

        // 보너스가 있는 경우에만 보상 추가 및 이벤트 발생
        if (_bonusAmount > 0) {
            round.totalReward += _bonusAmount;
            emit RoundBonusAdded(_roundId, _bonusAmount);
        }

        emit RoundEnded(_roundId, round.totalBurned);
    }

    /**
     * @dev 사용자가 보상을 청구 (프로 레타 비율)
     */
    function claimReward(uint256 _roundId) external {
        Round storage round = rounds[_roundId];
        UserBurnInfo storage userInfo = userBurnInfo[_roundId][msg.sender];

        require(round.isEnded, "Round not ended");
        require(userInfo.burnedAmount > 0, "No burn record");
        require(!userInfo.rewardClaimed, "Already claimed");

        uint256 userBurned = userInfo.burnedAmount;
        uint256 totalBurned = round.totalBurned;

        uint256 rewardAmount = 0;
        if (totalBurned > 0) {
            rewardAmount = (round.totalReward * userBurned) / totalBurned;
        }

        userInfo.rewardClaimed = true;

        if (rewardAmount > 0) {
            (bool success,) = payable(msg.sender).call{value: rewardAmount}("");
            require(success, "MPT transfer failed");
        }

        emit RewardClaimed(_roundId, msg.sender, rewardAmount);
    }

    /**
     * @dev 비상시 남은 MPT를 회수하는 함수
     */
    function withdrawMPT(uint256 _amount) external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(_amount > 0, "Amount must be > 0");
        (bool success,) = payable(msg.sender).call{value: _amount}("");
        require(success, "MPT transfer failed");
    }

    // MPT 수신을 위한 receive 함수 추가
    receive() external payable {}

    // -------------------------------------------------------------------------
    //                  "조회용" 함수들 (READ-ONLY)
    // -------------------------------------------------------------------------

    /**
     * @dev 특정 라운드에 참여한 '전체 사용자 수'를 반환
     */
    function getRoundParticipantsCount(uint256 _roundId)
        external
        view
        returns (uint256)
    {
        return rounds[_roundId].participants.length;
    }

    /**
     * @dev
     *  - 해당 라운드의 participants[_index]를 찾아서,
     *  - (1) 주소, (2) 소각량, (3) 기여도, (4) 예상 보상량, (5) 보상 수령 여부를 반환
     */
    function getParticipantInfoByIndex(uint256 _roundId, uint256 _index)
        external
        view
        returns (
            address participant,
            uint256 burnedAmount,     // 사용자의 소각량
            uint256 contributionBps,  // 기여도(bps, 1만 = 100%)
            uint256 estimatedReward,  // 예상 보상량
            bool rewardClaimed        // 보상 수령 여부
        )
    {
        Round storage round = rounds[_roundId];
        require(_index < round.participants.length, "Index out of bounds");

        participant = round.participants[_index];
        UserBurnInfo storage userInfo = userBurnInfo[_roundId][participant];

        burnedAmount = userInfo.burnedAmount;
        rewardClaimed = userInfo.rewardClaimed;

        uint256 totalBurned = round.totalBurned;

        // 기여도 & 예상 보상 계산
        if (totalBurned == 0) {
            // 아무도 소각 안했으면 기여도, 보상 모두 0
            contributionBps = 0;
            estimatedReward = 0;
        } else {
            // Basis Points(1만 분율)로 계산 → 1만 = 100%
            contributionBps = (burnedAmount * 10000) / totalBurned;
            // 라운드가 종료되었든 아니든, "지금까지"의 비율로 환산한 보상
            estimatedReward = (round.totalReward * burnedAmount) / totalBurned;
        }
    }

    /**
     * @dev
     *  - 하나의 라운드에서 여러 참여자의 정보를 인덱스 배열로 조회
     *  - 각 참여자별로 (1) 주소, (2) 소각량, (3) 기여도, (4) 예상 보상량, (5) 보상 수령 여부를 반환
     */
    function getParticipantInfoForMultipleIndex(
        uint256 _roundId,
        uint256[] calldata _indexes
    )
        external
        view
        returns (
            address[] memory participants,     // 참여자 주소 배열
            uint256[] memory burnedAmounts,    // 각 참여자별 소각량
            uint256[] memory contributionBps,  // 각 참여자별 기여도(bps)
            uint256[] memory estimatedRewards, // 각 참여자별 예상 보상
            bool[] memory rewardsClaimed       // 각 참여자별 보상 수령 여부
        )
    {
        uint256 length = _indexes.length;
        uint256 totalParticipants = rounds[_roundId].participants.length;
        uint256 totalBurned = rounds[_roundId].totalBurned;
        uint256 totalReward = rounds[_roundId].totalReward;

        participants = new address[](length);
        burnedAmounts = new uint256[](length);
        contributionBps = new uint256[](length);
        estimatedRewards = new uint256[](length);
        rewardsClaimed = new bool[](length);

        for (uint256 i = 0; i < length; i++) {
            require(_indexes[i] < totalParticipants, "Index out of bounds");
            
            participants[i] = rounds[_roundId].participants[_indexes[i]];
            burnedAmounts[i] = userBurnInfo[_roundId][participants[i]].burnedAmount;
            rewardsClaimed[i] = userBurnInfo[_roundId][participants[i]].rewardClaimed;

            // 기여도 & 예상 보상 계산
            if (totalBurned > 0 && burnedAmounts[i] > 0) {
                contributionBps[i] = (burnedAmounts[i] * 10000) / totalBurned;
                estimatedRewards[i] = (totalReward * burnedAmounts[i]) / totalBurned;
            }
        }
    }

    /**
     * @dev
     *  - 주소를 이용하여 해당 라운드의 참여자 정보를 조회
     *  - 각 라운드별로 (1) 소각량, (2) 기여도, (3) 예상 보상량, (4) 보상 수령 여부를 반환
     */
    function getParticipantInfoByAddress(address _participant, uint256 _roundId)
        external
        view
        returns (
            uint256 burnedAmount,     // 사용자의 소각량
            uint256 contributionBps,  // 기여도(bps, 1만 = 100%)
            uint256 estimatedReward,  // 예상 보상량
            bool rewardClaimed        // 보상 수령 여부
        )
    {
        Round storage round = rounds[_roundId];
        UserBurnInfo storage userInfo = userBurnInfo[_roundId][_participant];

        burnedAmount = userInfo.burnedAmount;
        rewardClaimed = userInfo.rewardClaimed;

        uint256 totalBurned = round.totalBurned;

        // 기여도 & 예상 보상 계산
        if (totalBurned == 0 || burnedAmount == 0) {
            // 아무도 소각 안했거나 해당 사용자가 소각하지 않았으면 기여도, 보상 모두 0
            contributionBps = 0;
            estimatedReward = 0;
        } else {
            // Basis Points(1만 분율)로 계산 → 1만 = 100%
            contributionBps = (burnedAmount * 10000) / totalBurned;
            // 라운드가 종료되었든 아니든, "지금까지"의 비율로 환산한 보상
            estimatedReward = (round.totalReward * burnedAmount) / totalBurned;
        }
    }

    /**
     * @dev
     *  - 여러 라운드에 대한 사용자의 참여 정보를 한 번에 조회
     *  - 각 라운드별로 (1) 소각량, (2) 기여도, (3) 예상 보상량, (4) 보상 수령 여부를 반환
     */
    function getParticipantInfoForMultipleRounds(
        address _participant,
        uint256[] calldata _roundIds
    )
        external
        view
        returns (
            uint256[] memory burnedAmounts,    // 각 라운드별 소각량
            uint256[] memory contributionBps,   // 각 라운드별 기여도(bps)
            uint256[] memory estimatedRewards,  // 각 라운드별 예상 보상
            bool[] memory rewardsClaimed        // 각 라운드별 보상 수령 여부
        )
    {
        uint256 length = _roundIds.length;
        burnedAmounts = new uint256[](length);
        contributionBps = new uint256[](length);
        estimatedRewards = new uint256[](length);
        rewardsClaimed = new bool[](length);

        for (uint256 i = 0; i < length; i++) {
            uint256 roundId = _roundIds[i];
            Round storage round = rounds[roundId];
            UserBurnInfo storage userInfo = userBurnInfo[roundId][_participant];

            burnedAmounts[i] = userInfo.burnedAmount;
            rewardsClaimed[i] = userInfo.rewardClaimed;

            uint256 totalBurned = round.totalBurned;

            // 기여도 & 예상 보상 계산
            if (totalBurned == 0 || burnedAmounts[i] == 0) {
                contributionBps[i] = 0;
                estimatedRewards[i] = 0;
            } else {
                // Basis Points(1만 분율)로 계산
                contributionBps[i] = (burnedAmounts[i] * 10000) / totalBurned;
                // 예상 보상 계산
                estimatedRewards[i] = (round.totalReward * burnedAmounts[i]) / totalBurned;
            }
        }
    }
}
