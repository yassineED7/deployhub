const express = require('express');
const pool = require('./db');

const app = express();

// Middleware to parse incoming JSON payloads
app.use(express.json());

/**
 * GET /health
 * Health check endpoint to verify API and database connectivity (crucial for DevOps/monitoring tools like Kubernetes/Docker)
 */
app.get('/health', async (req, res) => {
  try {
    // Run a simple query to verify active database connection
    await pool.query('SELECT 1');
    res.status(200).json({ status: 'UP', database: 'CONNECTED' });
  } catch (err) {
    res.status(500).json({ status: 'DOWN', database: 'DISCONNECTED', error: err.message });
  }
});

/**
 * GET /tasks
 * Fetch all tasks sorted by ID in ascending order
 */
app.get('/tasks', async (req, res) => {
  try {
    const { rows } = await pool.query('SELECT * FROM tasks ORDER BY id ASC');
    res.json(rows);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

/**
 * GET /tasks/:id
 * Fetch a single task by its unique ID
 */
app.get('/tasks/:id', async (req, res) => {
  try {
    const { id } = req.params;
    const { rows } = await pool.query('SELECT * FROM tasks WHERE id = $1', [id]);
    
    // Return 404 if no matching task is found
    if (rows.length === 0) return res.status(404).json({ error: 'Task not found' });
    
    res.json(rows[0]);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

/**
 * POST /tasks
 * Create a new task
 */
app.post('/tasks', async (req, res) => {
  try {
    const { title } = req.body;
    
    // Validate required request payload field
    if (!title) return res.status(400).json({ error: 'Title is required' });
    
    // Insert new task and return the inserted record
    const { rows } = await pool.query('INSERT INTO tasks (title) VALUES ($1) RETURNING *', [title]);
    res.status(201).json(rows[0]);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

/**
 * PUT /tasks/:id
 * Update an existing task's title or completion status
 */
app.put('/tasks/:id', async (req, res) => {
  try {
    const { id } = req.params;
    const { title, completed } = req.body;
    
    // COALESCE keeps existing values if new parameters are null/undefined
    const { rows } = await pool.query(
      'UPDATE tasks SET title = COALESCE($1, title), completed = COALESCE($2, completed) WHERE id = $3 RETURNING *',
      [title, completed, id]
    );
    
    if (rows.length === 0) return res.status(404).json({ error: 'Task not found' });
    
    res.json(rows[0]);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

/**
 * DELETE /tasks/:id
 * Remove a task by its ID
 */
app.delete('/tasks/:id', async (req, res) => {
  try {
    const { id } = req.params;
    const { rowCount } = await pool.query('DELETE FROM tasks WHERE id = $1', [id]);
    
    // Check if a record was actually deleted
    if (rowCount === 0) return res.status(404).json({ error: 'Task not found' });
    
    // Return 204 No Content on successful deletion
    res.status(204).send();
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

module.exports = app;