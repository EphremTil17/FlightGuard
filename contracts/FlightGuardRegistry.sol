// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7.0;

/**
 * @title FlightGuardRegistry
 * @dev Coordinates the different components of the FlightGuard ecosystem
 */
contract FlightGuardRegistry {
    // State variables
    address public policyContract;
    address public tokenContract;
    address public liquidityPoolContract;
    address public owner;
    
    // Registered airlines
    mapping(string => address) public registeredAirlines;
    
    // Trusted data sources
    mapping(address => bool) public trustedDataSources;
    
    // Events
    event PolicyContractUpdated(address indexed newPolicyContract);
    event TokenContractUpdated(address indexed newTokenContract);
    event LiquidityPoolUpdated(address indexed newLiquidityPool);
    event AirlineRegistered(string airlineCode, address airlineAddress);
    event DataSourceAdded(address indexed dataSource);
    event DataSourceRemoved(address indexed dataSource);
    
    /**
     * @dev Constructor sets initial owner
     */
    constructor() {
        owner = msg.sender;
    }
    
    /**
     * @dev Modifier to restrict access to owner
     */
    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this function");
        _;
    }
    
    /**
     * @dev Set the policy contract address
     * @param _policyContract Address of the FlightGuardPolicy contract
     */
    function setPolicyContract(address _policyContract) external onlyOwner {
        policyContract = _policyContract;
        emit PolicyContractUpdated(_policyContract);
    }
    
    /**
     * @dev Set the token contract address
     * @param _tokenContract Address of the FlightGuardToken contract
     */
    function setTokenContract(address _tokenContract) external onlyOwner {
        tokenContract = _tokenContract;
        emit TokenContractUpdated(_tokenContract);
    }
    
    /**
     * @dev Set the liquidity pool contract address
     * @param _liquidityPoolContract Address of the LiquidityPool contract
     */
    function setLiquidityPool(address _liquidityPoolContract) external onlyOwner {
        liquidityPoolContract = _liquidityPoolContract;
        emit LiquidityPoolUpdated(_liquidityPoolContract);
    }
    
    /**
     * @dev Register an airline in the system
     * @param _airlineCode IATA code for the airline (e.g., "AA" for American Airlines)
     * @param _airlineAddress Contract address or wallet for the airline
     */
    function registerAirline(string memory _airlineCode, address _airlineAddress) external onlyOwner {
        registeredAirlines[_airlineCode] = _airlineAddress;
        emit AirlineRegistered(_airlineCode, _airlineAddress);
    }
    
    /**
     * @dev Add a trusted data source for flight information
     * @param _dataSource Address of the oracle or data provider
     */
    function addTrustedDataSource(address _dataSource) external onlyOwner {
        trustedDataSources[_dataSource] = true;
        emit DataSourceAdded(_dataSource);
    }
    
    /**
     * @dev Remove a trusted data source
     * @param _dataSource Address of the oracle or data provider to remove
     */
    function removeTrustedDataSource(address _dataSource) external onlyOwner {
        trustedDataSources[_dataSource] = false;
        emit DataSourceRemoved(_dataSource);
    }
    
    /**
     * @dev Check if a data source is trusted
     * @param _dataSource Address to check
     * @return True if the data source is trusted
     */
    function isDataSourceTrusted(address _dataSource) external view returns (bool) {
        return trustedDataSources[_dataSource];
    }
    
    /**
     * @dev Transfer ownership of the registry
     * @param _newOwner Address of the new owner
     */
    function transferOwnership(address _newOwner) external onlyOwner {
        require(_newOwner != address(0), "New owner cannot be zero address");
        owner = _newOwner;
    }
    
    /**
     * @dev Get the airline address for a specific airline code
     * @param _airlineCode IATA code for the airline
     * @return The registered address for that airline
     */
    function getAirlineAddress(string memory _airlineCode) external view returns (address) {
        return registeredAirlines[_airlineCode];
    }
}