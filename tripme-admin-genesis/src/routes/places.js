const express = require('express');
const router = express.Router();
const placeController = require('../controllers/PlaceController');
const { ensureAuthenticated, authorize } = require('../middlewares/auth');
const { logAction } = require('../middlewares/audit');

router.use(ensureAuthenticated);

router.get('/', placeController.getPlaces);
router.get('/create', authorize('super_admin', 'admin'), placeController.getCreate);
router.post('/create', authorize('super_admin', 'admin'), logAction('CREATE_PLACE', 'PLACE'), placeController.postCreate);
router.get('/:id', placeController.getPlace);
router.get('/:id/edit', authorize('super_admin', 'admin'), placeController.getEdit);
router.post('/:id/edit', authorize('super_admin', 'admin'), logAction('UPDATE_PLACE', 'PLACE'), placeController.postUpdate);
router.post('/:id/approve', authorize('super_admin', 'admin'), logAction('APPROVE_PLACE', 'PLACE'), placeController.approvePlace);
router.post('/:id/delete', authorize('super_admin'), logAction('DELETE_PLACE', 'PLACE'), placeController.deletePlace);

// Bulk Operations
router.post('/bulk-action', authorize('super_admin', 'admin'), logAction('BULK_ACTION_PLACE', 'PLACE'), placeController.bulkAction);


module.exports = router;
