/**
 * Economy Worker for Ex-Cinere
 * Processes regional economic strategies and calculates resource deltas.
 */

const REGIONAL_STRATEGIES = {
  CORE: {
    productionMultiplier: 2.5,
    consumptionRate: 1.8,
    innovationChance: 0.05,
    calculate: (state) => {
      let growth = state.resources * 2.5;
      if (Math.random() < 0.05) growth *= 2; // Tech Leap
      return growth - (state.population * 1.8);
    }
  },
  PERIPHERY: {
    productionMultiplier: 1.2,
    consumptionRate: 0.5,
    exhaustionRisk: 0.02,
    calculate: (state) => {
      // High volume extraction
      let yieldAmount = state.rawDeposits * 1.2;
      if (state.intensity > 0.8 && Math.random() < 0.02) {
        yieldAmount *= 0.5; // Resource exhaustion event
      }
      return yieldAmount;
    }
  },
  ARCHIPELAGO: {
    taxRate: 0.15,
    tradeVolumeFactor: 1.1,
    calculate: (state, globalTradeVolume) => {
      // Revenue from transit
      return (globalTradeVolume * state.hubEfficiency) * 0.15;
    }
  }
};

/**
 * Processes a single economic tick for all regions.
 * @param {Array} regions - Current state of all regions.
 * @param {number} globalTradeVolume - Current global trade activity.
 */
export function processEconomyTick(regions, globalTradeVolume) {
  return regions.map(region => {
    const strategy = REGIONAL_STRATEGIES[region.type];
    
    if (!strategy) return region;

    const delta = strategy.calculate(region.state, globalTradeVolume);

    // --- Population Stability & Crisis Logic ---
    let { warIntensity = 0, diseaseLevel = 0, population = 0, infrastructure = 1 } = region.state;

    // Disease Waves: Congestion (Pop/Infra) increases disease spread
    const congestion = population / (infrastructure * 100);
    diseaseLevel += (Math.random() * 0.04 * congestion) - 0.01;
    diseaseLevel = Math.max(0, Math.min(1, diseaseLevel));

    // War Waves: Scarcity and low treasury increase war intensity
    const scarcity = region.state.resources < 500 ? 0.05 : 0;
    warIntensity += (Math.random() * 0.03) + scarcity - 0.015;
    warIntensity = Math.max(0, Math.min(1, warIntensity));
    
    return {
      ...region,
      state: {
        ...region.state,
        treasury: region.state.treasury + delta,
        warIntensity,
        diseaseLevel
      }
    };
  });
}