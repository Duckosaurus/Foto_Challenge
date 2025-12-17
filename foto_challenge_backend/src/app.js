// src/app.js
import express from "express";
import { runMigrations } from "./migrations.js";
import { runSeed } from "./seed.js";
import tripsRouter from "./routes/trips.js";

const app = express();
app.use(express.json());

// Routen registrieren
app.use('/trips', tripsRouter);


// Startup-Logik
(async () => {
    await runMigrations();
    await runSeed();
})();

const PORT = 3000;
app.listen(PORT, () => console.log(`Backend läuft auf Port ${PORT}`));
