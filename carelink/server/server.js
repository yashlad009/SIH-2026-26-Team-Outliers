const express = require('express');
const cors = require('cors');
require('dotenv').config();

const patientRoutes = require('./routes/patientRoutes');
const triageRoutes = require('./routes/triageRoutes');
const consultRoutes = require('./routes/consultRoutes');
const referralRoutes = require('./routes/referralRoutes');
const stubRoutes = require('./routes/stubRoutes');
const seedRoutes = require('./routes/seedRoutes');

const app = express();
const PORT = process.env.PORT || 5000;

// 1. CORS Middleware Setup
const corsOptions = {
  origin: '*', // Allow all origins for dev/demo client connections
  methods: ['GET', 'POST', 'PUT', 'DELETE', 'OPTIONS'],
  allowedHeaders: ['Content-Type', 'Authorization', 'X-Requested-With', 'Accept'],
  credentials: true,
  optionsSuccessStatus: 200,
};

app.use(cors(corsOptions));
app.options('*', cors(corsOptions)); // Enable preflight OPTIONS handling for all routes

// 2. Request Parsing Middleware
app.use(express.json());
app.use(express.urlencoded({ extended: true }));

// 3. Logger Middleware
app.use((req, res, next) => {
  console.log(`[REST API] ${new Date().toISOString()} | ${req.method} ${req.originalUrl}`);
  next();
});

// 4. API Routes
app.get('/api/health', (req, res) => {
  res.json({
    status: 'online',
    service: 'CareLink REST API Backend',
    timestamp: new Date().toISOString(),
    cors: 'configured',
  });
});

app.use('/api/patients', patientRoutes);
app.use('/api/triage', triageRoutes);
app.use('/api/consults', consultRoutes);
app.use('/api/referrals', referralRoutes);
app.use('/api', stubRoutes);
app.use('/api/seed', seedRoutes);

// 5. 404 Handler
app.use((req, res) => {
  res.status(404).json({ success: false, error: 'API Endpoint Not Found' });
});

// 6. Global Error Handling Middleware
app.use((err, req, res, next) => {
  console.error('[Unhandled Server Error]', err);
  res.status(500).json({
    success: false,
    error: 'Internal Server Error',
    message: err.message,
  });
});

// 7. Server Listener
app.listen(PORT, () => {
  console.log(`=================================================`);
  console.log(`🚀 CareLink REST API Server running on port ${PORT}`);
  console.log(`👉 Health check: http://localhost:${PORT}/api/health`);
  console.log(`👉 Seed endpoint: POST http://localhost:${PORT}/api/seed`);
  console.log(`=================================================`);
});
