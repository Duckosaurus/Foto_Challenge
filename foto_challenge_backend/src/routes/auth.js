import express from "express";
import { pool } from "../db.js";

const router = express.Router();

/**
 * POST /auth/login
 * Body: { username, passwort }
 * Response: { userid }
 */
router.post("/login", async (req, res) => {
    console.log("zum login gekommen")
    const { username, passwort } = req.body;

    console.log(req.body);
    console.log(username, " + ", passwort);
    if (!username || !passwort) {
        return res.status(400).json({ error: "username und passwort erforderlich" });
    }

    const query = `
    SELECT id, passwort
    FROM Benutzer
    WHERE username = $1
  `;

    try {
        const result = await pool.query(query, [username]);

        if (result.rows.length === 0) {
            return res.status(401).json({ error: "Benutzer nicht gefunden" });
        }

        const user = result.rows[0];

        console.log('User PW ', user.passwort, " pw geschickt: ", passwort);
        if (user.passwort !== passwort) {
            return res.status(401).json({ error: "Falsches Passwort" });
        }

        res.json({ userid: user.id });
    } catch (err) {
        console.error(err);
        res.status(500).json({ error: "Login fehlgeschlagen" });
    }
});

/**
 * POST /auth/register
 * Body: { username, passwort }
 * Response: { userid }
 */
router.post("/register", async (req, res) => {
    const { username, passwort } = req.body;

    if (!username || !passwort) {
        return res.status(400).json({ error: "Username und Passwort erforderlich" });
    }

    const query = `
    INSERT INTO Benutzer (username, passwort)
    VALUES ($1, $2)
    RETURNING id
  `;

    try {
        const result = await pool.query(query, [username, passwort]);
        res.status(201).json({ userid: result.rows[0].id });
    } catch (err) {
        if (err.code === "23505") {
            // UNIQUE constraint (username)
            return res.status(409).json({ error: "Username existiert bereits" });
        }

        console.error(err);
        res.status(500).json({ error: "Registrierung fehlgeschlagen" });
    }
});

/**
 * GET /auth/me?userid=1
 */
router.get("/me", async (req, res) => {
    const { userid } = req.query;

    if (!userid) {
        return res.status(400).json({ error: "userid fehlt" });
    }

    const query = `
    SELECT id, username
    FROM Benutzer
    WHERE id = $1
  `;

    try {
        const result = await pool.query(query, [userid]);

        if (result.rows.length === 0) {
            return res.status(404).json({ error: "User nicht gefunden" });
        }

        res.json(result.rows[0]);
    } catch (err) {
        console.error(err);
        res.status(500).json({ error: "Fehler beim Laden des Users" });
    }
});


export default router;

