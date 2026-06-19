require('dotenv').config();
const mongoose = require('mongoose');
const bcrypt = require('bcrypt');
const AdminUser = require('../models/AdminUser');
const Place = require('../models/Place');
const AuditLog = require('../models/AuditLog');
const PipelineRun = require('../models/PipelineRun');

const seedData = async () => {
  try {
    await mongoose.connect(process.env.MONGODB_URI || 'mongodb://localhost:27017/tripme_genesis');
    console.log('[SEED] Connected to MongoDB');

    // Clear existing
    await AdminUser.deleteMany({});
    await Place.deleteMany({});
    await AuditLog.deleteMany({});
    await PipelineRun.deleteMany({});

    // 1. Create Admins
    const salt = await bcrypt.genSalt(10);
    const passwordHash = await bcrypt.hash('admin123', salt);

    const superAdmin = await AdminUser.create({
      name: 'Chief Operations Officer',
      email: 'admin@tripme.ai',
      passwordHash,
      role: 'super_admin'
    });

    const reviewer = await AdminUser.create({
      name: 'Data Reviewer 01',
      email: 'reviewer@tripme.ai',
      passwordHash,
      role: 'reviewer'
    });

    console.log('[SEED] Admin users created');

    // 2. Create Places
    const places = [
      {
        name: 'Sigiriya Rock Fortress',
        category: 'Heritage',
        district: 'Matale',
        description: 'An ancient rock fortress located in the northern Matale District near the town of Dambulla in the Central Province, Sri Lanka.',
        status: 'approved',
        score: 98,
        lat: 7.957,
        lng: 80.759,
        ticket_price: 5500,
        ticket_range: '30-50 USD (Foreigners)',
        parking_fee: 500,
        road_type: 'B-Grade (Paved)',
        mobile_signal: 'High (4G/LTE)',
        parking_avail: 1,
        toilets: 1,
        food_nearby: 1,
        is_indoor: 0,
        safety_level: 'High (Secure Archaeological Site)',
        rain_sensitivity: 'Heavy (Slippery Steps)',
        external_image_url: 'https://images.unsplash.com/photo-1588665555327-a67c73b3cc23?auto=format&fit=crop&q=80&w=800'
      },
      {
        name: 'Yala National Park',
        category: 'Nature',
        district: 'Hambantota',
        description: 'The second largest national park in Sri Lanka, boasting the highest density of leopards in the world.',
        status: 'approved',
        score: 95,
        lat: 6.368,
        lng: 81.440,
        ticket_price: 4500,
        ticket_range: 'LKR 4000 - 8000',
        parking_fee: 0,
        road_type: 'Off-road (Dirt)',
        mobile_signal: 'Low (Critical Spots Only)',
        parking_avail: 1,
        toilets: 1,
        food_nearby: 0,
        is_indoor: 0,
        safety_level: 'Moderate (Wild Animal Risks)',
        rain_sensitivity: 'Critical (Flooding Trails)',
        external_image_url: 'https://images.unsplash.com/photo-1549366021-9f761d450615?auto=format&fit=crop&q=80&w=800'
      },
      {
        name: 'Galle Dutch Fort',
        category: 'Heritage',
        district: 'Galle',
        description: 'A historical, archaeological and architectural heritage monument, maintaining a polished appearance after 400+ years.',
        status: 'pending',
        score: 88,
        lat: 6.033,
        lng: 80.214,
        ticket_price: 0,
        ticket_range: 'Free Access',
        parking_fee: 200,
        road_type: 'Urban (Cobblestone)',
        mobile_signal: 'Excellent (5G Support)',
        parking_avail: 1,
        toilets: 1,
        food_nearby: 1,
        is_indoor: 0,
        safety_level: 'High (Tourist Police Present)',
        rain_sensitivity: 'Low (Good Drainage)',
        external_image_url: 'https://images.unsplash.com/photo-1627993414925-5853229b4009?auto=format&fit=crop&q=80&w=800'
      }
    ];

    await Place.create(places.map(p => ({ ...p, createdBy: superAdmin._id })));
    console.log('[SEED] Places created');

    // 3. Create a Pipeline Run
    await PipelineRun.create({
      status: 'completed',
      sourceList: ['Google Maps', 'TripAdvisor'],
      pagesScraped: 45,
      recordsExtracted: 12,
      autoApprovedCount: 8,
      pendingCount: 4,
      triggeredBy: superAdmin._id,
      logs: [
        { message: 'Source detected: TripAdvisor', level: 'info' },
        { message: 'Extraction started for Kandy region', level: 'info' },
        { message: 'AI Content generation in progress', level: 'info' },
        { message: 'Successful extraction of 12 nodes', level: 'info' }
      ]
    });

    // 4. Create initial Audit logs
    await AuditLog.create({
      actorId: superAdmin._id,
      actorName: superAdmin.name,
      actorRole: superAdmin.role,
      action: 'SYSTEM_BOOT',
      entityType: 'CORE',
      details: { version: '2.0.0-genesis' }
    });

    console.log('[SEED] Seeding completed successfully');
    process.exit(0);
  } catch (err) {
    console.error('[SEED] Error:', err);
    process.exit(1);
  }
};

seedData();
