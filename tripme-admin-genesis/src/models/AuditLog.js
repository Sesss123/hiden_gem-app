const mongoose = require('mongoose');

const AuditLogSchema = new mongoose.Schema({
  actorId: { type: mongoose.Schema.Types.ObjectId, ref: 'AdminUser', required: true },
  actorRole: { type: String, required: true },
  actorName: { type: String, required: true },
  action: { type: String, required: true }, // e.g. "CREATE_PLACE", "APPROVE_REVIEW"
  entityType: { type: String, required: true }, // e.g. "PLACE", "PIPELINE"
  entityId: { type: mongoose.Schema.Types.ObjectId },
  details: { type: mongoose.Schema.Types.Mixed },
  ipAddress: { type: String },
  userAgent: { type: String }
}, { timestamps: true });

module.exports = mongoose.model('AuditLog', AuditLogSchema);
