/**
 * TripMeAI Smart ID Mappings
 * Definitive source of truth for geographical and categorical codes.
 */

const PROVINCE_MAPPINGS = {
    'Western': 'WES',
    'Central': 'CEN',
    'Southern': 'SOU',
    'North Central': 'NCP',
    'Uva': 'UVA',
    'Sabaragamuwa': 'SAB',
    'North Western': 'NWP',
    'Eastern': 'EST',
    'Northern': 'NOR'
};

const DISTRICT_MAPPINGS = {
    // Western
    'Colombo': 'COL',
    'Gampaha': 'GAM',
    'Kalutara': 'KAL',
    // Central
    'Kandy': 'KAN',
    'Matale': 'MAT',
    'Nuwara Eliya': 'NEL',
    // Southern
    'Galle': 'GAL',
    'Matara': 'MTR',
    'Hambantota': 'HAM',
    // North Central
    'Anuradhapura': 'ANU',
    'Polonnaruwa': 'POL',
    // Uva
    'Badulla': 'BAD',
    'Moneragala': 'MON',
    // Sabaragamuwa
    'Ratnapura': 'RAT',
    'Kegalle': 'KEG',
    // North Western
    'Kurunegala': 'KUR',
    'Puttalam': 'PUT',
    // Eastern
    'Ampara': 'AMP',
    'Batticaloa': 'BAT',
    'Trincomalee': 'TRI',
    // Northern
    'Jaffna': 'JAF',
    'Kilinochchi': 'KIL',
    'Mannar': 'MAN',
    'Vavuniya': 'VAV',
    'Mullaitivu': 'MUL'
};

const CATEGORY_MAPPINGS = {
    'Heritage': 'HIS',
    'Historical': 'HIS',
    'Nature': 'NAT',
    'Religious': 'REL',
    'Adventure': 'ADV',
    'Urban': 'URB',
    'General': 'GEN'
};

const SUBCATEGORY_MAPPINGS = {
    'Stupa': 'STP',
    'Temple': 'TMP',
    'Rock': 'RCK',
    'Fortress': 'FRT',
    'Palace': 'PLC',
    'Monastery': 'MON',
    'Park': 'PKR',
    'Reserve': 'PKR',
    'Beach': 'BCH',
    'Waterfall': 'WTR',
    'Lake': 'LKE',
    'Trail': 'TRL',
    'Cave': 'CAV',
    'Museum': 'MUS',
    'Bridge': 'BRG',
    'Viewpoint': 'VWT',
    'General': 'GEN'
};

// Reverse lookup for automatic province detection via district
const DISTRICT_TO_PROVINCE = {
    'COL': 'WES', 'GAM': 'WES', 'KAL': 'WES',
    'KAN': 'CEN', 'MAT': 'CEN', 'NEL': 'CEN',
    'GAL': 'SOU', 'MTR': 'SOU', 'HAM': 'SOU',
    'ANU': 'NCP', 'POL': 'NCP',
    'BAD': 'UVA', 'MON': 'UVA',
    'RAT': 'SAB', 'KEG': 'SAB',
    'KUR': 'NWP', 'PUT': 'NWP',
    'AMP': 'EST', 'BAT': 'EST', 'TRI': 'EST',
    'JAF': 'NOR', 'KIL': 'NOR', 'MAN': 'NOR', 'VAV': 'NOR', 'MUL': 'NOR'
};

module.exports = {
    PROVINCE_MAPPINGS,
    DISTRICT_MAPPINGS,
    CATEGORY_MAPPINGS,
    SUBCATEGORY_MAPPINGS,
    DISTRICT_TO_PROVINCE
};
