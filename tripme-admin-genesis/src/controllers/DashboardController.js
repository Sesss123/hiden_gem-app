const axios = require('axios');
const Place = require('../models/Place');
const AdminUser = require('../models/AdminUser');
const PipelineRun = require('../models/PipelineRun');
const AuditLog = require('../models/AuditLog');

const PYTHON_API = process.env.PYTHON_BACKEND_URL || 'http://localhost:8000';
const INTERNAL_KEY = process.env.INTERNAL_API_KEY;

exports.getDashboard = async (req, res, next) => {
  try {
    // 1. Fetch Local MongoDB Stats
    const [totalPlaces, approvedPlaces, pendingPlaces, rejectedPlaces, totalUsers] = await Promise.all([
      Place.countDocuments(),
      Place.countDocuments({ status: 'approved' }),
      Place.countDocuments({ status: 'pending' }),
      Place.countDocuments({ status: 'rejected' }),
      AdminUser.countDocuments({ isActive: true })
    ]);
    
    // 2. Fetch Recent Activities
    const recentPlaces = await Place.find()
      .sort({ createdAt: -1 })
      .limit(5);
      
    const recentActivity = await AuditLog.find()
      .sort({ createdAt: -1 })
      .limit(10);
      
    const latestPipeline = await PipelineRun.findOne()
      .sort({ startedAt: -1 });

    // 3. Fetch Python Backend Analytics (Bridged)
    let analytics = {
      total_views: 0,
      top_places: [],
      popular_searches: [],
      recent_runs: []
    };

    try {
      console.log(`[DASHBOARD-BRIDGE] Syncing with Python Analytics Bridge: ${PYTHON_API}/api/admin/stats`);
      console.log(`[DASHBOARD-BRIDGE] Key: ${INTERNAL_KEY ? (INTERNAL_KEY.substring(0, 4) + '...') : 'MISSING'}`);
      
      const response = await axios.get(`${PYTHON_API}/api/admin/stats`, {

        headers: { 'X-Admin-Internal-Key': INTERNAL_KEY },
        timeout: 4000
      });
      analytics = response.data;
      console.log(`[DASHBOARD] Pulse received: ${analytics.total_views} views synced.`);
    } catch (err) {
      console.warn('[DASHBOARD] Python Analytics Bridge failure:', err.message);
    }

    res.render('dashboard', {
      stats: {
        totalPlaces,
        approvedPlaces,
        pendingPlaces,
        rejectedPlaces,
        totalUsers,
        totalViews: analytics.total_views // Bridging local and remote stats
      },
      analytics,
      recentPlaces,
      recentActivity,
      latestPipeline,
      title: 'Dashboard Overview'
    });
  } catch (err) {
    next(err);
  }
};
