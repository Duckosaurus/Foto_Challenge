// src/routes/users.js
import express from "express";
import { pool } from "../db.js";

const router = express.Router();

router.post("/", async (req, res) => {
    const { name, description, dateFrom, dateTo } = req.body;

    // SQL-Abfrage für das Einfügen eines neuen Trips
    const query = `
    INSERT INTO trips (name, description, date_from, date_to)
    VALUES ($1, $2, $3, $4) RETURNING *;
  `;
    const values = [name, description, dateFrom, dateTo];

    try {
        const result = await pool.query(query, values);
        res.status(201).json(result.rows[0]); // Gibt den neu angelegten Trip zurück
    } catch (err) {
        console.error(err);
        res.status(500).json({ error: 'Fehler beim Erstellen des Trips' });
    }
});

export default router;
