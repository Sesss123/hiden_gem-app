import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/incident_report.dart';

final incidentRepositoryProvider = Provider((ref) => IncidentRepository());

class IncidentRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Collection: incident_reports
  CollectionReference<Map<String, dynamic>> get _incidentRef => 
      _firestore.collection('incident_reports');

  /// Creates a new incident report with an initial timeline event.
  Future<String> createIncident(IncidentReport incident) async {
    final doc = _incidentRef.doc();
    final newIncident = IncidentReport(
      incidentId: doc.id,
      incidentNumber: incident.incidentNumber == 'INC-UNK' 
          ? 'INC-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}' 
          : incident.incidentNumber,
      sessionId: incident.sessionId,
      guideId: incident.guideId,
      touristId: incident.touristId,
      reportedBy: incident.reportedBy,
      reportedByRole: incident.reportedByRole,
      type: incident.type,
      severity: incident.severity,
      title: incident.title,
      description: incident.description,
      lat: incident.lat,
      lng: incident.lng,
      attachments: incident.attachments,
      status: 'open',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      timelineCount: 1,
      timelineEvents: [
        {
          'type': 'incident_created',
          'description': 'Incident report filed by ${incident.reportedByRole}.',
          'timestamp': DateTime.now().toIso8601String(),
          'userId': incident.reportedBy,
          'role': incident.reportedByRole,
        }
      ],
    );

    await doc.set(newIncident.toJson());
    
    // Increment incident counts in the session
    await _firestore.collection('tour_sessions').doc(incident.sessionId).update({
      'incidentCount': FieldValue.increment(1),
      if (incident.severity == 'critical') 'criticalIncidentCount': FieldValue.increment(1),
    });

    return doc.id;
  }

  /// Adds a history event to the incident timeline.
  Future<void> addTimelineEvent({
    required String incidentId,
    required String type,
    required String description,
    required String userId,
    required String role,
    Map<String, dynamic>? metadata,
  }) async {
    final event = {
      'type': type,
      'description': description,
      'timestamp': DateTime.now().toIso8601String(),
      'userId': userId,
      'role': role,
      if (metadata != null) 'metadata': metadata,
    };

    await _incidentRef.doc(incidentId).update({
      'timelineEvents': FieldValue.arrayUnion([event]),
      'timelineCount': FieldValue.increment(1),
      'updatedAt': DateTime.now().toIso8601String(),
    });
  }

  /// Resolves an incident with a final note.
  Future<void> resolveIncident({
    required String incidentId,
    required String resolvedBy,
    required String resolutionNote,
  }) async {
    await _incidentRef.doc(incidentId).update({
      'status': 'resolved',
      'resolvedAt': DateTime.now().toIso8601String(),
      'resolvedBy': resolvedBy,
      'resolutionNote': resolutionNote,
      'updatedAt': DateTime.now().toIso8601String(),
    });

    await addTimelineEvent(
      incidentId: incidentId,
      type: 'resolved',
      description: 'Incident resolved: $resolutionNote',
      userId: resolvedBy,
      role: 'admin',
    );
  }

  /// Tiered SOS Conversion Logic
  /// If SOS is critical, automatically create an incident.
  Future<void> handleSosTrigger({
    required String sessionId,
    required String userId,
    required String role,
    required String severity,
    double? lat,
    double? lng,
    String? sosAlertId,
  }) async {
    // Only Auto-Incident for Critical or Repeated SOS (logic here)
    if (severity == 'critical') {
      final incident = IncidentReport(
        incidentId: '', // Generated in createIncident
        incidentNumber: 'INC-AUTO',
        sessionId: sessionId,
        guideId: 'pending', // To be filled by repo logic
        touristId: role == 'tourist' ? userId : 'none',
        reportedBy: userId,
        reportedByRole: role,
        type: 'sos_trigger',
        severity: 'critical',
        title: 'Auto-Incident: Critical SOS Triggered',
        description: 'System automatically generated this report due to a critical SOS alert.',
        lat: lat,
        lng: lng,
        status: 'open',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        linkedSosAlertId: sosAlertId,
      );
      
      await createIncident(incident);
    }
  }

  Stream<List<IncidentReport>> getSessionIncidents(String sessionId) {
    return _incidentRef
        .where('sessionId', isEqualTo: sessionId)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => IncidentReport.fromJson(doc.data()))
            .toList());
  }

  Stream<List<IncidentReport>> getActiveIncidents() {
    return _incidentRef
        .where('status', whereIn: ['open', 'under_review', 'escalated'])
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => IncidentReport.fromJson(doc.data()))
            .toList());
  }
}
