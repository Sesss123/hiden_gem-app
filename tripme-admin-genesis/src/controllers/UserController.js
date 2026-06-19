const AdminUser = require('../models/AdminUser');

exports.getUsers = async (req, res, next) => {
  try {
    const users = await AdminUser.find().sort({ createdAt: -1 });
    res.render('users/index', { users, title: 'Identity Management' });
  } catch (err) {
    next(err);
  }
};

exports.toggleStatus = async (req, res, next) => {
  try {
    const user = await AdminUser.findById(req.params.id);
    user.isActive = !user.isActive;
    await user.save();
    res.redirect('/users');
  } catch (err) {
    next(err);
  }
};

exports.updateRole = async (req, res, next) => {
  try {
    await AdminUser.findByIdAndUpdate(req.params.id, { role: req.body.role });
    res.redirect('/users');
  } catch (err) {
    next(err);
  }
};
