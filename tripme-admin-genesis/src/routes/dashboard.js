const express = require('express');
const router = express.Router();
const dashboardController = require('../controllers/DashboardController');
const { ensureAuthenticated } = require('../middlewares/auth');

router.get('/', ensureAuthenticated, dashboardController.getDashboard);


module.exports = router;
