# Ex Cinere — Complete Player Action Specification

This document defines every meaningful action a player performs inside the Ex Cinere simulation.

---

# 👤 1. CARAVAN & IDENTITY ACTIONS

| Action | Description | Result |
|---|---|---|
| Initialize Caravan | Generate anonymous identity and first survivors | Profile + camp initialized |
| Customize Camp | Apply cosmetic upgrades to base camp | Visual identity |
| Rename Caravan | Use token to change broadcast name | New BLE identity |
| Toggle Mode | Switch between Neutral, Raider, or Merchant | Signal & behavior shift |
| View Lost Caravan | Inspect history of fallen survivors | Memorialization |

---

# 📡 2. PROXIMITY & SOCIAL ACTIONS

| Action | Description | Result |
|---|---|---|
| Form Bond | Stay in range of another player for 30s | Initial link formed |
| Build Chain | Link multiple caravans together | Shared defensive/economic buffs |
| Renew Bond | Re-enter proximity of chain-mate | Prevents bond decay |
| Invite to Chain | Explicitly request link with nearby player | Faster chain formation |
| Leave Chain | Voluntarily break proximity links | Loss of shared buffs |

---

# ⚔️ 3. COMBAT & RAID ACTIONS

| Action | Description | Result |
|---|---|---|
| Initiate Raid | Target unchained player (Raider mode only) | 2-minute resolution window |
| Allocate Survivors | Commit specific survivors to raid/defense | Power calculation |
| Use Consumable | Apply gear buffs during resolution window | Tactical advantage |
| Claim Loot | Interact with BLE loot chest within window | Asset acquisition |
| Defend Chain | Apply defensive bonus to attacked link | Collective security |

---

# 💰 4. CURRENCY & MARKET ACTIONS

| Action | Description | Result |
|---|---|---|
| Buy/Sell Valuables | Trade sovereign currencies on order book | Exposure to national policy |
| Issue Receipt | Create commodity note redeemable in proximity | Credit issuance |
| Redeem Receipt | Exchange receipt for resources via BLE link | Asset settlement |
| Mint Cipher | Issue syndicate scrip (Leader only) | Shadow liquidity |
| Establish Bridge | Create exchange agreement between syndicates | Bilateral liquidity |
| Place Order | Add buy/sell to global book (5% match) | Market participation |

---

# 🏛️ 5. POLITICAL & GOVERNANCE ACTIONS

| Action | Description | Result |
|---|---|---|
| Run for Election | Declare candidacy in chosen nation | Potential leadership |
| Vote | Support candidate in national election | Political influence |
| Set Monetary Policy | Define currency backing (Leader only) | Valuation shift |
| Impose Embargo | Restrict trade of specific commodities | Economic warfare |
| Set Tariffs | Apply tax to foreign trade | Revenue / Trade barrier |

---

# 🏗️ 6. CARAVAN MANAGEMENT ACTIONS

| Action | Description | Result |
|---|---|---|
| Assign Roles | Distribute survivors to Scout, Medic, etc. | Functional buffs |
| Upgrade Camp | Build structures for resource storage/buffs | Persistent base growth |
| Manage Resources | Balance Food, Water, Fuel, Scrap, Meds | Survival stability |
| Equip Survivors | Assign gear/weapons to survivors | Combat/Efficiency boost |

---

# 🎮 CORE GAME LOOP

```text
Enter Proximity (BLE)
        ↓
Build Chain / Trade
        ↓
Survive Raids / Scarcity
        ↓
Accumulate Valuables / Cipher
        ↓
Influence National Markets
        ↓
Shape the Wasteland Economy
```

---

# 🧠 DESIGN PRINCIPLE

Every action in CARAVAN is rooted in physical proximity or its macroeconomic consequences. Hardcore death ensures that every decision carries weight, and the proximity-first design ensures the "map" is always human.
