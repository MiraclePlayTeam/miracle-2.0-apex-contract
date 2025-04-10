// SPDX-License-Identifier: MIT

//    _______ _______ ___ ___ _______ ______  ___     ___ ______  _______     ___     _______ _______  _______ 
//   |   _   |   _   |   Y   |   _   |   _  \|   |   |   |   _  \|   _   |   |   |   |   _   |   _   \|   _   |
//   |   1___|.  1___|.  |   |.  1___|.  |   |.  |   |.  |.  |   |.  1___|   |.  |   |.  1   |.  1   /|   1___|
//   |____   |.  __)_|.  |   |.  __)_|.  |   |.  |___|.  |.  |   |.  __)_    |.  |___|.  _   |.  _   \|____   |
//   |:  1   |:  1   |:  1   |:  1   |:  |   |:  1   |:  |:  |   |:  1   |   |:  1   |:  |   |:  1    |:  1   |
//   |::.. . |::.. . |\:.. ./|::.. . |::.|   |::.. . |::.|::.|   |::.. . |   |::.. . |::.|:. |::.. .  |::.. . |
//   `-------`-------' `---' `-------`--- ---`-------`---`--- ---`-------'   `-------`--- ---`-------'`-------'
//   Miracleplay Native Token to ERC-20 staking v1.5.2
// The APR1 and APR2 supports two decimal places. ex) APR 1035 > 10.35%

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@thirdweb-dev/contracts/extension/PermissionsEnumerable.sol";
import "@thirdweb-dev/contracts/extension/ContractMetadata.sol";
import "@thirdweb-dev/contracts/extension/Multicall.sol";

interface IMintableERC20 is IERC20 {
    function mintTo(address to, uint256 amount) external;
}

contract DualRewardAPRStaking is PermissionsEnumerable, ContractMetadata, Multicall {
    address public deployer;
    IMintableERC20 public rewardToken2;

    uint256 private reward1APR;
    uint256 private reward2APR;

    uint256 private totalStakedTokens;
    uint256 private totalReward1Reserved;

    bool public POOL_PAUSE;
    bool public POOL_ENDED;

    struct Staker {
        uint256 stakedAmount;
        uint256 lastUpdateTime;
        uint256 reward1Earned;
        uint256 reward2Earned;
    }

    mapping(address => uint256) private stakerIndex;
    address[] public stakers;
    mapping(address => Staker) public stakings;

    constructor(
        address _adminAddr,
        address _rewardToken2,
        uint256 _reward1APR,
        uint256 _reward2APR,
        string memory _contractURI
    ) {
        _setupRole(DEFAULT_ADMIN_ROLE, _adminAddr);
        deployer = _adminAddr;
        rewardToken2 = IMintableERC20(_rewardToken2);
        reward1APR = (_reward1APR * 1e18) / 31536000; // The APR1 supports two decimal places. ex) APR1 1035 > 10.35%
        reward2APR = (_reward2APR * 1e18) / 31536000; // The APR2 supports two decimal places. ex) APR2 3846 > 38.46%
        POOL_PAUSE = false;
        POOL_ENDED = false;
        _setupContractURI(_contractURI);
    }

    function _canSetContractURI() internal view virtual override returns (bool){
        return msg.sender == deployer;
    }

    // Native token을 받기 위해 payable로 수정
    function stake() external payable {
        require(!POOL_ENDED, "Pool is ended.");
        require(!POOL_PAUSE, "Pool is pause.");
        require(msg.value > 0, "Must stake non-zero amount");
        
        updateRewards(msg.sender);

        if(stakings[msg.sender].stakedAmount == 0){
            stakerIndex[msg.sender] = stakers.length;
            stakers.push(msg.sender);
        }

        stakings[msg.sender].stakedAmount += msg.value;
        totalStakedTokens += msg.value;
    }

    function withdraw(uint256 amount) external {
        require(stakings[msg.sender].stakedAmount >= amount, "Not enough balance");
        updateRewards(msg.sender);
        stakings[msg.sender].stakedAmount -= amount;
        if(stakings[msg.sender].stakedAmount == 0){
            removeStaker(msg.sender);
        }
        totalStakedTokens -= amount;
        
        // Native token 전송
        (bool success, ) = msg.sender.call{value: amount}("");
        require(success, "Transfer failed");
    }

    function adminWithdraw(address user, uint256 amount) internal {
        require(stakings[user].stakedAmount >= amount, "Not enough balance");
        updateRewards(user);
        stakings[user].stakedAmount -= amount;
        if(stakings[user].stakedAmount == 0){
            removeStaker(user);
        }
        totalStakedTokens -= amount;
        
        // Native token 전송
        (bool success, ) = user.call{value: amount}("");
        require(success, "Transfer failed");
    }

    // Private function to remove a staker from the stakers list.
    function removeStaker(address _staker) private {
        // Retrieve the index of the staker in the stakers array.
        uint256 index = stakerIndex[_staker];
        // Replace the staker to be removed with the last staker in the array.
        stakers[index] = stakers[stakers.length - 1];
        // Update the index of the staker that was moved.
        stakerIndex[stakers[index]] = index;
        // Remove the last element (now duplicated) from the stakers array.
        stakers.pop();
        // Delete the index information of the removed staker.
        delete stakerIndex[_staker];
    }

    function claimRewards() external {
        require(!POOL_PAUSE, "Pool is pause.");
        updateRewards(msg.sender);

        uint256 reward1 = stakings[msg.sender].reward1Earned;
        uint256 reward2 = stakings[msg.sender].reward2Earned;
        if(!POOL_ENDED){
            if (reward1 > 0) {
                uint256 contractBalance = address(this).balance - totalStakedTokens;
                require(contractBalance >= reward1, "Insufficient reward1 balance");
                (bool success, ) = msg.sender.call{value: reward1}("");
                require(success, "Reward1 transfer failed");
                stakings[msg.sender].reward1Earned = 0;
                totalReward1Reserved -= reward1;
            }

            if (reward2 > 0) {
                rewardToken2.mintTo(msg.sender, reward2);
                stakings[msg.sender].reward2Earned = 0;
            }
        }else{
            stakings[msg.sender].reward1Earned = 0;
            stakings[msg.sender].reward2Earned = 0;
        }
    }

    function adminClaimRewards(address user) internal {
        require(!POOL_PAUSE, "Pool is pause.");

        uint256 reward1 = stakings[user].reward1Earned;
        uint256 reward2 = stakings[user].reward2Earned;

        if(!POOL_ENDED){
            if (reward1 > 0) {
                uint256 contractBalance = address(this).balance - totalStakedTokens;
                require(contractBalance >= reward1, "Insufficient reward1 balance");
                (bool success, ) = user.call{value: reward1}("");
                require(success, "Reward1 transfer failed");
                stakings[user].reward1Earned = 0;
                totalReward1Reserved -= reward1;
            }

            if (reward2 > 0) {
                rewardToken2.mintTo(user, reward2);
                stakings[user].reward2Earned = 0;
            }
        }else{
            stakings[user].reward1Earned = 0;
            stakings[user].reward2Earned = 0;
        }
    }

    function updateRewards(address staker) internal {
        Staker storage user = stakings[staker];
        uint256 timeElapsed = block.timestamp - user.lastUpdateTime;
        uint256 newReward1 = (timeElapsed * reward1APR * user.stakedAmount) / 1e18 / 10000;
        uint256 newReward2 = (timeElapsed * reward2APR * user.stakedAmount) / 1e18 / 10000;
        
        user.reward1Earned += newReward1;
        user.reward2Earned += newReward2;
        totalReward1Reserved += newReward1;
        
        user.lastUpdateTime = block.timestamp;
    }

    // 사용자가 현재 리워드를 조회하는 함수 추가
    function calculateRewards(address staker) public view returns (uint256 reward1, uint256 reward2) {
        Staker memory user = stakings[staker];
        uint256 timeElapsed = block.timestamp - user.lastUpdateTime;
        
        // 기존에 적립된 보상에 새로 발생한 보상을 더함
        reward1 = user.reward1Earned + (timeElapsed * reward1APR * user.stakedAmount) / 1e18 / 10000;
        reward2 = user.reward2Earned + (timeElapsed * reward2APR * user.stakedAmount) / 1e18 / 10000;
    }
    
    // 사용자의 스테이킹 정보 조회 함수 추가
    function getUserStakeInfo(address staker) external view returns (
        uint256 stakedAmount,
        uint256 lastUpdateTime,
        uint256 reward1,
        uint256 reward2
    ) {
        (reward1, reward2) = calculateRewards(staker);
        stakedAmount = stakings[staker].stakedAmount;
        lastUpdateTime = stakings[staker].lastUpdateTime;
    }
    
    // 전체 스테이킹된 금액 조회 함수 추가
    function getTotalStakedBalance() public view returns (uint256) {
        return totalStakedTokens;
    }

    function setToken2APR(uint256 _rate) external onlyRole(DEFAULT_ADMIN_ROLE) {
        reward2APR = (_rate * 1e18) / 31536000;
    }
    
    // 리워드1(네이티브 토큰) APR 설정 함수 추가
    function setToken1APR(uint256 _rate) external onlyRole(DEFAULT_ADMIN_ROLE) {
        reward1APR = (_rate * 1e18) / 31536000;
    }
    
    // 리워드1(네이티브 토큰) 현재 APR 조회 함수 추가
    function getCurrentToken1APR() public view returns (uint256) {
        uint256 annualReward = reward1APR * 31536000;
        uint256 aprWithDecimal = annualReward / 1e18;
        uint256 remainder = (annualReward % 1e18) / 1e16; 

        if (remainder >= 50) {
            aprWithDecimal += 1;
        }
        return aprWithDecimal;
    }

    function getCurrentToken2APR() public view returns (uint256) {
        uint256 annualReward = reward2APR * 31536000;
        uint256 aprWithDecimal = annualReward / 1e18;
        uint256 remainder = (annualReward % 1e18) / 1e16; 

        if (remainder >= 50) {
            aprWithDecimal += 1;
        }
        return aprWithDecimal;
    }

    function getAvailableReward1() public view returns (uint256) {
        return address(this).balance - totalStakedTokens - totalReward1Reserved;
    }

    // Native token reward1 deposit function - 관리자용
    function depositReward1() external payable onlyRole(DEFAULT_ADMIN_ROLE) {
        require(msg.value > 0, "Must deposit non-zero amount");
        // 이벤트 발생을 추가하면 좋을 수 있습니다
        emit RewardDeposited(msg.sender, msg.value);
    }
    
    // Native token reward1 deposit function - 누구나 사용 가능
    function addReward() external payable {
        require(msg.value > 0, "Must deposit non-zero amount");
        // 이벤트 발생을 추가하면 좋을 수 있습니다
        emit RewardDeposited(msg.sender, msg.value);
    }
    
    // 네이티브 토큰 직접 수신을 위한 함수들
    receive() external payable {
        // 스테이킹 함수를 통하지 않고 직접 전송된 경우 리워드로 처리
        emit RewardDeposited(msg.sender, msg.value);
    }
    
    fallback() external payable {
        // 스테이킹 함수를 통하지 않고 직접 전송된 경우 리워드로 처리
        emit RewardDeposited(msg.sender, msg.value);
    }
    
    // 이벤트 정의
    event RewardDeposited(address indexed from, uint256 amount);

    // Update emergencyWithdrawNativeToken function
    function emergencyWithdrawNativeToken() external onlyRole(DEFAULT_ADMIN_ROLE) {
        uint256 availableBalance = address(this).balance - totalStakedTokens - totalReward1Reserved;
        require(availableBalance > 0, "No available balance");
        (bool success, ) = msg.sender.call{value: availableBalance}("");
        require(success, "Transfer failed");
    }

    function getStakersCount() public view returns (uint256) {
        return stakers.length;
    }

    // Admin functions
    // Administrative function to unstake tokens on behalf of a user.
    function adminUnstakeUser(address _user) public onlyRole(DEFAULT_ADMIN_ROLE) {
        // Access the staking information of the specified user.
        Staker storage user = stakings[_user];
        uint256 amount = user.stakedAmount;
        // After the pool is finished, withdrawal is made without paying the reward.
        if(!POOL_ENDED){
            // Claim any rewards before withdrawing the tokens.
            adminWithdraw(_user, amount);
            adminClaimRewards(_user);
        }
    }

    // Administrative function to unstake all tokens from all users.
    function adminUnstakeAll() external onlyRole(DEFAULT_ADMIN_ROLE) {
        // Iterate over all stakers in reverse order to avoid index shifting issues.
        for (uint256 i = stakers.length; i > 0; i--) {
            // Retrieve the address of the current staker.
            address user = stakers[i - 1];
            // Access the staking information of the current staker.
            uint256 amount = stakings[user].stakedAmount;
            // Check if the staker has a non-zero staked amount.
            if (amount > 0) {
                adminUnstakeUser(user);
            }
        }
    }

    // Administrative function to confiscate staked ERC-20 tokens from a specific user.
    function confiscateFromUser(address _user) external onlyRole(DEFAULT_ADMIN_ROLE) {
        Staker storage user = stakings[_user];
        require(user.stakedAmount > 0, "User has no staked tokens");
        
        // Native token 전송
        (bool success, ) = msg.sender.call{value: user.stakedAmount}("");
        require(success, "Transfer failed");
        
        removeStaker(_user);
        delete stakings[_user];
    }

    function setPoolEnded(bool _value) external onlyRole(DEFAULT_ADMIN_ROLE) {
        POOL_ENDED = _value;
    }

    function setPoolPause(bool _value) external onlyRole(DEFAULT_ADMIN_ROLE) {
        POOL_PAUSE = _value;
    }
}