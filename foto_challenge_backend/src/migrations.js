// src/migrations.js
import { pool } from "./db.js";

export async function runMigrations() {
    await pool.query(`
    CREATE TABLE IF NOT EXISTS users (
      id SERIAL PRIMARY KEY,
      name TEXT NOT NULL,
      email TEXT UNIQUE NOT NULL
    );
  `);

    console.log("✔ Tabellen erstellt");
}
