const express = require('express');
const router = express.Router();
const authController = require('../controllers/AuthController');
const rateLimit = require('express-rate-limit');

// Security: Defense against brute-force password guessing
const loginLimiter = rateLimit({
  windowMs: 15 * 60 * 1000, // 15 minutes
  max: 100, // Limit each IP to 100 requests per windowMs
  message: 'Security Lockout: Too many login attempts from this IP. Please try again after 15 minutes.',
  standardHeaders: true,
  legacyHeaders: false,
});

router.get('/login', authController.getLogin);
router.post('/login', loginLimiter, authController.postLogin);
router.get('/logout', authController.logout);

module.exports = router;
