require('dotenv').config();
const express = require('express');
const mongoose = require('mongoose');
const path = require('path');
const session = require('express-session');
const passport = require('passport');
const flash = require('connect-flash');
const expressLayouts = require('express-ejs-layouts');

// Enterprise Security Modules
const helmet = require('helmet');
const mongoSanitize = require('express-mongo-sanitize');
const xss = require('xss-clean');
const cors = require('cors');

// Configs - Fixed path to auth.js
require('./src/config/auth')(passport);
require('./src/config/firebase')();

// Routes
const authRoutes = require('./src/routes/auth');
const dashboardRoutes = require('./src/routes/dashboard');
const placeRoutes = require('./src/routes/places');
const reviewRoutes = require('./src/routes/reviews');
const pipelineRoutes = require('./src/routes/pipeline');
const mediaRoutes = require('./src/routes/media');
const adminRoutes = require('./src/routes/admin');

const app = express();

// Security: Enable Trust Proxy if behind a load balancer (important for rate-limiting)
app.set('trust proxy', 1);

// Security: CORS Configuration
const corsOptions = {
  origin: process.env.NODE_ENV === 'production' ? process.env.FRONTEND_URL : '*',
  methods: ['GET', 'POST', 'PUT', 'DELETE'],
  allowedHeaders: ['Content-Type', 'Authorization']
};
app.use(cors(corsOptions));

// Security: Set Global HTTP Headers
app.use(helmet({
  contentSecurityPolicy: {
    directives: {
      defaultSrc: ["'self'"],
      scriptSrc: ["'self'", "'unsafe-inline'", "https://cdn.jsdelivr.net", "https://cdn.tailwindcss.com", "https://cdn.jsdelivr.net/npm/sweetalert2@11"],
      styleSrc: ["'self'", "'unsafe-inline'", "https://fonts.googleapis.com", "https://cdn.tailwindcss.com"],
      fontSrc: ["'self'", "https://fonts.gstatic.com"],
      imgSrc: ["'self'", "data:", "https:"],
      // SECURITY: Browser must NEVER connect directly to the Python backend.
      // All requests must flow through the Node.js proxy which adds the X-Admin-Internal-Key.
      connectSrc: ["'self'"]
    }
  }
}));

// MongoDB Connection
mongoose.connect(process.env.MONGODB_URI || 'mongodb://localhost:27017/hiddengems')
  .then(() => console.log('[GENESIS] Neural Link Established (MongoDB Connected)'))
  .catch(err => console.error('[GENESIS] Connection Failure:', err));

// EJS Setup
app.use(expressLayouts);
app.set('view engine', 'ejs');
app.set('views', path.join(__dirname, 'src/views'));
app.set('layout', 'layout');

// Middleware
app.use(express.json({ limit: '10mb' })); // Increased for batch intake
app.use(express.urlencoded({ extended: true, limit: '10mb' }));

// Security: Data Sanitization against NoSQL Query Injection
app.use(mongoSanitize());

// Security: Data Sanitization against XSS
app.use(xss());
app.use(express.static(path.join(__dirname, 'public')));

// Session Configuration
app.use(session({
  secret: process.env.SESSION_SECRET || 'genesis_secret_key_778',
  resave: false,
  saveUninitialized: false,
  cookie: { 
    maxAge: 6 * 60 * 60 * 1000, 
    httpOnly: true,
    secure: process.env.NODE_ENV === 'production',
    sameSite: 'strict'
  }
}));

// Auth
app.use(passport.initialize());
app.use(passport.session());
app.use(flash());

// Global Variables
app.use((req, res, next) => {
  res.locals.success_msg = req.flash('success_msg');
  res.locals.error_msg = req.flash('error_msg');
  res.locals.error = req.flash('error');
  res.locals.user = req.user || null;
  res.locals.path = req.path || '/'; // Added path for layout highlighting
  res.locals.title = 'Genesis Dashboard';
  next();
});

// Route Binding
app.use('/auth', authRoutes);
app.use('/', dashboardRoutes);
app.use('/places', placeRoutes);
app.use('/reviews', reviewRoutes);
app.use('/pipeline', pipelineRoutes);
app.use('/media', mediaRoutes);
app.use('/admin', adminRoutes);

// 404 & Error Handling
app.use((req, res, next) => {
  res.status(404).render('error', { message: 'The requested neural pathway does not exist.', error: {} });
});

app.use((err, req, res, next) => {
  console.error('[GENESIS ERROR]', err.stack);
  res.status(err.status || 500).render('error', { 
    message: err.message || 'A catastrophic system error has occurred.',
    error: process.env.NODE_ENV === 'development' ? err : {},
    layout: false // Fix: Don't use layout for errors to avoid ReferenceErrors
  });
});

const PORT = process.env.PORT || 3006;
app.listen(PORT, () => {
  console.log(`[GENESIS] Command Center broadcasting on http://localhost:${PORT}`);
});
