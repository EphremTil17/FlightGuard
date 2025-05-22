// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7.0;

/**
 * @title FlightGuardToken
 * @dev ERC20 Token for the FlightGuard ecosystem with governance capabilities
 */
contract FlightGuardToken {
    // Token details
    string public name = "FlightGuard Token";
    string public symbol = "FGT";
    uint8 public decimals = 18;
    uint256 public totalSupply;
    
    // Balances and allowances
    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;
    
    // Governance
    address public governance;
    uint256 public proposalCount;
    
    struct Proposal {
        address proposer;
        string description;
        uint256 forVotes;
        uint256 againstVotes;
        bool executed;
        bool active;
        uint256 endTime;
        mapping(address => bool) voted;
    }
    
    mapping(uint256 => Proposal) public proposals;
    
    // Events
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    event ProposalCreated(uint256 indexed proposalId, address proposer, string description);
    event Voted(uint256 indexed proposalId, address voter, bool support, uint256 weight);
    event ProposalExecuted(uint256 indexed proposalId);
    
    /**
     * @dev Constructor mints initial tokens to the deployer
     */
    constructor() {
        governance = msg.sender;
        
        // Mint initial supply to contract creator
        uint256 initialSupply = 1000000 * 10**uint256(decimals); // 1 million tokens
        balanceOf[msg.sender] = initialSupply;
        totalSupply = initialSupply;
        
        emit Transfer(address(0), msg.sender, initialSupply);
    }
    
    /**
     * @dev Transfer tokens to a specified address
     * @param _to Recipient address
     * @param _value Amount to transfer
     * @return Success status
     */
    function transfer(address _to, uint256 _value) external returns (bool) {
        require(_to != address(0), "Transfer to zero address");
        require(balanceOf[msg.sender] >= _value, "Insufficient balance");
        
        balanceOf[msg.sender] -= _value;
        balanceOf[_to] += _value;
        
        emit Transfer(msg.sender, _to, _value);
        return true;
    }
    
    /**
     * @dev Approve spender to withdraw from your account up to _value
     * @param _spender Address authorized to spend
     * @param _value Amount they can spend
     * @return Success status
     */
    function approve(address _spender, uint256 _value) external returns (bool) {
        allowance[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }
    
    /**
     * @dev Transfer tokens from one address to another
     * @param _from Address to transfer from
     * @param _to Address to transfer to
     * @param _value Amount to transfer
     * @return Success status
     */
    function transferFrom(address _from, address _to, uint256 _value) external returns (bool) {
        require(_to != address(0), "Transfer to zero address");
        require(balanceOf[_from] >= _value, "Insufficient balance");
        require(allowance[_from][msg.sender] >= _value, "Insufficient allowance");
        
        balanceOf[_from] -= _value;
        balanceOf[_to] += _value;
        allowance[_from][msg.sender] -= _value;
        
        emit Transfer(_from, _to, _value);
        return true;
    }
    
    /**
     * @dev Creates a governance proposal
     * @param _description Description of the proposal
     * @return proposalId The ID of the created proposal
     */
    function createProposal(string memory _description) external returns (uint256) {
        require(balanceOf[msg.sender] >= 1000 * 10**uint256(decimals), "Need 1000 tokens to create proposal");
        
        uint256 proposalId = proposalCount++;
        Proposal storage newProposal = proposals[proposalId];
        
        newProposal.proposer = msg.sender;
        newProposal.description = _description;
        newProposal.active = true;
        newProposal.endTime = block.timestamp + 7 days; // 1 week voting period
        
        emit ProposalCreated(proposalId, msg.sender, _description);
        
        return proposalId;
    }
    
    /**
     * @dev Vote on an active proposal
     * @param _proposalId ID of the proposal
     * @param _support Whether to support the proposal
     */
    function vote(uint256 _proposalId, bool _support) external {
        Proposal storage proposal = proposals[_proposalId];
        
        require(proposal.active, "Proposal not active");
        require(block.timestamp < proposal.endTime, "Voting period ended");
        require(!proposal.voted[msg.sender], "Already voted");
        
        proposal.voted[msg.sender] = true;
        
        uint256 weight = balanceOf[msg.sender];
        if (_support) {
            proposal.forVotes += weight;
        } else {
            proposal.againstVotes += weight;
        }
        
        emit Voted(_proposalId, msg.sender, _support, weight);
    }
    
    /**
     * @dev Execute a passed proposal
     * @param _proposalId ID of the proposal to execute
     */
    function executeProposal(uint256 _proposalId) external {
        Proposal storage proposal = proposals[_proposalId];
        
        require(proposal.active, "Proposal not active");
        require(block.timestamp >= proposal.endTime, "Voting period not ended");
        require(!proposal.executed, "Proposal already executed");
        require(proposal.forVotes > proposal.againstVotes, "Proposal did not pass");
        
        proposal.executed = true;
        proposal.active = false;
        
        emit ProposalExecuted(_proposalId);
        
        // In a full implementation, this would execute the actual proposal action
        // For demonstration purposes, we just mark it as executed
    }
    
    /**
     * @dev Change the governance address (controlled by governance)
     * @param _newGovernance The new governance address
     */
    function setGovernance(address _newGovernance) external {
        require(msg.sender == governance, "Only governance");
        governance = _newGovernance;
    }
}