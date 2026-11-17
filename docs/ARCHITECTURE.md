# Architecture Overview

**AI Automation Engineer: Zero to Hero** uses a feature-first Flutter architecture organized around explicit separation between **presentation** (`lib/features/*`), **application state & domain rules** (`lib/core/providers/*`, `lib/core/utils/*`), and **data access / persistence** (`lib/core/repositories/*`, `lib/core/models/*`).

---

## 1. Directory Layout

```text
lib/
├── main.dart                                # App entrypoint & ProviderScope bootstrap
├── app/
│   ├── app.dart                             # Root MaterialApp.router, ThemeMode wiring
│   ├── router/
│   │   ├── app_router.dart                  # GoRouter StatefulShellRoute + detail routes
│   │   └── responsive_shell.dart            # Desktop sidebar / mobile NavigationBar + Search
│   └── theme/
│       ├── app_theme.dart                   # Material 3 Light & Dark calm navy/slate themes
│       └── app_tokens.dart                  # Spacing, radii, breakpoints, AppMotion helper
├── core/
│   ├── models/
│   │   ├── curriculum_models.dart           # Immutable curriculum domain entities
│   │   └── learner_state.dart               # Versioned progress schema (v1) + import checks
│   ├── providers/
│   │   └── app_providers.dart               # Riverpod providers, ProgressSummary, Notifier
│   ├── repositories/
│   │   ├── curriculum_repository.dart         # AssetCurriculumRepository + interface
│   │   ├── key_value_store.dart             # KeyValueStore (SharedPreferencesAsync / Memory)
│   │   └── progress_repository.dart         # LocalProgressRepository + validated import/export
│   ├── utils/
│   │   ├── curriculum_validator.dart        # Structural, URL, and DAG prerequisite checks
│   │   ├── json_transfer.dart               # Conditional export (Web vs stub)
│   │   ├── json_transfer_stub.dart          # Non-web fallback
│   │   ├── json_transfer_web.dart           # Browser Blob download & file upload via package:web
│   │   ├── search_engine.dart               # Cross-entity search (lessons, glossary, notes, projects)
│   │   └── study_planner_engine.dart        # Adaptive weekly plan generator (estimates only)
│   └── widgets/
│       ├── code_snippet_card.dart           # Horizontal-scrolling code viewer with copy button
│       ├── common_widgets.dart              # Cards, error states, section wrappers
│       ├── comparison_card_widget.dart      # Side-by-side mental model comparison cards
│       └── status_badge.dart                # Explicit checkpoint mastery & difficulty badges
└── features/
    ├── bookmarks_notes/presentation/        # Saved bookmarks, note search, revisit queue
    ├── dashboard/presentation/              # Continue learning, goal summary, recent activity
    ├── glossary/presentation/               # Searchable technical & plain-English definitions
    ├── lesson/presentation/                 # Multi-section lesson view, worked code, notes, controls
    ├── onboarding/presentation/             # Entry path ("Start from zero" / "I already use n8n")
    ├── planner/presentation/                # Study budget, day picker, dynamic remaining schedule
    ├── projects/presentation/               # 4 capstones + detail rubric, metrics & GitHub links
    ├── quiz/presentation/                   # Checkpoint knowledge checks & 10-question diagnostic
    ├── roadmap/presentation/                # 15 expandable modules, soft prerequisite callouts
    └── settings/presentation/               # Theme mode, weekly hours, validated JSON backup/reset
```

---

## 2. State Management & Domain Rules

State is managed with **Riverpod 3 (`flutter_riverpod`)** without code generation:

- **`keyValueStoreProvider`**: Defaults to `SharedPreferencesAsyncStore`; overridden with `InMemoryKeyValueStore` in tests.
- **`curriculumRepositoryProvider` & `curriculumProvider`**: Loads the 10 JSON assets under `assets/curriculum/`, indexes lookup maps (`moduleById`, `checkpointById`, `checkpointsByModuleId`, `comparisonById`, `projectById`), and runs `CurriculumValidator.validate(bundle)`.
- **`progressRepositoryProvider` & `learnerStateProvider`**: Manages asynchronous loading/saving of `LearnerState` via `LearnerStateNotifier`.
- **`ProgressSummary.compute(...)`**: Derives per-module metrics, confirmed completion counts, project milestone totals, and the next recommended checkpoint without mutating stored progress.

### Explicit Integrity Guarantees

1. **No Auto-Mastery on Onboarding Diagnostic**: Choosing `"I already use n8n"` and completing the 10-question diagnostic computes `suggestedStartModuleId`, `weakModuleIds`, and `confidentModuleIds`, while leaving every prior module checkpoint at `notStarted`. Earlier modules remain openly accessible without hard locks.
2. **Knowledge Checks Do Not Equal Practical Mastery**: Passing a checkpoint quiz sets `quizPassed = true` and moves `notStarted` to `inProgress`, but `status` only becomes `completed` when the learner explicitly confirms completion after reading, quizzing, and doing the practice exercise.
3. **Time Estimates Are Non-Binding**: `StudyPlannerEngine` computes remaining study minutes from uncompleted checkpoints and labels every timeline as an **estimate only, not a guarantee**.

---

## 3. Navigation & Responsive Layout

Routing is driven by **`appRouterProvider`** (`GoRouter`):

- **Root Guard**: Initial route `/` redirects to `/onboarding` when `profile.onboardingCompleted == false`; `/onboarding` also supports exploring the dashboard immediately without erasing progress.
- **Persistent Shell Branches (`StatefulShellRoute.indexedStack`)**:
  - `/` (`DashboardScreen`)
  - `/roadmap` (`RoadmapScreen`)
  - `/projects` + `/projects/:projectId` (`ProjectsScreen` & `ProjectDetailScreen`)
  - `/planner` (`StudyPlannerScreen`)
  - `/glossary` (`GlossaryScreen`)
  - `/notes` (`BookmarksNotesScreen`)
  - `/settings` (`SettingsScreen`)
- **Full-Screen Focus Routes (`rootNavigatorKey`)**:
  - `/onboarding`
  - `/diagnostic`
  - `/lesson/:checkpointId`
  - `/quiz/:checkpointId`
- **Responsive Breakpoint**: `AppTokens.desktopBreakpoint` (`920 px`) switches cleanly between a persistent left sidebar (`_DesktopSidebar`) and a bottom `NavigationBar` with a `"More"` modal sheet on compact screens.

---

## 4. Persistence, Schema Versioning & Validation

`LearnerState` is serialized as JSON under schema version `1` (`LearnerState.currentSchemaVersion = 1`):

- Top-level keys: `schemaVersion`, `themeMode`, `profile`, `checkpointProgress`, `projectProgress`, `moduleChecklistDone`, `lastVisitedCheckpointId`, `recentActivity`.
- `LocalProgressRepository.parseAndValidateImport` verifies:
  1. Non-empty, syntactically valid JSON object.
  2. Supported integer `schemaVersion` (`1`).
  3. Valid enum values, integer bounds (`weeklyStudyHours` in `1..60`, weekday ints in `1..7`, quiz counts `0 <= correct <= total`), and ISO-8601 timestamps.
  4. Referential integrity against the active `CurriculumBundle` (`checkpointId`, `projectId`, `moduleId`, and `suggestedStartModuleId`).
- Browser builds offer `.json` file download and file upload via `package:web` (`json_transfer_web.dart`), while non-web platforms use copy/paste JSON transfer via `json_transfer_stub.dart`.

---

## 5. Accessibility & Visual Design

- Uses `package:material_ui/material_ui.dart` for Material 3 components across `AppTheme.light()` and `AppTheme.dark()` (calm navy/slate surfaces with teal primary and muted violet accents).
- `AppMotion.duration(context, ...)` respects `MediaQuery.disableAnimationsOf(context)` to zero animation durations when reduced motion is enabled.
- Code blocks wrap horizontally inside `SingleChildScrollView(scrollDirection: Axis.horizontal)` so wide snippets never cause horizontal page overflow on narrow viewports.
