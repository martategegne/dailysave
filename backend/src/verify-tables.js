import { pool, closePool } from './config/database.js';

async function listTables() {
  const queryText = `
    SELECT table_name 
    FROM information_schema.tables 
    WHERE table_schema = 'public' 
    ORDER BY table_name;
  `;
  const res = await pool.query(queryText);
  console.log(`Verified ${res.rowCount} tables in dailysave_db:`);
  for (const row of res.rows) {
    console.log(`  ✓ ${row.table_name}`);
  }
  await closePool();
}

listTables().catch((err) => {
  console.error(err);
  process.exit(1);
});
