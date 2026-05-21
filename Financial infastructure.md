# Ex Cinere — Financial Infrastructure & Currency Systems

The Ex Cinere economy is a multi-currency simulation where physical proximity and market confidence define value.

---

# 1. CURRENCY TIERS

## 1.1 Tier 1 — Sovereign Valuables
The primary medium of exchange. Nations issue their own variants of Valuables.
- **Backing**: Configured by the national leader (Commodity-pegged, Free-floating, or Mixed reserve).
- **Taxation**: National leaders set tax rates on all market orders settled in their currency.
- **Destabilization**: Excessive inflation or sell pressure can trigger a currency collapse and snap election.

## 1.2 Tier 2 — Commodity Receipts
Player-issued notes representing a specific quantity of a physical resource.
- **Redemption**: Can only be redeemed when the issuer and holder are within BLE range (~10m).
- **Counterparty Risk**: If the issuer dies or refuses to redeem, the receipt becomes worthless. This creates an emergent credit market based on reputation.
- **Tradability**: Traded on the global order book independently of Valuables.

## 1.3 Tier 3 — Cipher (Syndicate Scrip)
Encrypted private ledgers maintained by syndicates.
- **Minting**: Only syndicate leaders can mint new Cipher (rate-limited based on Infamy and membership).
- **Cipher Bridge**: Bilateral agreements between syndicates to exchange scrip at a fixed or floating rate.
- **Anonymity**: Transactions are visible only to the syndicate leader and the parties involved.

---

# 2. MARKET SYSTEMS

## 2.1 Global Order Book
All tradeable assets (resources, gear, receipts, currency pairs) are traded on a single global order book.
- **Escrow**: Funds/assets are escrowed immediately upon order placement.
- **5% Auto-Match Rule**: Orders fill automatically when buy and sell prices are within 5% of each other.
- **Settlement**: Instant for digital assets; resource receipts require proximity for final physical redemption.

## 2.2 Derivative Markets
- **Futures**: Contracts for future delivery of resources.
- **Options**: Right to buy/sell resources at a specific price.
- **Hardcore Impact**: Large player deaths can cause massive slippage and liquidations in derivative markets.

---

# 3. BLACK MARKETS

Black markets operate primarily through Cipher and are inaccessible to players with high Reputation or those in Merchant mode.
- **Shadow Liquidity**: Syndicates provide liquidity for contraband and high-tier gear.
- **Bounties**: Paid out in Cipher for successful raids on high-value targets.
- **Protection Rackets**: Cipher-denominated tribute paid to syndicates for safe passage in "turf" zones.

---

# DESIGN INTENT

The financial system is designed to create a "triple-threat" economy: the stability of sovereign Valuables, the flexibility of Commodity Receipts, and the resilience of Syndicate Cipher. Every transaction carries either market risk or physical counterparty risk.
