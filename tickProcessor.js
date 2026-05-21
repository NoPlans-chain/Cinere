import 'dotenv/config';
import fs from 'fs';
import path from 'path';
import { createClient } from '@supabase/supabase-js';

const SUPABASE_URL = process.env.SUPABASE_URL;
const SERVICE_ROLE_KEY = process.env.SUPABASE_SERVICE_ROLE_KEY;

if (!SUPABASE_URL || !SERVICE_ROLE_KEY) {
  console.error('Missing Supabase environment variables: SUPABASE_URL or SUPABASE_SERVICE_ROLE_KEY');
  process.exit(1);
}

const supabase = createClient(SUPABASE_URL, SERVICE_ROLE_KEY);

function sanitizeCsvValue(value) {
  if (value === null || value === undefined) return '';
  if (typeof value === 'object') return JSON.stringify(value);
  return String(value).replace(/"/g, '""');
}

function rowsToCsv(rows) {
  if (!Array.isArray(rows) || rows.length === 0) {
    return '';
  }

  const headers = Object.keys(rows[0]);
  const csvLines = [headers.map(header => `"${sanitizeCsvValue(header)}"`).join(',')];

  for (const row of rows) {
    const line = headers
      .map(header => {
        const value = sanitizeCsvValue(row[header]);
        return `"${value}"`;
      })
      .join(',');
    csvLines.push(line);
  }

  return csvLines.join('\n');
}

export class TickProcessor {
  constructor() {
    this.supabase = supabase;
  }

  async testConnection() {
    const { data, error } = await this.supabase
      .from('regions')
      .select('id')
      .limit(1);

    if (error) {
      console.error('Supabase connection test failed:', error.message);
      return false;
    }

    console.log('Supabase connection test succeeded. Sample row count:', data?.length ?? 0);
    return true;
  }

  async pullTable(tableName, limit = 1000) {
    const { data, error } = await this.supabase
      .from(tableName)
      .select('*')
      .limit(limit);

    if (error) {
      throw new Error(`Failed to pull table ${tableName}: ${error.message}`);
    }

    return data ?? [];
  }

  async exportTableToCsv(tableName, outputDir = 'exports', limit = 1000) {
    const rows = await this.pullTable(tableName, limit);
    const csv = rowsToCsv(rows);
    const fileName = `${tableName}.csv`;
    const targetDir = path.resolve(process.cwd(), outputDir);
    const targetPath = path.join(targetDir, fileName);

    fs.mkdirSync(targetDir, { recursive: true });
    fs.writeFileSync(targetPath, csv, 'utf-8');
    return { path: targetPath, rowCount: rows.length };
  }

  async runTick() {
    console.log('Running tick fetch: pulling sample data from key tables...');

    const tables = ['regions', 'currencies', 'ticks'];
    const result = {};

    for (const table of tables) {
      result[table] = await this.pullTable(table, 50);
      console.log(`Pulled ${result[table].length} rows from ${table}`);
    }

    return result;
  }
}
