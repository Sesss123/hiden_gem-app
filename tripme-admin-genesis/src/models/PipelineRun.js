const mongoose = require('mongoose');

const PipelineRunSchema = new mongoose.Schema({
  startedAt: { type: Date, default: Date.now },
  endedAt: { type: Date },
  status: { 
    type: String, 
    enum: ['running', 'completed', 'failed', 'interrupted'], 
    default: 'running' 
  },
  sourceList: [String],
  pagesScraped: { type: Number, default: 0 },
  recordsExtracted: { type: Number, default: 0 },
  autoApprovedCount: { type: Number, default: 0 },
  pendingCount: { type: Number, default: 0 },
  rejectedCount: { type: Number, default: 0 },
  logs: [{
    timestamp: { type: Date, default: Date.now },
    level: { type: String, enum: ['info', 'warn', 'error'], default: 'info' },
    message: { type: String }
  }],
  triggeredBy: { type: mongoose.Schema.Types.ObjectId, ref: 'AdminUser' }
}, { timestamps: true });

module.exports = mongoose.model('PipelineRun', PipelineRunSchema);
