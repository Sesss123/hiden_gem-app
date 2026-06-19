const Counter = require('../models/Counter');
const { 
    PROVINCE_MAPPINGS, 
    DISTRICT_MAPPINGS, 
    CATEGORY_MAPPINGS, 
    SUBCATEGORY_MAPPINGS,
    DISTRICT_TO_PROVINCE 
} = require('./code_mappings');

/**
 * Normalizes a name and extracts a 3-letter code.
 * Example: "Ruwanwelisaya" -> "RUW"
 */
function extractNameCode(name) {
    if (!name) return 'GEN';
    
    // Normalize: Uppercase, remove anything not A-Z
    const normalized = name.toUpperCase()
        .replace(/[^A-Z]/g, '');
    
    // Fallback for purely non-English (e.g. Sinhala) names
    if (normalized.length === 0) return 'GEN';
    
    let code = normalized.substring(0, 3);
    
    // Pad very short names with 'X' (e.g., "O" -> "OXX")
    while (code.length < 3) {
        code += 'X';
    }
    
    return code;
}

/**
 * Generates a Smart ID based on the provided place data.
 * Format: SL-{PROV}-{DIST}-{CAT}-{SUB}-{NAME3}-{SEQ}
 */
async function generateSmartId(placeData, options = {}) {
    const { 
        name, 
        district, 
        category, 
        tags, 
        name_code_override 
    } = placeData;

    // 1. Get Codes
    const distCode = DISTRICT_MAPPINGS[district] || 'XXX';
    const provCode = DISTRICT_TO_PROVINCE[distCode] || 'XXX';
    const catCode = CATEGORY_MAPPINGS[category] || 'GEN';
    
    // 2. Determine Subcategory (Logic: Check tags against mappings)
    let subCode = 'GEN';
    if (tags) {
        const tagList = Array.isArray(tags) ? tags : tags.split(',').map(t => t.trim());
        for (const tag of tagList) {
            if (SUBCATEGORY_MAPPINGS[tag]) {
                subCode = SUBCATEGORY_MAPPINGS[tag];
                break;
            }
        }
    }

    // 3. Name Code
    const nameCode = name_code_override && name_code_override.length === 3 
        ? name_code_override.toUpperCase() 
        : extractNameCode(name);

    // 4. Get Sequence (Always Increment, Never Reuse)
    const counterId = `${provCode}-${distCode}`;
    const counter = await Counter.findOneAndUpdate(
        { id: counterId },
        { $inc: { last_sequence: 1 } },
        { upsert: true, new: true }
    );
    const seq = counter.last_sequence.toString().padStart(4, '0');

    // 5. Construct Final ID
    const smartId = `SL-${provCode}-${distCode}-${catCode}-${subCode}-${nameCode}-${seq}`;

    return {
        smart_id: smartId,
        metadata: {
            province_code: provCode,
            district_code: distCode,
            category_code: catCode,
            subcategory_code: subCode,
            name_code: nameCode,
            sequence_no: counter.last_sequence
        }
    };
}

module.exports = {
    generateSmartId,
    extractNameCode
};
