const MediaAsset = require('../models/MediaAsset');
const path = require('path');
const fs = require('fs');

exports.getMedia = async (req, res, next) => {
  try {
    const assets = await MediaAsset.find().sort({ createdAt: -1 });
    res.render('media/index', { assets, title: 'Media Management' });
  } catch (err) {
    next(err);
  }
};

exports.uploadMedia = async (req, res, next) => {
  try {
    if (!req.file) return res.redirect('/media');

    const asset = await MediaAsset.create({
      filename: req.file.filename,
      originalName: req.file.originalname,
      url: `/uploads/${req.file.filename}`,
      mimeType: req.file.mimetype,
      size: req.file.size,
      uploadedBy: req.user._id
    });

    res.redirect('/media');
  } catch (err) {
    next(err);
  }
};

exports.deleteMedia = async (req, res, next) => {
  try {
    const asset = await MediaAsset.findById(req.params.id);
    if (asset) {
      const filePath = path.join(__dirname, '../../public', asset.url);
      if (fs.existsSync(filePath)) fs.unlinkSync(filePath);
      await asset.deleteOne();
    }
    res.redirect('/media');
  } catch (err) {
    next(err);
  }
};

exports.getVisionLab = async (req, res, next) => {
  try {
    res.render('media/vision-lab', { 
      title: 'Neural Vision Lab', 
      path: '/media/vision-lab',
      activePage: 'vision-lab'
    });
  } catch (err) {
    next(err);
  }
};
