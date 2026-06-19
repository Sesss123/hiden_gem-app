import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import 'package:google_fonts/google_fonts.dart';


/// Inline KB data for completely offline use.
/// Mirrors the top-level structure from backend/kb_data.py.
/// No network required — rendered directly from this map.
const Map<String, Map<String, dynamic>> _kbOffline = {
  'ella': {
    'must_see': ['Nine Arch Bridge', 'Little Adam\'s Peak', 'Ella Rock', 'Ravana Falls'],
    'indoor': ['Chill Cafe', 'Ella Spice Garden cooking class'],
    'safety': 'Leeches on hiking trails after rain. Wear leech socks.',
    'emoji': '🏔️',
  },
  'sigiriya': {
    'must_see': ['Sigiriya Rock Fortress', 'Pidurangala Rock', 'Minneriya Safari'],
    'indoor': ['Sigiriya Museum', 'Village tour'],
    'safety': 'Wasps near the fortress. Move slowly if disturbed.',
    'emoji': '🗿',
  },
  'kandy': {
    'must_see': ['Temple of the Tooth', 'Peradeniya Botanical Gardens', 'Udawatta Kele Sanctuary'],
    'indoor': ['Kandyan Arts Museum', 'Cultural Dance Show'],
    'safety': 'Traffic is heavy. Use tuk tuk for short hops.',
    'emoji': '🏛️',
  },
  'galle': {
    'must_see': ['Galle Fort', 'Stilt fishermen', 'Unawatuna Beach'],
    'indoor': ['Galle Maritime Museum', 'Dutch Reformed Church'],
    'safety': 'Ocean currents strong south of fort. Swim at Unawatuna only.',
    'emoji': '⚓',
  },
  'mirissa': {
    'must_see': ['Mirissa Beach', 'Whale watching boat tour', 'Parrot Rock'],
    'indoor': ['Beach-side restaurants', 'Coconut Tree Hill viewpoint'],
    'safety': 'Whale watching boats run Nov–Apr. Book in advance.',
    'emoji': '🐋',
  },
  'nuwara eliya': {
    'must_see': ['Victoria Park', 'Tea factory tour', 'Gregory Lake'],
    'indoor': ['Tea factory museums', 'Pedro Tea Estate', 'Post Office'],
    'safety': 'Cold year-round. Bring a jacket. Altitude sickness rare but watch for it.',
    'emoji': '🍵',
  },
  'colombo': {
    'must_see': ['Galle Face Green', 'Pettah Market', 'Gangaramaya Temple'],
    'indoor': ['National Museum', 'Arcade Independence Square'],
    'safety': 'Standard city care. Use metered taxis or PickMe app.',
    'emoji': '🌆',
  },
  'bentota': {
    'must_see': ['Bentota Beach', 'Madhu River Safari', 'Brief Garden'],
    'indoor': ['Ayurvedic spa', 'Lunuganga tour'],
    'safety': 'Avoid unauthorised guides on the beach.',
    'emoji': '🏖️',
  },
  'hikkaduwa': {
    'must_see': ['Coral Sanctuary', 'Turtle Hatchery', 'Hikkaduwa Lake'],
    'indoor': ['Tsunami Photo Museum', 'Jewellery shops'],
    'safety': 'Touching coral is illegal. Strong currents in some areas.',
    'emoji': '🐢',
  },
  'yala': {
    'must_see': ['Yala National Park Safari', 'Sithulpawwa Rock Temple'],
    'indoor': ['Visitor Centre'],
    'safety': 'Never exit the jeep on safari. Leopard country.',
    'emoji': '🐆',
  },
};

class OfflineHighlightsWidget extends StatelessWidget {
  final String destination;
  const OfflineHighlightsWidget({super.key, required this.destination});

  @override
  Widget build(BuildContext context) {
    final key = destination.toLowerCase().trim();
    final data = _kbOffline[key];
    if (data == null) return const SizedBox.shrink();

    final mustSee = (data['must_see'] as List).cast<String>();
    final indoor = (data['indoor'] as List).cast<String>();
    final safety = data['safety'] as String;
    final emoji = data['emoji'] as String;

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      decoration: AppTheme.glassDecoration(
        context,
        opacity: isDark ? 0.05 : 0.08,
        color: isDark ? null : Colors.orange.shade50,
      ),
      child: Theme(
        data: Theme.of(context).copyWith(
          dividerColor: Colors.transparent,
          splashColor: Colors.transparent,
          highlightColor: Colors.transparent,
        ),
        child: ExpansionTile(
          initiallyExpanded: true,
          tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          leading: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppTheme.modernGreen(context).withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Text(emoji, style: const TextStyle(fontSize: 20)),
          ),
          title: Text(
            '$destination Insights',
            style: GoogleFonts.outfit(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: AppTheme.textPrimary(context),
            ),
          ),
          subtitle: Row(
            children: [
              Icon(Icons.wifi_off, size: 12, color: AppTheme.modernGreen(context)),
              const SizedBox(width: 6),
              Text(
                'Offline Knowledge Base',
                style: GoogleFonts.inter(
                  fontSize: 11,
                  color: AppTheme.textSecondary(context),
                ),
              ),
            ],
          ),
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Divider(height: 24, thickness: 0.5),
                  _section(context, '📍 Must See', mustSee, AppTheme.modernGreen(context)),
                  const SizedBox(height: 16),
                  _section(context, '🌧️ Rainy Day Options', indoor, Theme.of(context).colorScheme.secondary),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppTheme.errorRed.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppTheme.errorRed.withValues(alpha: 0.2)),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('⚠️', style: TextStyle(fontSize: 14)),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            safety,
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              color: isDark ? Colors.red.shade200 : Colors.red.shade800,
                              height: 1.4,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _section(BuildContext context, String label, List<String> items, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: GoogleFonts.outfit(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: color,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: items
              .map((item) => Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: color.withValues(alpha: 0.2), width: 0.5),
                    ),
                    child: Text(
                      item,
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        color: AppTheme.textPrimary(context).withValues(alpha: 0.9),
                      ),
                    ),
                  ))
              .toList(),
        ),
      ],
    );
  }
}
