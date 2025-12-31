// src/app.js
import express from "express";
import { runMigrations } from "./migrations.js";
import { runSeed } from "./seed.js";
import tripsRouter from "./routes/trips.js";
import authRouter from "./routes/auth.js";

const app = express();
app.use(express.json());

// Routen registrieren
app.use('/trips', tripsRouter);
app.use('/auth', authRouter);

// Startup-Logik
(async () => {
    await runMigrations();
    await runSeed();
})();

const PORT = 3000;
app.listen(PORT, "0.0.0.0", () => console.log(`Backend läuft auf Port ${PORT}`));

// app.listen(PORT, () => console.log(`Backend läuft auf Port ${PORT}`));
