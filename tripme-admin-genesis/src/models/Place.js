const mongoose = require('mongoose');
const { v4: uuidv4 } = require('uuid');

const PlaceSchema = new mongoose.Schema({
  uuid: { type: String, default: uuidv4, unique: true },
  name: { type: String, required: true },
  slug: { type: String, unique: true },
  category: { type: String, required: true },
  category_id: { type: String },
  district: { type: String, required: true },
  district_id: { type: String },
  description: { type: String },
  source: { type: String, default: 'manual' },
  status: { 
    type: String, 
    enum: ['pending', 'approved', 'rejected', 'archived'], 
    default: 'pending' 
  },
  
  // High-Fidelity Identity
  smart_id: { type: String, unique: true, sparse: true },
  smart_id_locked: { type: Boolean, default: false },
  name_code_override: { type: String, maxlength: 3 },
  name_code_reason: { type: String },
  province_code: { type: String },
  district_code: { type: String },
  category_code: { type: String },
  subcategory_code: { type: String },
  sequence_no: { type: Number },
  
  // Coordinates
  lat: { type: Number },
  lng: { type: Number },
  address: { type: String },
  
  // Operational Details
  open_hours: { type: String },
  duration_min: { type: Number, default: 60 },
  is_indoor: { type: Number, default: 0 }, // 1 = Yes, 0 = No
  
  // Financials
  ticket_price: { type: Number, default: 0 },
  ticket_range: { type: String },
  parking_fee: { type: Number, default: 0 },
  cost_min: { type: Number },
  cost_max: { type: Number },
  
  // Travel & Access
  road_type: { type: String },
  wheelchair_access: { type: Number, default: 0 },
  stairs_heavy: { type: Number, default: 0 },
  
  // Facilities
  parking_avail: { type: Number, default: 0 },
  toilets: { type: Number, default: 0 },
  food_nearby: { type: Number, default: 0 },
  mobile_signal: { type: String },
  facilities: { type: String },
  
  // Safety & Weather
  rain_sensitivity: { type: String },
  monsoon_note: { type: String },
  scam_warning: { type: String },
  special_rules: { type: String },
  safety_level: { type: String, default: 'Safe' },
  safety_note: { type: String },
  
  // Contextual Data
  crowd_level: { type: String },
  noise_level: { type: String },
  dress_code_req: { type: Number, default: 0 },
  
  // Advanced Features
  ar_supported: { type: Number, default: 0 },
  external_image_url: { type: String },
  tags: { type: String }, // Comma separated or Array
  
  // Images
  images: [{
    image_path: String,
    thumbnail_path: String,
    caption: String,
    is_cover: { type: Number, default: 0 }
  }],

  // Metadata for legacy compatibility
  score: { type: Number, default: 0 },
  vision_metadata: {
    aesthetic_score: { type: Number, default: 0 },
    is_blurry: { type: Boolean, default: false },
    lighting: { type: String, default: 'unknown' },
    match_confidence: { type: Number, default: 0 },
    visual_description: { type: String },
    is_validated: { type: Boolean, default: false }
  },
    enrichment_metadata: {
      google_place_id: String,
      google_rating: Number,
      google_user_ratings_total: Number,
      google_maps_url: String,
      google_phone: String,
      google_website: String,
      opening_hours: [String],
      wiki_summary: String,
      nearby_facilities: [{
        name: String,
        type: String,
        lat: Number,
        lng: Number,
        distance: Number
      }],
      last_enriched_at: Date,
      social_signals: {
        popularity_index: { type: Number, default: 0 },
        is_trending: { type: Boolean, default: false },
        top_platform: String,
        social_mentions: String,
        last_monitored: Date
      }
    },
  is_defective: { type: Boolean, default: false },
  reviewReason: { type: String },
  reviewerNotes: { type: String },
  createdBy: { type: mongoose.Schema.Types.ObjectId, ref: 'AdminUser' },
  reviewedBy: { type: mongoose.Schema.Types.ObjectId, ref: 'AdminUser' }
}, { timestamps: true });

// Pre-save hook to handle Smart ID and slugs
PlaceSchema.pre('save', async function(next) {
  // 1. Generate Slug
  if (this.name && (!this.slug || this.isModified('name'))) {
    this.slug = this.name.toLowerCase().replace(/[^\w ]+/g, '').replace(/ +/g, '-');
  }
  
  // 2. Generate UUID
  if (!this.uuid) {
      this.uuid = uuidv4();
  }

  // 3. Generate Smart ID (Only if not locked and not already set)
  if (!this.smart_id && !this.smart_id_locked) {
      try {
          const { generateSmartId } = require('../utils/smart_id_generator');
          const result = await generateSmartId(this);
          
          this.smart_id = result.smart_id;
          this.province_code = result.metadata.province_code;
          this.district_code = result.metadata.district_code;
          this.category_code = result.metadata.category_code;
          this.subcategory_code = result.metadata.subcategory_code;
          this.name_code = result.metadata.name_code;
          this.sequence_no = result.metadata.sequence_no;
          this.smart_id_locked = true; // Lock after generation
      } catch (err) {
          console.error('Smart ID Generation Failed:', err);
      }
  }

  next();
});

module.exports = mongoose.model('Place', PlaceSchema);

