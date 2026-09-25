# Antigravity Prompt — CareLink SIH26133 Orchestration Platform (Flutter + Firebase)

Paste everything below into Antigravity as the master project brief, engineering spec, and architectural directive.

---

## 1. PROJECT POSITIONING

- **App Name**: CareLink (working name — keep, do not rename)
- **SIH Problem Statement**: SIH26133 — *"Accessibility and quality of public healthcare services, particularly in rural and underserved areas"* (Govt. of Maharashtra)
- **Core Positioning**: CareLink is an **intelligent rural healthcare orchestration platform** that helps coordinate a patient's journey from initial assessment to completed care.

### Core Idea:
> *"Don't just refer the patient. Orchestrate the journey until care is completed."*

CareLink coordinates the complete healthcare delivery chain:
```
Patient ──► CHW ──► Doctor ──► Care Requirement ──► Operational Reality ──► Care Routing ──► Facility / Diagnostics / Medicine ──► Follow-up ──► Care Completion
```

**Crucial Distinction**: CareLink is **NOT** simply another telemedicine video app or static electronic medical record (EMR). It focuses on making healthcare journeys actionable, feasible, and closed-loop in real-world rural conditions.

---

## 2. CORE INNOVATION

CareLink's innovation narrative centers around four major capabilities:

1. **Operational Reality Layer**
2. **Adaptive Care Journey**
3. **Single-Trip Care Bundling**
4. **Zero-Typing Doctor Documentation**

### The Operational Orchestration Logic:
```
Doctor identifies care requirement
                │
                ▼
Voice / Manual Documentation (Zero-Typing)
                │
                ▼
What does the patient actually need? (Diagnostics, Medicines, Specialist)
                │
                ▼
Operational Reality Layer (Audits facility capabilities & resource availability)
                │
                ▼
Where can that care actually be provided?
                │
                ▼
Adaptive Care Journey (Selects optimal facility & updates route)
                │
                ▼
Can compatible requirements be combined?
                │
                ▼
Single-Trip Care Bundling (Bundles consult + labs + pharmacy into minimum visits)
                │
                ▼
Care Completion & CHW Follow-up
```

### Capability Classification Table:
| Capability | Implementation Status | Notes |
| --- | --- | --- |
| **Operational Reality Layer** | **PROTOTYPE / DEMO** | Audits facility capabilities, diagnostics stock, and specialist presence using seeded Firestore facility records (`FacilityModel`). |
| **Adaptive Care Journey** | **PROTOTYPE / DEMO** | Computes recommended routes (`AdaptiveRoutingService`) based on clinical risk and facility readiness. |
| **Single-Trip Care Bundling** | **PROTOTYPE / DEMO** | Generates bundled care plans (`MinimumTripService`) combining doctor visit, diagnostic tests, and pharmacy dispense. |
| **Zero-Typing Doctor Documentation**| **PLANNED / PROTOTYPE** | Structure and Gemini AI prompt synthesis implemented; Speech-to-Text voice recording is planned future scope. |

---

## 3. OPERATIONAL REALITY LAYER

CareLink considers real-world facility conditions before recommending or creating a care route.

### Operational Signals Evaluated:
- Required specialist availability & on-duty status
- Facility tier (PHC, Sub-District Hospital, District Hospital)
- Diagnostic test availability (ECG, CBC, X-Ray, Biochemistry)
- Essential medicine stock status (`inStock`, `low`, `outOfStock`)
- Distance & travel burden
- Clinical urgency (Emergency, Urgent, Routine)

### Signal Freshness Architecture:
- **Active Signal**: Telemetry/inventory updated within operational window.
- **Expired Signal**: Outdated inventory/duty data.
- **Corroborated Signal**: Verified across CHW reports and facility updates.

*If an operational signal is stale or expired, the system treats it as UNKNOWN rather than assuming the service is available.*

> [!NOTE]
> **MVP Demo Reality**: Uses seeded/demo Firestore facility data (`FirestorePaths.facilities`). Does not claim live integration with government hospital APIs.

---

## 4. SMART CARE ROUTING

Determines appropriate level of care based on clinical risk and operational readiness:

### Care Route Destinations:
- **A. Manage Locally** (CHW Sub-Center guidance)
- **B. Teleconsultation** (Remote specialist review)
- **C. Refer to PHC / Sub-District Hospital**
- **D. Refer to District Hospital**
- **E. Emergency Transfer** (Immediate stabilization & transport)

### Routing Formula (Deterministic Rule Engine):
$$\text{Care Route} = \text{Clinical Urgency} \times \text{Facility Capability} \times \text{Service Availability} \times \text{Travel Burden}$$

*Implemented via deterministic, rule-based algorithms (`SmartAssignmentService` & `AdaptiveRoutingService`). No fake AI model claims.*

---

## 5. ADAPTIVE CARE JOURNEY

Handles real-world bottlenecks when a planned facility becomes unsuitable:

```
Detect Facility Bottleneck (e.g., Specialist / Diagnostic Unavailable)
                │
                ▼
Identify Root Cause
                │
                ▼
Search Alternative Facilities (Matching Required Specialty & Care Readiness)
                │
                ▼
Reroute / Reschedule / Escalate
                │
                ▼
Update Care Case & Notify CHW / Patient Timeline
```

*Demonstrated in the prototype via controlled demo flows with seeded facility conditions.*

---

## 6. SINGLE-TRIP CARE BUNDLING

Attempts to coordinate compatible healthcare services at a feasible facility so that unnecessary separate journeys are minimized.

### Example Bundling Scenario:
- **Patient Needs**: Cardiology consult + ECG + CBC Blood Test + Amlodipine 5mg
- **CareLink Action**: Evaluates facility readiness, schedules diagnostic sample collection alongside doctor consultation, and prepares pharmacy kit in a **single hospital trip**.

*Implemented via `MinimumTripService.generatePlan()`. The platform aims to minimize total journeys based on timing and availability constraints.*

---

## 7. ZERO-TYPING DOCTOR DOCUMENTATION

Voice-assisted and template-driven doctor workflow to eliminate tedious paperwork:

```
Doctor Voice Input / Quick Template Selection
                │
                ▼
Speech-to-Text Conversion (Planned)
                │
                ▼
AI Structured Referral & Clinical Summary Generation (Gemini Service)
                │
                ▼
Doctor Review & Manual Verification (Mandatory Safety Check)
                │
                ▼
Final Signed Referral & Care Plan Confirmation
```

### Safety & Compliance Rules:
- **CRITICAL**: AI must **NOT** independently diagnose the patient or prescribe treatment without explicit doctor confirmation.
- The doctor **MUST** review and approve all generated notes prior to saving to Firestore.

---

## 8. CARE CASE LIFECYCLE

### Complete End-to-End Workflow:
```
Patient Registration (CHW)
           │
           ▼
Vitals & Symptoms Capture
           │
           ▼
Digital Triage & Rule-Based Risk Assessment (Low / Medium / High)
           │
           ▼
Care Case Created & Smart Doctor Assignment
           │
           ▼
Doctor Teleconsultation & Queue Review
           │
           ▼
Care Requirement Identification (Diagnostics, Medicines, Specialty)
           │
           ▼
Operational Reality Check (Facility Readiness Audit)
           │
           ▼
Smart Care Routing & Single-Trip Care Plan
           │
           ▼
Referral & Facility Acceptance
           │
           ▼
Consultation, Diagnostic & Pharmacy Execution
           │
           ▼
Automated CHW Follow-up Task
           │
           ▼
Care Case Completed (Closed Loop)
```

### Failure Recovery Sub-Workflow:
```
Care Journey Started
        │
        ▼
Unexpected Problem (Specialist unavailable / Equipment breakdown)
        │
        ▼
Failure Reason Identified
        │
   ┌────┴────┐
   ▼         ▼
  YES        NO
   │         │
   │         └─► Escalate to District Control Room / Reschedule
   ▼
New Route Recommended ──► Updated Care Journey ──► Care Completion
```

---

## 9. TECH STACK (Verified Repository Stack)

- **Frontend Framework**: Flutter 3.x (Dart 3.x null-safety)
- **State Management**: Flutter Riverpod (`flutter_riverpod`, `riverpod_annotation`)
- **Backend & Database**: Firebase Authentication, Cloud Firestore (`cloud_firestore`)
- **Local Caching & Offline Storage**: Hive (`hive`, `hive_flutter`), `shared_preferences`
- **Network Monitoring**: `connectivity_plus`
- **Charts & Dashboards**: `fl_chart`
- **AI Triage & Note Synthesis**: Google Generative AI SDK (`google_generative_ai`) called directly via client SDK for demo purposes.

*No custom Node.js backend required. Built entirely on Flutter + Firebase.*

---

## 10. CURRENT MVP CODEBASE AUDIT

Every feature in the repository is classified into one of four states:

| Feature / Module | Status | Location in Codebase |
| --- | --- | --- |
| **CHW Patient Registration** | **WORKING** | `lib/features/chw_patient/new_patient_screen.dart` |
| **Patient List & Search** | **WORKING** | `lib/features/chw_patient/patient_list_screen.dart` |
| **Digital Triage & Vitals Capture** | **WORKING** | `lib/features/chw_patient/triage_form_screen.dart` |
| **Rule-Based Risk Scoring** | **WORKING** | `lib/core/utils/risk_scoring.dart` |
| **Smart Doctor Assignment Engine** | **WORKING** | `lib/core/services/smart_assignment_service.dart` |
| **Care Case Journey Screen** | **WORKING** | `lib/features/care_orchestration/care_case_detail_screen.dart` |
| **Adaptive Care Routing Engine** | **WORKING** | `lib/core/services/adaptive_routing_service.dart` |
| **Single-Trip Care Plan Generator** | **WORKING** | `lib/core/services/minimum_trip_service.dart` |
| **Doctor Consultation Queue** | **WORKING** | `lib/features/doctor/consult_queue_screen.dart` |
| **Doctor Acceptance & Chat** | **WORKING** | `lib/features/doctor/consult_chat_screen.dart` |
| **Longitudinal Patient Timeline** | **WORKING** | `lib/features/patient_record/patient_record_screen.dart` |
| **Referral Creation & Status Stepper** | **WORKING** | `lib/features/referral/referral_detail_screen.dart` |
| **Follow-up Task Completion** | **WORKING** | `lib/features/chw_patient/follow_up_task_screen.dart` |
| **Medicine Inventory Viewing** | **WORKING / STUB** | `lib/features/inventory/medicine_stock_screen.dart` |
| **Diagnostic Test Tracker** | **WORKING / STUB** | `lib/features/diagnostics/pending_tests_screen.dart` |
| **Admin Dashboard Charts** | **WORKING** | `lib/features/admin/dashboard_screen.dart` |
| **Role-Based Switcher Banner** | **WORKING** | `lib/core/widgets/role_switcher_banner.dart` |
| **Gemini AI Note Synthesis** | **WORKING** | `lib/core/services/gemini_service.dart` |
| **Firebase Native Caching** | **WORKING** | Firestore Cache + `LocalCacheService` (Hive) |
| **Voice Speech-to-Text (STT)** | **PLANNED** | UI Structure ready; Voice SDK is future scope |
| **ABDM / ABHA Interoperability** | **PLANNED** | Static roadmap screen (`roadmap_screen.dart`) |
| **WebRTC Video Consultation** | **PLANNED** | Placeholder screen (`dummy_video_call_screen.dart`) |
| **108 Ambulance Dispatch API** | **PLANNED** | Future architecture scope |

---

## 11. MVP VS FUTURE SCOPE CLASSIFICATION

### Currently Implemented (Working Code)
- Complete patient registration, digital triage, vitals capture, and rule-based risk scoring.
- Care Case creation, Smart Doctor Assignment, and Consultation Request dispatch.
- Active doctor queue filtered by `doctorUid` with full doctor consultation acceptance and chat thread.
- Closed-loop referral status tracking stepper (`created` $\rightarrow$ `accepted` $\rightarrow$ `scheduled` $\rightarrow$ `completed`).
- Patient longitudinal medical record timeline.
- CHW follow-up task completion with Firestore state mutation.
- Interactive demo role switcher banner (CHW, Dr. Vikram Deshmukh, Dr. Rajesh Patil, Admin).

### Prototype / Demo (Seeded Logic & Simulated Capabilities)
- Facility capability auditing (`FacilityModel` seeded in Firestore).
- Single-trip care bundling recommendations (`MinimumTripService`).
- Adaptive care routing recommendations based on facility readiness scores.

### Future Scope (Planned Architecture)
- Real government ABDM / ABHA health ID protocol integration.
- Real-time hospital telemetry APIs (live ICU beds, oxygen stock, blood bank integration).
- Production-grade queue-based offline synchronization engine with multi-master conflict resolution.
- Native low-bandwidth WebRTC video consultation.
- Multilingual voice-to-text AI clinical documentation.
- Emergency 108 ambulance dispatch system integration.

---

## 12. DEMO PRIORITY SEQUENCE

To deliver an impactful demonstration during evaluation, execute this exact sequence:

1. **CHW Role**: Open CareLink as CHW (**Sunita Kamble**).
2. **Register Patient**: Register a new patient or select an existing patient.
3. **Digital Triage**: Fill in symptoms and vitals (e.g. BP, SpO₂, HR, Temp).
4. **Risk Assessment**: View rule-based risk score badge (Medium/High) and optional AI clinical note.
5. **Care Case Creation**: Tap **Open Care Case Journey (Smart Engine)**.
6. **Smart Assignment & Routing**: Inspect auto-assigned doctor (e.g. **Dr. Vikram Deshmukh**), facility care readiness status, and single-trip care plan.
7. **Role Switch**: Use **DEMO ROLE SWITCHER $\rightarrow$ Doctor $\rightarrow$ Dr. Vikram (Pulmonology)**.
8. **Doctor Queue**: Verify the new consultation request appears in Dr. Vikram's queue.
9. **Doctor Acceptance**: Open consultation, inspect vitals and triage summary, and tap **Accept**.
10. **Chat & Prescription**: Send a teleconsultation message / clinical advice.
11. **Referral Stepper**: Raise or update referral status (`scheduled` / `completed`).
12. **Follow-up & Completion**: Switch back to CHW, view updated Patient Timeline, and mark follow-up task as **Completed**.

---

## 13. ENGINEERING RULES & GUIDELINES

- **Preserve Working Features**: Never break existing navigation, Firestore schemas, or working screens.
- **Strict UI Cleanliness**: Zero blank white cards, zero RenderFlex overflow bugs, zero dead-end buttons.
- **Single Source of Truth**: Always use doctor UID (`doctorUid`) rather than string names for querying queues and updating cases.
- **Honest Claims**: Clearly differentiate between working code, seeded prototype demonstrations, and future roadmap items.
