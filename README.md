# FlightGuard: Blockchain-Based Flight Delay Insurance

FlightGuard is a decentralized flight delay insurance platform that leverages blockchain technology and Chainlink oracles to provide automated, transparent, and instant compensation for flight delays. The platform eliminates traditional claims processing by automatically triggering payouts based on verified flight data.

## Project Overview

Traditional flight delay insurance suffers from complex claims processes, payment delays, and lack of transparency. FlightGuard transforms this industry by:

- **Automated Claims Processing**: Smart contracts automatically detect delays and trigger payouts
- **Instant Compensation**: Payments delivered directly to wallets within minutes of qualifying delays
- **Transparent Verification**: All flight data and delay criteria are publicly verifiable on-chain
- **Global Accessibility**: Available to anyone with a crypto wallet, regardless of location
- **Community Governance**: Token holders participate in protocol decisions and parameter updates

## Architecture

FlightGuard consists of four main smart contracts that work together to create a complete decentralized insurance ecosystem:

### Core Contracts

1. **FlightGuardPolicy.sol** - Main insurance contract handling policy creation, verification, and payouts
2. **FlightGuardToken.sol** - ERC-20 governance token with voting capabilities
3. **LiquidityPool.sol** - Community-backed insurance fund with staking rewards
4. **FlightGuardRegistry.sol** - Contract coordination and ecosystem management

## Smart Contract Features

### FlightGuardPolicy Contract

- **Tiered Insurance Plans**: Basic (1hr threshold), Premium (2hr threshold), Enterprise (3hr threshold)
- **Parametric Payouts**: Graduated compensation based on delay duration (25%, 50%, 100%)
- **Chainlink Integration**: Real-time flight data verification from trusted oracles
- **Multi-tier Premium Calculation**: Risk-based pricing with 2x-4x payout multipliers

### FlightGuardToken Contract

- **ERC-20 Compatibility**: Standard token functionality with 1M initial supply
- **Governance System**: Proposal creation and weighted voting mechanisms
- **Minimum Stake Requirements**: 1000 tokens required for proposal creation
- **Time-locked Voting**: 7-day voting periods for democratic decision making

### LiquidityPool Contract

- **Community Staking**: Token holders can stake to back insurance policies
- **Premium Distribution**: Stakers receive proportional shares of collected premiums
- **Flexible Staking**: Stake/unstake functionality with automatic reward claims
- **Emergency Provisions**: Admin controls for critical claim payouts

### FlightGuardRegistry Contract

- **Contract Coordination**: Centralized management of ecosystem components
- **Airline Registration**: IATA code mapping to blockchain addresses
- **Data Source Verification**: Trusted oracle and data provider management
- **Upgrade Management**: Coordinated contract upgrades across the ecosystem

##  Technology Stack

- **Blockchain**: Ethereum (with Layer 2 compatibility)
- **Oracle Network**: Chainlink for real-time flight data
- **Smart Contract Language**: Solidity ^0.8.7
- **Development Environment**: Remix IDE
- **Token Standard**: ERC-20

##  Prerequisites

- Ethereum wallet (MetaMask recommended)
- LINK tokens for oracle requests
- Test ETH for gas fees (on testnets)

##  Deployment

### Local Development

1. Open [Remix IDE](https://remix.ethereum.org/)
2. Create a new workspace
3. Import the contract files
4. Compile with Solidity ^0.8.7
5. Deploy to JavaScript VM for testing

### Testnet Deployment

1. Configure Remix for Sepolia testnet
2. Ensure wallet has test ETH and LINK tokens
3. Deploy contracts in order:
   ```
   1. FlightGuardToken
   2. FlightGuardRegistry
   3. LiquidityPool
   4. FlightGuardPolicy
   ```
4. Configure contract addresses in Registry

##  Usage Examples

### Purchase Insurance Policy

```solidity
// Purchase Premium tier policy for flight AA101
policyContract.purchasePolicy{value: 0.01 ether}(
    "AA101",                    // Flight number
    1640995200,                 // Departure timestamp
    2                           // Tier level (Premium)
);
```

### Stake in Liquidity Pool

```solidity
// Approve tokens for staking
tokenContract.approve(poolAddress, 1000 * 10**18);

// Stake 1000 tokens
poolContract.stake(1000 * 10**18);
```

### Create Governance Proposal

```solidity
// Create proposal to update oracle parameters
tokenContract.createProposal(
    "Update minimum delay threshold to 90 minutes for all tiers"
);
```

##  Key Features

### For Travelers
- **No Claims Process**: Automatic payout upon verified delays
- **Instant Compensation**: Receive payment within minutes
- **Transparent Terms**: Immutable policy conditions on blockchain
- **Global Coverage**: Works for international flights

### For Token Holders
- **Governance Rights**: Vote on protocol parameters and upgrades
- **Staking Rewards**: Earn from insurance premiums
- **Proposal Creation**: Submit improvement proposals
- **Community Ownership**: Decentralized protocol governance

### For the Ecosystem
- **Oracle Integration**: Reliable flight data from Chainlink network
- **Scalable Architecture**: Modular design for easy upgrades
- **Cross-chain Ready**: Architecture supports multiple blockchain networks
- **Regulatory Compliance**: Framework for meeting insurance regulations

##  Security Considerations

- **Oracle Dependence**: Relies on Chainlink network for flight data accuracy
- **Smart Contract Audits**: Contracts should be audited before mainnet deployment
- **Liquidity Management**: Pool must maintain sufficient funds for claims
- **Governance Attacks**: Token distribution should prevent governance manipulation

##  Economics

### Premium Structure
- **Basic Tier**: 2x payout multiplier, 1-hour delay threshold
- **Premium Tier**: 3x payout multiplier, 2-hour delay threshold  
- **Enterprise Tier**: 4x payout multiplier, 3-hour delay threshold

### Token Economics
- **Total Supply**: 1,000,000 FGT tokens
- **Governance Threshold**: 1,000 tokens minimum for proposals
- **Staking Rewards**: Proportional distribution of collected premiums
- **Voting Weight**: Linear relationship to token holdings

##  Disclaimer

FlightGuard is experimental software. Users should understand the risks involved in:
- Smart contract interactions
- Cryptocurrency transactions
- Oracle dependency
- Regulatory compliance in their jurisdiction

This software is provided "as is" without warranty of any kind.

---