// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7.0;

// Direct GitHub imports
import "https://github.com/smartcontractkit/chainlink/blob/develop/contracts/src/v0.8/operatorforwarder/ChainlinkClient.sol";
import "https://github.com/smartcontractkit/chainlink/blob/develop/contracts/src/v0.8/shared/access/ConfirmedOwner.sol";

/**
 * @title FlightGuardPolicy
 * @dev Insurance contract for flight delays using Chainlink Oracles
 */
contract FlightGuardPolicy is ChainlinkClient, ConfirmedOwner {
    using Chainlink for Chainlink.Request;
    
    // Structs
    struct Policy {
        address policyholder;
        string flightNumber;
        uint256 departureTime;
        uint256 premium;
        uint256 payoutAmount;
        uint8 delayThreshold; // in hours
        bool claimed;
        bool active;
        uint8 tierLevel; // 1=basic, 2=premium, 3=enterprise
    }
    
    // State variables
    mapping(bytes32 => uint256) private requestIdToPolicy;
    mapping(uint256 => Policy) public policies;
    uint256 public policyCount;
    
    address private oracle;
    bytes32 private jobId;
    uint256 private fee;
    
    // Constants
    uint8 public constant TIER1_THRESHOLD = 1; // hours
    uint8 public constant TIER2_THRESHOLD = 2; // hours
    uint8 public constant TIER3_THRESHOLD = 3; // hours
    
    uint8 public constant TIER1_PAYOUT_PERCENT = 25;
    uint8 public constant TIER2_PAYOUT_PERCENT = 50;
    uint8 public constant TIER3_PAYOUT_PERCENT = 100;
    
    // Events
    event PolicyPurchased(uint256 indexed policyId, address policyholder, string flightNumber, uint256 premium);
    event OracleRequestSent(bytes32 indexed requestId, uint256 policyId);
    event FlightDelayDataReceived(bytes32 indexed requestId, uint256 delayMinutes);
    event ClaimProcessed(uint256 indexed policyId, address policyholder, uint256 payoutAmount);
    
    /**
     * @dev Constructor initializes Chainlink configuration
     */
    constructor() ConfirmedOwner(msg.sender) {
        // Initialize Chainlink settings - using Sepolia testnet
        _setChainlinkToken(0x779877A7B0D9E8603169DdbD7836e478b4624789);
        oracle = 0x6090149792dAAeE9D1D568c9f9a6F6B46AA29eFD; // Example Sepolia oracle
        jobId = "ca98366cc7314957b8c012c72f05aeeb"; // Example job ID
        fee = (1 * LINK_DIVISIBILITY) / 10; // 0.1 LINK
    }
    
    /**
     * @dev Updates Chainlink oracle settings
     * @param _oracle Oracle address
     * @param _jobId JobID for the oracle
     * @param _fee Fee in LINK tokens
     */
    function updateOracleSettings(address _oracle, bytes32 _jobId, uint256 _fee) 
        external 
        onlyOwner 
    {
        oracle = _oracle;
        jobId = _jobId;
        fee = _fee;
    }
    
    /**
     * @dev Allows a user to purchase flight delay insurance
     * @param _flightNumber Flight identifier (e.g., "AA101")
     * @param _departureTime Unix timestamp of departure
     * @param _tierLevel Insurance tier (1-3)
     */
    function purchasePolicy(
        string memory _flightNumber, 
        uint256 _departureTime,
        uint8 _tierLevel
    ) 
        external 
        payable 
    {
        require(msg.value > 0, "Premium must be greater than 0");
        require(_tierLevel >= 1 && _tierLevel <= 3, "Invalid tier level");
        require(_departureTime > block.timestamp, "Departure time must be in the future");
        
        // Calculate payout based on tier and premium
        uint256 payoutAmount = calculatePayout(msg.value, _tierLevel);
        
        // Determine delay threshold based on tier
        uint8 delayThreshold = getTierThreshold(_tierLevel);
        
        // Create new policy
        uint256 policyId = policyCount++;
        policies[policyId] = Policy({
            policyholder: msg.sender,
            flightNumber: _flightNumber,
            departureTime: _departureTime,
            premium: msg.value,
            payoutAmount: payoutAmount,
            delayThreshold: delayThreshold,
            claimed: false,
            active: true,
            tierLevel: _tierLevel
        });
        
        emit PolicyPurchased(policyId, msg.sender, _flightNumber, msg.value);
    }
    
    /**
     * @dev Calculate payout amount based on premium and tier level
     */
    function calculatePayout(uint256 _premium, uint8 _tierLevel) 
        internal 
        pure 
        returns (uint256) 
    {
        if (_tierLevel == 1) {
            return _premium * 2; // 2x for basic tier
        } else if (_tierLevel == 2) {
            return _premium * 3; // 3x for premium tier
        } else {
            return _premium * 4; // 4x for enterprise tier
        }
    }
    
    /**
     * @dev Get delay threshold based on tier level
     */
    function getTierThreshold(uint8 _tierLevel) 
        internal 
        pure 
        returns (uint8) 
    {
        if (_tierLevel == 1) {
            return TIER1_THRESHOLD;
        } else if (_tierLevel == 2) {
            return TIER2_THRESHOLD;
        } else {
            return TIER3_THRESHOLD;
        }
    }
    
    /**
     * @dev Function to check flight status (can be called by user or admin)
     * @param _policyId ID of the policy to check
     */
    function checkFlightStatus(uint256 _policyId) 
        external 
        returns (bytes32) 
    {
        Policy storage policy = policies[_policyId];
        require(policy.active, "Policy is not active");
        require(!policy.claimed, "Policy already claimed");
        require(block.timestamp >= policy.departureTime, "Flight has not departed yet");
        
        // Create Chainlink request - Note the underscore in function name
        Chainlink.Request memory req = _buildChainlinkRequest(
            jobId,
            address(this),
            this.fulfillFlightStatus.selector
        );
        
        // Set request parameters
        req._add("flightNumber", policy.flightNumber);
        req._addUint("departureTime", policy.departureTime);
        
        // Send request - Note the underscore in function name
        bytes32 requestId = _sendChainlinkRequest(req, fee);
        requestIdToPolicy[requestId] = _policyId;
        
        emit OracleRequestSent(requestId, _policyId);
        
        return requestId;
    }
    
    /**
     * @dev Callback function for Chainlink oracle
     * @param _requestId The request ID for which data is being returned
     * @param _delayMinutes The delay in minutes returned by the oracle
     */
    function fulfillFlightStatus(bytes32 _requestId, uint256 _delayMinutes) 
        external 
        recordChainlinkFulfillment(_requestId) 
    {
        uint256 policyId = requestIdToPolicy[_requestId];
        Policy storage policy = policies[policyId];
        
        emit FlightDelayDataReceived(_requestId, _delayMinutes);
        
        // Convert delay minutes to hours (rounded down)
        uint256 delayHours = _delayMinutes / 60;
        
        // Process tiered payout based on delay
        if (delayHours >= policy.delayThreshold) {
            processPayoutTiered(policyId, delayHours);
        }
    }
    
    /**
     * @dev Process claims with tiered payout structure
     * @param _policyId Policy ID to process
     * @param _delayHours Delay in hours
     */
    function processPayoutTiered(uint256 _policyId, uint256 _delayHours) 
        internal 
    {
        Policy storage policy = policies[_policyId];
        require(policy.active, "Policy is not active");
        require(!policy.claimed, "Policy already claimed");
        
        policy.claimed = true;
        policy.active = false;
        
        uint256 payoutAmount = 0;
        
        // Calculate payout percentage based on delay
        if (_delayHours >= TIER3_THRESHOLD) {
            payoutAmount = (policy.payoutAmount * TIER3_PAYOUT_PERCENT) / 100;
        } else if (_delayHours >= TIER2_THRESHOLD) {
            payoutAmount = (policy.payoutAmount * TIER2_PAYOUT_PERCENT) / 100;
        } else if (_delayHours >= TIER1_THRESHOLD) {
            payoutAmount = (policy.payoutAmount * TIER1_PAYOUT_PERCENT) / 100;
        }
        
        require(payoutAmount > 0, "No payout due");
        require(address(this).balance >= payoutAmount, "Insufficient contract balance");
        
        // Transfer payout to policyholder
        payable(policy.policyholder).transfer(payoutAmount);
        
        emit ClaimProcessed(_policyId, policy.policyholder, payoutAmount);
    }
    
    /**
     * @dev Get all policies for a specific policyholder
     * @param _policyholder Address of the policyholder
     * @return Array of policy IDs belonging to the policyholder
     */
    function getPoliciesByHolder(address _policyholder) 
        external 
        view 
        returns (uint256[] memory) 
    {
        // Count policies for this holder
        uint256 count = 0;
        for (uint256 i = 0; i < policyCount; i++) {
            if (policies[i].policyholder == _policyholder) {
                count++;
            }
        }
        
        // Create array of policy IDs
        uint256[] memory holderPolicies = new uint256[](count);
        uint256 index = 0;
        
        // Fill array with policy IDs
        for (uint256 i = 0; i < policyCount; i++) {
            if (policies[i].policyholder == _policyholder) {
                holderPolicies[index] = i;
                index++;
            }
        }
        
        return holderPolicies;
    }
    
    /**
     * @dev Allow contract owner to withdraw LINK tokens
     */
    function withdrawLink() 
        external 
        onlyOwner 
    {
        LinkTokenInterface link = LinkTokenInterface(_chainlinkTokenAddress());
        require(link.transfer(msg.sender, link.balanceOf(address(this))), "Unable to transfer");
    }
    
    /**
     * @dev Allow withdrawal of ETH by owner
     */
    function withdrawETH() 
        external 
        onlyOwner 
    {
        payable(owner()).transfer(address(this).balance);
    }
}