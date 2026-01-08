import express from "express";
import multer from "multer";
import { pool } from "../db.js";
import fs from 'fs';
import path from 'path';

const router = express.Router();

/**
 * POST /challenge
 * Body: { name, beschreibung, status, tripid }
 * Response: neu angelegte Challenge (inkl. id)
 */
router.post("/", async (req, res) => {
    const { name, beschreibung, status, tripid } = req.body;
    console.log("Challenge post" + name, beschreibung, status, tripid);
    if (!name || !tripid) {
        return res.status(400).json({
            error: "name, tripid sind Pflichtfelder",
        });
    }

    const query = `
    INSERT INTO Challenge (titel, beschreibung, status, tripid)
    VALUES ($1, $2, $3, $4)
    RETURNING *;
  `;

    const values = [
        name,
        beschreibung ?? "",
        status ?? "offen",
        tripid
    ];

    try {
        const result = await pool.query(query, values);
        return res.status(201).json(result.rows[0]);
    } catch (err) {
        console.error(err);
        return res.status(500).json({ error: "Fehler beim Erstellen der Challenge" });
    }
});

router.get("/byTrip/:tripid", async (req, res) => {
    const { tripid } = req.params;
    console.log("trips laden");
    const query = `
    SELECT id, titel, status
    FROM Challenge
    WHERE tripid = $1
    ORDER BY id DESC;
  `;

    try {
        const result = await pool.query(query, [tripid]);
        res.json(result.rows);
    } catch (err) {
        console.error(err);
        res.status(500).json({ error: "Fehler beim Laden der Challenges" });
    }
});


// Multer Storage Setup
const storage = multer.memoryStorage();  // Speichert die Datei im Arbeitsspeicher
const upload = multer({ storage: storage });

// Bild hochladen und in die Datenbank speichern
router.post("/:challengeId/images", upload.single('image'), async (req, res) => {
    const { challengeId } = req.params;
    const { buffer } = req.file;  // `buffer` enthält das binäre Bild
    const notiz = req.body.notiz || '';  // Optional: Notiz zu Bild
    console.log("bild hochladen" + buffer);
    const query = `
    INSERT INTO Foto (Daten, Notiz, ChallengeID)
    VALUES ($1, $2, $3)
    RETURNING *;
  `;

    try {
        const result = await pool.query(query, [buffer, notiz, challengeId]);
        res.status(200).json(result.rows[0]);
    } catch (err) {
        console.error(err);
        res.status(500).json({ error: "Fehler beim Hochladen des Bildes" });
    }
});

// Bilder für eine Challenge anzeigen
router.get("/:challengeId/images", async (req, res) => {
    const { challengeId } = req.params;
    console.log("ja" + challengeId);
    const query = `
    SELECT ID, Daten, Notiz, ErstelltAm
    FROM Foto
    WHERE ChallengeID = $1
  `;

    try {
        const result = await pool.query(query, [challengeId]);

        if (result.rows.length === 0) {
            return res.status(404).json({ message: "Keine Bilder gefunden" });
        }
        console.log(result.rows.length);
        return res.status(404).json({ message: "Keine Bilder gefunden" });
        // Rückgabe der Bilddaten als Base64-String für die Darstellung im Frontend
        const images = result.rows.map(row => ({
            id: row.ID,
            data: row.Daten.toString('base64'),  // Konvertiere das Bild in Base64
            notiz: row.Notiz,
            erstelltAm: row.ErstelltAm,
        }));

        res.status(200).json({ images });
    } catch (err) {
        console.error(err);
        res.status(500).json({ error: "Fehler beim Laden der Bilder" });
    }
});

export default router;
