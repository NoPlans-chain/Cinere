# Ex Cinere — Core Game Mechanics Specification

This is the mechanical backbone of the simulation, integrating Bluetooth proximity with a global macroeconomic engine.

---

# 1. PROXIMITY SIMULATION LAYER

| Mechanic | Description | Inputs | Outputs |
|---|---|---|---|
| BLE Bonding | Players within ~10m for 30s form a link. | BLE RSSI, Time | Proximity Bond |
| Chain Building | Multi-link chains (2-8 players) unlock shared bonuses. | Active Bonds | Chain Level, Buffs |
| Proximity Zones | Speed of bonding based on distance (0-3m: 2x, 3-10m: 1x). | Signal Strength | Bond Velocity |
| Chain Decay | Bonds decay at 50% per 48h without renewal. | Real-time Clock | Bond Strength |
| Anti-Gaming | Movement required (accelerometer); 90m cap per pair/day. | Sensor Data | Bond Validity |

---

# 2. COMBAT & SURVIVAL

| Mechanic | Description | Inputs | Outputs |
|---|---|---|---|
| Raid Resolution | 2-minute commitment window for secret allocation of forces. | Survivors, Gear | Pillage/Defense |
| Instakill Gap | Quadratic defensive bonus for low-level players vs high-level. | Level Differential | Death Chance |
| Hardcore Death | Level resets to 1; survivors lost; gear drops as BLE loot. | Combat Outcome | Level Reset, Loot |
| Survivor Roles | Scout, Medic, Engineer, Cook, Guard — each with specific buffs. | Role Assignment | Caravan Efficiency |
| Camp Mode | Stationary proximity (>5m) pauses chain; enables base buffs. | GPS/BLE Delta | Resource Bonus |

---

# 3. MACROECONOMIC ENGINE

| Mechanic | Description | Inputs | Outputs |
|---|---|---|---|
| Sovereign Valuables | National currencies with configurable backing (Commodity/Floating). | National Policy | Exchange Rates |
| Commodity Receipts | Player-issued notes redeemable for physical resources in proximity. | Resource Stock | Credit Market |
| Cipher Ledger | Syndicate-encrypted scrip for black market transactions. | Syndicate Minting | Shadow Liquidity |
| Order Book | Global asset trading with 5% auto-match fill rule. | Player/AI Orders | Price Formation |
| Currency Collapse | Coordinated sell pressure/embargos trigger snap elections. | Market Sentiment | Political Reset |

---

# 4. ENTITY TYPES

| Type | Behavior | Signal |
|---|---|---|
| Hostile (Raider) | Opt-in raiders or server bots; targets unchained players. | Hostile BLE Flag |
| Neutral | Civilian players; standard trade and bonding participation. | Default BLE Flag |
| Trader | Merchant-mode players or bots; protected from civilian attack. | Merchant BLE Flag |

---

# 5. TICK ENGINE RULES

| Rule | Description |
|---|---|
| Deterministic Execution | Same state + same seed = same outcome. |
| Hybrid Persistence | Street-level state (bonds) synced via BLE; Macro state via server ticks. |
| Hardcore Integrity | No level restoration; loss is the primary economic driver. |
| Offline Buffers | State synced when internet available; full offline proximity supported. |

---

# DESIGN PHILOSOPHY

CARAVAN is a **proximity social simulation** where physical presence is the only map. The macroeconomy exists to provide stakes for the survival game, and hardcore death ensures the market remains liquid. Information asymmetry and physical coordination are the player's primary weapons.
