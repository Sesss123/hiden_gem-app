const Place = require('../models/Place');
const AuditLog = require('../models/AuditLog');

exports.getReviewQueue = async (req, res, next) => {
  try {
    const pending = await Place.find({ status: 'pending' })
      .sort({ createdAt: 1 });
      
    res.render('reviews/index', {
      places: pending,
      title: 'Review Workflow'
    });
  } catch (err) {
    next(err);
  }
};

exports.approvePlace = async (req, res, next) => {
  try {
    await Place.findByIdAndUpdate(req.params.id, {
      status: 'approved',
      reviewedBy: req.user._id,
      reviewerNotes: req.body.notes
    });
    res.redirect('/reviews');
  } catch (err) {
    next(err);
  }
};

exports.rejectPlace = async (req, res, next) => {
  try {
    await Place.findByIdAndUpdate(req.params.id, {
      status: 'rejected',
      reviewedBy: req.user._id,
      reviewReason: req.body.reason,
      reviewerNotes: req.body.notes
    });
    res.redirect('/reviews');
  } catch (err) {
    next(err);
  }
};
