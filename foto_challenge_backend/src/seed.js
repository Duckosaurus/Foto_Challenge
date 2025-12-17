// src/seed.js
import { pool } from "./db.js";

export async function runSeed() {
    const { rowCount } = await pool.query(`SELECT * FROM Benutzer;`);
    if (rowCount === 0) {
        // console.log(rowCount);
        await pool.query(`
      INSERT INTO Benutzer (Username, Passwort) VALUES
    ('Alice', '123'),
    ('Bob', '1234');
`);
        console.log("✔ Testdaten eingefügt");
    } else {
        console.log("✔ Testdaten bereits vorhanden");
    }
}
