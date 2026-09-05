const express = require('express');
const router = express.Router();
const { db } = require('../config/firebase');

let localInventory = [
  { id: 'med-01', name: 'Paracetamol 500mg', category: 'Analgesic', stockCount: 450, unit: 'Tablets', status: 'In Stock' },
  { id: 'med-02', name: 'Amoxicillin 250mg', category: 'Antibiotic', stockCount: 35, unit: 'Strip', status: 'Low Stock' },
  { id: 'med-03', name: 'ORS Packets', category: 'Rehydration', stockCount: 120, unit: 'Sachets', status: 'In Stock' },
  { id: 'med-04', name: 'Iron & Folic Acid', category: 'Maternal Health', stockCount: 8, unit: 'Bottles', status: 'Critical Stock' },
  { id: 'med-05', name: 'Metformin 500mg', category: 'NCD Care', stockCount: 210, unit: 'Tablets', status: 'In Stock' }
];

let localDiagnostics = [
  { id: 'diag-01', patientId: 'pat-102', patientName: 'Ramesh Patil', testName: 'Chest X-Ray', facility: 'Palghar PHC Lab', status: 'Pending', orderedDate: '2026-09-03' },
  { id: 'diag-02', patientId: 'pat-103', patientName: 'Anandi Deshmukh', testName: 'HbA1c & Fasting Glucose', facility: 'Wada Lab', status: 'Completed', orderedDate: '2026-09-02' },
  { id: 'diag-03', patientId: 'pat-101', patientName: 'Sunita Sharma', testName: 'Hemoglobin (Hb) Screening', facility: 'CHW Mobile Kit', status: 'Completed', orderedDate: '2026-09-01' }
];

let localFollowUps = [
  { id: 'task-01', patientId: 'pat-102', patientName: 'Ramesh Patil', taskType: 'Post-Referral Vitals Check', dueDate: '2026-09-05', isCompleted: false },
  { id: 'task-02', patientId: 'pat-103', patientName: 'Anandi Deshmukh', taskType: 'Maternal ANC Second Trimester Visit', dueDate: '2026-09-06', isCompleted: false },
  { id: 'task-03', patientId: 'pat-101', patientName: 'Sunita Sharma', taskType: 'Hypertension Medication Refill', dueDate: '2026-09-08', isCompleted: true }
];

// GET /api/inventory
router.get('/inventory', (req, res) => {
  return res.json({ success: true, count: localInventory.length, data: localInventory });
});

// GET /api/diagnostics
router.get('/diagnostics', (req, res) => {
  return res.json({ success: true, count: localDiagnostics.length, data: localDiagnostics });
});

// GET /api/followups
router.get('/followups', (req, res) => {
  return res.json({ success: true, count: localFollowUps.length, data: localFollowUps });
});

// PUT /api/followups/:id/complete - Toggle task status
router.put('/followups/:id/complete', (req, res) => {
  const { id } = req.params;
  const task = localFollowUps.find(t => t.id === id);
  if (task) {
    task.isCompleted = true;
    return res.json({ success: true, message: 'Follow-up marked as completed', data: task });
  }
  return res.status(404).json({ success: false, error: 'Task not found' });
});

module.exports = router;
