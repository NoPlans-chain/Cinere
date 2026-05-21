import { supabase } from './supabase.js';

async function seed() {
  console.log('--- SEEDING EX CINERE WORLD ---');

  // 1. Create a Region
  const { data: region } = await supabase.from('regions').insert([{
    name: 'Neo-Kyoto Sector',
    ideology: 'Market',
    government_type: 'Corporate Oversight',
    economic_model: 'Laissez-faire',
    stability: 0.85,
    tax_rate: 0.12
  }]).select().single();
  console.log('Region created:', region.name);

  // 2. Create a Currency
  const { data: currency } = await supabase.from('currencies').insert([{
    name: 'Credits',
    symbol: 'CR',
    region_id: region.id
  }]).select().single();

  // 3. Create a Character
  const { data: char } = await supabase.from('characters').insert([{
    name: 'Asset_01_User',
    origin_region_id: region.id,
    biological_integrity: 1.0,
    character_type: 'Player',
    preferred_currency_id: currency.id
  }]).select().single();
  console.log('Character created:', char.name);

  // 4. Initial Balance
  await supabase.from('balances').insert([{
    character_id: char.id,
    currency_id: currency.id,
    amount: 1500000
  }]);

  // 5. Create Resource Types (needed for market chart)
  const { data: res } = await supabase.from('resource_types').insert([{
    name: 'Raw Silicates',
    category: 'Mineral',
    base_value: 100
  }]).select().single();

  // 6. First Price Entry
  await supabase.from('resource_market_prices').insert([{
    resource_type_id: res.id,
    tick_id: null, // Initial seed
    price: 100.0
  }]);

  console.log('--- SEEDING COMPLETE ---');
  process.exit(0);
}

seed();