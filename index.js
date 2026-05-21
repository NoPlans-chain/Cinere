import 'dotenv/config';
import { TickProcessor } from './tickProcessor.js';

const TICK_INTERVAL_MS = 300_000; // 5 minutes in milliseconds
const processor = new TickProcessor();
let isProcessing = false;

async function tickLoop() {
  if (isProcessing) {
    console.warn('Previous tick still processing. Skipping interval to prevent race conditions.');
    return;
  }

  isProcessing = true;
  try {
    console.log(`[${new Date().toISOString()}] ENGINE_TICK_START`);
    await processor.runTick();
    console.log(`[${new Date().toISOString()}] ENGINE_TICK_COMPLETE`);
  } catch (err) {
    console.error('Fatal error in tick loop:', err);
  } finally {
    isProcessing = false;
  }
}

async function bootstrap() {
  console.log('--- EX CINERE: CORE ENGINE INITIALIZING ---');
  console.log(`Target Interval: ${TICK_INTERVAL_MS}ms`);
  
  const isConnected = await processor.testConnection();
  if (!isConnected) {
    console.error('CRITICAL: Startup aborted. Check Supabase credentials.');
    process.exit(1);
  }

  console.log('CONNECTION_ESTABLISHED: Terminal interface active.');
  setInterval(tickLoop, TICK_INTERVAL_MS);
  tickLoop(); // Run immediately on start
}

// Handle graceful shutdown to prevent interrupted persistence
process.on('SIGINT', () => {
  console.log('\nENGINE_SHUTDOWN_REQUESTED: Finalizing state and exiting...');
  process.exit(0);
});

bootstrap();