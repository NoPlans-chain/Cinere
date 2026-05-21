# Ex Cinere — LLM Development Protocol & Engineering Rules

This document defines how ALL future code generation for Ex Cinere must behave. Treat this as the project's constitutional law.

---

# 1. PROJECT IDENTITY

## Project Name
**Ex Cinere**

## Project Type
Proximity-based social survival RPG and political economy simulation.

## Core Principle
The simulation is:
- **Proximity-First**: Physical presence (BLE) is the only map.
- **Deterministic**: Same state + same seed = same outcome.
- **Hardcore**: Death is permanent for survivors; loss is the primary economic driver.
- **Systemic**: Markets, politics, and survival are deeply interconnected.

---

# ⚙️ 2. GLOBAL ENGINEERING RULES

| Rule | Description |
|---|---|
| No Placeholder Data | Never use fake hardcoded values in production components. |
| No GPS Usage | The game must never request or use GPS data for positioning. |
| BLE Authority | Proximity bonds must be validated via signal strength and motion. |
| Hardcore Integrity | No level restoration or death protection beyond the 10m grace period. |
| Deterministic Ticks | Economic state may only update through the tick worker. |
| Modular Systems | Proximity, Combat, and Economy must be independently testable. |

---

# 🖥️ 4. FRONTEND RULES (MOBILE FIRST)

## Approved Stack
- **Framework**: React / Vite
- **Styling**: TailwindCSS
- **Visual Identity**: Near-black navy background, burnt orange text, maroon panels (Terminal aesthetic).

## Frontend Constraints
- **BLE Priority**: Scanning and advertising must persist in background mode.
- **Privacy First**: Broadcast only anonymous rotating tokens; no real identity.
- **Offline Support**: Full proximity functionality without active internet; sync on reconnect.

---

# 🔁 6. TICK ENGINE RULES

## Tick Sequence (MANDATORY)
1. Load global world state.
2. Process proximity bond renewals/decays.
3. Resolve pending raids (asynchronous resolution).
4. Update resource consumption for all active caravans.
5. Aggregate market orders (Valuables, Receipts, Cipher).
6. Price formation (Global order book).
7. Execute trades and update portfolios.
8. Process political shifts (Elections, Tariffs, Embargos).
9. Update Reputation and Infamy scores.
10. Persist new state to Supabase.

---

# 🧪 10. TESTING RULES

Every generated system must include:
- **Error Handling**: Graceful failure for BLE connection/sync issues.
- **Console Logging**: Debug visibility for proximity bond formation.
- **Type Safety**: Use TypeScript to prevent undefined survivor or asset states.
- **DB Validation**: Verify successful hardcore state updates (level resets).

---

# ⚠️ 12. CRITICAL ANTI-PATTERNS

- **Hardcoded Market Data**: Breaks the living economy.
- **GPS Dependency**: Violates the core proximity-only design.
- **Scripted Combat**: Combat must resolve via secret player allocation and RNG.
- **Restorable Death**: Death must remain permanent to maintain market liquidity.
