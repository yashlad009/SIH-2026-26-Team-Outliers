# CareLink

> An intelligent rural healthcare coordination platform that helps coordinate a patient's journey from first assessment to completed care.

[![SIH 2026](https://img.shields.io/badge/SIH-2026-blue.svg)](https://sih.gov.in)
[![Problem Statement](https://img.shields.io/badge/Problem%20Statement-SIH26133-orange.svg)](https://sih.gov.in)
[![Flutter](https://img.shields.io/badge/Flutter-3.x-02569B?logo=flutter)](https://flutter.dev)
[![Firebase](https://img.shields.io/badge/Firebase-Firestore-FFCA28?logo=firebase)](https://firebase.google.com)

---

## Problem

Public healthcare delivery in rural and underserved areas faces significant structural challenges:

- **Long Travel Distances**: Rural patients often travel tens of kilometers over difficult terrain to reach primary or secondary healthcare centers without knowing if services are available.
- **Fragmented Medical Records**: Paper-based records and disconnected health registers lead to lost medical history during transfers.
- **High Referral Drop-offs**: Patients frequently drop out between primary health centers (PHCs) and district hospitals due to confusion, costs, or past negative experiences.
- **Resource Mismatches**: Patients arrive at facilities only to find that required specialists, diagnostic equipment, or essential medicines are currently unavailable.
- **Weak Follow-up Tracking**: Community Health Workers (CHWs / ASHAs) lack structured tools to track post-consultation care plans and medication compliance.
- **Intermittent Connectivity**: Rural health outposts suffer from unstable mobile network access, rendering traditional online-only systems unreliable.

---

## Our Solution

**CareLink** is a CHW-first healthcare coordination platform designed for rural health ecosystems. Instead of functioning solely as a teleconsultation video tool, CareLink focuses on closing the loop on patient care journeys across levels of care.

```
[ Patient ] ──► [ CHW / ASHA ] ──► [ Teleconsult Doctor ] ──► [ Referral Facility ] ──► [ Community Follow-up ]
```

CareLink equips CHWs at the sub-center level with digital triage, structured vitals capture, doctor consultation dispatch, and automated follow-up tracking, ensuring that every patient referral is actionable and executable.

---

## Key Features

### Currently Demonstrated Prototype

The current CareLink codebase includes a working prototype demonstrator with the following operational features:

- **CHW Patient Registration**: Register new patients with demographic details, contact info, blood group, and chronic condition history.
- **Patient Search & Filtering**: Real-time search across patient name, village, and contact details.
- **Digital Triage & Risk Scoring**: Capture vital signs (BP, SpO₂, Heart Rate, Temperature, Respiratory Rate) and chief complaints. Computes a rule-based risk score (Low, Medium, High).
- **Care Case Orchestration**: Automatically links triage assessments into an active Care Case journey with recommended doctor specialties and diagnostic requirements.
- **Doctor Consultation Requests**: CHWs can send teleconsultation requests linked to specific patient care cases.
- **Doctor Queue & Acceptance**: On-duty doctors can view assigned pending consultation requests, inspect triage reports, and accept cases.
- **Asynchronous Chat**: In-app messaging between CHWs and Doctors for teleconsultation discussion, clinical notes, and advice.
- **Patient Medical Timeline**: Centralized chronological history showing triage events, consultations, referrals, diagnostic tests, and follow-up tasks.
- **Referral Creation & Status Tracking**: Doctors and CHWs can raise facility referrals and track status progression (`created` → `accepted` → `scheduled` → `completed`).
- **Follow-up Task Management**: CHWs can view, complete, and track post-consultation follow-up tasks.
- **Medicine Stock & Diagnostics Viewing**: View facility inventory status (`inStock`, `low`, `outOfStock`) and diagnostic test orders.
- **Role-Based Demo Switcher**: Interactive role switcher allowing instant switching between CHW, Doctor (Dr. Vikram Deshmukh / Dr. Rajesh Patil), and Control Room admin views.
- **AI Clinical Note Synthesis (Optional)**: Optional integration with the Gemini API to generate structured clinical summary notes from triage data when configured.

### Planned / Future Scope (Not in Current Build)

The following capabilities represent conceptual directions and future architecture for full production deployment:
- Real-time IoT sensor integration for automated vitals capture.
- Real-time live facility telemetry (live bed availability, blood bank stock APIs).
- Production-grade offline sync engine with conflict resolution.
- ABDM / ABHA health ID protocol integration.
- Native WebRTC live video consultation.
- Automated emergency transport & ambulance dispatch routing.

---

## Innovation / USP

> *"CareLink moves beyond simply creating a referral by aiming to coordinate whether the next step of care is actually feasible."*

CareLink introduces structural concepts tailored for rural health logistics:

1. **Operational Reality Layer** *(Prototype Direction)*: Evaluates whether a target facility currently possesses the necessary operational capacity (specialist presence, diagnostic tools, medication stock) before confirming a route.
2. **Adaptive Care Journey**: Dynamically adjusts care plans based on patient risk tier and facility readiness, minimizing unnecessary travel.
3. **Single-Trip Care Bundling**: Aims to combine doctor consultations, lab tests, and pharmacy dispenses into a single hospital visit to reduce patient travel frequency.
4. **Zero-Typing Doctor Workflows**: Enables doctors to quickly review structured triage data, select template advisories, and approve care plans with minimal friction.

---

## Workflow

```
       +--------------------+
       |   Rural Patient    |
       +---------+----------+
                 |
                 v
   +----------------------------+
   |  CHW / ASHA Registration   |
   +-------------+--------------+
                 |
                 v
   +----------------------------+
   |  Vitals & Symptoms Capture |
   +-------------+--------------+
                 |
                 v
   +----------------------------+
   | Digital Triage & Risk Score|
   +-------------+--------------+
                 |
                 v
   +----------------------------+
   | Doctor Teleconsult Request |
   +-------------+--------------+
                 |
                 v
   +----------------------------+
   | Doctor Review & Acceptance |
   +-------------+--------------+
                 |
                 v
   +----------------------------+
   | Referral & Advice Issuance |
   +-------------+--------------+
                 |
                 v
   +----------------------------+
   | CHW Follow-up & Task Done  |
   +----------------------------+
```

---

## Tech Stack

The CareLink prototype is built using the following technologies:

| Layer | Technology |
| --- | --- |
| **Frontend Framework** | Flutter 3.x (Dart 3.x) |
| **State Management** | Flutter Riverpod (`flutter_riverpod`, `riverpod_annotation`) |
| **Database & Auth** | Firebase Authentication, Cloud Firestore (`cloud_firestore`) |
| **Local Storage / Caching** | Hive (`hive`, `hive_flutter`), `shared_preferences` |
| **Network Monitoring** | `connectivity_plus` |
| **Data Visualization** | `fl_chart` |
| **AI Integration** | Google Generative AI SDK (`google_generative_ai`) |


---

## Limitations

- **Prototype Scope**: Designed as an evaluation prototype for SIH 2026. Facility availability, inventory levels, and doctor schedules currently rely on seeded demo data.
- **Connectivity Model**: Basic local caching is supported via Hive, but full background conflict-handling offline sync requires production server infrastructure.
- **Hardware Integration**: Medical vitals are currently entered manually by the CHW rather than streamed directly from Bluetooth medical devices.

---

## Future Scope

- **ABDM / ABHA Integration**: Alignment with Ayushman Bharat Digital Mission standards for health ID creation and longitudinal record sharing.
- **Real-time Facility Telemetry**: Live APIs linking district hospital inventory systems, blood banks, and ICU bed management software.
- **Adaptive Routing Engine**: Algorithmic routing considering road conditions, public transit schedules, and facility load.
- **Production Offline Synchronization**: Robust queue-based offline storage for remote tribal regions.
- **WebRTC Video Consultations**: Integrated low-bandwidth video calling between CHWs and doctors.
- **Multilingual Voice Assistant**: Regional language voice prompts for CHWs during field triage.
- **Emergency Transport Integration**: Direct integration with 108 ambulance dispatch systems.

---

## Team

**Team Outliers** — *Smart India Hackathon (SIH) 2026*  
Problem Statement ID: **SIH26133**  
Theme: *Accessibility and Quality of Public Healthcare Services, particularly in rural and underserved areas*
