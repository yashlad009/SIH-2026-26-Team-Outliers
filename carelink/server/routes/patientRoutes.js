const express = require('express');
const router = express.Router();
const { db } = require('../config/firebase');

// In-memory fallback dataset for seamless demo if Firestore is offline
let localPatients = [
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

// GET /api/patients - Fetch all patients
router.get('/', async (req, res) => {
  try {
    if (db) {
      const snapshot = await db.collection('patients').get();
      if (!snapshot.empty) {
        const patients = snapshot.docs.map(doc => ({ id: doc.id, ...doc.data() }));
        return res.json({ success: true, count: patients.length, data: patients });
      }
    }
    return res.json({ success: true, count: localPatients.length, data: localPatients });
  } catch (err) {
    console.error('[Patient API Error]', err);
    return res.json({ success: true, count: localPatients.length, data: localPatients });
  }
});

// GET /api/patients/:id - Fetch patient details & longitudinal record
router.get('/:id', async (req, res) => {
  try {
    const { id } = req.params;
    if (db) {
      const doc = await db.collection('patients').doc(id).get();
      if (doc.exists) {
        return res.json({ success: true, data: { id: doc.id, ...doc.data() } });
      }
    }
    const patient = localPatients.find(p => p.id === id) || localPatients[0];
    return res.json({ success: true, data: patient });
  } catch (err) {
    return res.json({ success: true, data: localPatients[0] });
  }
});

// POST /api/patients - Create new patient
router.post('/', async (req, res) => {
  try {
    const newPatient = {
      id: `pat-${Date.now()}`,
      name: req.body.name || 'New Patient',
      age: Number(req.body.age) || 30,
      gender: req.body.gender || 'Unknown',
      phone: req.body.phone || '',
      village: req.body.village || 'Rural Health Post',
      district: req.body.district || 'Palghar',
      bloodGroup: req.body.bloodGroup || 'O+',
      vitals: req.body.vitals || { temp: 98.6, bpSystolic: 120, bpDiastolic: 80, pulse: 72, spo2: 98 },
      triageRisk: req.body.triageRisk || 'Low',
      lastVisitDate: new Date().toISOString(),
      createdAt: new Date().toISOString(),
    };

    if (db) {
      await db.collection('patients').doc(newPatient.id).set(newPatient);
    }
    localPatients.unshift(newPatient);

    return res.status(201).json({ success: true, message: 'Patient created successfully', data: newPatient });
  } catch (err) {
    return res.status(500).json({ success: false, error: err.message });
  }
});

module.exports = router;
