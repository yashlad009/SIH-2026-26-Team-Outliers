import '../../models/facility_model.dart';
import 'care_readiness_service.dart';

class AdaptiveRouteRecommendation {
  final FacilityModel recommendedFacility;
  final FacilityModel preferredFacility;
  final bool isAlternativeRoute;
  final String routingReason;
  final CareReadinessResult readinessResult;

  const AdaptiveRouteRecommendation({
    required this.recommendedFacility,
    required this.preferredFacility,
    required this.isAlternativeRoute,
    required this.routingReason,
    required this.readinessResult,
  });
}

class AdaptiveRoutingService {
  /// Evaluates available facilities and recommends the optimal Care Ready pathway
  static AdaptiveRouteRecommendation computeRecommendedRoute({
    required List<FacilityModel> facilities,
    required String preferredFacilityName,
    required String requiredSpecialty,
    required List<String> requiredDiagnostics,
    required List<String> requiredMedicines,
  }) {
    if (facilities.isEmpty) {
      final dummy = FacilityModel(
        id: 'phc_default',
        name: preferredFacilityName,
        tier: 'Primary',
        availableSpecialties: [requiredSpecialty],
        availableDiagnostics: requiredDiagnostics,
        availableMedicines: requiredMedicines,
      );
      return AdaptiveRouteRecommendation(
        recommendedFacility: dummy,
        preferredFacility: dummy,
        isAlternativeRoute: false,
        routingReason: 'Default facility route assigned.',
        readinessResult: CareReadinessService.auditFacilityReadiness(
          facility: dummy,
          requiredSpecialty: requiredSpecialty,
          requiredDiagnostics: requiredDiagnostics,
          requiredMedicines: requiredMedicines,
        ),
      );
    }

    // Find preferred facility or default to first
    final preferred = facilities.firstWhere(
      (f) => f.name.toLowerCase() == preferredFacilityName.toLowerCase(),
      orElse: () => facilities.first,
    );

    // Audit preferred facility first
    final preferredAudit = CareReadinessService.auditFacilityReadiness(
      facility: preferred,
      requiredSpecialty: requiredSpecialty,
      requiredDiagnostics: requiredDiagnostics,
      requiredMedicines: requiredMedicines,
    );

    if (preferredAudit.isCareReady) {
      return AdaptiveRouteRecommendation(
        recommendedFacility: preferred,
        preferredFacility: preferred,
        isAlternativeRoute: false,
        routingReason:
            'Preferred local facility "${preferred.name}" is fully Care Ready for all required services.',
        readinessResult: preferredAudit,
      );
    }

    // Preferred facility is NOT care ready — search for alternative facility in network
    for (final altFacility in facilities) {
      if (altFacility.id == preferred.id) continue;

      final altAudit = CareReadinessService.auditFacilityReadiness(
        facility: altFacility,
        requiredSpecialty: requiredSpecialty,
        requiredDiagnostics: requiredDiagnostics,
        requiredMedicines: requiredMedicines,
      );

      if (altAudit.isCareReady) {
        final reasons = preferredAudit.missingReasons.join('; ');
        return AdaptiveRouteRecommendation(
          recommendedFacility: altFacility,
          preferredFacility: preferred,
          isAlternativeRoute: true,
          routingReason:
              'Adaptive Routing Alert: "${preferred.name}" cannot fulfill care ($reasons). Adaptively routed to "${altFacility.name}" (${altFacility.tier} Tier) which has verified full care readiness.',
          readinessResult: altAudit,
        );
      }
    }

    // If no single facility is 100% ready, pick the highest scoring facility
    FacilityModel bestPartial = facilities.first;
    CareReadinessResult bestAudit = preferredAudit;

    for (final f in facilities) {
      final audit = CareReadinessService.auditFacilityReadiness(
        facility: f,
        requiredSpecialty: requiredSpecialty,
        requiredDiagnostics: requiredDiagnostics,
        requiredMedicines: requiredMedicines,
      );
      if (audit.readinessPercentage > bestAudit.readinessPercentage) {
        bestAudit = audit;
        bestPartial = f;
      }
    }

    return AdaptiveRouteRecommendation(
      recommendedFacility: bestPartial,
      preferredFacility: preferred,
      isAlternativeRoute: bestPartial.id != preferred.id,
      routingReason:
          'Escalated Referral Route: "${bestPartial.name}" provides highest available care capacity (${bestAudit.readinessPercentage}% readiness score).',
      readinessResult: bestAudit,
    );
  }
}
