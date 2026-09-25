import 'package:cloud_firestore/cloud_firestore.dart';
import 'triage_result_model.dart';

enum ConsultStatus { pending, accepted, inProgress, closed }

extension ConsultStatusX on ConsultStatus {
  String get label {
    switch (this) {
      case ConsultStatus.pending:
        return 'Pending';
      case ConsultStatus.accepted:
        return 'Accepted';
      case ConsultStatus.inProgress:
        return 'In Progress';
      case ConsultStatus.closed:
        return 'Closed';
    }
  }

  static ConsultStatus fromString(String s) {
    switch (s.toLowerCase()) {
      case 'accepted':
        return ConsultStatus.accepted;
      case 'inprogress':
      case 'in_progress':
        return ConsultStatus.inProgress;
      case 'closed':
        return ConsultStatus.closed;
      default:
        return ConsultStatus.pending;
    }
  }
}

enum UrgencyLevel { routine, urgent, emergency }

extension UrgencyLevelX on UrgencyLevel {
  String get label {
    switch (this) {
      case UrgencyLevel.routine:
        return 'Routine';
      case UrgencyLevel.urgent:
        return 'Urgent';
      case UrgencyLevel.emergency:
        return 'Emergency';
    }
  }

  static UrgencyLevel fromString(String s) {
    switch (s.toLowerCase()) {
      case 'urgent':
        return UrgencyLevel.urgent;
      case 'emergency':
        return UrgencyLevel.emergency;
      default:
        return UrgencyLevel.routine;
    }
  }
}

class ConsultMessage {
  final String id;
  final String senderUid;
  final String senderName;
  final String senderRole;
  final String text;
  final DateTime sentAt;

  const ConsultMessage({
    required this.id,
    required this.senderUid,
    required this.senderName,
    required this.senderRole,
    required this.text,
    required this.sentAt,
  });

  factory ConsultMessage.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ConsultMessage(
      id: doc.id,
      senderUid: data['senderUid'] as String? ?? '',
      senderName: data['senderName'] as String? ?? '',
      senderRole: data['senderRole'] as String? ?? '',
      text: data['text'] as String? ?? '',
      sentAt: (data['sentAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() => {
        'senderUid': senderUid,
        'senderName': senderName,
        'senderRole': senderRole,
        'text': text,
        'sentAt': Timestamp.fromDate(sentAt),
      };
}

class ConsultRequestModel {
  final String id;
  final String patientId;
  final String patientName;
  final String chwUid;
  final String chwName;
  final String? doctorUid;
  final String? doctorName;
  final String reason;
  final UrgencyLevel urgency;
  final ConsultStatus status;
  final String? careCaseId;
  final String? triageResultId;
  final RiskLevel? triageRisk;
  final String? prescriptionNote; // Doctor's prescription after consult
  final DateTime createdAt;
  final DateTime? acceptedAt;
  final DateTime? closedAt;

  const ConsultRequestModel({
    required this.id,
    required this.patientId,
    required this.patientName,
    required this.chwUid,
    required this.chwName,
    this.doctorUid,
    this.doctorName,
    required this.reason,
    required this.urgency,
    required this.status,
    this.careCaseId,
    this.triageResultId,
    this.triageRisk,
    this.prescriptionNote,
    required this.createdAt,
    this.acceptedAt,
    this.closedAt,
  });

  factory ConsultRequestModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ConsultRequestModel(
      id: doc.id,
      patientId: data['patientId'] as String? ?? '',
      patientName: data['patientName'] as String? ?? '',
      chwUid: data['chwUid'] as String? ?? '',
      chwName: data['chwName'] as String? ?? '',
      doctorUid: data['doctorUid'] as String?,
      doctorName: data['doctorName'] as String?,
      reason: data['reason'] as String? ?? '',
      urgency: UrgencyLevelX.fromString(data['urgency'] as String? ?? 'routine'),
      status: ConsultStatusX.fromString(data['status'] as String? ?? 'pending'),
      careCaseId: data['careCaseId'] as String?,
      triageResultId: data['triageResultId'] as String?,
      triageRisk: data['triageRisk'] != null
          ? RiskLevelX.fromString(data['triageRisk'] as String)
          : null,
      prescriptionNote: data['prescriptionNote'] as String?,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      acceptedAt: (data['acceptedAt'] as Timestamp?)?.toDate(),
      closedAt: (data['closedAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toFirestore() => {
        'patientId': patientId,
        'patientName': patientName,
        'chwUid': chwUid,
        'chwName': chwName,
        'doctorUid': doctorUid,
        'doctorName': doctorName,
        'reason': reason,
        'urgency': urgency.name,
        'status': status.name,
        'careCaseId': careCaseId,
        'triageResultId': triageResultId,
        'triageRisk': triageRisk?.name,
        'prescriptionNote': prescriptionNote,
        'createdAt': Timestamp.fromDate(createdAt),
        'acceptedAt': acceptedAt != null ? Timestamp.fromDate(acceptedAt!) : null,
        'closedAt': closedAt != null ? Timestamp.fromDate(closedAt!) : null,
      };

  ConsultRequestModel copyWith({
    String? doctorUid,
    String? doctorName,
    ConsultStatus? status,
    String? prescriptionNote,
    DateTime? acceptedAt,
    DateTime? closedAt,
  }) =>
      ConsultRequestModel(
        id: id,
        patientId: patientId,
        patientName: patientName,
        chwUid: chwUid,
        chwName: chwName,
        doctorUid: doctorUid ?? this.doctorUid,
        doctorName: doctorName ?? this.doctorName,
        reason: reason,
        urgency: urgency,
        status: status ?? this.status,
        careCaseId: careCaseId,
        triageResultId: triageResultId,
        triageRisk: triageRisk,
        prescriptionNote: prescriptionNote ?? this.prescriptionNote,
        createdAt: createdAt,
        acceptedAt: acceptedAt ?? this.acceptedAt,
        closedAt: closedAt ?? this.closedAt,
      );
}
