// src/app.js
import express from "express";
import { runMigrations } from "./migrations.js";
import { runSeed } from "./seed.js";
import usersRoute from "./routes/users.js";

const app = express();
app.use(express.json());

// Routen registrieren
app.use("/users", usersRoute);

// Startup-Logik
(async () => {
    await runMigrations();
    await runSeed();
})();

const PORT = 3000;
app.listen(PORT, () => console.log(`Backend läuft auf Port ${PORT}`));
