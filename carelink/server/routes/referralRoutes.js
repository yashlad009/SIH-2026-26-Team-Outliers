const express = require('express');
const router = express.Router();
const { db } = require('../config/firebase');

let localReferrals = [
  {
    id: 'ref-301',
    patientId: 'pat-102',
    patientName: 'Ramesh Patil',
    referredByDoctor: 'Dr. Anita Rao',
    targetFacility: 'Palghar District Hospital',
    specialty: 'Pulmonology / Critical Care',
    reason: 'Severe Hypoxia (SpO2 91%) and pneumonia suspicion',
    status: 'Scheduled', // Created -> Accepted -> Scheduled -> Completed
    statusHistory: [
      { status: 'Created', timestamp: '2026-09-04T08:35:00.000Z', note: 'Referral raised by Dr. Anita Rao' },
      { status: 'Accepted', timestamp: '2026-09-04T08:45:00.000Z', note: 'District Hospital triage accepted patient' },
      { status: 'Scheduled', timestamp: '2026-09-04T09:00:00.000Z', note: 'Bed & ICU consult scheduled for 2:00 PM' },
    ],
    createdAt: '2026-09-04T08:35:00.000Z',
  },
  {
    id: 'ref-302',
    patientId: 'pat-103',
    patientName: 'Anandi Deshmukh',
    referredByDoctor: 'Dr. Anita Rao',
    targetFacility: 'Wada Rural Hospital',
    specialty: 'Cardiology',
    reason: 'Hypertension monitoring and ECG evaluation',
    status: 'Accepted',
    statusHistory: [
      { status: 'Created', timestamp: '2026-09-03T11:00:00.000Z', note: 'Referral raised by Dr. Anita Rao' },
      { status: 'Accepted', timestamp: '2026-09-03T11:30:00.000Z', note: 'Accepted by Wada Rural OPD' },
    ],
    createdAt: '2026-09-03T11:00:00.000Z',
  }
];

// GET /api/referrals - Fetch all referrals
router.get('/', async (req, res) => {
  try {
    if (db) {
      const snapshot = await db.collection('referrals').get();
      if (!snapshot.empty) {
        const referrals = snapshot.docs.map(doc => ({ id: doc.id, ...doc.data() }));
        return res.json({ success: true, count: referrals.length, data: referrals });
      }
    }
    return res.json({ success: true, count: localReferrals.length, data: localReferrals });
  } catch (err) {
    return res.json({ success: true, count: localReferrals.length, data: localReferrals });
  }
});

// POST /api/referrals - Raise referral
router.post('/', async (req, res) => {
  try {
    const timestamp = new Date().toISOString();
    const newReferral = {
      id: `ref-${Date.now()}`,
      patientId: req.body.patientId || 'pat-101',
      patientName: req.body.patientName || 'Sunita Sharma',
      referredByDoctor: req.body.referredByDoctor || 'Dr. Anita Rao',
      targetFacility: req.body.targetFacility || 'Palghar District Hospital',
      specialty: req.body.specialty || 'General Medicine',
      reason: req.body.reason || 'Clinical referral',
      status: 'Created',
      statusHistory: [
        { status: 'Created', timestamp, note: 'Referral raised' },
      ],
      createdAt: timestamp,
    };

    if (db) {
      await db.collection('referrals').doc(newReferral.id).set(newReferral);
    }
    localReferrals.unshift(newReferral);

    return res.status(201).json({ success: true, message: 'Referral raised successfully', data: newReferral });
  } catch (err) {
    return res.status(500).json({ success: false, error: err.message });
  }
});

// PUT /api/referrals/:id/status - Progress referral state stepper
router.put('/:id/status', async (req, res) => {
  try {
    const { id } = req.params;
    const { status, note = '' } = req.body;
    const timestamp = new Date().toISOString();

    const referral = localReferrals.find(r => r.id === id);
    if (referral) {
      referral.status = status;
      referral.statusHistory.push({ status, timestamp, note });
    }

    if (db) {
      await db.collection('referrals').doc(id).update({
        status,
        statusHistory: admin.firestore.FieldValue.arrayUnion({ status, timestamp, note }),
      }).catch(() => {});
    }

    return res.json({ success: true, message: `Referral status updated to ${status}`, data: referral });
  } catch (err) {
    return res.status(500).json({ success: false, error: err.message });
  }
});

module.exports = router;
