import 'package:cloud_firestore/cloud_firestore.dart';

enum TestStatus { pending, ordered, sampleCollected, completed, cancelled }

extension TestStatusX on TestStatus {
  String get label {
    switch (this) {
      case TestStatus.pending:
        return 'Pending';
      case TestStatus.ordered:
        return 'Ordered';
      case TestStatus.sampleCollected:
        return 'Sample Collected';
      case TestStatus.completed:
        return 'Completed';
      case TestStatus.cancelled:
        return 'Cancelled';
    }
  }

  static TestStatus fromString(String s) {
    switch (s.toLowerCase()) {
      case 'ordered':
        return TestStatus.ordered;
      case 'samplecollected':
      case 'sample_collected':
        return TestStatus.sampleCollected;
      case 'completed':
        return TestStatus.completed;
      case 'cancelled':
        return TestStatus.cancelled;
      default:
        return TestStatus.pending;
    }
  }
}

class DiagnosticTestModel {
  final String id;
  final String patientId;
  final String patientName;
  final String testName;
  final String? testType; // e.g. "Blood", "Urine", "X-Ray"
  final TestStatus status;
  final String orderedByUid;
  final String? labName;
  final String? result;
  final DateTime orderedAt;
  final DateTime? completedAt;

  const DiagnosticTestModel({
    required this.id,
    required this.patientId,
    required this.patientName,
    required this.testName,
    this.testType,
    required this.status,
    required this.orderedByUid,
    this.labName,
    this.result,
    required this.orderedAt,
    this.completedAt,
  });

  factory DiagnosticTestModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return DiagnosticTestModel(
      id: doc.id,
      patientId: data['patientId'] as String? ?? '',
      patientName: data['patientName'] as String? ?? '',
      testName: data['testName'] as String? ?? '',
      testType: data['testType'] as String?,
      status: TestStatusX.fromString(data['status'] as String? ?? 'pending'),
      orderedByUid: data['orderedByUid'] as String? ?? '',
      labName: data['labName'] as String?,
      result: data['result'] as String?,
      orderedAt: (data['orderedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      completedAt: (data['completedAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toFirestore() => {
        'patientId': patientId,
        'patientName': patientName,
        'testName': testName,
        'testType': testType,
        'status': status.name,
        'orderedByUid': orderedByUid,
        'labName': labName,
        'result': result,
        'orderedAt': Timestamp.fromDate(orderedAt),
        'completedAt': completedAt != null ? Timestamp.fromDate(completedAt!) : null,
      };
}
