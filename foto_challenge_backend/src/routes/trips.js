import express from "express";
import { pool } from "../db.js";

const router = express.Router();

router.post("/", async (req, res) => {
    console.log('test1');
    const { name, beschreibung, startdatum, enddatum, userid } = req.body;
    console.log("req body: ", req.body)
    console.log(name)


    // SQL-Abfrage für das Einfügen eines neuen Trips
    const query = `
    INSERT INTO Trip (name, beschreibung, startdatum, enddatum, userid)
    VALUES ($1, $2, $3, $4, $5) RETURNING *;
  `;
    const values = [name, beschreibung, startdatum, enddatum, userid];

    try {
        console.log("query: ", query)
        const result = await pool.query(query, values);
        console.log("nach querry add");
        res.status(201).json(result.rows[0]); // Gibt den neu angelegten Trip zurück
    } catch (err) {
        console.error(err);
        res.status(500).json({ error: 'Fehler beim Erstellen des Trips' });
    }
});

export default router;
