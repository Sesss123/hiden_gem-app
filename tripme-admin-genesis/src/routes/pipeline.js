const express = require('express');
const router = express.Router();
const pipelineController = require('../controllers/PipelineController');
const aiCommandController = require('../controllers/AICommandController');
const { ensureAuthenticated, authorize } = require('../middlewares/auth');
const { logAction } = require('../middlewares/audit');

// ─── PROGRAMMATIC INTAKE (No auth — verified by secret key) ──────────────────
router.post('/intake', pipelineController.harvestIntake);
router.post('/batch-intake', pipelineController.harvestBatchIntake);

// ─── AUTHENTICATED ROUTES ─────────────────────────────────────────────────────
router.use(ensureAuthenticated);

// ── Existing pipeline routes ──
router.get('/', pipelineController.getPipelneLogs);
router.post('/trigger', authorize('super_admin', 'admin'), logAction('TRIGGER_PIPELINE', 'PIPELINE'), pipelineController.triggerPipeline);

// ─── AI COMMAND CENTER ────────────────────────────────────────────────────────
router.get('/ai-command', aiCommandController.getAICommandCenter);

// ── Vision AI Analysis (POST: image URL → feature detection) ──
router.post('/vision-analyze', aiCommandController.analyzeImage);

// ── AI Discovery (POST: prompt → search/scrape) ──
router.post('/discover', aiCommandController.triggerDiscovery);
router.post('/stop', aiCommandController.stopAgent);

// ── Cache Status ──
router.get('/cache-status', aiCommandController.getCacheStatus);

// ─── SSE LIVE STATUS STREAM ───────────────────────────────────────────────────
router.get('/live-status', aiCommandController.liveStatusStream);

// ── Smart Intake ──
router.post('/smart-intake', aiCommandController.processSmartIntake);

// ─── API KEY MANAGEMENT (CRUD) ────────────────────────────────────────────────
router.get('/keys',          aiCommandController.listKeys);
router.post('/keys',         aiCommandController.addKey);
router.delete('/keys/:index', aiCommandController.removeKey);
router.put('/keys/:index',   aiCommandController.updateKey);


module.exports = router;
