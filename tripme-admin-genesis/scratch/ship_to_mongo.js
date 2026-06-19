const mongoose = require('mongoose');
const fs = require('fs');
const path = require('path');
require('dotenv').config({ path: path.join(__dirname, '../.env') });

const Place = require('../src/models/Place');
const AuditLog = require('../src/models/AuditLog');
const AdminUser = require('../src/models/AdminUser');

async function syncData() {
    try {
        console.log('--- Genesis Data Sync: JSON to MongoDB ---');
        
        // 1. Connect to MongoDB
        const mongoUri = process.env.MONGODB_URI || 'mongodb://localhost:27017/tripme_genesis';
        await mongoose.connect(mongoUri);
        console.log('✅ Connected to MongoDB');

        // 2. Find a valid Admin for Audit Logs
        const admin = await AdminUser.findOne({ isActive: true });
        if (!admin) {
            console.error('❌ No active admin user found for audit log attribution.');
            process.exit(1);
        }
        console.log(`👤 Using Admin: ${admin.name} (${admin.role}) for audit trail.`);

        // 3. Read Ingested Data
        const dataPath = path.join(__dirname, '../../backend/data/historical_ingest_partial.json');
        if (!fs.existsSync(dataPath)) {
            console.error('❌ Data file not found at:', dataPath);
            process.exit(1);
        }
        
        const rawData = fs.readFileSync(dataPath, 'utf8');
        const places = JSON.parse(rawData);
        console.log(`📦 Found ${places.length} places to sync.`);

        let syncedCount = 0;
        let skippedCount = 0;

        for (const placeData of places) {
            // Check if exists by name
            const existing = await Place.findOne({ name: placeData.name });
            
            if (existing) {
                console.log(`⏭️  Skipping existing place: ${placeData.name}`);
                skippedCount++;
                continue;
            }

            // Create new Place
            const newPlace = new Place({
                ...placeData,
                source: 'ai_harvest',
                status: 'pending' // Force to pending for dashboard review
            });

            // Handle nested objects if they are flat in JSON
            if (placeData.logistics) newPlace.road_type = placeData.logistics.road_type;
            if (placeData.logistics) newPlace.mobile_signal = placeData.logistics.mobile_signal;
            if (placeData.logistics) newPlace.open_hours = placeData.logistics.open_hours;
            if (placeData.logistics) newPlace.address = placeData.logistics.address;
            
            if (placeData.climate_safety) {
                newPlace.safety_level = placeData.climate_safety.safety_level;
                newPlace.safety_note = placeData.climate_safety.safety_note;
                newPlace.rain_sensitivity = placeData.climate_safety.rain_sensitivity;
                newPlace.monsoon_note = placeData.climate_safety.monsoon_note;
                newPlace.scam_warning = placeData.climate_safety.scam_warning;
            }

            if (placeData.financials) {
                newPlace.ticket_price = placeData.financials.ticket_price;
                newPlace.ticket_range = placeData.financials.ticket_range;
            }

            await newPlace.save();
            
            // Create Audit Log
            await AuditLog.create({
                actorId: admin._id,
                actorRole: admin.role,
                actorName: 'Genesis AI System',
                action: 'AI_HARVEST',
                entityType: 'PLACE',
                entityId: newPlace._id,
                details: `Successfully harvested from ${placeData.data_source}`,
                actorName: 'Genesis AI'
            });

            console.log(`✅ Synced: ${placeData.name}`);
            syncedCount++;
        }

        console.log('\n--- Sync Complete ---');
        console.log(`Total: ${places.length} | Synced: ${syncedCount} | Skipped: ${skippedCount}`);
        
        mongoose.connection.close();
    } catch (err) {
        console.error('❌ Sync Error:', err);
        process.exit(1);
    }
}

syncData();
