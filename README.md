# eBTC Stability Module

## Overview

The BSM contract facilitates bi-directional exchange between eBTC and other BTC-denominated assets with no slippage. 

## Asset Vault

The BSM uses asset vaults to make the architecture more modular. This modular design allows the BSM to perform external lending by depositing idle assets into various money markets. This external lending capability is controlled through a configurable liquidity buffer (100% buffer maintains full reserves). Any yields generated from these lending activities contribute to protocol revenue, which governance can allocate to incentivize stEBTC.

## Fee Mechanism

The BSM can optionally charge a fee on swap operations. The fee percentage is controlled by governance and is capped at 20%.

## Oracle Module

The Oracle Module pauses minting if the asset price drops too much relative to eBTC. This check does not apply to eBTC burning because it reduces overall system risk.

## Minting Cap

The BSM employs a dynamic minting cap based on the eBTC total supply TWAP, which restricts the amount of eBTC that can be created through asset deposits. This security feature provides controlled exposure to external assets, protecting the system from potential manipulation.
