const mongoose = require('mongoose');
const Place = require('./src/models/Place');
const Counter = require('./src/models/Counter');
const { generateSmartId } = require('./src/utils/smart_id_generator');

async function migrate() {
    try {
        await mongoose.connect('mongodb://localhost:27017/tripme_genesis');
        console.log('Connected to MongoDB');

        const places = await Place.find({ 
            $or: [
                { smart_id: { $exists: false } },
                { smart_id: null },
                { smart_id: '' }
            ]
        });
        console.log(`Found ${places.length} places to migrate.`);

        for (const place of places) {
            console.log(`Generating ID for: ${place.name}`);
            const result = await generateSmartId(place);
            
            place.smart_id = result.smart_id;
            place.province_code = result.metadata.province_code;
            place.district_code = result.metadata.district_code;
            place.category_code = result.metadata.category_code;
            place.subcategory_code = result.metadata.subcategory_code;
            place.name_code = result.metadata.name_code;
            place.sequence_no = result.metadata.sequence_no;
            place.smart_id_locked = true;

            await place.save();
            console.log(`Success: ${place.name} -> ${place.smart_id}`);
        }

        console.log('Migration Complete.');
        process.exit(0);
    } catch (err) {
        console.error('Migration Failed:', err);
        process.exit(1);
    }
}

migrate();
