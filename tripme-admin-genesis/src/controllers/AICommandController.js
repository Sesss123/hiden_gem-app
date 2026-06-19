// src/controllers/AICommandController.js
// NEW: AI Command Center — Vision AI, Real-time Monitoring, Pipeline Execution View

const axios = require('axios');

const PYTHON_API = process.env.PYTHON_BACKEND_URL || 'http://localhost:8000';
const INTERNAL_KEY = process.env.INTERNAL_API_KEY;


// ─── SSE state (in-memory, per-server) ─────────────────────────────────────────
const sseClients = new Set();

function broadcastSSE(data) {
    const message = `data: ${JSON.stringify(data)}\n\n`;
    for (const res of sseClients) {
        try { res.write(message); } catch (e) { sseClients.delete(res); }
    }
}

// ── KEY MANAGEMENT — Proxy helpers ─────────────────────────────────────────────
exports.listKeys = async (req, res) => {
    try {
        const r = await axios.get(`${PYTHON_API}/api/pipeline/keys`, { 
            headers: { 'X-Admin-Internal-Key': INTERNAL_KEY },
            timeout: 5000 
        });
        return res.json(r.data);
    } catch (e) {
        console.error('[AICommand] listKeys Error:', e.response?.data || e.message);
        return res.status(e.response?.status || 503).json({ 
            success: false, 
            message: e.response?.data?.detail || 'Python API unavailable for key listing.' 
        });
    }
};

exports.addKey = async (req, res) => {
    try {
        const { api_key, provider, nickname } = req.body;
        if (!api_key) return res.status(400).json({ success: false, message: 'api_key is required.' });
        const r = await axios.post(`${PYTHON_API}/api/pipeline/keys`, 
            { api_key, provider, nickname }, 
            { 
                headers: { 'X-Admin-Internal-Key': INTERNAL_KEY },
                timeout: 8000 
            }
        );
        return res.json(r.data);
    } catch (e) {
        const msg = e.response?.data?.detail || e.message;
        return res.status(e.response?.status || 500).json({ success: false, message: msg });
    }
};

exports.removeKey = async (req, res) => {
    try {
        const { index } = req.params;
        const r = await axios.delete(`${PYTHON_API}/api/pipeline/keys/${index}`, { 
            headers: { 'X-Admin-Internal-Key': INTERNAL_KEY },
            timeout: 5000 
        });
        return res.json(r.data);
    } catch (e) {
        const msg = e.response?.data?.detail || e.message;
        return res.status(e.response?.status || 500).json({ success: false, message: msg });
    }
};

exports.updateKey = async (req, res) => {
    try {
        const { index } = req.params;
        const { api_key, nickname } = req.body;
        const r = await axios.put(`${PYTHON_API}/api/pipeline/keys/${index}`, 
            { api_key, nickname }, 
            { 
                headers: { 'X-Admin-Internal-Key': INTERNAL_KEY },
                timeout: 8000 
            }
        );
        return res.json(r.data);
    } catch (e) {
        const msg = e.response?.data?.detail || e.message;
        return res.status(e.response?.status || 500).json({ success: false, message: msg });
    }
};


// ─── RENDER AI COMMAND CENTER ───────────────────────────────────────────────────
exports.getAICommandCenter = async (req, res, next) => {
    try {
        // Fetch initial pipeline status from Python backend
        let pipelineStatus = {
            status: 'idle',
            health_score: 100,
            validation_pass_rate: 100,
            current_step: 'Idle',
            steps_completed: 0,
            total_steps: 7,
            log_summary: { INFO: 0, WARNING: 0, ERROR: 0, CRITICAL: 0 },
            alert_status: { consecutive_failures: 0, webhook_configured: false }
        };

        try {
            const statusRes = await axios.get(`${PYTHON_API}/api/pipeline/status`, { 
                headers: { 'X-Admin-Internal-Key': INTERNAL_KEY },
                timeout: 3000 
            });
            pipelineStatus = { ...pipelineStatus, ...statusRes.data };
        } catch (e) {
            console.warn('[AICommand] Python API unreachable, using defaults:', e.message);
        }

        res.render('pipeline/ai-command', {
            title: 'AI Command Center',
            pipelineStatus,
            pythonApiUrl: PYTHON_API,
            layout: 'layout'
        });
    } catch (err) {
        next(err);
    }
};

// ─── VISION AI ANALYSIS (Proxy to Python) ──────────────────────────────────────
exports.analyzeImage = async (req, res) => {
    try {
        const { image_url, place_name } = req.body;

        if (!image_url) {
            return res.status(400).json({ success: false, message: 'Image URL is required.' });
        }

        console.log(`[VisionAI] Analyzing: ${image_url.substring(0, 60)}`);

        const response = await axios.post(
            `${PYTHON_API}/api/pipeline/vision-analyze`,
            { image_url, place_name },
            { 
                headers: { 'X-Admin-Internal-Key': INTERNAL_KEY },
                timeout: 30000 
            }
        );

        return res.json(response.data);
    } catch (err) {
        console.error('[VisionAI] Error:', err.message);
        return res.status(500).json({
            success: false,
            message: 'Vision AI analysis failed.',
            error: err.message
        });
    }
};

// ─── LIVE STATUS SSE STREAM ──────────────────────────────────────────────────────
exports.liveStatusStream = async (req, res) => {
    // Set SSE headers
    res.setHeader('Content-Type', 'text/event-stream');
    res.setHeader('Cache-Control', 'no-cache');
    res.setHeader('Connection', 'keep-alive');
    res.setHeader('Access-Control-Allow-Origin', '*');
    res.flushHeaders();

    // Add this client to the broadcast pool
    sseClients.add(res);
    console.log(`[SSE] Client connected. Total: ${sseClients.size}`);

    // Send immediate heartbeat
    res.write(`data: ${JSON.stringify({ type: 'connected', timestamp: new Date().toISOString() })}\n\n`);

    // Poll Python API every 3 seconds and stream to this client
    const pollInterval = setInterval(async () => {
        try {
            const statusRes = await axios.get(`${PYTHON_API}/api/pipeline/status`, { 
                headers: { 'X-Admin-Internal-Key': INTERNAL_KEY },
                timeout: 2500 
            });
            const data = { type: 'status_update', ...statusRes.data };
            res.write(`data: ${JSON.stringify(data)}\n\n`);
        } catch (e) {
            res.write(`data: ${JSON.stringify({ type: 'api_unreachable', timestamp: new Date().toISOString() })}\n\n`);
        }
    }, 3000);

    // Cleanup on disconnect
    req.on('close', () => {
        clearInterval(pollInterval);
        sseClients.delete(res);
        console.log(`[SSE] Client disconnected. Total: ${sseClients.size}`);
    });
};

// ─── GET CACHE STATUS ─────────────────────────────────────────────────────────────
exports.getCacheStatus = async (req, res) => {
    try {
        const response = await axios.get(`${PYTHON_API}/api/pipeline/cache-status`, { 
            headers: { 'X-Admin-Internal-Key': INTERNAL_KEY },
            timeout: 5000 
        });
        return res.json(response.data);
    } catch (err) {
        console.error('[AICommand] getCacheStatus Error:', err.message);
        return res.status(err.response?.status || 503).json({ 
            error: 'Cache status unavailable', 
            message: err.response?.data?.detail || err.message 
        });
    }
};

// ─── START AI DISCOVERY ──────────────────────────────────────────────────────────
exports.triggerDiscovery = async (req, res) => {
    try {
        const { prompt } = req.body;
        if (!prompt) return res.status(400).json({ success: false, message: 'Prompt is required.' });

        console.log(`[Discovery] Engaging AI Discovery: "${prompt}"`);
        console.log(`[Discovery] URL: ${PYTHON_API}/api/pipeline/discover | Key: ${INTERNAL_KEY ? 'Present' : 'MISSING'}`);
        const r = await axios.post(`${PYTHON_API}/api/pipeline/discover`, 
            { prompt }, 
            { 
                headers: { 'X-Admin-Internal-Key': INTERNAL_KEY },
                timeout: 60000 
            }
        );
        return res.json(r.data);
    } catch (e) {
        const msg = e.response?.data?.detail || e.message;
        return res.status(e.response?.status || 500).json({ success: false, message: msg });
    }
};

// ─── SMART INTAKE (Single URL Extraction) ───────────────────────────────────────
exports.processSmartIntake = async (req, res) => {
    try {
        const { url } = req.body;
        if (!url) return res.status(400).json({ success: false, message: 'URL is required.' });

        console.log(`[SmartIntake] Processing URL: ${url}`);
        const response = await axios.post(
            `${PYTHON_API}/api/pipeline/smart-intake`,
            { url },
            { 
                headers: { 'X-Admin-Internal-Key': INTERNAL_KEY },
                timeout: 120000 // 2 minutes for full scrape+AI cycle
            }
        );

        return res.json(response.data);
    } catch (err) {
        console.error('[SmartIntake] Error:', err.message);
        const msg = err.response?.data?.message || err.message;
        return res.status(err.response?.status || 500).json({
            success: false,
            message: 'Smart Intake failed.',
            error: msg
        });
    }
};

// ─── BROADCAST HELPERS (called from PipelineController) ──────────────────────────
exports.broadcastSSE = broadcastSSE;
exports.stopAgent = async (req, res) => {
    try {
        const response = await axios.post(
            `${PYTHON_API}/api/pipeline/stop`,
            {},
            { 
                headers: { 'X-Admin-Internal-Key': INTERNAL_KEY },
                timeout: 5000 
            }
        );
        return res.json(response.data);
    } catch (err) {
        return res.status(500).json({ success: false, message: 'Stop signal failed.' });
    }
};
