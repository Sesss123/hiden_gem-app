const mongoose = require('mongoose');
const Place = require('./src/models/Place');
const Counter = require('./src/models/Counter');
require('dotenv').config();

async function runTest() {
  try {
    await mongoose.connect('mongodb://localhost:27017/tripme_genesis');
    console.log("--- Connected to MongoDB ---");

    // Test 1: Standard Generation
    console.log("Running Test 1: Standard Smart ID Generation (Sigiriya)...");
    const testPlace1 = new Place({
      name: 'Sigiriya Rock Verification Test',
      district: 'Matale',
      category: 'Historical',
      tags: 'Rock, Fortress, Heritage',
      description: 'A test entry for Smart ID verification.',
      status: 'pending',
      source: 'Test Script'
    });

    const saved1 = await testPlace1.save();
    console.log(`✅ Generated Smart ID: ${saved1.smart_id}`);
    console.log(`Metadata:`, saved1.metadata);

    // Test 2: Override Smart ID
    console.log("\nRunning Test 2: Manual Override Name Code (Temple of the Tooth)...");
    const testPlace2 = new Place({
      name: 'Temple of the Sacred Tooth Relic Test',
      district: 'Kandy',
      category: 'Religious',
      tags: 'Temple',
      name_code_override: 'DAL',
      name_code_reason: 'Testing override flow with familiar code.',
      description: 'A test entry with override.',
      status: 'pending',
      source: 'Test Script'
    });
    
    const saved2 = await testPlace2.save();
    console.log(`✅ Generated Smart ID: ${saved2.smart_id}`);
    console.log(`Metadata:`, saved2.metadata);

    // View Counter State
    console.log("\n--- Active Counters ---");
    const counters = await Counter.find();
    counters.forEach(c => console.log(`Counter ID: ${c.id} | Last Sequence: ${c.last_sequence}`));

    // Cleanup
    console.log("\nCleaning up test records...");
    await Place.deleteMany({ source: 'Test Script' });
    console.log("✅ Cleanup complete.");

  } catch (err) {
    console.error("Test Failed:", err);
  } finally {
    await mongoose.disconnect();
    console.log("--- Disconnected ---");
  }
}

runTest();
