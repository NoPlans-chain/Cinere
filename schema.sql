-- Ex Cinere Core Database Schema
-- Target: Supabase (PostgreSQL)

-- 1. FOUNDATION & SIMULATION
CREATE TABLE ticks (
    id BIGSERIAL PRIMARY KEY,
    timestamp TIMESTAMPTZ DEFAULT NOW(),
    seed TEXT NOT NULL,
    summary JSONB -- High-level snapshot of world state
);

CREATE TABLE regions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name TEXT NOT NULL UNIQUE,
    ideology TEXT NOT NULL, -- e.g., 'Planned', 'Market', 'Syndicalist'
    government_type TEXT, -- e.g., 'Democracy', 'Autocracy', 'Corporate Oversight'
    economic_model TEXT, -- e.g., 'Laissez-faire', 'State-directed'
    stability FLOAT DEFAULT 1.0,
    tax_rate FLOAT DEFAULT 0.1,
    infrastructure_level INT DEFAULT 1,
    financial_regulation FLOAT DEFAULT 0.5, -- 0.0 to 1.0
    crypto_policy TEXT DEFAULT 'Regulated', -- 'Fully Legal', 'Regulated', 'Restricted', 'Banned', 'Criminalized'
    capital_controls FLOAT DEFAULT 0.1,
    enforcement_strength FLOAT DEFAULT 0.5,
    corruption_level FLOAT DEFAULT 0.2,
    population BIGINT DEFAULT 0,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    CONSTRAINT check_crypto_policy CHECK (crypto_policy IN ('Fully Legal', 'Regulated', 'Restricted', 'Banned', 'Criminalized'))
);

CREATE TABLE land_tiles (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    region_id UUID REFERENCES regions(id),
    size_tier TEXT NOT NULL CHECK (size_tier IN ('S1', 'S2', 'S3', 'S4', 'S5')),
    tile_type TEXT NOT NULL, -- 'Urban District', 'Industrial Zone', 'Resource Field', 'Agricultural Zone', 'Strategic Corridor', 'Restricted Zone'
    base_value NUMERIC DEFAULT 0,
    infrastructure_level INT DEFAULT 0 CHECK (infrastructure_level BETWEEN 0 AND 5),
    population_density FLOAT DEFAULT 0.0,
    resource_index FLOAT DEFAULT 0.0,
    connectivity_score FLOAT DEFAULT 0.0,

    -- Environmental Modifiers
    has_ocean_access BOOLEAN DEFAULT FALSE,
    has_freshwater_access BOOLEAN DEFAULT FALSE,
    is_mountainous BOOLEAN DEFAULT FALSE,
    is_desert BOOLEAN DEFAULT FALSE,
    is_urban_core BOOLEAN DEFAULT FALSE,
    is_border_zone BOOLEAN DEFAULT FALSE,

    productivity_modifier FLOAT DEFAULT 1.0,
    stability_modifier FLOAT DEFAULT 1.0,
    coordinates_x INT,
    coordinates_y INT,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE resource_types (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name TEXT NOT NULL UNIQUE,
    category TEXT NOT NULL, -- 'Mineral', 'Energy', 'Agricultural'
    base_value NUMERIC DEFAULT 1.0,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 16. SUPPLY CHAIN & PRODUCTION BLUEPRINTS
-- Defines the "Labor + Resources -> Output" logic mentioned in mechanics.md
CREATE TABLE production_blueprints (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    output_resource_id UUID REFERENCES resource_types(id),
    required_inputs JSONB NOT NULL, -- e.g., [{"resource_id": "...", "amount": 10}]
    base_labor_required FLOAT NOT NULL,
    base_energy_required NUMERIC NOT NULL,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE office_buildings (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    land_tile_id UUID REFERENCES land_tiles(id),
    name TEXT,
    building_type TEXT NOT NULL, -- 'Brokerage Office', 'Exchange Hall', 'Clearing Center', 'Shadow Office'
    tier TEXT NOT NULL CHECK (tier IN ('S1', 'S2', 'S3', 'S4', 'S5')),
    financial_density FLOAT DEFAULT 1.0,
    connectivity_level FLOAT DEFAULT 1.0,
    security_level FLOAT DEFAULT 1.0,
    capital_throughput NUMERIC DEFAULT 1000000,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE exchanges (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    office_id UUID REFERENCES office_buildings(id),
    name TEXT NOT NULL,
    is_authorized BOOLEAN DEFAULT TRUE, -- False for shadow/illegal exchanges
    liquidity_health FLOAT DEFAULT 1.0,
    settlement_efficiency FLOAT DEFAULT 1.0,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE currencies (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name TEXT NOT NULL UNIQUE,
    symbol TEXT NOT NULL UNIQUE,
    region_id UUID REFERENCES regions(id),
    total_supply NUMERIC DEFAULT 0,
    inflation_rate FLOAT DEFAULT 0.0,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE exchange_rates (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    from_currency_id UUID REFERENCES currencies(id),
    to_currency_id UUID REFERENCES currencies(id),
    rate NUMERIC NOT NULL,
    last_update_tick BIGINT REFERENCES ticks(id),
    UNIQUE(from_currency_id, to_currency_id)
);

-- 2. CHARACTERS & IDENTITY
CREATE TABLE information_access_tiers (
    id TEXT PRIMARY KEY, -- 'T0' through 'T5'
    name TEXT NOT NULL,
    description TEXT,
    access_scope TEXT NOT NULL,
    strategic_power_modifier FLOAT DEFAULT 1.0,
    exposure_risk_modifier FLOAT DEFAULT 1.0,
    lifespan_decay_modifier FLOAT DEFAULT 1.0,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

INSERT INTO information_access_tiers (id, name, description, access_scope, strategic_power_modifier, exposure_risk_modifier, lifespan_decay_modifier)
VALUES
    ('T0', 'Civilian', 'Local visible events only', 'Local visible events', 0.8, 0.8, 1.0),
    ('T1', 'Commercial', 'Regional economic signals', 'Regional economics', 0.9, 0.85, 1.05),
    ('T2', 'Institutional', 'Macro market data and forecasts', 'Macro market data', 1.0, 0.9, 1.1),
    ('T3', 'Political', 'Government intelligence and early warnings', 'Government and intelligence signals', 1.1, 1.0, 1.2),
    ('T4', 'Strategic', 'Hidden geopolitical operations and confidential reports', 'Hidden geopolitical operations', 1.2, 1.2, 1.3),
    ('T5', 'Inner Circle', 'Predictive confidential world-state data', 'Predictive/confidential world-state data', 1.3, 1.4, 1.4)
ON CONFLICT (id) DO NOTHING;

-- Intelligence access tiers drive NPC awareness, data quality, and risk.
-- information_value = accuracy * exclusivity * timing_advantage
-- awareness influences which signals are available and how quickly the NPC reacts.
CREATE TABLE characters (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID, -- Links to auth.users if player
    name TEXT NOT NULL,
    origin_region_id UUID REFERENCES regions(id),
    
    -- Biological Stats (Hidden integrity)
    biological_integrity FLOAT DEFAULT 1.0,
    age INT DEFAULT 18,
    vitality FLOAT DEFAULT 1.0,
    
    -- Mental & Social Stats
    intelligence FLOAT DEFAULT 0.5,
    charisma FLOAT DEFAULT 0.5,
    endurance FLOAT DEFAULT 0.5,
    perception FLOAT DEFAULT 0.5,
    discipline FLOAT DEFAULT 0.5,
    combat_ability FLOAT DEFAULT 0.0,
    administration FLOAT DEFAULT 0.0,
    
    -- Social Capital
    reputation FLOAT DEFAULT 0.0,
    notoriety FLOAT DEFAULT 0.0,
    
    -- NPC/Behavioral Variables
    wealth_level FLOAT DEFAULT 0.1,
    trust_in_government FLOAT DEFAULT 0.5,
    risk_sensitivity FLOAT DEFAULT 0.5,
    ideological_alignment TEXT, -- Alignment with regional ideology
    syndicate_exposure FLOAT DEFAULT 0.0,
    mobility FLOAT DEFAULT 0.5,

    -- Intelligence access / awareness
    information_tier TEXT DEFAULT 'T0' REFERENCES information_access_tiers(id),
    awareness_level TEXT DEFAULT 'Low Awareness', -- Low/Moderate/High/Elite Awareness
    information_accuracy FLOAT DEFAULT 0.5,
    information_exclusivity FLOAT DEFAULT 0.5,
    timing_advantage FLOAT DEFAULT 0.0,
    information_value NUMERIC GENERATED ALWAYS AS (
      information_accuracy * information_exclusivity * timing_advantage
    ) STORED,
    exposure_risk FLOAT DEFAULT 0.0,
    cognitive_load FLOAT DEFAULT 0.0,

    preferred_currency_id UUID REFERENCES currencies(id),
    character_type TEXT DEFAULT 'NPC', -- 'Player', 'NPC', 'AI_Trader'
    is_alive BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE skills (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    character_id UUID REFERENCES characters(id) ON DELETE CASCADE,
    skill_type TEXT NOT NULL, -- e.g., 'Trading', 'Engineering', 'Violence'
    level FLOAT DEFAULT 0.0,
    UNIQUE(character_id, skill_type)
);

-- 2.1. NPC COGNITIVE BEHAVIOR PROFILES
-- Behavior score is derived from personality, information access, and stress.
-- Example decision weight formula:
--   behavior_score = (intelligence * 0.3) + (perception * 0.25) + (discipline * 0.2) + (charisma * 0.15) + ((1 - risk_sensitivity) * 0.1)
-- Information value alters predictive power and hidden-state detection.
CREATE TABLE npc_behavior_profiles (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    character_id UUID REFERENCES characters(id) ON DELETE CASCADE,
    awareness_level TEXT DEFAULT 'Low Awareness', -- 'Low Awareness', 'Moderate Awareness', 'High Awareness', 'Elite Awareness'
    memory_capacity FLOAT DEFAULT 0.5,
    emotional_weighting FLOAT DEFAULT 0.5,
    decision_rigidity FLOAT DEFAULT 0.5,
    threat_assessment FLOAT DEFAULT 0.5,
    negotiation_preference FLOAT DEFAULT 0.5,
    secrecy_coefficient FLOAT DEFAULT 0.5,
    intelligence_access_bias JSONB DEFAULT '{}', -- e.g. {"preferred_sources": ["market","political"], "trust_threshold": 0.6}
    last_update_tick BIGINT REFERENCES ticks(id),
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- NPC behavior contract:
--   predicted_behavior = CASE
--     WHEN exposure_risk > 0.7 AND cognitive_load > 0.6 THEN 'withdraw'
--     WHEN awareness_level IN ('High Awareness','Elite Awareness') AND intelligence > 0.6 THEN 'strategize'
--     WHEN notoriety > 0.7 AND aggression > 0.6 THEN 'escalate'
--     ELSE 'react'
--   END

-- 2.2. NPC BEHAVIOR PREDICTION
CREATE TABLE npc_behavior_predictions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    character_id UUID REFERENCES characters(id) ON DELETE CASCADE,
    tick_id BIGINT REFERENCES ticks(id),
    behavior_score NUMERIC,
    information_value NUMERIC,
    predicted_behavior TEXT,
    decision_reason JSONB DEFAULT '{}',
    created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE OR REPLACE FUNCTION calculate_information_value(
    information_accuracy FLOAT,
    information_exclusivity FLOAT,
    timing_advantage FLOAT
) RETURNS NUMERIC LANGUAGE SQL IMMUTABLE AS $$
    SELECT COALESCE(information_accuracy, 0) * COALESCE(information_exclusivity, 0) * COALESCE(timing_advantage, 0);
$$;

CREATE OR REPLACE FUNCTION calculate_npc_behavior_score(
    intelligence FLOAT,
    perception FLOAT,
    discipline FLOAT,
    charisma FLOAT,
    risk_sensitivity FLOAT
) RETURNS NUMERIC LANGUAGE SQL IMMUTABLE AS $$
    SELECT (
        COALESCE(intelligence, 0) * 0.30
        + COALESCE(perception, 0) * 0.25
        + COALESCE(discipline, 0) * 0.20
        + COALESCE(charisma, 0) * 0.15
        + COALESCE(1 - risk_sensitivity, 0) * 0.10
    );
$$;

CREATE OR REPLACE FUNCTION predict_npc_behavior(
    exposure_risk FLOAT,
    cognitive_load FLOAT,
    awareness_level TEXT,
    intelligence FLOAT,
    notoriety FLOAT,
    aggression FLOAT
) RETURNS TEXT LANGUAGE SQL IMMUTABLE AS $$
    SELECT CASE
        WHEN COALESCE(exposure_risk, 0) > 0.7 AND COALESCE(cognitive_load, 0) > 0.6 THEN 'withdraw'
        WHEN awareness_level IN ('High Awareness', 'Elite Awareness') AND COALESCE(intelligence, 0) > 0.6 THEN 'strategize'
        WHEN COALESCE(notoriety, 0) > 0.7 AND COALESCE(aggression, 0) > 0.6 THEN 'escalate'
        ELSE 'react'
    END;
$$;

-- 3. CORPORATIONS & PRODUCTION
CREATE TABLE companies (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name TEXT NOT NULL UNIQUE,
    sector TEXT NOT NULL,
    region_id UUID REFERENCES regions(id),
    headquarters_tile_id UUID,
    parent_company_id UUID REFERENCES companies(id), -- Supports fragmentation/subsidiaries
    founder_id UUID REFERENCES characters(id),
    total_shares BIGINT DEFAULT 1000000,
    capital_reserves NUMERIC DEFAULT 0,
    production_output NUMERIC DEFAULT 0,
    revenue NUMERIC DEFAULT 0,
    board_composition JSONB DEFAULT '[]', -- Tracking influential board members
    is_bankrupt BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE labor_contracts (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    character_id UUID REFERENCES characters(id),
    company_id UUID REFERENCES companies(id),
    wage NUMERIC NOT NULL,
    satisfaction FLOAT DEFAULT 1.0,
    productivity FLOAT DEFAULT 1.0,
    is_on_strike BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(character_id, company_id)
);

-- 4. MARKETS, TRADING & FINANCE
CREATE TABLE balances (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    character_id UUID REFERENCES characters(id) ON DELETE CASCADE,
    currency_id UUID REFERENCES currencies(id),
    amount NUMERIC DEFAULT 0,
    UNIQUE(character_id, currency_id)
);

CREATE TABLE debt_obligations (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    debtor_id UUID REFERENCES characters(id),
    creditor_id UUID NOT NULL, -- Can be character_id or company_id
    creditor_type TEXT NOT NULL, -- 'character', 'company', 'region'
    principal NUMERIC NOT NULL,
    interest_rate FLOAT DEFAULT 0.05,
    tick_id BIGINT REFERENCES ticks(id),
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE orders (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    asset_type TEXT NOT NULL CHECK (asset_type IN ('company', 'currency', 'perp', 'resource')), -- 'company', 'currency', 'perp', 'resource'
    asset_id UUID NOT NULL,
    trader_id UUID REFERENCES characters(id),
    order_side TEXT NOT NULL, -- 'buy', 'sell'
    order_kind TEXT NOT NULL, -- 'market', 'limit'
    amount NUMERIC NOT NULL,
    price NUMERIC, -- NULL for market orders
    exchange_id UUID REFERENCES exchanges(id),
    status TEXT DEFAULT 'pending', -- 'pending', 'filled', 'cancelled'
    tick_id BIGINT REFERENCES ticks(id),
    created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE positions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    trader_id UUID REFERENCES characters(id),
    asset_type TEXT NOT NULL,
    asset_id UUID NOT NULL,
    amount NUMERIC NOT NULL DEFAULT 0,
    entry_price NUMERIC NOT NULL,
    last_tick_price NUMERIC,
    unrealized_pnl NUMERIC DEFAULT 0,
    UNIQUE(trader_id, asset_type, asset_id)
);

CREATE TABLE perp_markets (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    underlying_asset_type TEXT NOT NULL,
    exchange_id UUID REFERENCES exchanges(id),
    underlying_asset_id UUID NOT NULL,
    mark_price NUMERIC NOT NULL,
    index_price NUMERIC NOT NULL,
    funding_rate FLOAT DEFAULT 0.0,
    open_interest NUMERIC DEFAULT 0,
    last_update_tick BIGINT REFERENCES ticks(id)
);

-- 5. WORLD SYSTEMS & LOGS
CREATE TABLE market_events (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    event_type TEXT NOT NULL,
    severity TEXT NOT NULL,
    region_id UUID REFERENCES regions(id),
    description TEXT,
    tick_id BIGINT REFERENCES ticks(id),
    created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE trade_history (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    order_id UUID REFERENCES orders(id),
    buyer_id UUID REFERENCES characters(id),
    seller_id UUID REFERENCES characters(id),
    amount NUMERIC NOT NULL,
    price NUMERIC NOT NULL,
    tick_id BIGINT REFERENCES ticks(id),
    executed_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE ai_traders (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    character_id UUID REFERENCES characters(id) ON DELETE CASCADE,
    strategy_type TEXT NOT NULL, -- 'Momentum', 'MeanReversion', 'Arbitrage', 'Macro'
    capital_limit NUMERIC NOT NULL,
    memory JSONB DEFAULT '{}',
    created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE tick_logs (
    id BIGSERIAL PRIMARY KEY,
    tick_id BIGINT REFERENCES ticks(id),
    system_name TEXT NOT NULL,
    message TEXT NOT NULL,
    log_level TEXT DEFAULT 'info',
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 6. RESOURCES & INFRASTRUCTURE
CREATE TABLE resource_reserves (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    region_id UUID REFERENCES regions(id),
    resource_type_id UUID REFERENCES resource_types(id),
    current_amount NUMERIC NOT NULL,
    max_capacity NUMERIC NOT NULL,
    extraction_rate FLOAT DEFAULT 1.0,
    UNIQUE(region_id, resource_type_id)
);

CREATE TABLE resource_claims (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    character_id UUID REFERENCES characters(id),
    region_id UUID REFERENCES regions(id),
    resource_type_id UUID REFERENCES resource_types(id),
    claim_size FLOAT NOT NULL,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE infrastructure (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    region_id UUID REFERENCES regions(id),
    name TEXT NOT NULL,
    type TEXT NOT NULL, -- 'PowerGrid', 'Port', 'Roads', 'Industrial'
    land_tile_id UUID REFERENCES land_tiles(id), -- Infrastructure exists on specific tiles
    level INT DEFAULT 1 CHECK (level BETWEEN 0 AND 5),
    efficiency FLOAT DEFAULT 1.0,
    maintenance_cost NUMERIC DEFAULT 0,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE land_ownership (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tile_id UUID REFERENCES land_tiles(id) ON DELETE CASCADE,
    owner_id UUID NOT NULL, -- character_id or company_id
    owner_type TEXT NOT NULL, -- 'character', 'company', 'government', 'syndicate'
    control_layer TEXT NOT NULL DEFAULT 'Legal', -- 'Legal Owner', 'Economic Controller', 'Operational Controller', 'Shadow Controller'
    ownership_percent FLOAT DEFAULT 100.0,
    influence_score FLOAT DEFAULT 1.0,
    is_lease BOOLEAN DEFAULT FALSE,
    lease_expiry_tick BIGINT,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    CONSTRAINT check_control_layer CHECK (control_layer IN ('Legal Owner', 'Economic Controller', 'Operational Controller', 'Shadow Controller'))
);

CREATE TABLE brokers (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    office_id UUID REFERENCES office_buildings(id),
    name TEXT NOT NULL,
    broker_type TEXT NOT NULL CHECK (broker_type IN ('Retail', 'Institutional', 'Shadow')),
    trust_level FLOAT DEFAULT 0.5,
    capital_capacity NUMERIC DEFAULT 100000,
    regulation_status FLOAT DEFAULT 1.0,
    fee_structure JSONB DEFAULT '{}',
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 7. GOVERNANCE & POLITICS
CREATE TABLE elections (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    region_id UUID REFERENCES regions(id),
    election_tick BIGINT REFERENCES ticks(id),
    status TEXT DEFAULT 'upcoming', -- 'upcoming', 'active', 'completed'
    winner_id UUID REFERENCES characters(id),
    created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE election_candidates (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    election_id UUID REFERENCES elections(id),
    character_id UUID REFERENCES characters(id),
    votes BIGINT DEFAULT 0,
    UNIQUE(election_id, character_id)
);

CREATE TABLE sanctions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    origin_region_id UUID REFERENCES regions(id),
    target_region_id UUID REFERENCES regions(id),
    severity FLOAT DEFAULT 0.5,
    is_active BOOLEAN DEFAULT TRUE,
    start_tick BIGINT REFERENCES ticks(id),
    end_tick BIGINT,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 8. LIFECYCLE & LEGACY
CREATE TABLE character_genetics (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    character_id UUID REFERENCES characters(id) ON DELETE CASCADE,
    longevity_modifier FLOAT DEFAULT 1.0,
    stress_tolerance FLOAT DEFAULT 1.0,
    intelligence_modifier FLOAT DEFAULT 1.0,
    aggression FLOAT DEFAULT 0.0,
    addiction_susceptibility FLOAT DEFAULT 0.0,
    fertility FLOAT DEFAULT 0.0,
    immunity FLOAT DEFAULT 0.0,
    charisma_modifier FLOAT DEFAULT 1.0,
    risk_appetite FLOAT DEFAULT 1.0,
    UNIQUE(character_id)
);

CREATE TABLE inheritance (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    predecessor_id UUID REFERENCES characters(id),
    successor_id UUID REFERENCES characters(id),
    transfer_tax_rate FLOAT DEFAULT 0.0,
    executed_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE syndicates (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name TEXT NOT NULL UNIQUE,
    region_id UUID REFERENCES regions(id),
    leader_id UUID REFERENCES characters(id),
    influence FLOAT DEFAULT 0.0,
    notoriety_requirement FLOAT DEFAULT 0.5,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE syndicate_members (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    syndicate_id UUID REFERENCES syndicates(id) ON DELETE CASCADE,
    character_id UUID REFERENCES characters(id),
    rank TEXT DEFAULT 'Associate', -- 'Associate', 'Broker', 'Lieutenant', 'Director', 'Syndicate Head'
    UNIQUE(syndicate_id, character_id),
    CONSTRAINT check_syndicate_rank CHECK (rank IN ('Associate', 'Broker', 'Lieutenant', 'Director', 'Syndicate Head'))
);

-- 9. NOTIFICATIONS & FEEDBACK
CREATE TABLE notifications (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    character_id UUID REFERENCES characters(id),
    type TEXT NOT NULL, -- 'Trade', 'Election', 'Death', 'MarketEvent'
    title TEXT NOT NULL,
    message TEXT NOT NULL,
    is_read BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 10. ADVANCED TAKEOVER & ACQUISITION
CREATE TABLE tender_offers (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    company_id UUID REFERENCES companies(id),
    bidder_id UUID NOT NULL, -- character_id or company_id
    bidder_type TEXT NOT NULL, -- 'character', 'company'
    share_price NUMERIC NOT NULL,
    target_share_count BIGINT NOT NULL,
    current_filled_count BIGINT DEFAULT 0,
    status TEXT DEFAULT 'active', -- 'active', 'completed', 'cancelled', 'expired'
    start_tick BIGINT REFERENCES ticks(id),
    expiry_tick BIGINT NOT NULL,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 11. DIPLOMACY & GEOPOLITICS
CREATE TABLE region_relations (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    region_a_id UUID REFERENCES regions(id),
    region_b_id UUID REFERENCES regions(id),
    status TEXT DEFAULT 'Neutral', -- 'Alliance', 'Trade_Partner', 'Neutral', 'Cold_War', 'War'
    tension_level FLOAT DEFAULT 0.0, -- 0.0 to 1.0
    last_update_tick BIGINT REFERENCES ticks(id),
    UNIQUE(region_a_id, region_b_id)
);

-- 12. EXTENDED LIFECYCLE (HIDDEN STATS)
-- Separated from 'characters' to keep high-frequency biological decay isolation
CREATE TABLE character_health_state (
    character_id UUID PRIMARY KEY REFERENCES characters(id) ON DELETE CASCADE,
    cellular_stress FLOAT DEFAULT 0.0,
    neurological_fatigue FLOAT DEFAULT 0.0,
    occupational_damage FLOAT DEFAULT 0.0,
    injury_burden FLOAT DEFAULT 0.0,
    addiction_level FLOAT DEFAULT 0.0,
    last_update_tick BIGINT REFERENCES ticks(id)
);

-- 13. INFORMATION ENGINE & NEWS
CREATE TABLE news_feed (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tick_id BIGINT REFERENCES ticks(id),
    region_id UUID REFERENCES regions(id), -- NULL if global
    category TEXT NOT NULL, -- 'Economic', 'Geopolitical', 'Corporate', 'Syndicate'
    headline TEXT NOT NULL,
    content TEXT,
    impact_vector JSONB, -- e.g., {"sector": "Mining", "volatility_mod": 0.2}
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 13.1. TODO LISTS
-- Simple task records used by the sample Supabase page and basic workflow tracking
CREATE TABLE todos (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name TEXT NOT NULL,
    description TEXT,
    is_completed BOOLEAN DEFAULT FALSE,
    priority TEXT DEFAULT 'medium', -- 'low', 'medium', 'high'
    due_date TIMESTAMPTZ,
    assigned_to UUID REFERENCES characters(id),
    tick_id BIGINT REFERENCES ticks(id),
    created_at TIMESTAMPTZ DEFAULT NOW(),
    completed_at TIMESTAMPTZ
);

-- 14. INDUSTRIAL ASSETS & PRODUCTION SYSTEMS
-- Tracks the "bundles of assets" mentioned in the Ownership docs
CREATE TABLE industrial_assets (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    company_id UUID REFERENCES companies(id),
    blueprint_id UUID REFERENCES production_blueprints(id),
    land_tile_id UUID REFERENCES land_tiles(id),
    asset_type TEXT NOT NULL, -- 'Refinery', 'Factory', 'PowerPlant', 'ExtractionRig'
    efficiency_rating FLOAT DEFAULT 1.0,
    condition FLOAT DEFAULT 1.0, -- Degrades over time/use
    output_capacity NUMERIC NOT NULL,
    maintenance_cost_per_tick NUMERIC DEFAULT 0,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 15. COMMODITY MARKET DYNAMICS
-- Tracks the spot price of raw resources independent of company stock
CREATE TABLE resource_market_prices (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    resource_type_id UUID REFERENCES resource_types(id),
    tick_id BIGINT REFERENCES ticks(id),
    price NUMERIC NOT NULL,
    volume_last_tick NUMERIC DEFAULT 0,
    UNIQUE(resource_type_id, tick_id)
);

-- 17. SECURITY & CONFLICT SYSTEM
-- Tracks the "Military fracture" and "Security forces" mechanics
CREATE TABLE regional_security (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    region_id UUID REFERENCES regions(id) UNIQUE,
    military_strength FLOAT DEFAULT 0.0,
    police_loyalty FLOAT DEFAULT 1.0, -- Influences Coup risk
    upkeep_cost_per_tick NUMERIC DEFAULT 0,
    unrest_level FLOAT DEFAULT 0.0, -- 0.0 to 1.0, drives insurgency
    last_update_tick BIGINT REFERENCES ticks(id)
);

CREATE TABLE insurgencies (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    region_id UUID REFERENCES regions(id),
    syndicate_id UUID REFERENCES syndicates(id), -- If backed by a syndicate
    progress FLOAT DEFAULT 0.0, -- 1.0 triggers regime change
    is_active BOOLEAN DEFAULT TRUE,
    start_tick BIGINT REFERENCES ticks(id),
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 18. CORPORATE GOVERNANCE & PROXY VOTING
-- Formalizes "Board Influence" and "Strategic Blocks" for Takeovers
CREATE TABLE corporate_proposals (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    company_id UUID REFERENCES companies(id),
    proposer_id UUID REFERENCES characters(id),
    proposal_type TEXT NOT NULL, -- 'Merger', 'Liquidation', 'CEO_Removal', 'Issuance'
    description TEXT,
    parameters JSONB,
    voting_deadline_tick BIGINT NOT NULL,
    status TEXT DEFAULT 'pending', -- 'pending', 'passed', 'failed'
    created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE corporate_votes (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    proposal_id UUID REFERENCES corporate_proposals(id) ON DELETE CASCADE,
    voter_id UUID REFERENCES characters(id),
    share_weight BIGINT NOT NULL,
    vote_side BOOLEAN NOT NULL, -- TRUE = For, FALSE = Against
    voted_at_tick BIGINT REFERENCES ticks(id),
    UNIQUE(proposal_id, voter_id)
);

-- Indexing for performance on high-frequency tick lookups
CREATE INDEX idx_resource_prices_tick ON resource_market_prices(tick_id);
CREATE INDEX idx_industrial_assets_company ON industrial_assets(company_id);

-- DISABLE RLS FOR DEVELOPMENT (Allows GUI to see data)
ALTER TABLE ticks DISABLE ROW LEVEL SECURITY;
ALTER TABLE regions DISABLE ROW LEVEL SECURITY;
ALTER TABLE characters DISABLE ROW LEVEL SECURITY;
ALTER TABLE balances DISABLE ROW LEVEL SECURITY;
ALTER TABLE currencies DISABLE ROW LEVEL SECURITY;
ALTER TABLE tick_logs DISABLE ROW LEVEL SECURITY;
ALTER TABLE resource_market_prices DISABLE ROW LEVEL SECURITY;
ALTER TABLE trade_history DISABLE ROW LEVEL SECURITY;
ALTER TABLE industrial_assets DISABLE ROW LEVEL SECURITY;
ALTER TABLE news_feed DISABLE ROW LEVEL SECURITY;
ALTER TABLE skills DISABLE ROW LEVEL SECURITY;

-- 25. REALTIME CONFIGURATION
-- Ensure the ticks table can broadcast updates to the frontend
ALTER TABLE ticks REPLICA IDENTITY FULL;
ALTER PUBLICATION supabase_realtime ADD TABLE ticks;

-- 19. SHADOW ECONOMY & MONEY LAUNDERING
-- Tracks 'Dirty' vs 'Clean' capital as mentioned in Syndicate/Governance docs
CREATE TABLE dirty_money_pools (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    owner_id UUID NOT NULL, -- character_id or syndicate_id
    currency_id UUID REFERENCES currencies(id),
    amount NUMERIC DEFAULT 0,
    traceability FLOAT DEFAULT 1.0, -- 1.0 is highly visible, 0.0 is laundered
    last_update_tick BIGINT REFERENCES ticks(id)
);

CREATE TABLE laundering_operations (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    company_id UUID REFERENCES companies(id), -- Front companies
    syndicate_id UUID REFERENCES syndicates(id),
    volume_per_tick NUMERIC NOT NULL,
    efficiency FLOAT DEFAULT 0.5, -- How much is 'lost' in the process
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 20. SUCCESSION & ESTATE PLANNING
-- Supports the 'Bloodline' and 'Wills' mechanics from the Lifecycle doc
CREATE TABLE estate_wills (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    testator_id UUID UNIQUE REFERENCES characters(id),
    primary_heir_id UUID REFERENCES characters(id),
    charity_split FLOAT DEFAULT 0.0, -- Percent to non-profits/state
    corporate_split FLOAT DEFAULT 0.0, -- Percent to company reserves
    is_sealed BOOLEAN DEFAULT TRUE, -- If TRUE, heirs can't see details until death
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 21. MACRO SENTIMENT & PSYCHOLOGY
-- Drives the 'Rumor System' and 'Economic Sentiment' mentioned in mechanics.md
CREATE TABLE world_sentiment (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tick_id BIGINT REFERENCES ticks(id),
    region_id UUID REFERENCES regions(id), -- Global if NULL
    sector TEXT, -- e.g., 'Mining', 'Finance'
    fear_index FLOAT DEFAULT 0.0, -- 0.0 to 1.0
    greed_index FLOAT DEFAULT 0.0, -- 0.0 to 1.0
    stability_perception FLOAT DEFAULT 1.0,
    UNIQUE(tick_id, region_id, sector)
);

-- 22. RANKING & HISTORICAL PERFORMANCE
-- Supports the 'Wealth Ranking' and 'Leaderboards'
CREATE TABLE portfolio_snapshots (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    character_id UUID REFERENCES characters(id),
    tick_id BIGINT REFERENCES ticks(id),
    net_worth_usd_equivalent NUMERIC NOT NULL,
    liquid_assets NUMERIC NOT NULL,
    illiquid_assets NUMERIC NOT NULL,
    total_debt NUMERIC NOT NULL,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 23. MIGRATION & POPULATION FLOW
CREATE TABLE migration_events (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    from_region_id UUID REFERENCES regions(id),
    to_region_id UUID REFERENCES regions(id),
    population_count BIGINT NOT NULL,
    reason TEXT, -- 'War', 'Economic_Opportunity', 'Sanctions'
    tick_id BIGINT REFERENCES ticks(id)
);

-- 24. CONSTRAINTS & PERFORMANCE
ALTER TABLE companies ADD CONSTRAINT fk_companies_headquarters_tile 
    FOREIGN KEY (headquarters_tile_id) REFERENCES land_tiles(id);
