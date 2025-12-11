// src/db.js
import pkg from 'pg';
const { Pool } = pkg;

export const pool = new Pool({
    host: 'localhost',
    port: 5432,
    user: 'user',
    password: 'password',
    database: 'mydb',
});
