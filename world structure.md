# Ex Cinere — World Structure & Proximity Graph

In Ex Cinere, there is no GPS map. Physical movement is the only map, and the world is defined by who is physically near you right now.

---

# 1. THE PROXIMITY GRAPH

The world of CARAVAN is a dynamic graph where nodes are players/caravans and edges are BLE proximity links.

- **Nodes**: Individual caravans, merchant bots, raider bands, and base camps.
- **Edges (Bonds)**: Formed when two nodes are within ~10m for at least 30 seconds.
- **Topology**: The global network is an emergent structure created by player movement (commutes, markets, gatherings).

---

# 2. LOGICAL REGIONS (NATIONS)

While there is no physical map, the world is logically divided into Nations. Nations are not spatially assigned; they are opt-in political allegiances.

## 2.1 Nation Allegiance
- **Opt-in**: Players explicitly declare their allegiance to a Nation.
- **National Identity**: Nations are defined by their monetary policy, leadership, and member composition.
- **Proximity Effects**: Being in proximity to fellow nation members provides minor resource efficiency buffs and shared defensive bonuses.

---

# 3. TURF & SYNDICATE TERRITORY

Syndicates can declare "Turf," which is a logical layer over specific high-density proximity clusters.

- **Turf Declaration**: A syndicate leader can flag a specific network cluster (e.g., a known commuter hub or market) as their territory.
- **Tolls**: Players entering this "logical zone" (identified by the presence of multiple syndicate members) may be prompted to pay a Cipher toll or face increased raiding risk.
- **Stability**: Turf is not permanent; it exists only as long as the syndicate maintains a physical or economic presence in that proximity cluster.

---

# 4. BASE CAMPS (THE ANCHOR)

Base camps provide a semi-persistent physical anchor in the proximity graph.

- **Camp Mode**: When a player remains stationary for >5 minutes, their caravan enters "Camp Mode."
- **Bond Pausing**: Proximity bonds are paused while in camp mode to prevent "couch-bonding" exploits.
- **Resource Buffs**: Camps provide storage and production buffs to the caravan's survivors.
- **Persistence**: While survivors can die, camp structures and upgrades persist through hardcore death.

---

# 5. THE WASTE ECONOMY TOPOLOGY

The "map" of the wasteland is defined by the flow of resources through the proximity graph.

- **Supply Lines**: Formed by the physical movement of players carrying resources or commodity receipts.
- **Trade Hubs**: Emergent areas where high volumes of Merchant-mode players congregate physically.
- **Conflict Zones**: Areas with high Raider activity or where multiple syndicate turfs overlap.

---

# DESIGN INTENT

By removing the GPS map, CARAVAN forces players to focus on their immediate physical environment. The world structure is social and economic rather than geographic, ensuring that the game remains an "ambient" experience that integrates with the player's real-world movement.
