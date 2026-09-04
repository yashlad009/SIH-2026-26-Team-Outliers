const express = require('express');
const router = express.Router();
const { db } = require('../config/firebase');

// Rule-based triage scoring function
function computeTriageRisk(vitals) {
  const { temp = 98.6, bpSystolic = 120, bpDiastolic = 80, pulse = 72, spo2 = 98 } = vitals;

  if (spo2 < 92 || bpSystolic >= 160 || temp >= 102.0 || pulse > 120) {
    return {
      riskLevel: 'High',
      score: 3,
      reason: 'Critical vitals detected: Hypoxia (SpO2 < 92%) or severe hypertension / high fever.',
      recommendation: 'Immediate teleconsultation and priority hospital referral required.',
    };
  } else if (spo2 <= 95 || bpSystolic >= 140 || temp >= 100.4 || pulse >= 100) {
    return {
      riskLevel: 'Medium',
      score: 2,
      reason: 'Moderate physiological stress: Elevated BP / temperature or mild hypoxia.',
      recommendation: 'Schedule doctor teleconsultation within 24 hours.',
    };
  } else {
    return {
      riskLevel: 'Low',
      score: 1,
      reason: 'Vitals within normal physiological range.',
      recommendation: 'Routine follow-up and local CHW monitoring.',
    };
  }
}

// POST /api/triage - Process vitals & compute triage risk
router.post('/', async (req, res) => {
  try {
    const { patientId, patientName, vitals, symptoms = [] } = req.body;
    
    if (!vitals) {
      return res.status(400).json({ success: false, error: 'Vitals data is required for triage processing.' });
    }

    const triageResult = computeTriageRisk(vitals);
    const triageRecord = {
      id: `triage-${Date.now()}`,
      patientId: patientId || 'pat-unknown',
      patientName: patientName || 'Patient',
      vitals,
      symptoms,
      riskLevel: triageResult.riskLevel,
      score: triageResult.score,
      reason: triageResult.reason,
      recommendation: triageResult.recommendation,
      createdAt: new Date().toISOString(),
    };

    if (db) {
      await db.collection('triage_records').doc(triageRecord.id).set(triageRecord);
      if (patientId) {
        await db.collection('patients').doc(patientId).update({
          vitals,
          triageRisk: triageResult.riskLevel,
          lastVisitDate: new Date().toISOString(),
        }).catch(() => {});
      }
    }

    return res.json({
      success: true,
      message: 'Triage risk calculated successfully',
      data: triageRecord,
    });
  } catch (err) {
    console.error('[Triage API Error]', err);
    return res.status(500).json({ success: false, error: err.message });
  }
});

module.exports = router;
