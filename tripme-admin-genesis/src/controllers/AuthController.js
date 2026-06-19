const passport = require('passport');
const AdminUser = require('../models/AdminUser');

exports.getLogin = (req, res) => {
  if (req.isAuthenticated()) return res.redirect('/');
  res.render('auth/login', { layout: false, error: null });
};

exports.postLogin = (req, res, next) => {
  passport.authenticate('local', (err, user, info) => {
    if (err) return next(err);
    if (!user) {
      return res.render('auth/login', { layout: false, error: info.message });
    }
    req.logIn(user, async (err) => {
      if (err) return next(err);
      
      // Update last login
      user.lastLogin = new Date();
      await user.save();
      
      const redirectTo = req.session.returnTo || '/';
      delete req.session.returnTo;
      res.redirect(redirectTo);
    });
  })(req, res, next);
};

exports.logout = (req, res, next) => {
  req.logout((err) => {
    if (err) return next(err);
    res.redirect('/auth/login');
  });
};
