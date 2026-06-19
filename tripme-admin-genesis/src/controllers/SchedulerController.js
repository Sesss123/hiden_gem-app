// src/controllers/SchedulerController.js
// Proxies all scheduler operations to the Python FastAPI backend.

const axios = require('axios');
const PYTHON_API = process.env.PYTHON_BACKEND_URL || 'http://localhost:8000';
const INTERNAL_KEY = process.env.INTERNAL_API_KEY;

// ─── Helper ───────────────────────────────────────────────────────────────────
async function pyGet(path) {
    const r = await axios.get(`${PYTHON_API}${path}`, { 
        headers: { 'X-Admin-Internal-Key': INTERNAL_KEY },
        timeout: 8000 
    });
    return r.data;
}
async function pyPost(path, body = {}) {
    const r = await axios.post(`${PYTHON_API}${path}`, body, { 
        headers: { 'X-Admin-Internal-Key': INTERNAL_KEY },
        timeout: 10000 
    });
    return r.data;
}
async function pyDelete(path) {
    const r = await axios.delete(`${PYTHON_API}${path}`, { 
        headers: { 'X-Admin-Internal-Key': INTERNAL_KEY },
        timeout: 8000 
    });
    return r.data;
}
async function pyPut(path, body = {}) {
    const r = await axios.put(`${PYTHON_API}${path}`, body, { 
        headers: { 'X-Admin-Internal-Key': INTERNAL_KEY },
        timeout: 10000 
    });
    return r.data;
}

// ─── RENDER PAGE ─────────────────────────────────────────────────────────────
exports.getSchedulerPage = async (req, res, next) => {
    try {
        const [jobsRes, logsRes] = await Promise.allSettled([
            pyGet('/api/scheduler/jobs'),
            pyGet('/api/scheduler/logs?limit=30'),
        ]);
        const jobsData = jobsRes.status === 'fulfilled' ? jobsRes.value : { jobs: [], status: {} };
        const logsData = logsRes.status === 'fulfilled' ? logsRes.value : { logs: [] };

        res.render('scheduler/index', {
            title: 'Job Scheduler',
            jobs: jobsData.jobs || [],
            schedulerStatus: jobsData.status || {},
            runLogs: logsData.logs || [],
            pythonOnline: jobsRes.status === 'fulfilled',
        });
    } catch (err) {
        next(err);
    }
};

// ─── API: LIST JOBS (JSON) ────────────────────────────────────────────────────
exports.listJobs = async (req, res) => {
    try {
        const data = await pyGet('/api/scheduler/jobs');
        return res.json(data);
    } catch (e) {
        return res.status(503).json({ success: false, message: 'Python API unavailable.' });
    }
};

// ─── API: CREATE JOB ─────────────────────────────────────────────────────────
exports.createJob = async (req, res) => {
    try {
        const data = await pyPost('/api/scheduler/jobs', req.body);
        return res.status(201).json(data);
    } catch (e) {
        const msg = e.response?.data?.detail || e.message;
        return res.status(e.response?.status || 500).json({ success: false, message: msg });
    }
};

// ─── API: UPDATE JOB ─────────────────────────────────────────────────────────
exports.updateJob = async (req, res) => {
    try {
        const data = await pyPut(`/api/scheduler/jobs/${req.params.id}`, req.body);
        return res.json(data);
    } catch (e) {
        const msg = e.response?.data?.detail || e.message;
        return res.status(e.response?.status || 500).json({ success: false, message: msg });
    }
};

// ─── API: TOGGLE JOB ─────────────────────────────────────────────────────────
exports.toggleJob = async (req, res) => {
    try {
        const data = await pyPost(`/api/scheduler/jobs/${req.params.id}/toggle`);
        return res.json(data);
    } catch (e) {
        const msg = e.response?.data?.detail || e.message;
        return res.status(e.response?.status || 500).json({ success: false, message: msg });
    }
};

// ─── API: RUN NOW ─────────────────────────────────────────────────────────────
exports.runNow = async (req, res) => {
    try {
        const data = await pyPost(`/api/scheduler/jobs/${req.params.id}/run-now`);
        return res.json(data);
    } catch (e) {
        const msg = e.response?.data?.detail || e.message;
        return res.status(e.response?.status || 500).json({ success: false, message: msg });
    }
};

// ─── API: DELETE JOB ─────────────────────────────────────────────────────────
exports.deleteJob = async (req, res) => {
    try {
        const data = await pyDelete(`/api/scheduler/jobs/${req.params.id}`);
        return res.json(data);
    } catch (e) {
        const msg = e.response?.data?.detail || e.message;
        return res.status(e.response?.status || 500).json({ success: false, message: msg });
    }
};

// ─── API: RUN LOGS ────────────────────────────────────────────────────────────
exports.getLogs = async (req, res) => {
    try {
        const data = await pyGet('/api/scheduler/logs?limit=50');
        return res.json(data);
    } catch (e) {
        return res.status(503).json({ success: false, message: 'Python API unavailable.' });
    }
};
