# Antigravity Prompt — SIH26133 MVP (Flutter + Firebase)

Paste everything below into Antigravity as the project brief / system prompt.

---

## PROJECT BRIEF

You are implementing an MVP Flutter app called **CareLink** (working name — keep, don't rename)
for Smart India Hackathon problem statement SIH26133: "Accessibility and quality of public
healthcare services, particularly in rural and underserved areas" (Govt. of Maharashtra).

Positioning: this is NOT a video-calling app. It is a **closed-loop rural healthcare
coordination platform** connecting Patient → Community Health Worker (CHW) → Doctor → Referral
Hospital, with a unified patient record following the patient across every visit.

Time budget: this must be demo-ready in ~36–40 hours. Prioritize a working end-to-end flow
over feature breadth. Every screen must be reachable and clickable in the demo — no dead ends.

## TECH STACK (fixed — do not deviate)

- Flutter (stable channel), Dart null-safety
- State management: Riverpod
- Backend: Firebase — Firestore (data), Firebase Auth (email/password + role claim),
  Cloud Functions (only if trivial; otherwise do logic client-side to save time)
- Local cache/offline banner: `hive` + `connectivity_plus`
- Charts (admin dashboard): `fl_chart`
- AI triage assist: Gemini API (`google_generative_ai` package) called client-side with a
  server-held API key proxy is out of scope for MVP — call directly from client with the key
  in `--dart-define`, flagged clearly as "for demo only, move to backend post-hackathon"
- No native platform channels, no custom backend server. Firebase only.

## ROLES (single app, role-based routing after login)

1. **CHW/Patient** (combined for MVP — CHW logs in and enters on behalf of patient)
2. **Doctor**
3. **Admin** (PHC/District dashboard)

Seed 3 demo accounts on first run via a `seed_data.dart` script: one per role, plus ~6 fake
patient records with realistic Marathi-region names, vitals, and a mix of referral statuses so
the dashboard and referral tracker are never empty during the demo.

## MUST-BUILD PILLARS (real, working, wired to Firestore)

1. **Assisted Teleconsultation request flow** — CHW creates a consult request for a patient →
   appears in Doctor's queue → Doctor can view vitals + accept → simple in-app chat thread
   (Firestore-backed, not real video/WebRTC — a "Start Video Call" button can be a visual
   placeholder that opens a dummy call screen)
2. **Digital Triage** — CHW fills a symptom + vitals form → rule-based scoring
   (temp/BP/SpO2/age thresholds) produces Low/Medium/High risk badge → optionally call Gemini
   to generate a one-line clinical note explaining the score (label clearly as "AI-assisted,
   not diagnostic")
3. **Longitudinal Patient Record** — single scrollable timeline per patient: visits, vitals,
   prescriptions, referrals, follow-ups, newest first, with filter chips by type
4. **Referral Tracking (closed loop)** — Doctor raises a referral to Rural/District Hospital →
   status stepper: Created → Accepted → Scheduled → Completed / Dropped → visible to CHW,
   Doctor, and Admin with timestamped status history

## STUB PILLARS (static/seeded UI, no real backend logic needed — but must look finished)

5. Medicine inventory — a facility stock table (In Stock / Low / Out) pulled from a seeded
   Firestore collection, read-only
6. Diagnostic coordination — a "Pending Tests" list per patient, status badges only
7. High-risk follow-up scheduler — a task list (maternal/child/NCD) with due dates, seeded,
   checkbox to mark done (writes to Firestore so it feels real)
8. Admin/Facility dashboard — `fl_chart` bar/line charts from the seeded dataset: case volume,
   active referrals, triage risk distribution, stock levels
9. Multilingual toggle — EN/Marathi string swap via `easy_localization` or a simple map, applied
   to at least the login screen, triage form, and patient record header (breadth of coverage
   matters less than it visibly working)

## NON-NEGOTIABLE DEMO POLISH

- Connectivity-status banner (online/offline) using `connectivity_plus`, even if actual
  offline-write-queueing isn't fully implemented — cache last-viewed patient record via Hive
  so the app doesn't go blank offline
- Consistent color system: teal/blue for clinical trust, red/amber/green strictly reserved for
  triage risk levels (don't reuse elsewhere)
- Empty states and loading states on every screen — never a raw error or blank white screen
- App must run with `flutter run` with zero manual Firebase console steps beyond dropping in
  `google-services.json` / `GoogleService-Info.plist`

## OUT OF SCOPE — do not build

- Real WebRTC/video calling
- Real ABDM/ABHA/FHIR integration (mention it in a "Roadmap" screen instead, as a static list)
- Payment/billing
- Push notifications
- Full i18n coverage of every string

---

## DIRECTORY STRUCTURE

```
carelink/
├── android/
├── ios/
├── lib/
│   ├── main.dart
│   ├── app.dart                          # MaterialApp, routing, theme
│   ├── firebase_options.dart             # generated by flutterfire configure
│   │
│   ├── core/
│   │   ├── constants/
│   │   │   ├── app_colors.dart
│   │   │   ├── app_strings_en.dart
│   │   │   ├── app_strings_mr.dart
│   │   │   └── firestore_paths.dart      # collection/doc path constants
│   │   ├── theme/
│   │   │   └── app_theme.dart
│   │   ├── utils/
│   │   │   ├── risk_scoring.dart         # rule-based triage scoring logic
│   │   │   ├── date_formatters.dart
│   │   │   └── validators.dart
│   │   ├── services/
│   │   │   ├── connectivity_service.dart
│   │   │   ├── local_cache_service.dart  # Hive wrapper
│   │   │   ├── gemini_service.dart       # AI triage note generation
│   │   │   └── auth_service.dart
│   │   └── widgets/                      # shared, reused across roles
│   │       ├── risk_badge.dart
│   │       ├── status_stepper.dart       # referral closed-loop stepper
│   │       ├── empty_state.dart
│   │       ├── loading_state.dart
│   │       ├── connectivity_banner.dart
│   │       └── app_scaffold.dart
│   │
│   ├── models/
│   │   ├── user_model.dart               # role: chw | doctor | admin
│   │   ├── patient_model.dart
│   │   ├── vitals_model.dart
│   │   ├── triage_result_model.dart
│   │   ├── consult_request_model.dart
│   │   ├── referral_model.dart           # status enum + history list
│   │   ├── medicine_stock_model.dart
│   │   ├── diagnostic_test_model.dart
│   │   └── follow_up_task_model.dart
│   │
│   ├── data/
│   │   ├── repositories/
│   │   │   ├── patient_repository.dart
│   │   │   ├── consult_repository.dart
│   │   │   ├── referral_repository.dart
│   │   │   ├── inventory_repository.dart
│   │   │   ├── diagnostic_repository.dart
│   │   │   └── follow_up_repository.dart
│   │   └── seed/
│   │       └── seed_data.dart            # run once to populate demo Firestore data
│   │
│   ├── providers/                        # Riverpod providers, one file per feature
│   │   ├── auth_provider.dart
│   │   ├── patient_provider.dart
│   │   ├── triage_provider.dart
│   │   ├── consult_provider.dart
│   │   ├── referral_provider.dart
│   │   ├── inventory_provider.dart
│   │   ├── dashboard_provider.dart
│   │   └── locale_provider.dart
│   │
│   └── features/
│       ├── auth/
│       │   └── login_screen.dart
│       │
│       ├── chw_patient/                  # CHW-facing role
│       │   ├── home_screen.dart
│       │   ├── patient_list_screen.dart
│       │   ├── new_patient_screen.dart
│       │   ├── triage_form_screen.dart
│       │   ├── consult_request_screen.dart
│       │   └── follow_up_task_screen.dart
│       │
│       ├── doctor/
│       │   ├── home_screen.dart
│       │   ├── consult_queue_screen.dart
│       │   ├── consult_chat_screen.dart
│       │   ├── dummy_video_call_screen.dart
│       │   └── raise_referral_screen.dart
│       │
│       ├── patient_record/               # shared across roles
│       │   ├── patient_record_screen.dart   # the longitudinal timeline
│       │   └── timeline_tile.dart
│       │
│       ├── referral/                     # shared, role-aware
│       │   ├── referral_detail_screen.dart
│       │   └── referral_list_screen.dart
│       │
│       ├── inventory/
│       │   └── medicine_stock_screen.dart
│       │
│       ├── diagnostics/
│       │   └── pending_tests_screen.dart
│       │
│       ├── admin/
│       │   ├── dashboard_screen.dart
│       │   ├── charts/
│       │   │   ├── case_volume_chart.dart
│       │   │   ├── referral_status_chart.dart
│       │   │   ├── triage_distribution_chart.dart
│       │   │   └── stock_level_chart.dart
│       │   └── roadmap_screen.dart       # static "coming next" — ABDM/FHIR, offline sync etc.
│       │
│       └── settings/
│           └── settings_screen.dart      # language toggle lives here
│
├── assets/
│   ├── images/
│   ├── icons/
│   └── translations/                     # if using easy_localization: en.json, mr.json
│
├── test/
│   └── core/
│       └── risk_scoring_test.dart        # at least one unit test — judges may ask
│
├── pubspec.yaml
└── firebase.json
```

## BUILD ORDER (so there's always a demoable app, even if time runs out)

1. Firebase setup + auth + role routing + seed data script
2. Patient record timeline (static read from seeded data) — this alone is demo-worthy
3. Triage form + risk scoring + risk badge
4. Consult request flow (CHW → Doctor queue → accept)
5. Referral closed-loop stepper
6. Admin dashboard charts
7. Stub screens (inventory, diagnostics, follow-up) — copy-paste UI patterns from step 2/3
8. Connectivity banner, Hive caching, language toggle, polish pass

Stop and demo with whatever is done after step 6 if time is short — steps 7–8 are polish, not
core story.
