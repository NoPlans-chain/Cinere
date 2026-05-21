# Ex Cinere — CRITICAL MISSING COMPONENTS & ARCHITECTURAL GAPS

> This is a deep audit of everything blocking production. I found **12 major system gaps** + **infrastructure issues**.

---

## 🔴 TIER 1: BLOCKING ISSUES (Must Fix Before Anything Runs)

### 1. NO BACKEND API ROUTES
**Status:** 0% implemented  
**Impact:** Frontend can't talk to backend  
**Location:** Should be `app/api/` directory (doesn't exist)

#### Missing Routes:
```
app/api/
├── proximity/
│   ├── validate         (POST) - Server-side chain validation
│   ├── submit          (POST) - Client submits proximity events
│   └── subscribe       (WS) - Realtime proximity updates
├── market/
│   ├── orders/submit   (POST) - Place order
│   ├── orders/cancel   (POST) - Cancel order
│   ├── orders/list     (GET) - Get player's orders
│   ├── prices          (GET) - Get current market prices
│   └── orderbook       (WS) - Realtime order book updates
├── combat/
│   ├── raid/initiate   (POST) - Start a raid
│   ├── raid/commit     (POST) - Commit fighters/equipment
│   └── raid/resolve    (GET) - Get raid outcome
├── game/
│   ├── tick            (GET) - Get current tick state
│   ├── news            (GET) - Get news feed
│   ├── player/me       (GET) - Get current player
│   └── world/state     (GET) - Get global world state
├── politics/
│   ├── elections/vote  (POST) - Vote in election
│   ├── vote/info       (GET) - Get election info
│   └── policy          (GET) - Get nation policies
└── admin/
    ├── seed/world     (POST) - Initialize world
    ├── tick/process   (POST) - Manual tick trigger
    └── health         (GET) - System health check
```

**Why this blocks everything:**
- Frontend has no way to submit proximity data
- Market can't match orders
- Combat can't resolve
- Elections can't count votes
- **Every feature is blocked**

#### Quick Implementation Order:
1. [ ] `/api/game/player/me` — Player identity (needed for everything)
2. [ ] `/api/game/tick` — Current game state
3. [ ] `/api/proximity/submit` — Client sends nearby devices
4. [ ] `/api/market/orders/submit` — Place buy/sell order
5. [ ] `/api/market/orderbook` — Subscribe to price updates
6. [ ] `/api/combat/raid/initiate` — Start combat
7. [ ] All other routes can be async

---

### 2. NO UTILS/SUPABASE/SERVER.TS
**Status:** Referenced but doesn't exist  
**Impact:** Frontend can't authenticate or query database  
**Location:** `utils/supabase/server.ts` (missing)

#### What `app/page.tsx` expects:
```typescript
// This file references:
import { createClient } from '@/utils/supabase/server'

// But this doesn't exist!
```

#### Missing Files:
```
utils/supabase/
├── server.ts          (MISSING) - Server-side Supabase client
├── client.ts          (MISSING) - Client-side browser client
├── middleware.ts      (EXISTS but incomplete)
└── types.ts           (MISSING) - TypeScript types
```

#### Create `utils/supabase/server.ts`:
```typescript
// utils/supabase/server.ts
import { createServerClient, type CookieOptions } from '@supabase/ssr'
import { cookies } from 'next/headers'

export async function createClient() {
  const cookieStore = await cookies()

  return createServerClient(
    process.env.NEXT_PUBLIC_SUPABASE_URL!,
    process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY!,
    {
      cookies: {
        getAll() {
          return cookieStore.getAll()
        },
        setAll(cookiesToSet) {
          try {
            cookiesToSet.forEach(({ name, value, options }) =>
              cookieStore.set(name, value, options)
            )
          } catch {
            // Cookie not available during build
          }
        },
      },
    }
  )
}
```

---

### 3. CHECKLIST.MD IS COMPLETELY WRONG
**Status:** Describes React stream utilities (not Ex Cinere)  
**Impact:** Confusing + nobody knows actual project status

The file talks about "Stream Parser Robustness" and "Fizz renderer" — this is copy-pasted from a different project entirely.

**Should be replaced with actual Ex Cinere tasks:**
- [ ] BLE proximity engine
- [ ] TickProcessor integration
- [ ] Market matching engine
- [ ] Combat resolution
- [ ] Political system

---

### 4. ENVIRONMENT VARIABLES NOT DOCUMENTED
**Status:** `.env` is gitignored (good), but no `.env.example` exists  
**Impact:** New devs don't know what to configure

#### Create `.env.example`:
```bash
# Supabase
NEXT_PUBLIC_SUPABASE_URL=https://your-project.supabase.co
NEXT_PUBLIC_SUPABASE_ANON_KEY=eyJhbGc...
SUPABASE_SERVICE_ROLE_KEY=eyJhbGc... (server-only)

# Game Config
NEXT_PUBLIC_TICK_INTERVAL_MS=300000
NEXT_PUBLIC_MAX_CHAIN_LENGTH=8
NEXT_PUBLIC_ANTI_CHEAT_BAN_THRESHOLD=-50

# API
NEXT_PUBLIC_API_BASE_URL=http://localhost:3000

# Analytics (optional)
NEXT_PUBLIC_SENTRY_DSN=
```

---

## 🟡 TIER 2: MAJOR ARCHITECTURAL GAPS (High Priority)

### 5. NO AUTHENTICATION LAYER
**Status:** 0% implemented  
**Impact:** Anyone can impersonate anyone else

#### Missing:
```typescript
// auth/
├── useAuth.ts         - React hook for current user
├── protectedRoute.ts  - Middleware to guard routes
├── login.ts           - Login/signup logic
└── logout.ts          - Logout logic

// app/auth/
├── login/page.tsx     - Login UI
├── signup/page.tsx    - Signup UI
├── callback/page.tsx  - OAuth callback (Supabase)
└── logout/page.tsx    - Logout endpoint
```

#### Minimal Auth Setup:
```typescript
// app/api/auth/callback/route.ts
import { createClient } from '@/utils/supabase/server'
import { NextRequest, NextResponse } from 'next/server'

export async function GET(request: NextRequest) {
  const { searchParams } = new URL(request.url)
  const code = searchParams.get('code')

  if (code) {
    const supabase = await createClient()
    await supabase.auth.exchangeCodeForSession(code)
  }

  return NextResponse.redirect(new URL('/game', request.url))
}
```

---

### 6. NO REALTIME SUBSCRIPTIONS
**Status:** 0% implemented  
**Impact:** Updates are stuck in 5-second batches

#### Missing:
```typescript
// hooks/
├── useProximityUpdates.ts    - Subscribe to nearby devices
├── useMarketUpdates.ts       - Subscribe to price changes
├── useCombatUpdates.ts       - Subscribe to raid status
├── useNewsUpdates.ts         - Subscribe to news feed
└── useRealtimeSubscription.ts - Generic realtime hook
```

#### Quick Implementation:
```typescript
// hooks/useProximityUpdates.ts
import { useEffect, useState } from 'react'
import { useSupabaseClient } from '@supabase/auth-helpers-react'

export function useProximityUpdates(playerId: string) {
  const supabase = useSupabaseClient()
  const [devices, setDevices] = useState([])

  useEffect(() => {
    const subscription = supabase
      .channel(`proximity:${playerId}`)
      .on('postgres_changes', {
        event: 'INSERT',
        schema: 'public',
        table: 'proximity_events',
        filter: `player_id=eq.${playerId}`
      }, (payload) => {
        setDevices(payload.new.nearby_devices)
      })
      .subscribe()

    return () => subscription.unsubscribe()
  }, [playerId, supabase])

  return devices
}
```

---

### 7. NO ERROR HANDLING OR LOGGING
**Status:** 0% implemented  
**Impact:** Bugs are silent; impossible to debug

#### Missing:
```typescript
// lib/
├── logger.ts          - Centralized logging
├── errorHandler.ts    - Global error boundary
├── metrics.ts         - Prometheus/Datadog metrics
└── sentry.ts          - Error tracking

// app/
└── error.tsx          - Global error page
```

#### Minimal Logger:
```typescript
// lib/logger.ts
export const logger = {
  info: (msg: string, data?: any) => {
    console.log(`[INFO] ${msg}`, data)
    // TODO: Send to logging service
  },
  error: (msg: string, err: any) => {
    console.error(`[ERROR] ${msg}`, err)
    // TODO: Send to Sentry
  },
  warn: (msg: string, data?: any) => {
    console.warn(`[WARN] ${msg}`, data)
  }
}
```

---

### 8. NO STATE MANAGEMENT
**Status:** 0% implemented  
**Impact:** Prop drilling hell; no caching

#### Missing:
```typescript
// contexts/
├── GameContext.tsx    - Current game state
├── PlayerContext.tsx  - Player identity & stats
├── MarketContext.tsx  - Order book & prices
└── CombatContext.tsx  - Raid state

// Or use Zustand:
// store/
├── gameStore.ts
├── playerStore.ts
├── marketStore.ts
└── combatStore.ts
```

---

### 9. NO DATA VALIDATION ON SERVER
**Status:** 0% implemented  
**Impact:** Cheaters can send fake orders/claims

#### Missing:
```typescript
// lib/validation/
├── proximityValidator.ts  - Check proximity claims
├── orderValidator.ts      - Check order constraints
├── combatValidator.ts     - Check combat legality
└── politicsValidator.ts   - Check vote eligibility

// middleware/
└── validateRequest.ts     - Zod/Yup request validation
```

#### Example Validator:
```typescript
// lib/validation/orderValidator.ts
import { z } from 'zod'

export const submitOrderSchema = z.object({
  asset_type: z.enum(['resource', 'company', 'perp', 'currency']),
  asset_id: z.string().uuid(),
  order_side: z.enum(['buy', 'sell']),
  amount: z.number().positive(),
  price: z.number().positive(),
})

export async function validateOrder(playerId: string, order: z.infer<typeof submitOrderSchema>) {
  // 1. Check player has enough balance
  // 2. Check order is within reasonable price range
  // 3. Check player isn't banned
  // 4. Check order count < max
  return true
}
```

---

### 10. NO JOBS/BACKGROUND WORKERS
**Status:** Only TickProcessor exists; needs orchestration  
**Impact:** Ticks might not run; no tick retries

#### Missing:
```
workers/
├── tickWorker.ts        - Run simulation ticks
├── marketMatcherWorker.ts - Match orders
├── newsGeneratorWorker.ts - Generate news
├── antiCheatWorker.ts   - Check for cheating
└── healthCheckWorker.ts - Monitor system health

Or use:
- Bull Queue (Redis-based)
- AWS Lambda
- Firebase Cloud Tasks
- Render Cron Jobs
```

#### Job Queue Setup:
```typescript
// lib/queue.ts
import Queue from 'bull'

export const tickQueue = new Queue('tick', {
  redis: process.env.REDIS_URL
})

tickQueue.process(async (job) => {
  const processor = new TickProcessor()
  return await processor.runTick()
})

tickQueue.add({}, { repeat: { every: 300000 } }) // Every 5 min
```

---

### 11. NO TESTING INFRASTRUCTURE
**Status:** 0% implemented  
**Impact:** Can't verify anything works

#### Missing:
```
__tests__/
├── unit/
│   ├── ChainManager.test.ts
│   ├── AntiCheatEngine.test.ts
│   └── MarketMatcher.test.ts
├── integration/
│   ├── proximity.integration.test.ts
│   ├── market.integration.test.ts
│   └── combat.integration.test.ts
└── e2e/
    ├── full-game-loop.e2e.test.ts
    └── raider-vs-neutral.e2e.test.ts

Config:
- jest.config.ts
- .env.test
```

---

### 12. NO DEPLOYMENT / CI-CD
**Status:** 0% implemented  
**Impact:** Can't ship to production safely

#### Missing:
```
.github/workflows/
├── test.yml           - Run tests on PR
├── lint.yml           - Lint on PR
├── deploy.yml         - Deploy to production
└── health-check.yml   - Verify uptime

Deployment config:
- Dockerfile
- docker-compose.yml
- vercel.json (if using Vercel)
- .env.production
```

---

## 🟢 TIER 3: FRONTEND COMPONENT GAPS

### 13. UI Components Don't Exist
**Status:** App.jsx has skeleton; needs full build-out

#### Missing Screens:
```
components/
├── ProximityFeed.tsx        - Show nearby devices
├── ChainVisualization.tsx   - Visualize multi-link chains
├── OrderBook.tsx            - Live order book UI
├── OrderSubmitForm.tsx      - Place buy/sell order
├── MarketChart.tsx          - Price chart (uPlot/Chart.js)
├── CombatWindow.tsx         - 2-minute raid resolution
├── CombatCommitForm.tsx     - Allocate fighters/equipment
├── NewsTickerWidget.tsx     - Live news feed
├── SurvivorCard.tsx         - Individual survivor UI
├── CampUpgrades.tsx         - Camp building interface
├── ElectionBallot.tsx       - Vote interface
├── RepInfamyBar.tsx         - Reputation/Infamy display
├── CharacterStats.tsx       - Stats dashboard
└── ErrorBoundary.tsx        - Catch rendering errors
```

---

### 14. No Responsive Design
**Status:** App.jsx is desktop-only  
**Impact:** Mobile users get broken UI

#### Missing:
```typescript
// Mobile detection
import { useMediaQuery } from '@/hooks/useMediaQuery'

if (isMobile) {
  return <MobileLayout />
} else {
  return <DesktopLayout />
}
```

---

### 15. No Loading States / Skeletons
**Status:** All API calls will block UI  
**Impact:** UI freezes while loading

#### Missing:
```typescript
// components/LoadingSkeleton.tsx
export function OrderBookSkeleton() {
  return (
    <div className="space-y-2">
      {[...Array(5)].map(i => (
        <div key={i} className="h-8 bg-gray-300 rounded animate-pulse" />
      ))}
    </div>
  )
}
```

---

## 📋 QUICK FIX PRIORITY

### Week 1 (Unblocking):
1. [ ] Create `utils/supabase/server.ts`
2. [ ] Create `/api/game/player/me` endpoint
3. [ ] Create `/api/game/tick` endpoint
4. [ ] Fix `app/page.tsx` (remove broken import)
5. [ ] Replace `checklist.md` with real checklist

### Week 2 (MVP):
6. [ ] Create `/api/proximity/submit`
7. [ ] Create `/api/market/orders/submit`
8. [ ] Add ProximityFeed component
9. [ ] Add OrderBook component
10. [ ] Connect TickProcessor to backend

### Week 3 (Combat):
11. [ ] Create `/api/combat/raid/initiate`
12. [ ] Create CombatWindow component
13. [ ] Implement raid resolution logic

### Week 4+ (Polish):
14. [ ] Authentication
15. [ ] Error handling
16. [ ] Background jobs
17. [ ] Testing
18. [ ] Deployment

---

## 🚨 TECHNICAL DEBT

| Issue | Severity | Impact |
|-------|----------|--------|
| **No type safety** | 🟠 High | Easy to pass wrong data |
| **tsconfig has `strict: false`** | 🔴 Critical | TypeScript bugs will compile |
| **No request validation** | 🔴 Critical | Cheaters can exploit API |
| **No database transactions** | 🟠 High | Race conditions in trading |
| **No audit logging** | 🟠 High | Can't detect fraud |
| **No rate limiting** | 🔴 Critical | Can spam orders infinitely |
| **No CORS configured** | 🟠 High | Browser can't call API from localhost |
| **Middleware incomplete** | 🟡 Medium | Auth not integrated |

---

## 🔧 IMMEDIATE ACTION ITEMS

**Create these files TODAY:**

```bash
# 1. Fix missing Supabase client
touch utils/supabase/server.ts
touch utils/supabase/client.ts

# 2. Create placeholder API routes
mkdir -p app/api/game
mkdir -p app/api/proximity
mkdir -p app/api/market

# 3. Fix tsconfig
# Change: "strict": false → "strict": true

# 4. Create .env.example
touch .env.example

# 5. Replace broken checklist
rm checklist.md
# Use MISSING_IMPLEMENTATIONS.md and BLE_ARCHITECTURE.md instead
```

---

**This audit took 2 hours. I found the missing pieces. Now it's your move.**
