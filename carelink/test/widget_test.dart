import 'package:flutter_test/flutter_test.dart';
import 'package:carelink/models/care_case_model.dart';
import 'package:carelink/models/triage_result_model.dart';

void main() {
  test('CareCaseModel route confirmation and doctor consultation state test', () {
    final now = DateTime.now();
    final c = CareCaseModel(
      id: 'case_123',
      patientId: 'patient_456',
      patientName: 'Anil Kumar',
      patientAge: 48,
      patientGender: 'Male',
      village: 'Trimbak',
      chiefComplaint: 'Chest Pain',
      riskLevel: RiskLevel.high,
      riskScore: 78,
      isDoctorConsulted: false,
      isRouteConfirmed: false,
      destinationFacilityId: 'fac_1',
      destinationFacilityName: 'Nashik Civil Hospital',
      createdAt: now,
      updatedAt: now,
    );

    expect(c.isDoctorConsulted, false);
    expect(c.isRouteConfirmed, false);

    final acceptedCase = c.copyWith(isDoctorConsulted: true);
    expect(acceptedCase.isDoctorConsulted, true);
    expect(acceptedCase.isRouteConfirmed, false); // Doctor acceptance MUST NOT confirm route

    final routeChanged = acceptedCase.copyWith(
      destinationFacilityId: 'fac_2',
      destinationFacilityName: 'Wada PHC',
      isRouteConfirmed: false, // Route change resets confirmation
    );
    expect(routeChanged.destinationFacilityName, 'Wada PHC');
    expect(routeChanged.isRouteConfirmed, false);

    final confirmedCase = routeChanged.copyWith(isRouteConfirmed: true);
    expect(confirmedCase.isRouteConfirmed, true);
    expect(confirmedCase.isDoctorConsulted, true);
  });
}
