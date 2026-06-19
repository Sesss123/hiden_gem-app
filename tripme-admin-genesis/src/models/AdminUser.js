const mongoose = require('mongoose');
const bcrypt = require('bcrypt');

const AdminUserSchema = new mongoose.Schema({
  name: { type: String, required: true },
  email: { type: String, required: true, unique: true },
  passwordHash: { type: String, required: true },
  role: { 
    type: String, 
    enum: ['super_admin', 'admin', 'reviewer'], 
    default: 'reviewer' 
  },
  isActive: { type: Boolean, default: true },
  lastLogin: { type: Date },
  avatar: { type: String }
}, { timestamps: true });

AdminUserSchema.methods.comparePassword = async function(password) {
  return await bcrypt.compare(password, this.passwordHash);
};

module.exports = mongoose.model('AdminUser', AdminUserSchema);
