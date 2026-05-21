/**
 * Trading Worker for Ex-Cinere
 * Logic for NPC market participation and National Leader sovereign trading.
 */

const MARKET_CONFIG = {
  CRYPTO_VOLATILITY: 0.08,
  FIAT_STABILITY: 0.01,
  BASE_EXCHANGE_RATE: 45000.0 // 1 Crypto = 45k Fiat
};

const REGIONAL_DEMOGRAPHICS = {
  CORE: { minLife: 80, maxLife: 100, birthChance: 0.01, birthThreshold: 5000, healthResilience: 0.9 },
  PERIPHERY: { minLife: 40, maxLife: 60, birthChance: 0.05, birthThreshold: 1000, healthResilience: 0.2 },
  ARCHIPELAGO: { minLife: 60, maxLife: 80, birthChance: 0.03, birthThreshold: 2500, healthResilience: 0.6 }
};

function getRandomInt(min, max) {
  return Math.floor(Math.random() * (max - min + 1)) + min;
}

const LEADER_TRADING_LOGIC = {
  CORE: (state, price) => {
    // Core leaders hedge against maintenance costs by accumulating crypto
    if (state.treasury > 1000000 && price < MARKET_CONFIG.BASE_EXCHANGE_RATE * 1.1) {
      return { action: 'BUY', amount: state.treasury * 0.1 };
    }
    return { action: 'HOLD' };
  },
  PERIPHERY: (state, price) => {
    // Periphery leaders liquidate crypto to fund extraction if treasury is low
    if (state.treasury < 50000 && state.cryptoReserves > 0) {
      return { action: 'SELL', amount: state.cryptoReserves * 0.5 };
    }
    return { action: 'HOLD' };
  },
  ARCHIPELAGO: (state, price) => {
    // Archipelago leaders act as market makers, buying low/selling high
    if (price < MARKET_CONFIG.BASE_EXCHANGE_RATE * 0.95) return { action: 'BUY', amount: state.treasury * 0.05 };
    if (price > MARKET_CONFIG.BASE_EXCHANGE_RATE * 1.05) return { action: 'SELL', amount: state.cryptoReserves * 0.05 };
    return { action: 'HOLD' };
  }
};

/**
 * Speculatively determines initial NPC count based on nation wealth.
 */
export function initializeNPCTraders(nation) {
  const strategy = REGIONAL_DEMOGRAPHICS[nation.type];
  // Speculative: 1 NPC per 10,000 Fiat in treasury, capped at 1000 for performance
  const count = Math.min(Math.floor(nation.state.treasury / 10000), 1000);
  
  return Array.from({ length: count }, (_, i) => ({
    id: `npc_${nation.type}_${i}`,
    region: nation.type,
    age: getRandomInt(0, strategy.minLife),
    maxAge: getRandomInt(strategy.minLife, strategy.maxLife),
    riskTolerance: Math.random() * 2 - 1, // -1 to 1
    wallet: {
      fiat: getRandomInt(100, 1000),
      crypto: 0
    },
    lastAction: 'HOLD'
  }));
}

/**
 * Executes a sovereign trade for a nation leader.
 * Assets stay within nation state (non-transferable).
 */
export function executeLeaderTrade(nation, currentPrice) {
  const strategy = LEADER_TRADING_LOGIC[nation.type];
  if (!strategy) return nation;

  const { action, amount } = strategy(nation.state, currentPrice);

  const newState = { ...nation.state };

  if (action === 'BUY' && newState.treasury >= amount) {
    newState.treasury -= amount;
    newState.cryptoReserves += (amount / currentPrice);
  } else if (action === 'SELL' && newState.cryptoReserves > 0) {
    const cryptoToSell = Math.min(newState.cryptoReserves, amount);
    newState.cryptoReserves -= cryptoToSell;
    newState.treasury += (cryptoToSell * currentPrice);
  }

  return { ...nation, state: newState };
}

/**
 * NPC (Retail) trading behavior based on sentiment.
 * Influenced by price action.
 */
export function processNPCLifecycle(npcs, currentPrice, priceChangePercent, regionalStability = {}) {
  const nextGeneration = [];
  
  const processedNPCs = npcs.map(npc => {
    const demo = REGIONAL_DEMOGRAPHICS[npc.region];
    const stability = regionalStability[npc.region] || { warIntensity: 0, diseaseLevel: 0 };

    const updatedNPC = { ...npc, age: npc.age + 1 };

    // 1. Check for Death (Natural, Disease, or War Attrition)
    const diseaseMortality = (stability.diseaseLevel * (1 - demo.healthResilience)) * (updatedNPC.age / updatedNPC.maxAge);
    const warMortality = stability.warIntensity * 0.02; // Flat 2% attrition max during total war
    const healthCheckFailed = Math.random() < (diseaseMortality + warMortality);

    if (updatedNPC.age >= updatedNPC.maxAge || healthCheckFailed) {
      return null; // NPC dies
    }

    // 2. Trading Logic
    const sentiment = updatedNPC.riskTolerance + priceChangePercent;
    let { fiat, crypto } = updatedNPC.wallet;

    if (sentiment > 0.6 && fiat > 10) {
      const spend = fiat * 0.2;
      crypto += spend / currentPrice;
      fiat -= spend;
      updatedNPC.lastAction = 'BUY';
    } else if (sentiment < -0.4 && crypto > 0) {
      fiat += crypto * currentPrice;
      crypto = 0;
      updatedNPC.lastAction = 'SELL';
    } else {
      updatedNPC.lastAction = 'HOLD';
    }

    updatedNPC.wallet = { fiat, crypto };

    // 3. Offspring Logic
    const totalWealth = fiat + (crypto * currentPrice);
    // War suppresses the birth rate
    const effectiveBirthChance = demo.birthChance * (1 - stability.warIntensity);

    if (totalWealth > demo.birthThreshold && Math.random() < effectiveBirthChance) {
      const inheritance = updatedNPC.wallet.fiat * 0.1;
      updatedNPC.wallet.fiat -= inheritance;
      
      nextGeneration.push({
        id: `npc_${npc.region}_born_${Date.now()}_${Math.random()}`,
        region: npc.region,
        age: 0,
        maxAge: getRandomInt(demo.minLife, demo.maxLife),
        riskTolerance: Math.random() * 2 - 1,
        wallet: {
          fiat: inheritance,
          crypto: 0
        },
        lastAction: 'BORN'
      });
    }

    return updatedNPC;
  }).filter(Boolean); // Remove dead NPCs

  return [...processedNPCs, ...nextGeneration];
}

export function getMarketPrice(lastPrice) {
  const noise = (Math.random() - 0.5) * 2 * MARKET_CONFIG.CRYPTO_VOLATILITY;
  return lastPrice * (1 + noise);
}