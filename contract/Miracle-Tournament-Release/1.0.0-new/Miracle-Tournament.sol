// SPDX-License-Identifier: MIT
//    _______ _______ ___ ___ _______ ______  ___     ___ ______  _______     ___     _______ _______  _______
//   |   _   |   _   |   Y   |   _   |   _  \|   |   |   |   _  \|   _   |   |   |   |   _   |   _   \|   _   |
//   |   1___|.  1___|.  |   |.  1___|.  |   |.  |   |.  |.  |   |.  1___|   |.  |   |.  1   |.  1   /|   1___|
//   |____   |.  __)_|.  |   |.  __)_|.  |   |.  |___|.  |.  |   |.  __)_    |.  |___|.  _   |.  _   \|____   |
//   |:  1   |:  1   |:  1   |:  1   |:  |   |:  1   |:  |:  |   |:  1   |   |:  1   |:  |   |:  1    |:  1   |
//   |::.. . |::.. . |\:.. ./|::.. . |::.|   |::.. . |::.|::.|   |::.. . |   |::.. . |::.|:. |::.. .  |::.. . |
//   `-------`-------' `---' `-------`--- ---`-------`---`--- ---`-------'   `-------`--- ---`-------'`-------'
//   TournamentManager v2.5.7 Native Coin Support
//   2.5.9 Modify prize distribution logic (multiple prize sums to one address)

pragma solidity ^0.8.0;
import "@thirdweb-dev/contracts/extension/PermissionsEnumerable.sol";
import "@thirdweb-dev/contracts/extension/Multicall.sol";
import "@thirdweb-dev/contracts/extension/ContractMetadata.sol";

// 이벤트 선언
event TournamentCreated(
    uint256 indexed tournamentId,
    address indexed creator,
    address prizeTokenAddress,
    address entryTokenAddress,
    uint256 prizeAmount,
    uint256 entryFee,
    uint256 maxParticipants
);

event ParticipantJoined(
    uint256 indexed tournamentId,
    address indexed participant,
    uint256 entryFee
);

event ParticipantRemoved(
    uint256 indexed tournamentId,
    address indexed participant,
    uint256 refundAmount
);

event ParticipantsShuffled(
    uint256 indexed tournamentId,
    address[] participants
);

event TournamentCancelled(
    uint256 indexed tournamentId,
    address indexed creator,
    uint256 refundedPrize,
    uint256 refundedEntryFees
);

event TournamentEnded(
    uint256 indexed tournamentId,
    address[] winners,
    uint256[] prizeDistribution,
    bool isAutoPayout
);

event PrizesClaimed(
    uint256 indexed tournamentId,
    address indexed winner,
    uint256 amount
);

event FeesUpdated(
    address indexed feeAddress,
    uint256 feePercent,
    string feeType
);

interface IERC20 {
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    function transfer(address recipient, uint256 amount) external returns (bool);
}

contract  MiracleTournamentManager is PermissionsEnumerable, Multicall, ContractMetadata{
    address public deployer;
    uint256 private developerFeePercent;
    uint256 private winnerClubFeePercent;
    uint256 private platformFeePercent;
    address private developerFeeAddress;
    address private winnerClubFeeAddress;
    address private platformFeeAddress;

    bytes32 public constant FACTORY_ROLE = keccak256("FACTORY_ROLE");

    // 토너먼트 구조체 - 각 토너먼트의 정보를 저장
    struct Tournament {
        uint256 id;                     // 토너먼트 고유 ID
        address creator;                // 토너먼트 생성자 주소
        address prizeTokenAddress;      // 상금으로 지급될 토큰 주소
        address entryTokenAddress;      // 참가비로 받을 토큰 주소
        uint256 prizeAmount;           // 총 상금 금액
        uint256 entryFee;             // 참가비 금액
        uint256 maxParticipants;      // 최대 참가자 수
        bool isActive;                // 토너먼트 활성화 상태
        bool isCancelled;            // 토너먼트 취소 상태
        address[] participants;      // 참가자 목록
        uint256[] prizeDistribution; // 상금 분배 비율
        mapping(address => uint256) winnerPrizes; // 각 우승자별 상금 금액
        bool isPrizesSet;           // 상금 분배가 설정되었는지 여부
        bool isPrizesDistributed;   // 상금이 분배되었는지 여부
    }

    mapping(uint256 => Tournament) private tournaments;

    constructor(address admin, string memory _contractURI) {
        deployer = admin;
        _setupContractURI(_contractURI);

        _setupRole(DEFAULT_ADMIN_ROLE, admin);
        _setupRole(FACTORY_ROLE, admin);

        _setupRole(FACTORY_ROLE, 0x36205404Ca7dFe48db631B7BbADB57286A2E486a);
        _setupRole(FACTORY_ROLE, 0xB839a747777141FD91E53DA00a986f022b5Ebe3e);
        _setupRole(FACTORY_ROLE, 0xd5AB20464D55c85e5996770d14A567AA140e8fDe);
        _setupRole(FACTORY_ROLE, 0x960c8465B6931C0153Dd233D7C53dfa0DaF45CDa);
        _setupRole(FACTORY_ROLE, 0xF0357FA8D7eF4ad6FF099A9635e2b36eC77Fe979);
        _setupRole(FACTORY_ROLE, 0xF8dc2c9e23298FeD0B721624CaCA7a79E092ED89);
        _setupRole(FACTORY_ROLE, 0x0aa8202803e0Ab80DD2f63651F28BF4B892933fe);
        _setupRole(FACTORY_ROLE, 0x4228dDEb08B1FD561b41Ecc7eebD0C95dee19099);
        _setupRole(FACTORY_ROLE, 0xF5fe16F753E570A442a447817B9aEaEc342b3B72);
        _setupRole(FACTORY_ROLE, 0xfa95EFAdC6Df2927cA23aEe93650979bA2FAe138);
        _setupRole(FACTORY_ROLE, 0xf262b4A6B049c46bCee782f36ce755df04780369);
        _setupRole(FACTORY_ROLE, 0x5E81b89CE9A5Fe9bE209a18BD5C6c96e77B4e0D9);
        _setupRole(FACTORY_ROLE, 0xEd28Ca8715ee0EEdf6f07a6B3Fc6C514132Ec77C);
        _setupRole(FACTORY_ROLE, 0x3f47Fb659a86e67BA5C1A983719FbA005aE27E3e);
        _setupRole(FACTORY_ROLE, 0x2009a1D3590966020D7Cb1dac60b45c5667488cB);
        _setupRole(FACTORY_ROLE, 0xa96C941DDb1DcD36E7E03D5FFbcD2A2825D3009D);
        _setupRole(FACTORY_ROLE, 0xdC48C97939DeCb597FCb51cC8c9a55caE5ecd9B9);
        _setupRole(FACTORY_ROLE, 0x0B47702Ee4A7619f9De9C2d0E3228FB990028AFa);
        _setupRole(FACTORY_ROLE, 0x753e8Fc2dfe66D8ca0B9d2902D04B32226eAC4Db);
        _setupRole(FACTORY_ROLE, 0xAb675dcb0Fe48689f6A44e188FaA8584d30e6ce2);
    }

    function _canSetContractURI() internal view virtual override returns (bool){
        return msg.sender == deployer;
    }

    // 토너먼트 생성 함수
    function createTournament(
        uint256 _tournamentId,
        address _prizeTokenAddress,
        address _entryTokenAddress,
        uint256 _prizeAmount,
        uint256 _entryFee,
        uint256[] memory _prizeDistribution,
        uint256 _maxParticipants
    ) external payable {
        require(tournaments[_tournamentId].id == 0, "Tournament ID already exists.");

        if (_prizeAmount > 0) {
            if (_prizeTokenAddress == address(0)) {
                require(msg.value == _prizeAmount, "Incorrect native coin amount");
            } else {
                IERC20 prizeToken = IERC20(_prizeTokenAddress);
                prizeToken.transferFrom(msg.sender, address(this), _prizeAmount);
            }
        }

        Tournament storage tournament = tournaments[_tournamentId];
        tournament.id = _tournamentId;
        tournament.creator = msg.sender;
        tournament.prizeTokenAddress = _prizeTokenAddress;
        tournament.entryTokenAddress = _entryTokenAddress;
        tournament.prizeAmount = _prizeAmount;
        tournament.entryFee = _entryFee;
        tournament.maxParticipants = _maxParticipants;
        tournament.isActive = true;
        tournament.isPrizesSet = false;
        tournament.isPrizesDistributed = false;

        updatePrizeDistribution(_tournamentId, _prizeDistribution);

        emit TournamentCreated(_tournamentId, msg.sender, _prizeTokenAddress, _entryTokenAddress, _prizeAmount, _entryFee, _maxParticipants);
    }

    // 상금 분배 비율 업데이트 (내부 함수)
    function updatePrizeDistribution(uint256 _tournamentId, uint256[] memory _prizeDistribution) internal {
        Tournament storage tournament = tournaments[_tournamentId];
        require(tournament.id != 0, "Tournament does not exist.");
        require(!tournament.isPrizesSet, "Prizes already set.");

        uint256 totalPrize = 0;
        for (uint256 i = 0; i < _prizeDistribution.length; i++) {
            totalPrize += _prizeDistribution[i];
        }
        require(totalPrize == tournament.prizeAmount, "Total prize distribution must equal prizeAmount.");

        tournament.prizeDistribution = _prizeDistribution;
    }

    // Factory 권한으로 상금 분배 비율 업데이트
    function updatePrizeDistributionByFactory(uint256 _tournamentId, uint256[] memory _prizeDistribution) external onlyRole(FACTORY_ROLE) {
        updatePrizeDistribution(_tournamentId, _prizeDistribution);
    }

    // 토너먼트 참가 함수
    function participateInTournament(uint256 _tournamentId) public payable {
        Tournament storage tournament = tournaments[_tournamentId];
        require(tournament.isActive, "Tournament is not active.");
        require(tournament.participants.length < tournament.maxParticipants, "Maximum participants reached.");

        if (tournament.entryFee > 0) {
            if (tournament.entryTokenAddress == address(0)) {
                require(msg.value == tournament.entryFee, "Incorrect native coin amount");
            } else {
                IERC20 entryToken = IERC20(tournament.entryTokenAddress);
                entryToken.transferFrom(msg.sender, address(this), tournament.entryFee);
            }
        }
        tournament.participants.push(msg.sender);
        emit ParticipantJoined(_tournamentId, msg.sender, tournament.entryFee);
    }

    function participateInTournamentBatch(uint256 _tournamentId, uint256 _participantsCount) external payable{
        Tournament storage tournament = tournaments[_tournamentId];
        require(tournament.isActive, "Tournament is not active.");
        require(tournament.participants.length + _participantsCount <= tournament.maxParticipants, "Maximum participants reached.");
        
        if (tournament.entryTokenAddress == address(0)) {
            require(msg.value == tournament.entryFee * _participantsCount, "Incorrect native coin amount");
        } else {
            IERC20 entryToken = IERC20(tournament.entryTokenAddress);
            entryToken.transferFrom(msg.sender, address(this), tournament.entryFee * _participantsCount);
        }

        for (uint256 i = 0; i < _participantsCount; i++) {
            tournament.participants.push(msg.sender);
            emit ParticipantJoined(_tournamentId, msg.sender, tournament.entryFee);
        }
    }

    function factoryParticipateInTournament(uint256 _tournamentId, address _participant) external onlyRole(FACTORY_ROLE) {
        Tournament storage tournament = tournaments[_tournamentId];
        require(tournament.isActive, "Tournament is not active.");
        require(tournament.participants.length < tournament.maxParticipants, "Maximum participants reached.");

        tournament.participants.push(_participant);
        emit ParticipantJoined(_tournamentId, _participant, 0);
    }

    function factoryParticipateInTournamentBatch(uint256 _tournamentId, address _participant, uint256 _participantsCount) external onlyRole(FACTORY_ROLE) {
        Tournament storage tournament = tournaments[_tournamentId];
        require(tournament.isActive, "Tournament is not active.");
        require(tournament.participants.length + _participantsCount <= tournament.maxParticipants, "Maximum participants reached.");
        
        for (uint256 i = 0; i < _participantsCount; i++) {
            tournament.participants.push(_participant);
            emit ParticipantJoined(_tournamentId, _participant, 0);
        }
    }

    // 참가자 제거 함수 (Factory 권한 필요)
    function removeParticipant(uint256 _tournamentId, address _participant) public onlyRole(FACTORY_ROLE) {
        Tournament storage tournament = tournaments[_tournamentId];
        require(tournament.isActive, "Tournament is not active.");

        for (uint256 i = 0; i < tournament.participants.length; i++) {
            if (tournament.participants[i] == _participant) {
                tournament.participants[i] = tournament.participants[tournament.participants.length - 1];
                tournament.participants.pop();
                if (tournament.entryFee > 0) {
                    if (tournament.entryTokenAddress == address(0)) {
                        // Native coin refund
                        (bool success, ) = _participant.call{value: tournament.entryFee}("");
                        require(success, "Native coin transfer failed");
                    } else {
                        // ERC20 token refund
                        IERC20 entryToken = IERC20(tournament.entryTokenAddress);
                        entryToken.transfer(_participant, tournament.entryFee);
                    }
                }
                break;
            }
        }
        emit ParticipantRemoved(_tournamentId, _participant, tournament.entryFee);
    }

    function removeParticipantBatch(uint256 _tournamentId, address _participant, uint256 _participantsCount) external onlyRole(FACTORY_ROLE) {
        for (uint256 i = 0; i < _participantsCount; i++) {
            removeParticipant(_tournamentId, _participant);
        }
    }

    // 참가자 순서 무작위 섞기 (Factory 권한 필요)
    function shuffleParticipants(uint256 _tournamentId) external onlyRole(FACTORY_ROLE) {
        Tournament storage tournament = tournaments[_tournamentId];
        require(tournament.isActive, "Tournament must be active to shuffle participants.");
        
        uint256 numParticipants = tournament.participants.length;
        for (uint256 i = 0; i < numParticipants; i++) {
            uint256 n = i + uint256(keccak256(abi.encodePacked(
                block.timestamp,
                block.prevrandao,   // Replace block.difficulty with block.prevrandao
                msg.sender,
                _tournamentId,
                i
            ))) % (numParticipants - i);
            
            address temp = tournament.participants[n];
            tournament.participants[n] = tournament.participants[i];
            tournament.participants[i] = temp;
        }

        emit ParticipantsShuffled(_tournamentId, tournament.participants);
    }

    // 토너먼트 취소 함수 (Factory 권한 필요)
    function cancelTournament(uint256 _tournamentId) external onlyRole(FACTORY_ROLE) {
        Tournament storage tournament = tournaments[_tournamentId];
        require(tournament.isActive, "Tournament is not active.");

        // 참가비 환불
        if (tournament.entryFee > 0) {
            if (tournament.entryTokenAddress == address(0)) {
                // Native coin refund
                for (uint256 i = 0; i < tournament.participants.length; i++) {
                    (bool success, ) = tournament.participants[i].call{value: tournament.entryFee}("");
                    require(success, "Native coin transfer failed");
                }
            } else {
                // ERC20 token refund
                IERC20 entryToken = IERC20(tournament.entryTokenAddress);
                for (uint256 i = 0; i < tournament.participants.length; i++) {
                    entryToken.transfer(tournament.participants[i], tournament.entryFee);
                }
            }
        }

        // 상금 반환
        if (tournament.prizeAmount > 0) {
            if (tournament.prizeTokenAddress == address(0)) {
                // Native coin return
                (bool success, ) = tournament.creator.call{value: tournament.prizeAmount}("");
                require(success, "Native coin transfer failed");
            } else {
                // ERC20 token return
                IERC20 prizeToken = IERC20(tournament.prizeTokenAddress);
                prizeToken.transfer(tournament.creator, tournament.prizeAmount);
            }
        }

        tournament.isActive = false;
        tournament.isCancelled = true;

        emit TournamentCancelled(_tournamentId, msg.sender, tournament.prizeAmount, tournament.entryFee * tournament.participants.length);
    }

    // 토너먼트 종료 및 상금 청구 설정 (Claim 방식)
    function endTournamentC(uint256 _tournamentId, address[] memory _winners) external onlyRole(FACTORY_ROLE) {
        Tournament storage tournament = tournaments[_tournamentId];
        require(tournament.isActive, "Tournament is not active.");
        require(_winners.length == tournament.prizeDistribution.length, "Winners and prize distribution length mismatch.");
        require(!tournament.isPrizesSet, "Prizes already set.");
        require(!tournament.isPrizesDistributed, "Prizes already distributed.");

        uint256 totalPrize = tournament.prizeAmount;
        uint256 totalEntryFee = tournament.entryFee * tournament.participants.length;

        // Step 1: Transfer and distribute fees
        TransferFees(totalPrize, totalEntryFee, tournament.prizeTokenAddress, tournament.entryTokenAddress);

        // Finalize tournament state
        tournament.isActive = false;

        // Step 2 and 3: Calculate and set prizes for claim
        setDistributePrizes(_tournamentId, _winners);

        tournament.isPrizesSet = true;

        emit TournamentEnded(_tournamentId, _winners, tournament.prizeDistribution, false);
    }

    // 토너먼트 종료 및 자동 상금 지급 (Auto 방식)
    function endTournamentA(uint256 _tournamentId, address[] memory _winners) external onlyRole(FACTORY_ROLE) {
        Tournament storage tournament = tournaments[_tournamentId];
        require(tournament.isActive, "Tournament is not active.");
        require(_winners.length == tournament.prizeDistribution.length, "Winners and prize distribution length mismatch.");
        require(!tournament.isPrizesSet, "Prizes already set.");
        require(!tournament.isPrizesDistributed, "Prizes already distributed.");

        uint256 totalPrize = tournament.prizeAmount;
        uint256 totalEntryFee = tournament.entryFee * tournament.participants.length;

        // Step 1: Transfer fees (both prize and entry fees)
        TransferFees(totalPrize, totalEntryFee, tournament.prizeTokenAddress, tournament.entryTokenAddress);

        // Finalize tournament state
        tournament.isActive = false;

        // Step 2 and 3: Calculate and directly distribute prizes
        distributePrizes(_tournamentId, _winners);

        tournament.isPrizesDistributed = true;

        emit TournamentEnded(_tournamentId, _winners, tournament.prizeDistribution, true);
    }

    // 수수료 전송 및 분배 (내부 함수)
    function TransferFees(uint256 totalPrize, uint256 totalEntryFee, address prizeTokenAddress, address entryTokenAddress) internal {
        // Prize token transfers - only execute if totalPrize > 0
        if (totalPrize > 0) {
            uint256 developerPrizeFee = (totalPrize * developerFeePercent) / 100;
            uint256 winnerClubPrizeFee = (totalPrize * winnerClubFeePercent) / 100;
            uint256 platformPrizeFee = (totalPrize * platformFeePercent) / 100;

            if (prizeTokenAddress == address(0)) {
                // Native coin transfer for prize
                if (developerPrizeFee > 0) {
                    (bool success, ) = developerFeeAddress.call{value: developerPrizeFee}("");
                    require(success, "Native coin transfer failed");
                }
                if (winnerClubPrizeFee > 0) {
                    (bool success, ) = winnerClubFeeAddress.call{value: winnerClubPrizeFee}("");
                    require(success, "Native coin transfer failed");
                }
                if (platformPrizeFee > 0) {
                    (bool success, ) = platformFeeAddress.call{value: platformPrizeFee}("");
                    require(success, "Native coin transfer failed");
                }
            } else {
                // ERC20 token transfer for prize
                IERC20 prizeToken = IERC20(prizeTokenAddress);
                if (developerPrizeFee > 0) {
                    prizeToken.transfer(developerFeeAddress, developerPrizeFee);
                }
                if (winnerClubPrizeFee > 0) {
                    prizeToken.transfer(winnerClubFeeAddress, winnerClubPrizeFee);
                }
                if (platformPrizeFee > 0) {
                    prizeToken.transfer(platformFeeAddress, platformPrizeFee);
                }
            }
        }
        
        uint256 developerEntryFee = (totalEntryFee * developerFeePercent) / 100;
        uint256 winnerClubEntryFee = (totalEntryFee * winnerClubFeePercent) / 100;
        uint256 platformEntryFee = (totalEntryFee * platformFeePercent) / 100;

        // Entry fee transfers
        if (entryTokenAddress == address(0)) {
            // Native coin transfer for entry fee
            if (developerEntryFee > 0) {
                (bool success, ) = developerFeeAddress.call{value: developerEntryFee}("");
                require(success, "Native coin transfer failed");
            }
            if (winnerClubEntryFee > 0) {
                (bool success, ) = winnerClubFeeAddress.call{value: winnerClubEntryFee}("");
                require(success, "Native coin transfer failed");
            }
            if (platformEntryFee > 0) {
                (bool success, ) = platformFeeAddress.call{value: platformEntryFee}("");
                require(success, "Native coin transfer failed");
            }
        } else {
            // ERC20 token transfer for entry fee
            IERC20 entryToken = IERC20(entryTokenAddress);
            if (developerEntryFee > 0) {
                entryToken.transfer(developerFeeAddress, developerEntryFee);
            }
            if (winnerClubEntryFee > 0) {
                entryToken.transfer(winnerClubFeeAddress, winnerClubEntryFee);
            }
            if (platformEntryFee > 0) {
                entryToken.transfer(platformFeeAddress, platformEntryFee);
            }
        }

        emit FeesUpdated(msg.sender, developerFeePercent, "Developer");
        emit FeesUpdated(msg.sender, winnerClubFeePercent, "Winner Club");
        emit FeesUpdated(msg.sender, platformFeePercent, "Platform");
    }

    // 수수료 공제 후 실제 지급될 상금 계산
    function calculateAdjustedPrize(uint256 totalPrize) internal view returns (uint256) {
        uint256 remainingPrize = totalPrize - (totalPrize * (developerFeePercent + winnerClubFeePercent + platformFeePercent)) / 100;
        return remainingPrize;
    }

    // 상금 분배 설정 (Claim 방식)
    function setDistributePrizes(uint256 _tournamentId, address[] memory _winners) internal {
        Tournament storage tournament = tournaments[_tournamentId];
        require(!tournament.isActive, "Tournament must be ended.");
        require(!tournament.isPrizesDistributed, "Prizes have already been distributed.");
        require(_winners.length == tournament.prizeDistribution.length, "Winners and prize distribution length mismatch.");

        uint256 totalPrize = tournament.prizeAmount;
        uint256 remainingPrize = calculateAdjustedPrize(totalPrize);

        // Set prize for each winner based on remaining prize
        for (uint256 i = 0; i < _winners.length; i++) {
            uint256 adjustedPrize = (remainingPrize * tournament.prizeDistribution[i]) / totalPrize;
            tournament.winnerPrizes[_winners[i]] = tournament.winnerPrizes[_winners[i]] + adjustedPrize;
        }
    }

    // 상금 즉시 분배 (Auto 방식)
    function distributePrizes(uint256 _tournamentId, address[] memory _winners) internal {
        Tournament storage tournament = tournaments[_tournamentId];
        require(!tournament.isActive, "Tournament must be ended before distributing prizes.");
        require(!tournament.isPrizesDistributed, "Prizes have already been distributed.");
        require(!tournament.isPrizesSet, "Prizes already set.");
        require(_winners.length == tournament.prizeDistribution.length, "Winners and prize distribution length mismatch.");

        uint256 totalPrize = tournament.prizeAmount;
        uint256 remainingPrize = calculateAdjustedPrize(totalPrize);

        for (uint256 i = 0; i < _winners.length; i++) {
            uint256 adjustedPrize = (remainingPrize * tournament.prizeDistribution[i]) / totalPrize;
            if (adjustedPrize > 0) {
                if (tournament.prizeTokenAddress == address(0)) {
                    // Native coin transfer
                    (bool success, ) = _winners[i].call{value: adjustedPrize}("");
                    require(success, "Native coin transfer failed");
                } else {
                    // ERC20 token transfer
                    IERC20 prizeToken = IERC20(tournament.prizeTokenAddress);
                    prizeToken.transfer(_winners[i], adjustedPrize);
                }
                emit PrizesClaimed(_tournamentId, _winners[i], adjustedPrize);
            }
        }

        tournament.isPrizesDistributed = true;
    }

    // 우승자 상금 청구 함수 (Claim 방식)
    function claimPrize(uint256 _tournamentId) external {
        Tournament storage tournament = tournaments[_tournamentId];
        require(!tournament.isActive, "Tournament must be ended to claim prizes.");
        require(tournament.isPrizesSet, "Prizes have not been set.");
        require(!tournament.isPrizesDistributed, "Prizes already distributed by admin.");

        uint256 prizeAmount = tournament.winnerPrizes[msg.sender];
        require(prizeAmount > 0, "No prize to claim.");

        tournament.winnerPrizes[msg.sender] = 0; // Prevent double claim

        if (prizeAmount > 0) {
            if (tournament.prizeTokenAddress == address(0)) {
                // Native coin transfer
                (bool success, ) = msg.sender.call{value: prizeAmount}("");
                require(success, "Native coin transfer failed");
            } else {
                // ERC20 token transfer
                IERC20 prizeToken = IERC20(tournament.prizeTokenAddress);
                prizeToken.transfer(msg.sender, prizeAmount);
            }
        }

        emit PrizesClaimed(_tournamentId, msg.sender, prizeAmount);
    }

    // 토너먼트 정보 조회
    function getTournamentInfo(uint256 _tournamentId) external view returns (
        address creator,
        address prizeTokenAddress,
        address entryTokenAddress,
        uint256 prizeAmount,
        uint256 entryFee,
        uint256 maxParticipants,
        bool isActive,
        bool isCancelled
    ) {
        Tournament storage tournament = tournaments[_tournamentId];
        return (
            tournament.creator,
            tournament.prizeTokenAddress,
            tournament.entryTokenAddress,
            tournament.prizeAmount,
            tournament.entryFee,
            tournament.maxParticipants,
            tournament.isActive,
            tournament.isCancelled
        );
    }

    // 토너먼트 참가자 목록 조회
    function getTournamentParticipants(uint256 _tournamentId) external view returns (address[] memory) {
        Tournament storage tournament = tournaments[_tournamentId];
        return tournament.participants;
    }

    // 토너먼트 상금 분배 비율 조회
    function getTournamentPrizeDistribution(uint256 _tournamentId) external view returns (uint256[] memory) {
        Tournament storage tournament = tournaments[_tournamentId];
        return tournament.prizeDistribution;
    }

    // 토너먼트 수수료 정보 조회
    function getTournamentFees() external view returns (
        uint256 _developerFeePercent,
        uint256 _winnerClubFeePercent,
        uint256 _platformFeePercent,
        address _developerFeeAddress,
        address _winnerClubFeeAddress,
        address _platformFeeAddress
    ) {
        return (
            developerFeePercent,
            winnerClubFeePercent,
            platformFeePercent,
            developerFeeAddress,
            winnerClubFeeAddress,
            platformFeeAddress
        );
    }

    // 개발자 수수료 설정
    function setDeveloperFee(address _feeAddress, uint256 _feePercent) external onlyRole(DEFAULT_ADMIN_ROLE) {
        developerFeeAddress = _feeAddress;
        developerFeePercent = _feePercent;

        emit FeesUpdated(_feeAddress, _feePercent, "Developer");
    }

    // 위너클럽 수수료 설정
    function setWinnerClubFee(address _feeAddress, uint256 _feePercent) external onlyRole(DEFAULT_ADMIN_ROLE) {
        winnerClubFeeAddress = _feeAddress;
        winnerClubFeePercent = _feePercent;

        emit FeesUpdated(_feeAddress, _feePercent, "Winner Club");
    }

    // 플랫폼 수수료 설정
    function setPlatformFee(address _feeAddress, uint256 _feePercent) external onlyRole(DEFAULT_ADMIN_ROLE) {
        platformFeeAddress = _feeAddress;
        platformFeePercent = _feePercent;

        emit FeesUpdated(_feeAddress, _feePercent, "Platform");
    }

    // 청구 가능한 상금 조회
    function getClaimablePrize(address _participant, uint256 _tournamentId) external view returns (uint256) {
        Tournament storage tournament = tournaments[_tournamentId];
        uint256 prizeAmount = tournament.winnerPrizes[_participant];
        return prizeAmount;
    }

    // Native coin을 받기 위한 receive 함수
    receive() external payable {}
}
