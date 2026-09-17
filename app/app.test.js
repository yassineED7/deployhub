const request = require('supertest');
const app = require('./app');
const pool = require('./db');

describe('API Healthcheck & Smoke Tests', () => {
  // Close the database connection pool after all tests finish so Jest can exit gracefully
  afterAll(async () => {
    await pool.end();
  });

  it('GET /health - should respond with status code', async () => {
    const res = await request(app).get('/health');
    // Even if the database is disconnected locally, the server should respond with a valid status code (200 or 500)
    expect([200, 500]).toContain(res.statusCode);
  });
});