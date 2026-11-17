# AI Automation Engineer: Zero to Hero

A calm, offline-first Flutter learning application built to take learners—both complete beginners and experienced **n8n** builders—from zero systems knowledge to shipping reliable, observable, secure AI & automation services.

---

## What It Includes

- **Two Honest Entry Paths (`Onboarding` & `n8n Diagnostic`)**:
  - **Start from zero**: Begins cleanly at Module 1.
  - **I already use n8n**: Runs a 10-question diagnostic across HTTP/localhost, Python, FastAPI, Pydantic, RAG, LangGraph, and deployment, suggesting a starting module and weak areas **without** falsely marking skipped modules as mastered.
- **15 Modules & 186 Substantive Checkpoints**:
  - Covers Engineering Foundations, Terminal & Git, Networking/HTTP/Localhost/CORS/Docker, Python, FastAPI, LLM Fundamentals, Pydantic v2, LangChain, RAG, LangGraph, Agent Safety, n8n + Python Integration, Evals & Observability, Deployment & Cloudflare (`Tunnel`, `Access`, `DNS`, `Workers`), and Production Engineering.
  - Every checkpoint includes learning objectives, plain-English mental models, technical explanations, *When to Use* / *When NOT to Use*, worked code examples, practical exercises, common mistakes, acceptance criteria, official HTTPS docs, and scenario quizzes.
  - **10 Side-by-Side Comparison Cards** (`LangChain vs. LangGraph`, `Pydantic vs. Dicts`, `Workflow vs. Agent`, `Localhost vs. Public Host`, `Webhook vs. Polling`, `Cloudflare Tunnel vs. Hosting`, and more).
- **Explicit 3-Step Mastery Discipline**:
  - Passing a Knowledge Check does **not** automatically mark a checkpoint mastered; completion requires explicit learner confirmation after studying, passing the check, and completing the hands-on exercise.
- **4 Portfolio Capstone Guides (`Projects`)**:
  - *Support Triage Assistant*, *Document Processing Pipeline*, *Human-Approved Research Workflow*, and *n8n + Python AI Service*—with architecture diagrams, milestone checklists, test cases, rubrics, security checklists, portfolio README templates, learner GitHub URL tracking, and user-entered metric/reflection forms.
- **Learning Tools**:
  - **Engineering Dashboard** with continuation, overall confirmed mastery, weekly study target, and recent activity.
  - **Non-Locking Roadmap** with soft prerequisite explanations and module filters.
  - **Searchable Glossary (70 terms)** linking directly back to lessons.
  - **Adaptive Study Planner** calculated dynamically from remaining checkpoints and explicitly labeled as **estimates only, not guarantees**.
  - **Bookmarks & Personal Notes** plus **Global Search** across checkpoints, glossary, capstones, and learner notes.
- **Zero Backend & Portable Local Storage**:
  - Persists locally via `SharedPreferencesAsync` with schema-versioned (`schemaVersion: 1`) JSON export/import validation and explicit reset confirmation.
  - No login, paid service, or LLM API key is required to use the application.

---

## Documentation

- [Architecture Overview](docs/ARCHITECTURE.md)
- [Curriculum Specification](docs/CURRICULUM.md)

---

## Getting Started Locally

### Prerequisites

- **Flutter SDK** (`stable`, verified on Flutter `3.50.0` / Dart `^3.14.0`)
- Chrome (for running or inspecting the web app locally)

### Run & Verify

```bash
# Install packages
flutter pub get

# Check formatting & static analysis
dart format --output=none --set-exit-if-changed lib test
flutter analyze

# Run unit & widget test suite
flutter test

# Run locally in Chrome
flutter run -d chrome

# Build self-contained production web bundle (bundles CanvasKit locally, zero external CDN required)
flutter build web --release --no-web-resources-cdn
```

### Platform Status & Honesty Note

- **Verified**: All unit and widget tests (`flutter test`), static analysis (`flutter analyze`), formatting (`dart format`), production Web compilation (`flutter build web --release --no-web-resources-cdn`), and a headless Chromium boot check confirming HTTP 200 asset loading for CanvasKit and all 10 curriculum JSON files with zero runtime console errors have been executed and verified.
- **Cross-platform compatibility**: Feature/repository abstractions avoid web-only imports outside conditional `json_transfer_web.dart` so `android/` and `ios/` targets remain structurally compatible in source. Android and iOS builds were **not** executed or claimed as verified because Android/Xcode SDK toolchains are not configured in the verification environment.

---

## Progress Export & Import Schema (`schemaVersion: 1`)

Settings provides strict client-side validation when importing progress backups:

- Rejects malformed JSON, non-object payloads, missing/unsupported `schemaVersion` values, invalid weekday (`1..7`) or study-hour (`1..60`) bounds, invalid quiz score bounds, and unknown `checkpointId` / `projectId` / `moduleId` references.
- Use **Export Progress JSON** regularly before clearing browser storage or running **Reset Progress**.
