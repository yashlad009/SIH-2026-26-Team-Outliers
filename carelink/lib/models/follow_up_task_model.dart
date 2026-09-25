import 'package:cloud_firestore/cloud_firestore.dart';

enum FollowUpCategory { maternal, child, ncd, general }

extension FollowUpCategoryX on FollowUpCategory {
  String get label {
    switch (this) {
      case FollowUpCategory.maternal:
        return 'Maternal';
      case FollowUpCategory.child:
        return 'Child';
      case FollowUpCategory.ncd:
        return 'NCD';
      case FollowUpCategory.general:
        return 'General';
    }
  }

  static FollowUpCategory fromString(String s) {
    switch (s.toLowerCase()) {
      case 'maternal':
        return FollowUpCategory.maternal;
      case 'child':
        return FollowUpCategory.child;
      case 'ncd':
        return FollowUpCategory.ncd;
      default:
        return FollowUpCategory.general;
    }
  }
}

class FollowUpTaskModel {
  final String id;
  final String patientId;
  final String patientName;
  final String assignedToUid; // CHW
  final String title;
  final String? description;
  final FollowUpCategory category;
  final DateTime dueDate;
  final bool isDone;
  final DateTime? completedAt;
  final String? careCaseId;
  final String createdByUid;
  final DateTime createdAt;

  const FollowUpTaskModel({
    required this.id,
    required this.patientId,
    required this.patientName,
    required this.assignedToUid,
    required this.title,
    this.description,
    required this.category,
    required this.dueDate,
    this.isDone = false,
    this.completedAt,
    this.careCaseId,
    required this.createdByUid,
    required this.createdAt,
  });

  bool get isOverdue => !isDone && dueDate.isBefore(DateTime.now());

  factory FollowUpTaskModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return FollowUpTaskModel(
      id: doc.id,
      patientId: data['patientId'] as String? ?? '',
      patientName: data['patientName'] as String? ?? '',
      assignedToUid: data['assignedToUid'] as String? ?? '',
      title: data['title'] as String? ?? '',
      description: data['description'] as String?,
      category: FollowUpCategoryX.fromString(data['category'] as String? ?? 'general'),
      dueDate: (data['dueDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      isDone: data['isDone'] as bool? ?? false,
      completedAt: (data['completedAt'] as Timestamp?)?.toDate(),
      careCaseId: data['careCaseId'] as String?,
      createdByUid: data['createdByUid'] as String? ?? '',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() => {
        'patientId': patientId,
        'patientName': patientName,
        'assignedToUid': assignedToUid,
        'title': title,
        'description': description,
        'category': category.name,
        'dueDate': Timestamp.fromDate(dueDate),
        'isDone': isDone,
        'completedAt': completedAt != null ? Timestamp.fromDate(completedAt!) : null,
        'careCaseId': careCaseId,
        'createdByUid': createdByUid,
        'createdAt': Timestamp.fromDate(createdAt),
      };

  FollowUpTaskModel copyWith({
    bool? isDone,
    DateTime? completedAt,
    String? careCaseId,
  }) =>
      FollowUpTaskModel(
        id: id,
        patientId: patientId,
        patientName: patientName,
        assignedToUid: assignedToUid,
        title: title,
        description: description,
        category: category,
        dueDate: dueDate,
        isDone: isDone ?? this.isDone,
        completedAt: completedAt ?? this.completedAt,
        careCaseId: careCaseId ?? this.careCaseId,
        createdByUid: createdByUid,
        createdAt: createdAt,
      );
}
