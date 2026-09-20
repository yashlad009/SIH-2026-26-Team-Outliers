class MinimumTripPlan {
  final String title;
  final List<String> bundledServices;
  final int estimatedVisits;
  final int uncoordinatedVisits;
  final String coordinationNote;

  const MinimumTripPlan({
    required this.title,
    required this.bundledServices,
    required this.estimatedVisits,
    required this.uncoordinatedVisits,
    required this.coordinationNote,
  });
}

class MinimumTripService {
  /// Bundles required clinical services into a coordinated minimum-trip care plan
  static MinimumTripPlan generatePlan({
    required String doctorName,
    required List<String> diagnostics,
    required List<String> medicines,
    required String facilityName,
  }) {
    final bundled = <String>[];

    // 1. Doctor Consultation
    bundled.add('Doctor Consultation ($doctorName)');

    // 2. Diagnostics
    for (final d in diagnostics) {
      bundled.add('Diagnostic Test ($d)');
    }

    // 3. Pharmacy Dispensing
    if (medicines.isNotEmpty) {
      final medText = medicines.length > 2
          ? '${medicines.take(2).join(', ')} +${medicines.length - 2} more'
          : medicines.join(', ');
      bundled.add('Pharmacy Dispensing ($medText)');
    }

    final uncoordinated = 1 + diagnostics.length + (medicines.isNotEmpty ? 1 : 0);
    final estimatedVisits = 1;

    return MinimumTripPlan(
      title: 'Recommended minimum-trip care plan',
      bundledServices: bundled,
      estimatedVisits: estimatedVisits,
      uncoordinatedVisits: uncoordinated,
      coordinationNote:
          'Coordinated 1-visit care plan at $facilityName: Synchronizes consultation, diagnostic testing, and pharmacy dispensing into one coordinated visit to minimize patient travel burden.',
    );
  }
}
