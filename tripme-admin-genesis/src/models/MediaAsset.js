const mongoose = require('mongoose');

const MediaAssetSchema = new mongoose.Schema({
  filename: { type: String, required: true },
  originalName: { type: String, required: true },
  url: { type: String, required: true },
  mimeType: { type: String },
  size: { type: Number },
  linkedPlace: { type: mongoose.Schema.Types.ObjectId, ref: 'Place' },
  uploadedBy: { type: mongoose.Schema.Types.ObjectId, ref: 'AdminUser' },
  metadata: {
    width: { type: Number },
    height: { type: Number },
    alt: { type: String }
  }
}, { timestamps: true });

module.exports = mongoose.model('MediaAsset', MediaAssetSchema);
