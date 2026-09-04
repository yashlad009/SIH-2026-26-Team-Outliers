const express = require('express');
const router = express.Router();
const { db } = require('../config/firebase');

let localConsults = [
  {
    id: 'consult-201',
    patientId: 'pat-102',
    patientName: 'Ramesh Patil',
    chwName: 'Priya Shinde (CHW)',
    doctorName: 'Dr. Anita Rao',
    status: 'Accepted',
    chiefComplaint: 'High fever 101.4F, breathlessness, SpO2 91%',
    triageRisk: 'High',
    createdAt: '2026-09-04T08:30:00.000Z',
    messages: [
      { sender: 'Priya Shinde (CHW)', text: 'Doctor, patient Ramesh has SpO2 91% and high fever.', timestamp: '2026-09-04T08:31:00.000Z' },
      { sender: 'Dr. Anita Rao', text: 'Administer oxygen, I am initiating a referral to Palghar District Hospital.', timestamp: '2026-09-04T08:33:00.000Z' },
    ]
  },
  {
    id: 'consult-202',
    patientId: 'pat-103',
    patientName: 'Anandi Deshmukh',
    chwName: 'Priya Shinde (CHW)',
    doctorName: null,
    status: 'Pending',
    chiefComplaint: 'Elevated Blood Pressure 132/86, persistent dizziness',
    triageRisk: 'Medium',
    createdAt: '2026-09-04T09:15:00.000Z',
    messages: []
  }
];

// GET /api/consults - Fetch active consult queue
router.get('/', async (req, res) => {
  try {
    if (db) {
      const snapshot = await db.collection('consult_requests').get();
      if (!snapshot.empty) {
        const consults = snapshot.docs.map(doc => ({ id: doc.id, ...doc.data() }));
        return res.json({ success: true, count: consults.length, data: consults });
      }
    }
    return res.json({ success: true, count: localConsults.length, data: localConsults });
  } catch (err) {
    return res.json({ success: true, count: localConsults.length, data: localConsults });
  }
});

// POST /api/consults - Create teleconsult request
router.post('/', async (req, res) => {
  try {
    const newConsult = {
      id: `consult-${Date.now()}`,
      patientId: req.body.patientId || 'pat-101',
      patientName: req.body.patientName || 'Sunita Sharma',
      chwName: req.body.chwName || 'CHW Worker',
      doctorName: null,
      status: 'Pending',
      chiefComplaint: req.body.chiefComplaint || 'Vitals review requested',
      triageRisk: req.body.triageRisk || 'Medium',
      createdAt: new Date().toISOString(),
      messages: [],
    };

    if (db) {
      await db.collection('consult_requests').doc(newConsult.id).set(newConsult);
    }
    localConsults.unshift(newConsult);

    return res.status(201).json({ success: true, message: 'Consult request submitted', data: newConsult });
  } catch (err) {
    return res.status(500).json({ success: false, error: err.message });
  }
});

// PUT /api/consults/:id/accept - Doctor accepts consult
router.put('/:id/accept', async (req, res) => {
  try {
    const { id } = req.params;
    const { doctorName = 'Dr. Anita Rao' } = req.body;

    if (db) {
      await db.collection('consult_requests').doc(id).update({
        status: 'Accepted',
        doctorName,
        acceptedAt: new Date().toISOString(),
      }).catch(() => {});
    }

    const consult = localConsults.find(c => c.id === id);
    if (consult) {
      consult.status = 'Accepted';
      consult.doctorName = doctorName;
    }

    return res.json({ success: true, message: 'Consult request accepted', data: consult });
  } catch (err) {
    return res.status(500).json({ success: false, error: err.message });
  }
});

// POST /api/consults/:id/messages - Send message in consult chat thread
router.post('/:id/messages', async (req, res) => {
  try {
    const { id } = req.params;
    const { sender, text } = req.body;
    
    const messageObj = {
      sender: sender || 'User',
      text: text || '',
      timestamp: new Date().toISOString(),
    };

    const consult = localConsults.find(c => c.id === id);
    if (consult) {
      consult.messages.push(messageObj);
    }

    return res.json({ success: true, message: 'Message sent', data: messageObj });
  } catch (err) {
    return res.status(500).json({ success: false, error: err.message });
  }
});

module.exports = router;
