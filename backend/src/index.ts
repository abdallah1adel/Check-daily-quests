import express from 'express';
import cors from 'cors';
import dotenv from 'dotenv';
import { PrismaClient } from '@prisma/client';
import referralRoutes from './routes/referrals';

dotenv.config();

const app = express();
const prisma = new PrismaClient();
const PORT = process.env.PORT || 3000;

// Middleware
app.use(cors());
app.use(express.json());

// Health Check
app.get('/health', (req, res) => {
    res.json({ status: 'ok', timestamp: new Date() });
});

// --- API Routes ---

// Referral System
app.use('/api/referrals', referralRoutes);

// 1. Identity
app.post('/api/auth/register', async (req, res) => {
    // TODO: Implement DID registration
    res.json({ message: "Registration endpoint" });
});

// 2. Memory (Vector Search)
app.post('/api/memory/search', async (req, res) => {
    const { query, limit } = req.body;
    // TODO: Implement vector search using pgvector
    res.json({ results: [] });
});

// 3. Knowledge Graph
app.get('/api/graph/entity/:name', async (req, res) => {
    // TODO: Retrieve entity and relationships
    res.json({ entity: null });
});

// Start Server
app.listen(PORT, () => {
    console.log(`🚀 Backend Server running on port ${PORT}`);
    console.log(`📚 Database URL: ${process.env.DATABASE_URL ? 'Configured' : 'Missing'}`);
});
