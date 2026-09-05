const express = require('express');
const router = express.Router();
const { db } = require('../config/firebase');

// POST /api/seed - Population script for Firestore collections
router.post('/', async (req, res) => {
  try {
    if (!db) {
      return res.json({
        success: true,
        message: 'Running in demo in-memory mode. Pre-seeded fallback data active.',
      });
    }

    const batch = db.batch();

    // 1. Demo Users
    const users = [
      { id: 'user-chw', name: 'Priya Shinde', role: 'chw', email: 'chw@carelink.org', facility: 'Palghar Sub-Center' },
      { id: 'user-doc', name: 'Dr. Anita Rao', role: 'doctor', email: 'doctor@carelink.org', facility: 'Wada PHC' },
      { id: 'user-admin', name: 'District Admin', role: 'admin', email: 'admin@carelink.org', facility: 'Palghar HQ' }
    ];
    users.forEach(u => batch.set(db.collection('users').doc(u.id), u));

    // 2. Demo Patients
    const patients = [
      {
        id: 'pat-101',
        name: 'Sunita Sharma',
        age: 34,
        gender: 'Female',
        phone: '+91 98230 11223',
        village: 'Palghar Rural',
        district: 'Palghar',
        bloodGroup: 'O+',
        vitals: { temp: 98.6, bpSystolic: 120, bpDiastolic: 80, pulse: 72, spo2: 98 },
        triageRisk: 'Low',
        lastVisitDate: '2026-09-01T10:30:00.000Z',
      },
      {
        id: 'pat-102',
        name: 'Ramesh Patil',
        age: 52,
        gender: 'Male',
        phone: '+91 98451 22334',
        village: 'Wada',
        district: 'Palghar',
        bloodGroup: 'B+',
        vitals: { temp: 101.4, bpSystolic: 155, bpDiastolic: 98, pulse: 104, spo2: 91 },
        triageRisk: 'High',
        lastVisitDate: '2026-09-03T14:15:00.000Z',
      },
      {
        id: 'pat-103',
        name: 'Anandi Deshmukh',
        age: 27,
        gender: 'Female',
        phone: '+91 97112 33445',
        village: 'Jawhar',
        district: 'Palghar',
        bloodGroup: 'A+',
        vitals: { temp: 99.2, bpSystolic: 132, bpDiastolic: 86, pulse: 88, spo2: 96 },
        triageRisk: 'Medium',
        lastVisitDate: '2026-09-02T09:00:00.000Z',
      }
    ];
    patients.forEach(p => batch.set(db.collection('patients').doc(p.id), p));

    await batch.commit();

    return res.json({
      success: true,
      message: 'Firestore successfully populated with seed data.',
    });
  } catch (err) {
    console.error('[Seed Error]', err);
    return res.status(500).json({ success: false, error: err.message });
  }
});

module.exports = router;
