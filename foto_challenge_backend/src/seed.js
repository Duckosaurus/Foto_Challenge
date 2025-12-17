// src/seed.js
import { pool } from "./db.js";

export async function runSeed() {
    const { rowCount } = await pool.query(`SELECT * FROM User;`);
    if (rowCount < 10) {
        // console.log(rowCount);
        await pool.query(`
      INSERT INTO "User" (Username, Passwort) VALUES
    ('Alice', '123'),
    ('Bob', '1234');
`);
        console.log("✔ Testdaten eingefügt");
    } else {
        console.log("✔ Testdaten bereits vorhanden");
    }
}
