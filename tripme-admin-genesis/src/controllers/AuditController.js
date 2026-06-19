const AuditLog = require('../models/AuditLog');

exports.getLogs = async (req, res, next) => {
  try {
    const page = parseInt(req.query.page) || 1;
    const limit = 20;
    const skip = (page - 1) * limit;

    const total = await AuditLog.countDocuments();
    const logs = await AuditLog.find()
      .sort({ createdAt: -1 })
      .skip(skip)
      .limit(limit);

    res.render('logs/index', {
      logs,
      total,
      page,
      pages: Math.ceil(total / limit),
      title: 'Security & Audit Logs'
    });
  } catch (err) {
    next(err);
  }
};
