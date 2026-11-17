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

## Try Live (No Local Setup Needed)

- **Live Web App (GitHub Pages)**: [https://zyadwaled780-cmd.github.io/project-1/](https://zyadwaled780-cmd.github.io/project-1/)

---

## Documentation

- [Architecture Overview](docs/ARCHITECTURE.md)
- [Curriculum Specification](docs/CURRICULUM.md)

---

## Getting Started Locally

### Prerequisites

- **Flutter SDK**:
  - **Web / Desktop / Tests**: `Dart >=3.10.0 <4.0.0` (verified with Flutter `3.50.0` / Dart `3.14.0`, and dependency-compatible with Flutter `3.41+` / Dart `3.11.5`)
  - **Local Android builds**: Flutter `3.44+` / `3.50.0` + Android Studio / Android SDK + JDK 17 or 21 (`android/` uses AGP `9.3.1` and Gradle `9.5.0`; if `flutter --version` on Windows shows Dart `3.11.5` / Flutter `3.41.x`, run `flutter upgrade` first or download the CI-built APK below)
- Google Chrome (for running or inspecting the web app locally)

### Run & Verify

```bash
# Clone into a regular user directory (avoid C:\WINDOWS\system32 on Windows)
git clone https://github.com/zyadwaled780-cmd/project-1.git
cd project-1

# Install packages (if switching across Dart versions, run `flutter pub upgrade`
# if pub asks to refresh pubspec.lock)
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

### Install on Android Phone or Tablet

#### Option A: Build & Install via Local Android Studio + Android SDK (Windows)

```powershell
# 1. Verify Android Studio, Android SDK, licenses, and JDK
flutter doctor -v

# Accept any pending Android SDK licenses if prompted
flutter doctor --android-licenses

# Ensure Flutter >= 3.44 / 3.50.0 so AGP 9.3.1 & Gradle 9.5.0 match android/
flutter upgrade

# 2. Enable Developer Options -> USB Debugging on your phone/tablet, plug in via USB, and check:
flutter devices
adb devices

# 3. Build universal release APK (supports both 32-bit/64-bit ARM phones and tablets)
flutter pub get
flutter build apk --release

# 4. Install onto a connected device (use `adb -s <serial> install -r ...` if multiple devices are attached)
adb install -r build\app\outputs\flutter-apk\app-release.apk
```

> **Note on release signing**: `android/app/build.gradle.kts` configures `release` builds with the debug signing key (`signingConfigs.getByName("debug")`) so local and CI sideloaded APKs install smoothly on personal devices. Replace this with your own keystore before Play Store distribution.

#### Option B: Download Prebuilt APK from GitHub Actions

1. Open [GitHub Actions](https://github.com/zyadwaled780-cmd/project-1/actions) and select the latest green **CI** workflow run.
2. Under **Artifacts**, download **`ai-automation-hero-android-apk`**.
3. Extract `app-release.apk` and either transfer it to your phone/tablet to install directly or run `adb install -r app-release.apk`.

#### Option C: Zero-Install Browser / PWA App (No USB or SDK Needed)

- Open [https://zyadwaled780-cmd.github.io/project-1/](https://zyadwaled780-cmd.github.io/project-1/) in Chrome, Edge, or Samsung Internet on your phone or tablet and choose **Install app** / **Add to Home screen**.

### Platform Status & Honesty Note

- **Verified in Linux VM (`Flutter 3.50.0`)**: Formatting (`dart format`), static analysis (`flutter analyze`), all unit and widget tests (`flutter test`), production Web build (`flutter build web --release --no-web-resources-cdn`), and headless Chromium local boot check.
- **Verified in GitHub Actions (`ubuntu-latest`, `Flutter 3.50.0` + JDK 21)**: Full check suite, live GitHub Pages deployment, and release Android APK compilation (`flutter build apk --release`, `app-release.apk`).
- **Not executed in CI / remote VM**: iOS builds (macOS/Xcode required), direct Windows `Dart 3.11.5` execution on your local machine, and physical on-device manual testing on Honor 50 Lite or Galaxy Tab A7 hardware.

---

## Progress Export & Import Schema (`schemaVersion: 1`)

Settings provides strict client-side validation when importing progress backups:

- Rejects malformed JSON, non-object payloads, missing/unsupported `schemaVersion` values, invalid weekday (`1..7`) or study-hour (`1..60`) bounds, invalid quiz score bounds, and unknown `checkpointId` / `projectId` / `moduleId` references.
- Use **Export Progress JSON** regularly before clearing browser storage or running **Reset Progress**.
