# Ex Cinere — Missing Implementations & Unfinished Components

## Overview
This document catalogs all functions, scripts, and systems that are referenced in the codebase or design documents but are either **not yet implemented**, **stubbed out**, or **incomplete**.

---

## 🔴 CRITICAL MISSING SYSTEMS

### 1. **TickProcessor - Core Game Loop (Incomplete)**
**File:** `tickProcessor.js`  
**Status:** Partially stubbed  
**Issue:** The `runTick()` method only fetches sample data. It does NOT execute the actual game simulation.

#### What's Missing:
- [ ] **Economy tick processing** - should call `processEconomyTick()` from `economyWorker.js`
- [ ] **Trading worker integration** - should call `executeLeaderTrade()` and `processNPCLifecycle()` from `tradingWorker.js`
- [ ] **Market price updates** - should call `getMarketPrice()` to update all resource prices
- [ ] **Tick summary calculation** - aggregating trades, orders, and events for the tick
- [ ] **News feed generation** - should create news_feed entries for significant events
- [ ] **Logging system** - should write comprehensive tick_logs for debugging
- [ ] **State persistence** - should atomically update all tables with new tick state
- [ ] **Error handling & rollback** - if tick fails mid-execution, should roll back to safe state

#### Expected Implementation:
```javascript
export class TickProcessor {
  async runTick() {
    const tickId = await this.createTickRecord();
    
    try {
      // 1. Fetch world state
      const regions = await this.pullTable('regions');
      const npcs = await this.pullTable('ai_traders');
      
      // 2. Process economy
      const updatedRegions = processEconomyTick(regions, globalTradeVolume);
      
      // 3. Process trading
      for (const region of updatedRegions) {
        executeLeaderTrade(region, currentPrice);
      }
      
      // 4. Process NPC lifecycle
      const npcsNext = processNPCLifecycle(npcs, currentPrice, priceChange);
      
      // 5. Update market prices
      const newPrices = await this.updateMarketPrices(tickId);
      
      // 6. Generate news events
      await this.generateNewsEvents(tickId, updatedRegions);
      
      // 7. Write tick logs
      await this.writeLogs(tickId);
      
      // 8. Mark tick complete
      await this.completeTick(tickId);
    } catch (err) {
      await this.rollbackTick(tickId, err);
      throw err;
    }
  }
}
```

---

### 2. **Frontend UI/UX Layer (Mostly Missing)**
**Location:** `app/` and `./App.jsx`  
**Status:** Skeleton only

#### What's Missing:
- [ ] **app/page.tsx** - Currently imports from non-existent `@/utils/supabase/server`
- [ ] **utils/supabase/server.ts** - Server-side Supabase client (referenced but doesn't exist)
- [ ] **Real-time subscription handlers** - WebSocket or Supabase realtime for live market updates
- [ ] **Mobile responsiveness** - App.jsx is desktop-focused, needs mobile optimization
- [ ] **BLE integration** - No Bluetooth Low Energy communication layer implemented
- [ ] **Proximity UI** - Should visualize nearby players/entities
- [ ] **Market UI components** - Order book viewer, trading interface
- [ ] **Survivor management** - Role assignment, camp upgrades
- [ ] **Combat resolution UI** - 2-minute commitment window visualizer
- [ ] **News ticker** - Live event feed from economy
- [ ] **Character creation/respawn flow** - Death recovery UI

#### Expected New Files:
```
app/
├── layout.tsx (exists but minimal)
├── page.tsx (exists but broken)
├── (routes)/
│   ├── market/
│   │   └── page.tsx
│   ├── combat/
│   │   └── page.tsx
│   ├── caravan/
│   │   └── page.tsx
│   ├── politics/
│   │   └── page.tsx
│   └── ...
├── components/
│   ├── ProximityFeed.tsx
│   ├── OrderBook.tsx
│   ├── CombatWindow.tsx
│   ├── SurvivorManager.tsx
│   ├── NewsFeed.tsx
│   └── ...
└── hooks/
    ├── useRealtime.ts
    ├── useMarket.ts
    ├── useBLE.ts
    └── ...

utils/
├── supabase/
│   ├── server.ts (missing)
│   ├── client.ts (missing)
│   └── types.ts (missing)
└── ...
```

---

### 3. **BLE (Bluetooth Low Energy) Module (Not Started)**
**Status:** 0% implementation  
**Referenced in:** masterdesign, devplan  

#### What's Missing:
- [ ] **BLE Advertising & Scanning** - iOS background mode + Android service
- [ ] **Proximity detection** - 10m range, 30s min link time
- [ ] **Motion validation** - Accelerometer check to prevent stationary farming
- [ ] **Device identification** - Anonymous rotating token system
- [ ] **Chain management** - Multi-link chain state tracking
- [ ] **Anti-cheat layer** - Spoofing detection, rate limiting
- [ ] **Offline fallback** - Sync state when connectivity restored

#### Expected New Files:
```
ble/
├── BLEService.ts (iOS)
├── BLEService.android.ts
├── ProximityEngine.ts
├── ChainManager.ts
├── AntiCheat.ts
├── MotionValidator.ts
└── ...
```

---

### 4. **Combat System (Core Logic Missing)**
**Status:** Design exists, code doesn't  
**Referenced in:** masterdesign, devplan  

#### What's Missing:
- [ ] **RaidEngine** - Asynchronous combat resolution
  - 2-minute commitment window
  - Secret allocation of fighters & equipment
  - Outcome calculation with variance
- [ ] **DefensiveInstakill** - Level gap mechanic
  ```javascript
  instakill_chance = (level_gap / 98)^2 * 35%
  ```
- [ ] **LootDrop** - Loot chest creation & decay
  - Killer priority (60s exclusive window)
  - Chain member access
  - 10-minute decay
- [ ] **SurvivorInjury** - Injury state tracking
- [ ] **PermaDeath** - Level reset, reputation preservation

#### Expected New Files:
```
combat/
├── RaidEngine.ts
├── CombatResolver.ts
├── LootSystem.ts
├── PermadeathHandler.ts
├── DefensiveInstakill.ts
└── ...
```

---

### 5. **Economic Simulation (Partially Stubbed)**
**Status:** Helper functions exist, integration missing

#### economyWorker.js Issues:
- [x] `processEconomyTick()` - Exists but **not called anywhere**
- [ ] Regional strategy calculations need calibration
- [ ] Production/consumption deltas need persistence
- [ ] Disease/war intensity feedback loop needs testing

#### tradingWorker.js Issues:
- [x] `executeLeaderTrade()` - Exists but **not called anywhere**
- [x] `processNPCLifecycle()` - Exists but **not called anywhere**
- [x] `getMarketPrice()` - Exists but **not called anywhere**
- [ ] NPC initialization needs to populate database
- [ ] Sentiment-based trading needs market data integration
- [ ] Birth/death mechanics need to be driven by regional state

#### What's Missing:
- [ ] **Market matching engine** - 5% auto-match rule implementation
- [ ] **Price discovery** - How market prices settle given supply/demand
- [ ] **Derivative pricing** - Futures/options valuation
- [ ] **Treasury management** - Nation spending, tariff collection
- [ ] **Embargo mechanics** - Supply/demand impact on prices
- [ ] **Currency backing** - Commodity peg validation
- [ ] **Cipher minting rate-limiter** - Syndicate inflation control

#### Expected New Files:
```
economy/
├── MarketMatcher.ts
├── PriceDiscovery.ts
├── DerivativePricer.ts
├── TreasuryManager.ts
├── EmbargoPolicyEngine.ts
├── CurrencyValidator.ts
└── ...
```

---

### 6. **Political System (Design Only)**
**Status:** Referenced but not implemented  

#### What's Missing:
- [ ] **ElectionSystem** - Reputation-gated voting
- [ ] **LeaderPowers** - Embargo, tariff, policy enforcement
- [ ] **NationFormation** - How new nations spawn
- [ ] **SnapElection** - Currency collapse triggers
- [ ] **SyndicateManagement** - Cipher ledger, bounties, protection rackets
- [ ] **Turf system** - BLE cluster territorial claims
- [ ] **AntiCheat** - Prevent vote manipulation

#### Expected New Files:
```
politics/
├── ElectionEngine.ts
├── LeaderPolicies.ts
├── NationManager.ts
├── SyndicateManager.ts
├── TurfManager.ts
├── BountySystem.ts
└── ...
```

---

### 7. **Character & Progression System (Design Only)**
**Status:** Database schema exists, logic missing  

#### What's Missing:
- [ ] **SurvivorRoles** - Scout, Medic, Engineer, Cook, Guard implementations
- [ ] **SkillTrees** - Level progression for each role
- [ ] **ReputationSystem** - Tracking reputation gains/decay
- [ ] **InfamySystem** - Tracking infamy gains/decay
- [ ] **AccessThresholds** - Syndicate membership, political candidacy gates
- [ ] **CampManagement** - Upgrades, resource generation, buffs
- [ ] **ChainBonuses** - 8-tier bonus system implementation

#### Expected New Files:
```
character/
├── SurvivorManager.ts
├── SkillSystem.ts
├── ReputationEngine.ts
├── InfamyEngine.ts
├── CampSystem.ts
├── ChainBonusCalculator.ts
└── ...
```

---

### 8. **Database Sync & Persistence (Partially Stubbed)**
**Files:** `tickProcessor.js`, `seed.js`  
**Status:** Basic operations exist, complex transactions missing

#### What's Missing:
- [ ] **Atomic transactions** - Multi-table state changes
- [ ] **Conflict resolution** - Offline updates vs. server state
- [ ] **Data validation** - Constraints enforcement
- [ ] **Audit logging** - Who changed what, when
- [ ] **Batch operations** - Efficient bulk updates
- [ ] **State recovery** - Tick-level rollback on error
- [ ] **Subscription management** - Real-time broadcast system

#### Expected New Files:
```
db/
├── TransactionManager.ts
├── ConflictResolver.ts
├── Validator.ts
├── AuditLog.ts
├── BatchOperations.ts
├── StateRecovery.ts
└── ...
```

---

## 🟡 PARTIAL IMPLEMENTATIONS

### Already Have (But Incomplete):
1. **supabase.js** - Client initialization ✅, but missing error handling and retry logic
2. **App.jsx** - Basic UI shell ✅, but missing routing, modals, and interactive features
3. **economyWorker.js** - Regional math ✅, but not integrated into tick processor
4. **tradingWorker.js** - NPC trading logic ✅, but NPC population not seeded
5. **seed.js** - World initialization ✅, but only creates minimal data
6. **db-verify.js** - Schema validation ✅, but doesn't test data integrity constraints

---

## 🟢 EXISTING FOUNDATIONS

### These Files Are Complete (or Nearly So):
- ✅ `schema.sql` - Comprehensive database schema
- ✅ `.gitignore` - Proper secrets handling
- ✅ `package.json` - Dependencies installed
- ✅ `index.js` - Tick loop bootstrap
- ✅ `tickProcessor.js` - Database connection & CSV export utilities
- ✅ `middleware.ts` - Supabase middleware setup

---

## 📋 IMPLEMENTATION PRIORITY

### Phase 1: Core Simulation (URGENT)
1. [ ] Complete `TickProcessor.runTick()` - Call workers, update state, log results
2. [ ] Create `MarketMatcher.ts` - 5% auto-match rule for order book
3. [ ] Create `NPC seeding script` - Populate `ai_traders` with initial population
4. [ ] Create `RealtimeSubscriptions.ts` - Push updates to connected clients

### Phase 2: Frontend MVP (HIGH)
1. [ ] Create `utils/supabase/server.ts` - Server client for app/page.tsx
2. [ ] Create `ProximityFeed.tsx` - Nearby entity visualization
3. [ ] Create `OrderBook.tsx` - Simple trading UI
4. [ ] Create `CombatWindow.tsx` - Raid resolution UI

### Phase 3: Game Mechanics (MEDIUM)
1. [ ] Implement `RaidEngine.ts` - Combat resolution
2. [ ] Implement `LootSystem.ts` - Loot drops & expiry
3. [ ] Implement `ReputationEngine.ts` - Score tracking
4. [ ] Implement `ChainBonusCalculator.ts` - 8-tier bonus system

### Phase 4: Advanced Systems (LOWER PRIORITY)
1. [ ] BLE module - Phone-specific integration
2. [ ] Political system - Elections, embargoes
3. [ ] Syndicate system - Cipher ledger, bridges
4. [ ] Derivatives - Options & futures pricing

---

## 🛠️ Quick Reference: What to Build Next

### If you want the simulation running:
**Start with**: Complete `tickProcessor.js` → Add `MarketMatcher.ts` → Seed NPCs

### If you want a playable UI:
**Start with**: Create `/utils/supabase/server.ts` → Fix `app/page.tsx` → Add `ProximityFeed.tsx`

### If you want combat working:
**Start with**: Create `RaidEngine.ts` → `LootSystem.ts` → `DefensiveInstakill.ts`

### If you want economics working:
**Start with**: Wire `tickProcessor.js` → `MarketMatcher.ts` → `PriceDiscovery.ts`

---

## 📝 Notes

- **All missing systems are in the masterdesign document.** Reference it for specifications.
- **Workers are built but orphaned.** `economyWorker.js` and `tradingWorker.js` contain solid logic but nothing calls them.
- **Database schema is complete.** All tables exist and are properly structured in `schema.sql`.
- **Testing is missing entirely.** No unit tests, integration tests, or simulation harnesses.
- **Documentation is strong.** The game design (masterdesign) and development plan (devplan) are thorough; code just lags behind.

---

**Last Updated:** 2026-05-21  
**Status:** Ex Cinere MVP is ~20% implemented (core systems exist, integration is missing)
