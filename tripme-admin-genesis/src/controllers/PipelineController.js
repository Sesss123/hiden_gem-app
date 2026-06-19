const axios = require('axios');
const Place = require('../models/Place');

const BACKEND_URL = process.env.BACKEND_API_URL || 'http://localhost:8000';
const INTERNAL_KEY = process.env.INTERNAL_API_KEY;

exports.triggerDiscovery = async (req, res) => {
    try {
        const { prompt } = req.body;
        if (!prompt) return res.status(400).json({ success: false, message: 'Prompt is required' });

        // Forward to Python AI Discovery engine
        const response = await axios.post(`${BACKEND_URL}/api/pipeline/discover`, {
            prompt
        }, {
            headers: { 'X-Admin-Internal-Key': INTERNAL_KEY }
        });

        res.json({
            success: true,
            message: 'Neural AI discovery job initiated.',
            data: response.data
        });
    } catch (err) {
        console.error('Neural Discovery Error:', err.message);
        res.status(500).json({ success: false, message: 'Failed to trigger AI discovery' });
    }
};

exports.harvestIntake = async (req, res) => {
    try {
        const { url } = req.body;
        if (!url) return res.status(400).json({ success: false, message: 'URL is required' });

        // Forward to Python Smart Intake engine
        const response = await axios.post(`${BACKEND_URL}/api/pipeline/smart-intake`, {
            url
        }, {
            headers: { 'X-Admin-Internal-Key': INTERNAL_KEY }
        });

        res.json({
            success: true,
            message: 'Smart URL intake job initiated.',
            data: response.data
        });
    } catch (err) {
        console.error('Smart Intake Error:', err.message);
        res.status(500).json({ success: false, message: 'Failed to trigger URL intake' });
    }
};

exports.getPipelineState = async (req, res) => {
    try {
        const response = await axios.get(`${BACKEND_URL}/api/pipeline/state`, {
            headers: { 'X-Admin-Internal-Key': INTERNAL_KEY }
        });
        res.json(response.data);
    } catch (err) {
        res.status(500).json({ message: 'Offline' });
    }
};
exports.harvestBatchIntake = async (req, res) => {
    res.json({ success: true, message: 'Batch intake scheduled.' });
};

exports.getPipelneLogs = async (req, res, next) => {
    try {
        const PipelineRun = require('../models/PipelineRun');
        const runs = await PipelineRun.find().sort({ startedAt: -1 }).populate('triggeredBy', 'name');
        res.render('pipeline/index', { 
            title: 'Pipeline Monitor', 
            runs: runs || []
        });
    } catch (err) {
        console.error('Pipeline UI Render Error:', err);
        next(err);
    }
};

exports.triggerPipeline = async (req, res) => {
    try {
        await axios.post(`${BACKEND_URL}/api/pipeline/trigger`, {}, {
            headers: { 'X-Admin-Internal-Key': INTERNAL_KEY }
        });
        res.redirect('/pipeline');
    } catch (err) {
        console.error('Trigger Pipeline Error:', err.message);
        res.redirect('/pipeline?error=TriggerFailed');
    }
};

exports.stopPipeline = async (req, res) => {
    try {
        const { runId } = req.params;
        const response = await axios.post(`${BACKEND_URL}/api/admin/stop-pipeline/${runId}`, {}, {
            headers: { 'X-Admin-Internal-Key': INTERNAL_KEY }
        });
        res.json(response.data);
    } catch (err) {
        res.status(500).json({ success: false, message: 'Stop failed' });
    }
};
