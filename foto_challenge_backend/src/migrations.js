// src/migrations.js
import { pool } from "./db.js";

export async function runMigrations() {
  await pool.query(`
CREATE TABLE IF NOT EXISTS "User" (
    ID SERIAL PRIMARY KEY,
    Username VARCHAR(255) NOT NULL UNIQUE,
    Passwort VARCHAR(255) NOT NULL
);

CREATE TABLE IF NOT EXISTS "Trip" (
    ID SERIAL PRIMARY KEY,
    Name VARCHAR(255) NOT NULL,
    Beschreibung TEXT,
    Startdatum DATE NOT NULL,
    Enddatum DATE NOT NULL,
    UserID INT NOT NULL,
    FOREIGN KEY (UserID) REFERENCES "User"(ID) ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS "Challenge" (
    ID SERIAL PRIMARY KEY,
    Titel VARCHAR(255) NOT NULL,
    Beschreibung TEXT,
    Status VARCHAR(50) NOT NULL,
    TripID INT NOT NULL,
    FOREIGN KEY (TripID) REFERENCES "Trip"(ID) ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS "ChallengeTemplate" (
    ID SERIAL PRIMARY KEY,
    Titel VARCHAR(255) NOT NULL,
    Beschreibung TEXT
);

CREATE TABLE IF NOT EXISTS "Foto" (
    ID SERIAL PRIMARY KEY,
    Daten BYTEA NOT NULL,
    ErstelltAm TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    Notiz TEXT,
    ChallengeID INT NOT NULL,
    FOREIGN KEY (ChallengeID) REFERENCES "Challenge"(ID) ON DELETE CASCADE
);
  `);

  console.log("✔ Tabellen erstellt");
}
