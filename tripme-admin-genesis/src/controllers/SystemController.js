const { spawn, exec } = require('child_process');
const path = require('path');
const axios = require('axios');

const PYTHON_API = process.env.PYTHON_BACKEND_URL || 'http://localhost:8000';
const INTERNAL_KEY = process.env.INTERNAL_API_KEY;

// Keep global reference to the process
let pyProcess = null;

const killPythonProcess = () => {
    if (pyProcess) {
        console.log(`[SYSTEM] Terminating Python Subsystem (PID: ${pyProcess.pid})`);
        if (process.platform === 'win32') {
            exec(`taskkill /pid ${pyProcess.pid} /T /F`);
        } else {
            pyProcess.kill('SIGTERM');
        }
        pyProcess = null;
    }
};

// Graceful cleanup on Node exit
process.on('exit', killPythonProcess);
process.on('SIGINT', () => { killPythonProcess(); process.exit(); });
process.on('SIGTERM', () => { killPythonProcess(); process.exit(); });

exports.getSystemStatus = async (req, res) => {
    let pyActive = pyProcess !== null;
    let pyPid = pyProcess ? pyProcess.pid : 'Offline';

    // If not active locally, ping the API to see if it was started manually
    if (!pyActive) {
        try {
            await axios.get(PYTHON_API, { timeout: 800 });
            pyActive = true;
            pyPid = 'Active (External)';
        } catch (err) {
            // Remains offline
        }
    }

    res.render('system/index', {
        title: 'System Commands',
        pyActive,
        pyPid
    });
};

exports.startAiBackend = (req, res) => {
    if (pyProcess) {
        req.flash('error_msg', 'AI Pipeline Server is already online.');
        return res.redirect('/admin/system');
    }

    const backendPath = path.join(__dirname, '../../../backend');
    console.log('[SYSTEM] Booting Uvicorn Matrix in:', backendPath);

    try {
        pyProcess = spawn('uvicorn', ['main:app', '--port', '8000', '--reload'], {
            cwd: backendPath,
            shell: true
        });

        pyProcess.stdout.on('data', (data) => {
            console.log(`[AI-API] ${data}`.trim());
        });

        pyProcess.stderr.on('data', (data) => {
            console.error(`[AI-API WARN] ${data}`.trim());
        });

        pyProcess.on('close', (code) => {
            console.log(`[SYSTEM] Python API exited with termination code ${code}`);
            pyProcess = null;
        });

        req.flash('success_msg', 'AI Pipeline Server sequence initiated.');
    } catch (err) {
        console.error('[SYSTEM] Failed to spawn process:', err);
        req.flash('error_msg', 'Critical failure during AI boot sequence.');
    }
    
    res.redirect('/admin/system');
};

exports.stopAiBackend = (req, res) => {
    if (!pyProcess) {
        req.flash('error_msg', 'AI Pipeline Server is offline.');
        return res.redirect('/admin/system');
    }

    killPythonProcess();
    req.flash('success_msg', 'AI Pipeline terminated safely.');
    res.redirect('/admin/system');
};

// ─── BACKUP & RESTORE PROXIES ──────────────────────────────────────────────────

exports.listBackups = async (req, res) => {
    try {
        const response = await axios.get(`${PYTHON_API}/api/admin/system/backups`, {
            headers: { 'X-Admin-Internal-Key': INTERNAL_KEY }
        });
        res.json(response.data);
    } catch (err) {
        console.error('[System] listBackups Error:', err.message);
        res.status(err.response?.status || 500).json({ 
            success: false, 
            message: err.response?.data?.detail || err.message 
        });
    }
};

exports.runBackup = async (req, res) => {
    try {
        const response = await axios.post(`${PYTHON_API}/api/admin/system/backup`, {}, {
            headers: { 'X-Admin-Internal-Key': INTERNAL_KEY }
        });
        res.json({ success: true, ...response.data });
    } catch (err) {
        console.error('[System] runBackup Error:', err.message);
        res.status(err.response?.status || 500).json({ 
            success: false, 
            message: err.response?.data?.detail || err.message 
        });
    }
};

exports.runRestore = async (req, res) => {
    try {
        const { folder } = req.body;
        if (!folder) return res.status(400).json({ success: false, message: 'Folder name is required.' });

        const response = await axios.post(`${PYTHON_API}/api/admin/system/restore`, { folder }, {
            headers: { 'X-Admin-Internal-Key': INTERNAL_KEY }
        });
        res.json({ success: true, ...response.data });
    } catch (err) {
        console.error('[System] runRestore Error:', err.message);
        res.status(err.response?.status || 500).json({ 
            success: false, 
            message: err.response?.data?.detail || err.message 
        });
    }
};
