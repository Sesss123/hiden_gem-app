const LocalStrategy = require('passport-local').Strategy;
const AdminUser = require('../models/AdminUser');

module.exports = function(passport) {
  passport.use(new LocalStrategy({ usernameField: 'email' }, async (email, password, done) => {
    try {
      const user = await AdminUser.findOne({ email });
      if (!user) return done(null, false, { message: 'Invalid email or password.' });

      const isMatch = await user.comparePassword(password);
      if (!isMatch) return done(null, false, { message: 'Invalid email or password.' });

      if (!user.isActive) return done(null, false, { message: 'Account is disabled.' });

      return done(null, user);
    } catch (err) {
      return done(err);
    }
  }));

  passport.serializeUser((user, done) => {
    done(null, user.id);
  });

  passport.deserializeUser(async (id, done) => {
    try {
      const user = await AdminUser.findById(id);
      done(null, user);
    } catch (err) {
      done(err);
    }
  });
};
