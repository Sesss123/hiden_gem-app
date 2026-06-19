const Place = require('../models/Place');
const AuditLog = require('../models/AuditLog');

exports.getPlaces = async (req, res, next) => {
  try {
    const page = parseInt(req.query.page) || 1;
    const limit = 10;
    const skip = (page - 1) * limit;

    // Filters
    const query = {};
    if (req.query.status && req.query.status !== 'all') query.status = req.query.status;
    if (req.query.category && req.query.category !== 'all') {
      query.$or = [
        { category: req.query.category },
        { category_id: req.query.category }
      ];
    }
    if (req.query.district && req.query.district !== 'all') {
      query.$or = [
        { district: req.query.district },
        { district_id: req.query.district }
      ];
    }
    if (req.query.search) {
      const searchRegex = { $regex: req.query.search, $options: 'i' };
      query.$or = [
        { name: searchRegex },
        { smart_id: searchRegex }
      ];
    }

    const total = await Place.countDocuments(query);
    const places = await Place.find(query)
      .sort({ createdAt: -1 })
      .skip(skip)
      .limit(limit);

    res.render('places/index', {
      places,
      total,
      page,
      pages: Math.ceil(total / limit),
      filters: req.query,
      title: 'Places Registry'
    });
  } catch (err) {
    next(err);
  }
};

exports.getCreate = (req, res) => {
  res.render('places/form', { place: {}, isEdit: false, title: 'Add New Place' });
};

exports.postCreate = async (req, res, next) => {
  try {
    const placeData = {
      ...req.body,
      createdBy: req.user._id,
      // Ensure specific types
      duration_min: parseInt(req.body.duration_min) || 60,
      ticket_price: parseFloat(req.body.ticket_price) || 0,
      parking_fee: parseFloat(req.body.parking_fee) || 0,
      cost_min: parseFloat(req.body.cost_min) || 0,
      cost_max: parseFloat(req.body.cost_max) || 0,
      is_indoor: req.body.is_indoor === 'on' || req.body.is_indoor === '1' ? 1 : 0,
      wheelchair_access: req.body.wheelchair_access === 'on' || req.body.wheelchair_access === '1' ? 1 : 0,
      stairs_heavy: req.body.stairs_heavy === 'on' || req.body.stairs_heavy === '1' ? 1 : 0,
      parking_avail: req.body.parking_avail === 'on' || req.body.parking_avail === '1' ? 1 : 0,
      toilets: req.body.toilets === 'on' || req.body.toilets === '1' ? 1 : 0,
      food_nearby: req.body.food_nearby === 'on' || req.body.food_nearby === '1' ? 1 : 0,
      dress_code_req: req.body.dress_code_req === 'on' || req.body.dress_code_req === '1' ? 1 : 0,
      ar_supported: req.body.ar_supported === 'on' || req.body.ar_supported === '1' ? 1 : 0,
      // Identity Overrides
      name_code_override: req.body.name_code_override ? req.body.name_code_override.toUpperCase().substring(0, 3) : undefined,
      name_code_reason: req.body.name_code_reason,
    };
    const place = await Place.create(placeData);
    req.flash('success', 'Place created successfully and pending review.');
    res.redirect(`/places/${place._id}`);
  } catch (err) {
    next(err);
  }
};

exports.getPlace = async (req, res, next) => {
  try {
    const place = await Place.findById(req.params.id)
      .populate('createdBy', 'name')
      .populate('reviewedBy', 'name');
    if (!place) return res.status(404).render('error', { message: 'Place not found' });
    
    res.render('places/details', { place, title: place.name });
  } catch (err) {
    next(err);
  }
};

exports.getEdit = async (req, res, next) => {
  try {
    const place = await Place.findById(req.params.id);
    if (!place) return res.status(404).render('error', { message: 'Place not found' });
    res.render('places/form', { place, isEdit: true, title: `Edit ${place.name}` });
  } catch (err) {
    next(err);
  }
};

exports.postUpdate = async (req, res, next) => {
  try {
    const oldPlace = await Place.findById(req.params.id);
    if (!oldPlace) return res.status(404).render('error', { message: 'Place not found' });

    const updateData = {
      ...req.body,
      duration_min: parseInt(req.body.duration_min) || 60,
      ticket_price: parseFloat(req.body.ticket_price) || 0,
      parking_fee: parseFloat(req.body.parking_fee) || 0,
      cost_min: parseFloat(req.body.cost_min) || 0,
      cost_max: parseFloat(req.body.cost_max) || 0,
      is_indoor: req.body.is_indoor === 'on' || req.body.is_indoor === '1' ? 1 : 0,
      wheelchair_access: req.body.wheelchair_access === 'on' || req.body.wheelchair_access === '1' ? 1 : 0,
      stairs_heavy: req.body.stairs_heavy === 'on' || req.body.stairs_heavy === '1' ? 1 : 0,
      parking_avail: req.body.parking_avail === 'on' || req.body.parking_avail === '1' ? 1 : 0,
      toilets: req.body.toilets === 'on' || req.body.toilets === '1' ? 1 : 0,
      food_nearby: req.body.food_nearby === 'on' || req.body.food_nearby === '1' ? 1 : 0,
      dress_code_req: req.body.dress_code_req === 'on' || req.body.dress_code_req === '1' ? 1 : 0,
      ar_supported: req.body.ar_supported === 'on' || req.body.ar_supported === '1' ? 1 : 0,
      name_code_override: req.body.name_code_override ? req.body.name_code_override.toUpperCase().substring(0, 3) : undefined,
    };
    
    // Calculate Diff
    const changes = {};
    for (const key in updateData) {
      if (updateData[key] !== undefined && String(oldPlace[key]) !== String(updateData[key])) {
        changes[key] = { old: oldPlace[key], new: updateData[key] };
      }
    }

    const place = await Place.findByIdAndUpdate(req.params.id, updateData, { new: true });

    // Create Audit Log with Diff
    await AuditLog.create({
      actorId: req.user._id,
      actorRole: req.user.role,
      actorName: req.user.name,
      action: 'UPDATE_PLACE',
      entityType: 'PLACE',
      entityId: place._id,
      details: { changes }
    });

    req.flash('success', 'Place updated successfully with audit trail.');
    res.redirect(`/places/${place._id}`);
  } catch (err) {
    next(err);
  }
};

exports.approvePlace = async (req, res, next) => {
  try {
    const oldPlace = await Place.findById(req.params.id);
    const place = await Place.findByIdAndUpdate(req.params.id, {
      status: 'approved',
      reviewedBy: req.user._id,
      reviewerNotes: req.body.notes || 'Approved via dashboard'
    }, { new: true });
    
    await AuditLog.create({
      actorId: req.user._id,
      actorRole: req.user.role,
      actorName: req.user.name,
      action: 'APPROVE_PLACE',
      entityType: 'PLACE',
      entityId: place._id,
      details: { 
        status_change: { old: oldPlace.status, new: 'approved' },
        notes: req.body.notes 
      }
    });

    req.flash('success', `${place.name} has been approved and is now live.`);
    res.redirect(`/places/${place._id}`);
  } catch (err) {
    next(err);
  }
};

exports.deletePlace = async (req, res, next) => {
  try {
    await Place.findByIdAndDelete(req.params.id);
    req.flash('success', 'Place deleted successfully.');
    res.redirect('/places');
  } catch (err) {
    next(err);
  }
};

exports.bulkAction = async (req, res, next) => {
  try {
    const { action, ids } = req.body;
    if (!ids || !ids.length) {
      return res.status(400).json({ success: false, message: 'No items selected.' });
    }

    const pythonUrl = process.env.PYTHON_BACKEND_URL || 'http://localhost:8000';
    const internalKey = process.env.INTERNAL_API_KEY;

    const response = await axios.post(`${pythonUrl}/api/admin/bulk-action`, {
      action,
      place_ids: ids
    }, {
      headers: { 'X-Admin-Internal-Key': internalKey }
    });

    res.json(response.data);
  } catch (err) {
    console.error('[GENESIS] Bulk Action Failed:', err.message);
    res.status(err.response?.status || 500).json({ 
      success: false, 
      message: err.response?.data?.detail || 'Failed to execute bulk action in backend.'
    });
  }
};

