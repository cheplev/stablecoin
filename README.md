# Overcollateralized Stablecoin backed by ETH and wBTC

## 1. Relative Stability: Anchored or Pegged -> $1.00

- **1.1 Chainlink Price Feed:**  
  The stablecoin price is anchored to $1.00 using Chainlink's price feeds.

- **1.2 Set a function to exchange ETH & BTC -> USD:**  
  A function is set up to allow conversion between ETH, wBTC, and USD for price stability.

## 2. Stability Mechanism (Minting): Algorithmic (Decentralized)

- **2.1 Minting:**  
  Users can mint the stablecoin only if they have enough collateral. This is coded into the smart contract.

## 3. Collateral: Exogenous (Crypto)

- **3.1 wETH**  
- **3.2 wBTC**

## How it works:

1. Users deposit wETH or wBTC as collateral.
2. The algorithm checks the collateral ratio.
3. If sufficient collateral is provided, the stablecoin is minted.
4. The system uses Chainlink price feeds to maintain price stability.
