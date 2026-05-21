import 'dotenv/config';
import { createClient } from '@supabase/supabase-js';

const supabase = createClient(
  process.env.SUPABASE_URL,
  process.env.SUPABASE_SERVICE_ROLE_KEY
);

async function runIntegrityCheck() {
  console.log('--- EX CINERE: DATABASE SCHEMA AUDIT ---');

  if (!process.env.SUPABASE_URL || !process.env.SUPABASE_SERVICE_ROLE_KEY) {
    console.error('❌ Error: Missing Supabase credentials in environment variables.');
    process.exit(1);
  }

  // Comprehensive map of all tables and columns required by the TickProcessor
  const validationMap = {
    ticks: ['id', 'seed', 'summary'],
    companies: ['id', 'capital_reserves', 'production_output'],
    regions: ['id', 'name', 'stability', 'tax_rate'],
    ai_traders: ['id', 'strategy_type', 'capital_limit', 'character_id'],
    industrial_assets: ['id', 'company_id', 'output_capacity', 'condition', 'is_active'],
    characters: ['id', 'name', 'biological_integrity', 'is_alive'],
    character_health_state: ['character_id', 'cellular_stress', 'injury_burden', 'occupational_damage'],
    character_genetics: ['character_id', 'longevity_modifier'],
    orders: ['id', 'asset_id', 'asset_type', 'trader_id', 'order_side', 'status'],
    resource_market_prices: ['resource_type_id', 'tick_id', 'price'],
    perp_markets: ['id', 'underlying_asset_id', 'mark_price', 'funding_rate'],
    trade_history: ['id', 'order_id', 'buyer_id', 'seller_id', 'amount', 'price'],
    balances: ['character_id', 'currency_id', 'amount'],
    positions: ['trader_id', 'asset_type', 'asset_id', 'amount', 'entry_price', 'unrealized_pnl'],
    currencies: ['id', 'symbol', 'name'],
    tick_logs: ['tick_id', 'message', 'log_level']
  };

  for (const [table, columns] of Object.entries(validationMap)) {
    process.stdout.write(`Validating table [${table.padEnd(25)}]... `);
    const { data, error, count } = await supabase
      .from(table)
      .select(columns.join(','), { count: 'exact' })
      .limit(1);

    if (error) {
      console.log('FAILED');
      console.error(`   ❌ Error: ${error.message}`);
    } else {
      console.log(`PASSED (Rows: ${count ?? 0})`);
      if (data && data.length > 0) {
        console.log(`   ✅ Successfully pulled data: ${JSON.stringify(data[0]).substring(0, 60)}...`);
      } else {
        console.log(`   ℹ️ Table is empty, but connectivity is confirmed.`);
      }
    }
  }

  console.log('\nAudit complete.');
}

runIntegrityCheck().catch(err => {
  console.error('Audit crashed:', err);
  process.exit(1);
});