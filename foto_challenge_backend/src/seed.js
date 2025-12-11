// src/seed.js
import { pool } from "./db.js";

export async function runSeed() {
    const { rowCount } = await pool.query(`SELECT * FROM users;`);
    if (rowCount === 0) {
        await pool.query(`
      INSERT INTO users (name, email) VALUES
        ('Alice', 'alice@example.com'),
        ('Bob', 'bob@example.com');
    `);
        console.log("✔ Testdaten eingefügt");
    } else {
        console.log("✔ Testdaten bereits vorhanden");
    }
}
