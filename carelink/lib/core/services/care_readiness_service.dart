import '../../models/facility_model.dart';

class CareReadinessItem {
  final String category; // 'Doctor', 'Diagnostic', 'Medicine'
  final String name;
  final bool isAvailable;
  final String note;

  const CareReadinessItem({
    required this.category,
    required this.name,
    required this.isAvailable,
    required this.note,
  });
}

class CareReadinessResult {
  final FacilityModel facility;
  final bool isCareReady;
  final int readinessPercentage;
  final List<CareReadinessItem> checklist;
  final List<String> missingReasons;

  const CareReadinessResult({
    required this.facility,
    required this.isCareReady,
    required this.readinessPercentage,
    required this.checklist,
    required this.missingReasons,
  });
}

class CareReadinessService {
  /// Assesses whether a specific facility is Care Ready for a patient's requirements
  static CareReadinessResult auditFacilityReadiness({
    required FacilityModel facility,
    required String requiredSpecialty,
    required List<String> requiredDiagnostics,
    required List<String> requiredMedicines,
  }) {
    final checklist = <CareReadinessItem>[];
    final missingReasons = <String>[];

    // 1. Facility Operational Status
    if (!facility.isOperational) {
      missingReasons.add('Facility "${facility.name}" is currently non-operational.');
    }

    // 2. Specialty / Provider Check
    final specMatch = facility.availableSpecialties.any(
      (s) => s.toLowerCase() == requiredSpecialty.toLowerCase() || s.toLowerCase() == 'general medicine',
    );
    final docAvailable = facility.isOperational && specMatch;
    checklist.add(CareReadinessItem(
      category: 'Doctor & Specialty',
      name: requiredSpecialty,
      isAvailable: docAvailable,
      note: docAvailable
          ? 'Specialist / Physician available at ${facility.name}'
          : 'Specialty "$requiredSpecialty" not available at ${facility.name}',
    ));
    if (!docAvailable) {
      missingReasons.add('Specialty "$requiredSpecialty" unavailable');
    }

    // 3. Diagnostic Tests Check
    int diagAvailableCount = 0;
    for (final test in requiredDiagnostics) {
      final available = facility.availableDiagnostics.any(
        (d) => d.toLowerCase().contains(test.toLowerCase()) || test.toLowerCase().contains(d.toLowerCase()),
      );
      if (available) diagAvailableCount++;
      checklist.add(CareReadinessItem(
        category: 'Diagnostic Test',
        name: test,
        isAvailable: available,
        note: available ? 'Equipment & lab ready' : 'Test unavailable at facility lab',
      ));
      if (!available) {
        missingReasons.add('Diagnostic test "$test" unavailable');
      }
    }

    // 4. Medicine Stock Check
    int medAvailableCount = 0;
    for (final med in requiredMedicines) {
      final available = facility.availableMedicines.any(
        (m) => m.toLowerCase().contains(med.toLowerCase()) || med.toLowerCase().contains(m.toLowerCase()),
      );
      if (available) medAvailableCount++;
      checklist.add(CareReadinessItem(
        category: 'Medicine Stock',
        name: med,
        isAvailable: available,
        note: available ? 'In stock in pharmacy' : 'Out of stock in facility pharmacy',
      ));
      if (!available) {
        missingReasons.add('Medicine "$med" out of stock');
      }
    }

    // Calculate percentage score
    final totalItems = 1 + requiredDiagnostics.length + requiredMedicines.length;
    int passedItems = (docAvailable ? 1 : 0) + diagAvailableCount + medAvailableCount;
    final percentage = totalItems > 0 ? ((passedItems / totalItems) * 100).round() : 100;

    final isCareReady = facility.isOperational && missingReasons.isEmpty;

    return CareReadinessResult(
      facility: facility,
      isCareReady: isCareReady,
      readinessPercentage: percentage,
      checklist: checklist,
      missingReasons: missingReasons,
    );
  }
}
