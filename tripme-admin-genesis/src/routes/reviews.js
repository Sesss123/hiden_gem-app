const express = require('express');
const router = express.Router();
const reviewController = require('../controllers/ReviewController');
const { ensureAuthenticated, authorize } = require('../middlewares/auth');
const { logAction } = require('../middlewares/audit');

router.use(ensureAuthenticated);
router.use(authorize('super_admin', 'admin', 'reviewer'));

router.get('/', reviewController.getReviewQueue);
router.post('/:id/approve', logAction('APPROVE_PLACE', 'PLACE'), reviewController.approvePlace);
router.post('/:id/reject', logAction('REJECT_PLACE', 'PLACE'), reviewController.rejectPlace);

module.exports = router;
