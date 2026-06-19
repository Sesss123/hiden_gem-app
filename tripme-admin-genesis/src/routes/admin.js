const express = require('express');
const router = express.Router();
const userController = require('../controllers/UserController');
const auditController = require('../controllers/AuditController');
const schedulerController = require('../controllers/SchedulerController');
const { ensureAuthenticated, authorize } = require('../middlewares/auth');

router.use(ensureAuthenticated);
router.use(authorize('super_admin'));

// User Management
router.get('/users', userController.getUsers);
router.post('/users/:id/toggle', userController.toggleStatus);
router.post('/users/:id/role', userController.updateRole);

// Security Logs
router.get('/logs', auditController.getLogs);

// Scheduler — Page
router.get('/scheduler', schedulerController.getSchedulerPage);

// Scheduler — JSON API (used by dashboard JS)
router.get('/scheduler/jobs', schedulerController.listJobs);
router.post('/scheduler/jobs', schedulerController.createJob);
router.put('/scheduler/jobs/:id', schedulerController.updateJob);
router.post('/scheduler/jobs/:id/toggle', schedulerController.toggleJob);
router.post('/scheduler/jobs/:id/run-now', schedulerController.runNow);
router.delete('/scheduler/jobs/:id', schedulerController.deleteJob);
router.get('/scheduler/logs', schedulerController.getLogs);


// System Commands
const systemController = require('../controllers/SystemController');
router.get('/system', systemController.getSystemStatus);
router.post('/system/start-ai', systemController.startAiBackend);
router.post('/system/stop-ai', systemController.stopAiBackend);
router.get('/system/backups', systemController.listBackups);
router.post('/system/backup', systemController.runBackup);
router.post('/system/restore', systemController.runRestore);

// Pipeline Controls
const pipelineController = require('../controllers/PipelineController');
router.post('/stop-pipeline/:runId', pipelineController.stopPipeline);

module.exports = router;
