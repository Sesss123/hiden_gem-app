const AuditLog = require('../models/AuditLog');

exports.logAction = (action, entityType) => {
  return async (req, res, next) => {
    // We wrap the original res.send/redirect to log after successful operation
    const originalSend = res.send;
    
    res.send = function(data) {
      if (res.statusCode >= 200 && res.statusCode < 300) {
        // Log the success
        AuditLog.create({
          actorId: req.user._id,
          actorRole: req.user.role,
          actorName: req.user.name,
          action,
          entityType,
          entityId: req.params.id || null,
          ipAddress: req.ip,
          userAgent: req.get('User-Agent'),
          details: {
             body: req.body,
             path: req.originalUrl
          }
        }).catch(err => console.error('[AUDIT] Failed to log:', err));
      }
      originalSend.apply(res, arguments);
    };
    
    next();
  };
};
