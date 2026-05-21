import 'dotenv/config';
import { TickProcessor } from '../tickProcessor.js';

async function main() {
  const processor = new TickProcessor();

  console.log('--- EXPORT DATA: START ---');

  const connected = await processor.testConnection();
  if (!connected) {
    console.error('Connection failed. Aborting export.');
    process.exit(1);
  }

  const tables = [
    'regions',
    'currencies',
    'ticks'
  ];

  for (const table of tables) {
    try {
      const { path, rowCount } = await processor.exportTableToCsv(table, 'exports', 1000);
      console.log(`Exported ${rowCount} rows from ${table} → ${path}`);
    } catch (error) {
      console.error(`Failed to export ${table}:`, error.message || error);
    }
  }

  console.log('--- EXPORT DATA: COMPLETE ---');
}

main().catch(err => {
  console.error('Export crashed:', err);
  process.exit(1);
});