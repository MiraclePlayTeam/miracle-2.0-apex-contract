// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

interface IERC20 {
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);
}

contract TokenLockup {
    // ---------------------
    //    Basic Settings
    // ---------------------
    IERC20 public token;                // Target ERC-20 token for release
    address public operator;            // Operator (executes release and triggers emergency return)
    address public admin;               // Administrator
    address public buyer;               // Buyer
    address public receiver;            // Address to receive monthly token releases

    // ---------------------
    //   Lockup/Release Settings
    // ---------------------
    uint256 public startTimestamp;      // Lockup start time (set at deployment)
    uint256 public lockupPeriod = 180 days;   // 6 months (180 days) lockup
    uint256 public releaseDuration = 30 days; // Release interval of 30 days
    uint256 public maxReleaseCount = 12;      // Total of 12 releases

    uint256 public totalLocked;         // Total tokens deposited in contract
    uint256 public totalReleased;       // Total amount of tokens released so far
    uint256 public releasedCount;       // Number of releases executed so far

    // ---------------------
    //   Emergency Return Settings
    // ---------------------
    mapping(address => bool) public emergencyApproved;  
    // Requires approval from all 3 wallets (operator, admin, buyer) for emergency return

    // ---------------------
    //      Events
    // ---------------------
    event Deposit(address indexed from, uint256 amount);
    event Release(uint256 amount, uint256 indexed releaseCount);
    event EmergencyApproved(address indexed approver);
    event EmergencyReturn(uint256 amountReturned);

    // ---------------------
    //   Access Control
    // ---------------------
    modifier onlyOperator() {
        require(msg.sender == operator, "Not operator");
        _;
    }

    /**
     * @param _tokenAddress   Address of ERC-20 token to be released
     * @param _operator       Operator address
     * @param _admin          Administrator address
     * @param _buyer          Buyer address
     * @param _receiver       Address to receive monthly token releases
     * @param _startTimestamp Lockup start time (UNIX timestamp, manually set at deployment)
     */
    constructor(
        address _tokenAddress,
        address _operator,
        address _admin,
        address _buyer,
        address _receiver,
        uint256 _startTimestamp
    ) {
        require(_tokenAddress != address(0), "Invalid token address");
        require(_operator != address(0), "Invalid operator address");
        require(_admin != address(0), "Invalid admin address");
        require(_buyer != address(0), "Invalid buyer address");
        require(_receiver != address(0), "Invalid receiver address");

        // If needed, can add logic to check if startTimestamp is in the past
        // require(_startTimestamp >= block.timestamp, "startTimestamp is in the past");

        token = IERC20(_tokenAddress);
        operator = _operator;
        admin = _admin;
        buyer = _buyer;
        receiver = _receiver;
        startTimestamp = _startTimestamp;
    }

    /**
     * @notice Function to deposit tokens into the contract
     * @dev Before calling, msg.sender must approve this contract address
     *      for (amount) tokens on the token contract
     */
    function deposit(uint256 amount) external {
        require(amount > 0, "Deposit amount must be > 0");

        bool success = token.transferFrom(msg.sender, address(this), amount);
        require(success, "Token transfer failed");

        totalLocked += amount;
        emit Deposit(msg.sender, amount);
    }

    /**
     * @notice Release tokens (after 6-month lockup, at 30-day intervals, max 12 times)
     * @dev Only callable by operator
     */
    function release() external onlyOperator {
        // Check if 6-month (180 days) lockup period has ended
        require(block.timestamp >= startTimestamp + lockupPeriod, "Lockup not finished yet");
        require(releasedCount < maxReleaseCount, "All tokens already released");

        // Enforce monthly release intervals (after releasedCount releases)
        // Example: Round 0 release -> (startTimestamp + lockupPeriod)
        //         Round 1 release -> (startTimestamp + lockupPeriod + 30 days)
        //         Round 2 release -> (startTimestamp + lockupPeriod + 60 days) ...
        uint256 nextReleaseTimestamp = startTimestamp + lockupPeriod + (releaseDuration * releasedCount);
        require(block.timestamp >= nextReleaseTimestamp, "Not time for next monthly release yet");

        // Calculate amount to release (equal distribution)
        uint256 amountPerRelease = totalLocked / maxReleaseCount;

        // For the final round (12th), release all remaining tokens
        uint256 remaining = totalLocked - totalReleased;
        uint256 amountToRelease = (releasedCount == maxReleaseCount - 1)
            ? remaining
            : amountPerRelease;

        require(amountToRelease > 0, "No tokens left to release");

        // Check contract balance
        uint256 contractBalance = token.balanceOf(address(this));
        require(contractBalance >= amountToRelease, "Insufficient contract balance");

        // Execute release
        bool success = token.transfer(receiver, amountToRelease);
        require(success, "Token transfer failed");

        totalReleased += amountToRelease;
        releasedCount += 1;

        emit Release(amountToRelease, releasedCount);
    }

    /**
     * @notice Only operator, admin, and buyer can call this function
     *         Approval process for emergency return (multi-sig like functionality)
     */
    function approveEmergency() external {
        require(
            msg.sender == operator ||
            msg.sender == admin ||
            msg.sender == buyer,
            "Not authorized for emergency"
        );

        emergencyApproved[msg.sender] = true;
        emit EmergencyApproved(msg.sender);
    }

    /**
     * @notice Execute emergency return
     * @dev Requires operator to call and approval from all 3 parties
     */
    function emergencyReturn() external onlyOperator {
        require(emergencyApproved[operator], "Operator not approved");
        require(emergencyApproved[admin], "Admin not approved");
        require(emergencyApproved[buyer], "Buyer not approved");

        // Return entire contract balance
        uint256 contractBalance = token.balanceOf(address(this));
        require(contractBalance > 0, "No tokens to return");

        bool success = token.transfer(operator, contractBalance);
        require(success, "Emergency return transfer failed");

        emit EmergencyReturn(contractBalance);
    }

    // -----------------------------
    //   Helper View Functions
    // -----------------------------

    /**
     * @notice Query remaining token balance in contract (=balanceOf)
     */
    function getContractTokenBalance() external view returns (uint256) {
        return token.balanceOf(address(this));
    }

    /**
     * @notice Returns time remaining until lockup end (in seconds)
     *         - Returns 0 if lockup period has already ended
     */
    function getTimeUntilLockupEnd() external view returns (uint256) {
        uint256 lockupEnd = startTimestamp + lockupPeriod;
        if (block.timestamp >= lockupEnd) {
            return 0;
        } else {
            return lockupEnd - block.timestamp;
        }
    }

    /**
     * @notice Returns time until next release (monthly interval)
     *         - Returns 0 if all releases are completed
     *         - Returns 0 if release is possible now (or release time has passed)
     */
    function getTimeUntilNextRelease() external view returns (uint256) {
        if (releasedCount >= maxReleaseCount) {
            return 0; // All releases completed
        }
        // Calculate next release timestamp
        uint256 nextReleaseTimestamp = startTimestamp + lockupPeriod + (releaseDuration * releasedCount);
        if (block.timestamp >= nextReleaseTimestamp) {
            return 0; // Release time has already passed
        } else {
            return nextReleaseTimestamp - block.timestamp;
        }
    }

    /**
     * @notice Returns current release round (releasedCount) and remaining rounds
     */
    function getReleaseRoundInfo() external view returns (uint256 currentRound, uint256 roundsLeft) {
        currentRound = releasedCount;
        if (releasedCount >= maxReleaseCount) {
            roundsLeft = 0;
        } else {
            roundsLeft = maxReleaseCount - releasedCount;
        }
    }
}
