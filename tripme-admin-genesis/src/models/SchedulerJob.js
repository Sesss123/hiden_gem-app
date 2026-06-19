const mongoose = require('mongoose');

const SchedulerJobSchema = new mongoose.Schema({
  name: { type: String, required: true, unique: true },
  cronExpression: { type: String, required: true },
  isEnabled: { type: Boolean, default: true },
  lastRunAt: { type: Date },
  lastStatus: { type: String, enum: ['success', 'error'] },
  nextRunAt: { type: Date },
  description: { type: String },
  jobType: { type: String, enum: ['SCRAPER', 'AI_EXTRACTOR', 'DB_CLEANUP'], required: true }
}, { timestamps: true });

module.exports = mongoose.model('SchedulerJob', SchedulerJobSchema);
