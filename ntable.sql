-- EX CINERE: CORE SCHEMA DEFINITION

-- 1. Core Simulation Tracking
CREATE TABLE ticks (
    id bigint PRIMARY KEY GENERATED ALWAYS AS IDENTITY,
    seed text NOT NULL,
    summary jsonb DEFAULT '{}'::jsonb,
    created_at timestamptz DEFAULT now()
);

-- 2. Entities & Economy
CREATE TABLE companies (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    capital_reserves numeric NOT NULL DEFAULT 0,
    production_output numeric NOT NULL DEFAULT 0
);

CREATE TABLE regions (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    name text NOT NULL,
    ideology text,
    stability numeric DEFAULT 1.0,
    crypto_policy text,
    tax_rate numeric DEFAULT 0.0,
    government_type text,
    economic_model text,
    corruption_level numeric DEFAULT 0.0,
    infrastructure_level integer DEFAULT 0
);

CREATE TABLE characters (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    name text NOT NULL,
    biological_integrity numeric DEFAULT 1.0,
    is_alive boolean DEFAULT true
);

CREATE TABLE currencies (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    symbol text NOT NULL UNIQUE,
    name text NOT NULL
);

CREATE TABLE resource_types (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    name text NOT NULL UNIQUE
);

-- 3. Assets & Agents
CREATE TABLE ai_traders (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    strategy_type text NOT NULL, -- e.g., 'Momentum'
    capital_limit numeric NOT NULL,
    character_id uuid REFERENCES characters(id) ON DELETE CASCADE
);

CREATE TABLE industrial_assets (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    company_id uuid REFERENCES companies(id) ON DELETE CASCADE,
    output_capacity numeric NOT NULL,
    efficiency_rating numeric DEFAULT 1.0,
    condition numeric DEFAULT 1.0,
    maintenance_cost_per_tick numeric DEFAULT 0,
    is_active boolean DEFAULT true
);

-- 4. Biological & Genetic Persistence
CREATE TABLE character_health_state (
    character_id uuid PRIMARY KEY REFERENCES characters(id) ON DELETE CASCADE,
    cellular_stress numeric DEFAULT 0,
    neurological_fatigue numeric DEFAULT 0,
    injury_burden numeric DEFAULT 0,
    occupational_damage numeric DEFAULT 0,
    last_update_tick bigint
);

CREATE TABLE character_genetics (
    character_id uuid PRIMARY KEY REFERENCES characters(id) ON DELETE CASCADE,
    longevity_modifier numeric DEFAULT 1.0
);

-- 5. Market Infrastructure
CREATE TABLE orders (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    asset_id uuid NOT NULL,
    asset_type text NOT NULL, -- 'resource', 'perp'
    trader_id uuid REFERENCES characters(id) ON DELETE CASCADE,
    order_side text NOT NULL, -- 'buy', 'sell'
    order_kind text NOT NULL, -- 'limit', 'market'
    amount numeric NOT NULL,
    price numeric,
    tick_id bigint REFERENCES ticks(id),
    status text DEFAULT 'pending' -- 'pending', 'filled', 'cancelled'
);

CREATE TABLE resource_market_prices (
    resource_type_id uuid REFERENCES resource_types(id) ON DELETE CASCADE,
    tick_id bigint REFERENCES ticks(id),
    price numeric NOT NULL,
    volume_last_tick numeric DEFAULT 0,
    PRIMARY KEY (resource_type_id, tick_id)
);

CREATE TABLE perp_markets (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    underlying_asset_id uuid NOT NULL,
    mark_price numeric NOT NULL,
    index_price numeric NOT NULL,
    funding_rate numeric DEFAULT 0,
    last_update_tick bigint
);

CREATE TABLE trade_history (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    order_id uuid REFERENCES orders(id),
    buyer_id uuid REFERENCES characters(id),
    seller_id uuid REFERENCES characters(id),
    amount numeric NOT NULL,
    price numeric NOT NULL,
    tick_id bigint REFERENCES ticks(id)
);

-- 6. Portfolios & Ownership
CREATE TABLE balances (
    character_id uuid REFERENCES characters(id) ON DELETE CASCADE,
    currency_id uuid REFERENCES currencies(id) ON DELETE CASCADE,
    amount numeric NOT NULL DEFAULT 0,
    PRIMARY KEY (character_id, currency_id)
);

CREATE TABLE positions (
    trader_id uuid REFERENCES characters(id) ON DELETE CASCADE,
    asset_type text NOT NULL,
    asset_id uuid NOT NULL,
    amount numeric NOT NULL DEFAULT 0,
    entry_price numeric NOT NULL,
    last_tick_price numeric,
    unrealized_pnl numeric DEFAULT 0,
    PRIMARY KEY (trader_id, asset_type, asset_id)
);

-- 7. Metagame & Narrative
CREATE TABLE tick_logs (
    id bigint PRIMARY KEY GENERATED ALWAYS AS IDENTITY,
    tick_id bigint REFERENCES ticks(id),
    system_name text,
    message text,
    log_level text,
    created_at timestamptz DEFAULT now()
);

CREATE TABLE news_feed (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    category text,
    headline text,
    created_at timestamptz DEFAULT now()
);