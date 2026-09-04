import 'package:cloud_firestore/cloud_firestore.dart';
import 'consult_request_model.dart';

enum ReferralStatus { created, accepted, scheduled, completed, dropped }

extension ReferralStatusX on ReferralStatus {
  String get label {
    switch (this) {
      case ReferralStatus.created:
        return 'Created';
      case ReferralStatus.accepted:
        return 'Accepted';
      case ReferralStatus.scheduled:
        return 'Scheduled';
      case ReferralStatus.completed:
        return 'Completed';
      case ReferralStatus.dropped:
        return 'Dropped';
    }
  }

  static ReferralStatus fromString(String s) {
    switch (s.toLowerCase()) {
      case 'accepted':
        return ReferralStatus.accepted;
      case 'scheduled':
        return ReferralStatus.scheduled;
      case 'completed':
        return ReferralStatus.completed;
      case 'dropped':
        return ReferralStatus.dropped;
      default:
        return ReferralStatus.created;
    }
  }

  bool get isTerminal =>
      this == ReferralStatus.completed || this == ReferralStatus.dropped;
}

class ReferralStatusEntry {
  final ReferralStatus status;
  final String updatedByUid;
  final String updatedByName;
  final String? note;
  final DateTime timestamp;

  const ReferralStatusEntry({
    required this.status,
    required this.updatedByUid,
    required this.updatedByName,
    this.note,
    required this.timestamp,
  });

  factory ReferralStatusEntry.fromMap(Map<String, dynamic> data) =>
      ReferralStatusEntry(
        status: ReferralStatusX.fromString(data['status'] as String? ?? 'created'),
        updatedByUid: data['updatedByUid'] as String? ?? '',
        updatedByName: data['updatedByName'] as String? ?? '',
        note: data['note'] as String?,
        timestamp: (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
      );

  Map<String, dynamic> toMap() => {
        'status': status.name,
        'updatedByUid': updatedByUid,
        'updatedByName': updatedByName,
        'note': note,
        'timestamp': Timestamp.fromDate(timestamp),
      };
}

class ReferralModel {
  final String id;
  final String patientId;
  final String patientName;
  final String raisedByUid;
  final String raisedByName;
  final String raisedByRole; // 'chw' or 'doctor'
  final String? fromFacility;
  final String referredTo; // Hospital/facility/doctor name
  final String reason;
  final UrgencyLevel urgency;
  final String? diagnosis;
  final ReferralStatus currentStatus;
  final List<ReferralStatusEntry> statusHistory;
  final String? consultRequestId;
  final DateTime createdAt;
  final DateTime? scheduledDate;

  const ReferralModel({
    required this.id,
    required this.patientId,
    required this.patientName,
    required this.raisedByUid,
    required this.raisedByName,
    this.raisedByRole = 'doctor',
    this.fromFacility,
    required this.referredTo,
    required this.reason,
    this.urgency = UrgencyLevel.routine,
    this.diagnosis,
    required this.currentStatus,
    this.statusHistory = const [],
    this.consultRequestId,
    required this.createdAt,
    this.scheduledDate,
  });

  factory ReferralModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final historyList = (data['statusHistory'] as List<dynamic>?) ?? [];
    return ReferralModel(
      id: doc.id,
      patientId: data['patientId'] as String? ?? '',
      patientName: data['patientName'] as String? ?? '',
      raisedByUid: data['raisedByUid'] as String? ?? '',
      raisedByName: data['raisedByName'] as String? ?? '',
      raisedByRole: data['raisedByRole'] as String? ?? 'doctor',
      fromFacility: data['fromFacility'] as String?,
      referredTo: data['referredTo'] as String? ?? '',
      reason: data['reason'] as String? ?? '',
      urgency: UrgencyLevelX.fromString(data['urgency'] as String? ?? 'routine'),
      diagnosis: data['diagnosis'] as String?,
      currentStatus: ReferralStatusX.fromString(data['currentStatus'] as String? ?? 'created'),
      statusHistory: historyList
          .map((e) => ReferralStatusEntry.fromMap(e as Map<String, dynamic>))
          .toList(),
      consultRequestId: data['consultRequestId'] as String?,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      scheduledDate: (data['scheduledDate'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toFirestore() => {
        'patientId': patientId,
        'patientName': patientName,
        'raisedByUid': raisedByUid,
        'raisedByName': raisedByName,
        'raisedByRole': raisedByRole,
        'fromFacility': fromFacility,
        'referredTo': referredTo,
        'reason': reason,
        'urgency': urgency.name,
        'diagnosis': diagnosis,
        'currentStatus': currentStatus.name,
        'statusHistory': statusHistory.map((e) => e.toMap()).toList(),
        'consultRequestId': consultRequestId,
        'createdAt': Timestamp.fromDate(createdAt),
        'scheduledDate': scheduledDate != null ? Timestamp.fromDate(scheduledDate!) : null,
      };

  ReferralModel copyWith({
    ReferralStatus? currentStatus,
    List<ReferralStatusEntry>? statusHistory,
    DateTime? scheduledDate,
    UrgencyLevel? urgency,
  }) =>
      ReferralModel(
        id: id,
        patientId: patientId,
        patientName: patientName,
        raisedByUid: raisedByUid,
        raisedByName: raisedByName,
        raisedByRole: raisedByRole,
        fromFacility: fromFacility,
        referredTo: referredTo,
        reason: reason,
        urgency: urgency ?? this.urgency,
        diagnosis: diagnosis,
        currentStatus: currentStatus ?? this.currentStatus,
        statusHistory: statusHistory ?? this.statusHistory,
        consultRequestId: consultRequestId,
        createdAt: createdAt,
        scheduledDate: scheduledDate ?? this.scheduledDate,
      );
}

