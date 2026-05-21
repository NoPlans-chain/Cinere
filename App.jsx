import React, { useEffect, useState, useRef, useCallback } from 'react';
import { createClient } from '@supabase/supabase-js';
import { Terminal as TerminalIcon, Activity, User, Globe, Wallet, ShieldAlert, TrendingUp } from 'lucide-react';

// Frontend-safe client using environment variables
const supabase = createClient(
  import.meta.env.VITE_SUPABASE_URL,
  import.meta.env.VITE_SUPABASE_ANON_KEY
);

export default function App() {
  const [currentView, setCurrentView] = useState('terminal');
  const [tick, setTick] = useState(0);
  const [character, setCharacter] = useState(null);
  const [balances, setBalances] = useState([]);
  const [regions, setRegions] = useState([]);
  const [logs, setLogs] = useState([]);
  const [tickSummary, setTickSummary] = useState({ trades: 0, orders: 0 });
  const [news, setNews] = useState([]);
  const [markets, setMarkets] = useState([]);
  const [skills, setSkills] = useState([]);

  useEffect(() => {
    const initializeSession = async () => {
      console.log("GUI: Initializing session...");
      
      // 1. Fetch Character (handle potential empty state)
      const { data: chars, error: charErr } = await supabase
        .from('characters')
        .select('*')
        .eq('is_alive', true)
        .limit(1);

      if (chars && chars.length > 0) {
        const activeChar = chars[0];
        setCharacter(activeChar);
        fetchBalances(activeChar.id);
        fetchSkills(activeChar.id);
      }

      // 2. Fetch World State
      const { data: regData } = await supabase.from('regions').select('*');
      setRegions(regData || []);

      const { data: tickData } = await supabase
        .from('ticks')
        .select('id')
        .order('id', { ascending: false })
        .limit(1);
      if (tickData && tickData.length > 0) {
        setTick(tickData[0].id);
        fetchTickSummary(tickData[0].id);
      }

      fetchLogs();
      fetchNews();
      fetchMarkets();
    };

    initializeSession();

    // 2. Real-time Subscriptions
    const channel = supabase
      .channel('simulation-stream')
      .on('postgres_changes', { event: 'UPDATE', schema: 'public', table: 'ticks' }, payload => {
        if (payload.new.summary?.status === 'completed') {
          setTick(payload.new.id);
          fetchLogs();
          fetchNews();
          fetchMarkets();
          fetchTickSummary(payload.new.id);
          if (character) fetchBalances(character.id);
        }
      })
      .subscribe();

    return () => { channel.unsubscribe(); };
  }, []); // Only initialize once on mount

  const fetchBalances = async (charId) => {
    const { data, error } = await supabase
      .from('balances')
      .select('amount, currencies(symbol, name)')
      .eq('character_id', charId);
    
    if (error) console.error("PORTFOLIO_ERROR:", error.message);
    setBalances(data || []);
  };

  const fetchLogs = async () => {
    const { data, error } = await supabase
      .from('tick_logs')
      .select('*')
      .order('created_at', { ascending: false })
      .limit(15);

    if (error) console.error("LOG_STREAM_ERROR:", error.message);
    setLogs(data || []);
  };

  const fetchTickSummary = async (tickId) => {
    const { count: trades } = await supabase.from('trade_history').select('*', { count: 'exact', head: true }).eq('tick_id', tickId);
    const { count: orders } = await supabase.from('orders').select('*', { count: 'exact', head: true }).eq('tick_id', tickId);
    setTickSummary({ trades: trades || 0, orders: orders || 0 });
  };

  const fetchNews = async () => {
    const { data } = await supabase.from('news_feed').select('*').order('created_at', { ascending: false }).limit(5);
    setNews(data || []);
  };

  const fetchMarkets = async () => {
    const { data } = await supabase
      .from('resource_market_prices')
      .select('price, resource_type_id, resource_types(name)')
      .order('tick_id', { ascending: false });
    
    if (data) {
      const latest = {};
      data.forEach(item => {
        if (!latest[item.resource_type_id]) latest[item.resource_type_id] = item;
      });
      setMarkets(Object.values(latest));
    }
  };

  const fetchSkills = async (charId) => {
    const { data } = await supabase.from('skills').select('*').eq('character_id', charId);
    setSkills(data || []);
  };

  return (
    <div className="flex h-screen w-full flex-col bg-navy p-4 text-orange overflow-hidden font-mono">
      {/* TOP HUD - Check if variables are loaded */}
      <header className="mb-4 flex items-center justify-between border-b border-maroon pb-2 shrink-0">
        <div className="flex items-center gap-6">
          <h1 className="text-2xl font-black italic tracking-tighter">EX CINERE // 0.1</h1>
          <div className="flex gap-4">
            <button onClick={() => setCurrentView('terminal')} className={`px-3 py-1 text-xs border ${currentView === 'terminal' ? 'bg-orange text-navy' : 'border-orange'}`}>[ TERMINAL ]</button>
            <button onClick={() => setCurrentView('regions')} className={`px-3 py-1 text-xs border ${currentView === 'regions' ? 'bg-orange text-navy' : 'border-orange'}`}>[ GEOPOLITICS ]</button>
          </div>
        </div>
        <div className="flex items-center gap-4 text-[10px]">
          <span className="flex items-center gap-1"><Activity size={12} /> ENGINE_ACTIVE</span>
          <span className="bg-maroon px-2 py-1 text-white font-bold">TICK: {tick}</span>
        </div>
      </header>

      <div className="flex flex-1 gap-4 overflow-hidden">
        {/* LEFT SIDEBAR: CHARACTER PORTFOLIO */}
        <aside className="w-64 border border-maroon bg-navy/50 p-4 flex flex-col gap-6 shrink-0">
          <section>
            <h2 className="text-[10px] border-b border-maroon mb-2 flex items-center gap-2"><User size={12}/> ENTITY_ID</h2>
            <p className="text-sm font-bold truncate">{character?.name || 'INITIALIZING...'}</p>
            <div className="mt-2 text-[10px] opacity-70">
              <div>INTEGRITY: {character?.is_alive ? (character?.biological_integrity * 100)?.toFixed(2) + '%' : '0.00% [DECEASED]'}</div>
              <div className="w-full bg-maroon/20 h-1 mt-1">
                <div className={`${character?.is_alive ? 'bg-orange' : 'bg-white'} h-full`} style={{width: `${character?.is_alive ? character?.biological_integrity * 100 : 100}%`}}></div>
              </div>
            </div>
          </section>

          <section className="overflow-y-auto max-h-32 shrink-0">
            <h2 className="text-[10px] border-b border-maroon mb-2 flex items-center gap-2"><Wallet size={12}/> CAPITAL_RESERVES</h2>
            {balances.map((b, i) => (
              <div key={i} className="flex justify-between items-center mb-1 text-xs">
                <span>{b.currencies?.symbol}</span>
                <span className="font-bold">{Number(b.amount).toLocaleString()}</span>
              </div>
            ))}
          </section>

          <section className="overflow-y-auto max-h-32 shrink-0">
            <h2 className="text-[10px] border-b border-maroon mb-2 flex items-center gap-2"><Activity size={12}/> COMPETENCIES</h2>
            {skills.map((s, i) => (
              <div key={i} className="flex justify-between items-center mb-1 text-[10px]">
                <span className="opacity-70 capitalize">{s.skill_type}</span>
                <span>{s.level.toFixed(2)}</span>
              </div>
            ))}
          </section>

          <section className="flex-1 overflow-y-auto">
            <h2 className="text-[10px] border-b border-maroon mb-2 flex items-center gap-2"><TrendingUp size={12}/> MARKET_WATCH</h2>
            {markets.map((m, i) => (
              <div key={i} className="flex justify-between items-center mb-1 text-[10px]">
                <span className="opacity-70">{m.resource_types?.name}</span>
                <span className="font-mono">{Number(m.price).toFixed(2)}</span>
              </div>
            ))}
          </section>

          <section className="border-t border-maroon pt-2 italic text-[9px] opacity-50">
            MORTALITY_PROTOCOL_v1.0.4
            <br />PERSISTENCE_LAYER: OK
          </section>
        </aside>

        {/* MAIN VIEW AREA */}
        <main className="flex-1 overflow-hidden flex flex-col gap-4">
          {currentView === 'terminal' && (
            <>
              {/* Tick Summary */}
              <div className="border border-maroon bg-navy/80 p-3 mb-4 shrink-0">
                <h2 className="text-[10px] border-b border-maroon pb-1 mb-2 flex items-center gap-2">
                  <Activity size={12} /> LAST_TICK_SUMMARY (TICK: {tick})
                </h2>
                <div className="grid grid-cols-2 text-[10px] gap-1">
                  <div className="opacity-70">TRADES_EXECUTED:</div>
                  <div className="text-right">{tickSummary?.trades ?? 'N/A'}</div>
                  <div className="opacity-70">ORDERS_PLACED:</div>
                  <div className="text-right">{tickSummary?.orders ?? 'N/A'}</div>
                </div>
              </div>

              {/* Global News Feed */}
              <div className="border border-maroon bg-navy/80 p-3 mb-4 shrink-0">
                <h2 className="text-[10px] border-b border-maroon pb-1 mb-2 flex items-center gap-2">
                  <Globe size={12} /> GLOBAL_NEWS_FEED
                </h2>
                <div className="space-y-1">
                  {news.map((n, i) => (
                    <div key={i} className="text-[10px] flex gap-2">
                      <span className="text-white font-bold shrink-0">[{n.category}]</span>
                      <span className="truncate">{n.headline}</span>
                    </div>
                  ))}
                  {news.length === 0 && <div className="text-[10px] opacity-40 italic">Waiting for signal...</div>}
                </div>
              </div>

              {/* Log Stream */}
              <div className="flex-1 border border-maroon bg-navy/80 overflow-hidden flex flex-col">
                <div className="bg-maroon/20 p-2 text-[10px] flex items-center gap-2 border-b border-maroon">
                  <TerminalIcon size={12} /> SYSTEM_OUTPUT_STREAM
                </div>
                <div className="flex-1 overflow-y-auto p-3 text-[10px] space-y-1">
                  {logs.map((l, i) => (
                    <div key={i} className="border-l border-maroon/50 pl-2">
                      <span className="opacity-50">[{new Date(l.created_at).toLocaleTimeString()}]</span>
                      <span className={`ml-2 ${l.log_level === 'error' ? 'text-white bg-maroon' : ''}`}>
                        {l.message}
                      </span>
                    </div>
                  ))}
                  <div className="animate-pulse">_</div>
                </div>
              </div>
            </>
          )}

          {currentView === 'regions' && (
            <div className="flex-1 border border-maroon overflow-y-auto p-4">
              <h2 className="text-lg font-bold border-b border-maroon mb-4 flex items-center gap-2">
                <Globe size={18} /> GLOBAL_JURISDICTIONS
              </h2>
              <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
                {regions.map((r, i) => (
                  <div key={i} className="border border-maroon/30 p-4 bg-maroon/5">
                    <div className="flex justify-between items-start mb-2">
                      <h3 className="font-black text-white">{r.name}</h3>
                      <span className="text-[10px] bg-orange text-navy px-1">{r.ideology}</span>
                    </div>
                    <div className="grid grid-cols-2 text-[10px] gap-2">
                      <div className="opacity-70">STABILITY:</div>
                      <div className="text-right">{(r.stability * 100).toFixed(0)}%</div>
                      <div className="opacity-70">CRYPTO_POLICY:</div>
                      <div className={`text-right ${r.crypto_policy === 'Banned' ? 'text-white bg-maroon px-1' : ''}`}>
                        {r.crypto_policy}
                      </div>
                      <div className="opacity-70">TAX_RATE:</div>
                      <div className="text-right">{(r.tax_rate * 100).toFixed(1)}%</div>
                      {/* New dynamic data for regions */}
                      <div className="opacity-70">GOVERNMENT:</div>
                      <div className="text-right">{r.government_type || 'N/A'}</div>
                      <div className="opacity-70">ECON_MODEL:</div>
                      <div className="text-right">{r.economic_model || 'N/A'}</div>
                      <div className="opacity-70">CORRUPTION:</div>
                      <div className="text-right">{(r.corruption_level * 100).toFixed(0)}%</div>
                      <div className="opacity-70">INFRA_LEVEL:</div>
                      <div className="text-right">{r.infrastructure_level || '0'}</div>
                    </div>
                  </div>
                ))}
              </div>
            </div>
          )}
        </main>

        {/* QUICK ACTION PANEL */}
        <aside className="w-16 flex flex-col gap-2 shrink-0">
          <button className="flex-1 border border-orange flex flex-col items-center justify-center hover:bg-orange hover:text-navy transition-all">
            <ShieldAlert size={20} />
            <span className="text-[8px] mt-2">ALARM</span>
          </button>
          <div className="flex-1 border border-maroon/30"></div>
        </aside>
      </div>

      {/* FOOTER */}
      <footer className="mt-4 flex justify-between items-center text-[9px] border-t border-maroon pt-2 opacity-60">
        <div className="flex gap-4">
          <span>NET_STATUS: SYNCHRONIZED</span>
          <span>LATENCY: 12ms</span>
        </div>
        <div className="flex gap-4">
          <span>V_1.0.PRIME</span>
          <span className="animate-pulse">● SIGNAL_READY</span>
        </div>
      </footer>

      <style dangerouslySetInnerHTML={{ __html: `
        ::-webkit-scrollbar { width: 4px; }
        ::-webkit-scrollbar-track { background: #020617; }
        ::-webkit-scrollbar-thumb { background: #7f1d1d; }
      `}} />
    </div>
  );
}