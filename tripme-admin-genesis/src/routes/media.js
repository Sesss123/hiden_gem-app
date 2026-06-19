const express = require('express');
const router = express.Router();
const multer = require('multer');
const path = require('path');
const mediaController = require('../controllers/MediaController');
const { ensureAuthenticated } = require('../middlewares/auth');

// Multer Storage Config
const storage = multer.diskStorage({
  destination: (req, file, cb) => {
    cb(null, './public/uploads/');
  },
  filename: (req, file, cb) => {
    cb(null, `tripme-${Date.now()}${path.extname(file.originalname)}`);
  }
});

const upload = multer({ storage });

router.use(ensureAuthenticated);

router.get('/', mediaController.getMedia);
router.get('/vision-lab', mediaController.getVisionLab);
router.post('/upload', upload.single('media'), mediaController.uploadMedia);
router.post('/:id/delete', mediaController.deleteMedia);

module.exports = router;
