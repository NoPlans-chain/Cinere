# Ex Cinere — Entities, Factions & NPC Behavior

Every entity in Ex Cinere is either a real player or a server-seeded bot broadcast via BLE. No server-spawned world exists; the game is populated entirely by the physical proximity of devices.

---

# 1. PLAYER & NPC MODES

Entities are distinguished by their opt-in behavior flags, which alter their BLE signature and available interactions.

## 1.1 Neutral (Civilian)
- **Behavior**: Standard commuters and social players.
- **Interactions**: Bonding, chain building, market trading.
- **Risk**: Can be raided by Raiders; protected from other civilians.

## 1.2 Hostile (Raider)
- **Behavior**: Predatory players or server-seeded bots.
- **Interactions**: Can initiate raids on unchained Neutrals.
- **Loot**: Access to Raider-only loot multipliers and the black market.
- **Consequence**: Accumulate Infamy; suffer reputation decay; targeted by bounties.

## 1.3 Friendly (Merchant)
- **Behavior**: Dedicated traders (players or bots).
- **Interactions**: Broadcast a recognizable "Merchant" BLE signal.
- **Protection**: Cannot attack or be attacked by civilians. Raiders attacking Merchants suffer severe Market Reputation penalties.

---

# 2. SYNDICATES (SHADOW POWER)

Syndicates are the primary organizational structure for Raiders and black market actors.

## 2.1 NPC Syndicates
- **Ancient Powers**: Permanent world fixtures with fixed trading patterns and Cipher networks.
- **Function**: Provide baseline black market liquidity. They do not seek political office but respond to national embargos with economic countermeasures.

## 2.2 Player Syndicates
- **Leader-Driven**: Formed by players with high Infamy.
- **Stability**: A player syndicate's Cipher value is tied to its leader's survival and standing.
- **Turf**: Can declare specific BLE network clusters as territory, imposing Cipher-denominated tolls.

---

# 3. NATIONS (POLITICAL POWER)

Nations are opt-in allegiances formed by players with high Reputation.

## 3.1 National Structure
- **Allegiance**: Membership is opt-in, not spatially assigned (since no GPS is used).
- **Leadership**: Elected by members. Leaders control the national treasury and monetary policy.
- **Geopolitical Conflict**: Nations fight syndicates and other nations through embargos, tariffs, and currency destabilization.

---

# 4. NPC BEHAVIOR LOGIC (BOTS)

Server-seeded bots ensure the world is never empty and provide predictable economic baselines.

| Bot Type | Behavior | Economic Role |
|---|---|---|
| Scavenger | Weak Raider bot | Basic resource drops for low-level players. |
| Raider Band | Coordinated bot group | Mid-tier threat; protects high-value loot drops. |
| Warlord Crew | Elite bot crew | Extreme threat; guards legendary gear and blueprints. |
| Merchant Bot | Static/Mobile trader | Sets baseline commodity prices in specific areas. |

---

# DESIGN INTENT

The entity system is designed to create a "living wasteland" where behavior reveals intent. By tying organization (Nations/Syndicates) to social metrics (Reputation/Infamy), the game creates emergent social structures that define the physical "map" through BLE proximity.
