// src/seed.js
import { pool } from "./db.js";

export async function runSeed() {
    const benutzerResult = await pool.query(`SELECT * FROM Benutzer;`);
    if (benutzerResult.rowCount === 0) {
        // console.log(rowCount);
        await pool.query(`
      INSERT INTO Benutzer (Username, Passwort) VALUES
    ('Alice', '123'),
    ('Bob', '1234'); `);

        console.log("✔ Benutzer Testdaten eingefügt");
    } else {
        console.log("✔ Benutzer Testdaten bereits vorhanden");
    }

    const tripResult = await pool.query(`SELECT * FROM Trip ;`);
    // console.log(tripResult.rowCount)
    if (tripResult.rowCount === 0) {
        await pool.query(`
          INSERT INTO Trip (Name, Beschreibung, Startdatum, Enddatum, UserID)
VALUES (
    'Sommerurlaub Italien',
    'Roadtrip durch Norditalien',
    '2025-07-10',
    '2025-07-20',
    1
); `);

        console.log("✔ Trip Testdaten eingefügt");
    } else {
        console.log("✔ Trip Testdaten bereits vorhanden");
    }
}
