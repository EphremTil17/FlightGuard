// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7.0;

// Token interface
interface IFlightGuardToken {
    function transferFrom(address from, address to, uint256 value) external returns (bool);
    function transfer(address to, uint256 value) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
}

// FlightGuardPolicy interface
interface IFlightGuardPolicy {
    function owner() external view returns (address);
}

/**
 * @title LiquidityPool
 * @dev Manages the insurance liquidity pool for FlightGuard policies
 */
contract LiquidityPool {
    
    // State variables
    IFlightGuardToken public token;
    IFlightGuardPolicy public policyContract;
    
    uint256 public totalStaked;
    uint256 public premiumsCollected;
    uint256 public lastDistributionTime;
    uint256 public distributionInterval = 7 days; // Weekly distributions
    
    mapping(address => uint256) public userStake;
    mapping(address => uint256) public lastClaimTime;
    
    // Events
    event Staked(address indexed user, uint256 amount);
    event Unstaked(address indexed user, uint256 amount);
    event RewardsClaimed(address indexed user, uint256 amount);
    event PremiumReceived(uint256 amount);
    event RewardsDistributed(uint256 totalAmount);
    
    /**
     * @dev Constructor sets the token and policy contract addresses
     */
    constructor(address _tokenAddress, address _policyAddress) {
        token = IFlightGuardToken(_tokenAddress);
        policyContract = IFlightGuardPolicy(_policyAddress);
        lastDistributionTime = block.timestamp;
    }
    
    /**
     * @dev Modifier to restrict functions to policy contract or owner
     */
    modifier onlyPolicyOrOwner() {
        require(
            msg.sender == address(policyContract) || 
            msg.sender == policyContract.owner(),
            "Not authorized"
        );
        _;
    }
    
    /**
     * @dev Stake tokens into the liquidity pool
     * @param _amount Amount of tokens to stake
     */
    function stake(uint256 _amount) external {
        require(_amount > 0, "Amount must be greater than zero");
        
        // First claim any pending rewards
        claimRewards();
        
        // Transfer tokens from user to this contract
        require(token.transferFrom(msg.sender, address(this), _amount), "Token transfer failed");
        
        // Update user stake
        userStake[msg.sender] += _amount;
        totalStaked += _amount;
        
        emit Staked(msg.sender, _amount);
    }
    
    /**
     * @dev Unstake tokens from the liquidity pool
     * @param _amount Amount of tokens to unstake
     */
    function unstake(uint256 _amount) external {
        require(_amount > 0, "Amount must be greater than zero");
        require(userStake[msg.sender] >= _amount, "Insufficient staked amount");
        
        // First claim any pending rewards
        claimRewards();
        
        // Update user stake
        userStake[msg.sender] -= _amount;
        totalStaked -= _amount;
        
        // Transfer tokens back to user
        require(token.transfer(msg.sender, _amount), "Token transfer failed");
        
        emit Unstaked(msg.sender, _amount);
    }
    
    /**
     * @dev Claim pending rewards based on stake
     */
    function claimRewards() public {
        if (totalStaked == 0) return;
        
        uint256 userShare = userStake[msg.sender];
        if (userShare == 0) return;
        
        uint256 pendingRewards = (premiumsCollected * userShare) / totalStaked;
        if (pendingRewards == 0) return;
        
        // Update last claim time
        lastClaimTime[msg.sender] = block.timestamp;
        
        // Transfer rewards to user
        require(token.transfer(msg.sender, pendingRewards), "Token transfer failed");
        
        emit RewardsClaimed(msg.sender, pendingRewards);
    }
    
    /**
     * @dev Receive premium from policy contract
     */
    function receivePremium() external payable onlyPolicyOrOwner {
        premiumsCollected += msg.value;
        emit PremiumReceived(msg.value);
    }
    
    /**
     * @dev Distribute rewards to stakers
     */
    function distributeRewards() external {
        require(block.timestamp >= lastDistributionTime + distributionInterval, "Distribution interval not reached");
        
        lastDistributionTime = block.timestamp;
        
        if (totalStaked == 0 || premiumsCollected == 0) return;
        
        uint256 rewardsAmount = premiumsCollected;
        premiumsCollected = 0;
        
        emit RewardsDistributed(rewardsAmount);
    }
    
    /**
     * @dev Get staking info for a user
     * @param _user Address of the user
     * @return stakeAmount Amount staked
     * @return share Percentage share of the pool (as a number out of 10000)
     */
    function getStakingInfo(address _user) external view returns (uint256 stakeAmount, uint256 share) {
        stakeAmount = userStake[_user];
        share = totalStaked > 0 ? (stakeAmount * 10000) / totalStaked : 0;
    }
    
    /**
     * @dev Emergency fund release for claim payouts
     * @param _to Address to send funds to
     * @param _amount Amount to send
     */
    function emergencyRelease(address payable _to, uint256 _amount) external onlyPolicyOrOwner {
        require(_amount <= address(this).balance, "Insufficient balance");
        _to.transfer(_amount);
    }
    
    /**
     * @dev Receive ETH directly
     */
    receive() external payable {
        premiumsCollected += msg.value;
        emit PremiumReceived(msg.value);
    }
}