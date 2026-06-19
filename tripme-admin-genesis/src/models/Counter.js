const mongoose = require('mongoose');

const CounterSchema = new mongoose.Schema({
    id: { 
        type: String, 
        required: true, 
        unique: true 
    }, // Format: {province_code}-{district_code}
    last_sequence: { 
        type: Number, 
        default: 0 
    }
}, { timestamps: true });

module.exports = mongoose.model('Counter', CounterSchema);
