import 'package:flutter/foundation.dart';

enum EntryPath {
  zero,
  n8nUser;

  static EntryPath fromString(String value) {
    return switch (value) {
      'zero' => EntryPath.zero,
      'n8nUser' => EntryPath.n8nUser,
      _ => throw FormatException('Invalid entryPath: $value'),
    };
  }
}

enum CheckpointStatus {
  notStarted('Not started'),
  inProgress('In progress'),
  completed('Completed');

  const CheckpointStatus(this.label);
  final String label;

  static CheckpointStatus fromString(String value) {
    return switch (value) {
      'notStarted' => CheckpointStatus.notStarted,
      'inProgress' => CheckpointStatus.inProgress,
      'completed' => CheckpointStatus.completed,
      _ => throw FormatException('Invalid checkpoint status: $value'),
    };
  }
}

enum AppThemeSetting {
  system('System'),
  light('Light'),
  dark('Dark');

  const AppThemeSetting(this.label);
  final String label;

  static AppThemeSetting fromString(String value) {
    return switch (value) {
      'system' => AppThemeSetting.system,
      'light' => AppThemeSetting.light,
      'dark' => AppThemeSetting.dark,
      _ => throw FormatException('Invalid themeMode: $value'),
    };
  }
}

@immutable
class QuizAttemptRecord {
  const QuizAttemptRecord({
    required this.id,
    required this.targetId,
    required this.attemptedAt,
    required this.correctCount,
    required this.totalCount,
    required this.selectedOptionByQuestion,
  });

  final String id;
  final String targetId;
  final DateTime attemptedAt;
  final int correctCount;
  final int totalCount;
  final Map<String, String> selectedOptionByQuestion;

  double get scoreRatio => totalCount <= 0 ? 0 : correctCount / totalCount;
  int get percentage => (scoreRatio * 100).round();
  bool get passed => totalCount > 0 && scoreRatio >= 0.7;

  factory QuizAttemptRecord.fromJson(Map<String, dynamic> json) {
    final correct = json['correctCount'];
    final total = json['totalCount'];
    if (correct is! int ||
        total is! int ||
        total < 0 ||
        correct < 0 ||
        correct > total) {
      throw const FormatException('Invalid quiz attempt counts');
    }
    final rawSelected = json['selectedOptionByQuestion'];
    if (rawSelected is! Map) {
      throw const FormatException('Invalid selectedOptionByQuestion map');
    }
    return QuizAttemptRecord(
      id: _reqStr(json, 'id'),
      targetId: _reqStr(json, 'targetId'),
      attemptedAt: DateTime.parse(_reqStr(json, 'attemptedAt')),
      correctCount: correct,
      totalCount: total,
      selectedOptionByQuestion: rawSelected.map(
        (k, v) => MapEntry(k.toString(), v.toString()),
      ),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'targetId': targetId,
    'attemptedAt': attemptedAt.toUtc().toIso8601String(),
    'correctCount': correctCount,
    'totalCount': totalCount,
    'selectedOptionByQuestion': selectedOptionByQuestion,
  };
}

@immutable
class CheckpointProgress {
  const CheckpointProgress({
    required this.checkpointId,
    this.status = CheckpointStatus.notStarted,
    this.lessonRead = false,
    this.quizPassed = false,
    this.practiceCompleted = false,
    this.isBookmarked = false,
    this.needsRevisit = false,
    this.note = '',
    this.completedAt,
    this.lastUpdatedAt,
    this.quizAttempts = const [],
  });

  final String checkpointId;
  final CheckpointStatus status;
  final bool lessonRead;
  final bool quizPassed;
  final bool practiceCompleted;
  final bool isBookmarked;
  final bool needsRevisit;
  final String note;
  final DateTime? completedAt;
  final DateTime? lastUpdatedAt;
  final List<QuizAttemptRecord> quizAttempts;

  int get completedPillars =>
      (lessonRead ? 1 : 0) + (quizPassed ? 1 : 0) + (practiceCompleted ? 1 : 0);

  QuizAttemptRecord? get latestAttempt =>
      quizAttempts.isEmpty ? null : quizAttempts.last;

  int? get bestScorePercent {
    if (quizAttempts.isEmpty) return null;
    return quizAttempts
        .map((a) => a.percentage)
        .reduce((a, b) => a > b ? a : b);
  }

  CheckpointProgress copyWith({
    CheckpointStatus? status,
    bool? lessonRead,
    bool? quizPassed,
    bool? practiceCompleted,
    bool? isBookmarked,
    bool? needsRevisit,
    String? note,
    DateTime? completedAt,
    bool clearCompletedAt = false,
    DateTime? lastUpdatedAt,
    List<QuizAttemptRecord>? quizAttempts,
  }) {
    return CheckpointProgress(
      checkpointId: checkpointId,
      status: status ?? this.status,
      lessonRead: lessonRead ?? this.lessonRead,
      quizPassed: quizPassed ?? this.quizPassed,
      practiceCompleted: practiceCompleted ?? this.practiceCompleted,
      isBookmarked: isBookmarked ?? this.isBookmarked,
      needsRevisit: needsRevisit ?? this.needsRevisit,
      note: note ?? this.note,
      completedAt: clearCompletedAt ? null : (completedAt ?? this.completedAt),
      lastUpdatedAt: lastUpdatedAt ?? this.lastUpdatedAt,
      quizAttempts: quizAttempts ?? this.quizAttempts,
    );
  }

  factory CheckpointProgress.fromJson(Map<String, dynamic> json) {
    final attemptsRaw = json['quizAttempts'];
    if (attemptsRaw != null && attemptsRaw is! List) {
      throw const FormatException('quizAttempts must be a list');
    }
    return CheckpointProgress(
      checkpointId: _reqStr(json, 'checkpointId'),
      status: CheckpointStatus.fromString(_reqStr(json, 'status')),
      lessonRead: _reqBool(json, 'lessonRead'),
      quizPassed: _reqBool(json, 'quizPassed'),
      practiceCompleted: _reqBool(json, 'practiceCompleted'),
      isBookmarked: _reqBool(json, 'isBookmarked'),
      needsRevisit: json['needsRevisit'] as bool? ?? false,
      note: json['note'] as String? ?? '',
      completedAt: json['completedAt'] == null
          ? null
          : DateTime.parse(json['completedAt'] as String),
      lastUpdatedAt: json['lastUpdatedAt'] == null
          ? null
          : DateTime.parse(json['lastUpdatedAt'] as String),
      quizAttempts: (attemptsRaw as List? ?? const [])
          .map(
            (e) =>
                QuizAttemptRecord.fromJson(Map<String, dynamic>.from(e as Map)),
          )
          .toList(growable: false),
    );
  }

  Map<String, dynamic> toJson() => {
    'checkpointId': checkpointId,
    'status': status.name,
    'lessonRead': lessonRead,
    'quizPassed': quizPassed,
    'practiceCompleted': practiceCompleted,
    'isBookmarked': isBookmarked,
    'needsRevisit': needsRevisit,
    'note': note,
    'completedAt': completedAt?.toUtc().toIso8601String(),
    'lastUpdatedAt': lastUpdatedAt?.toUtc().toIso8601String(),
    'quizAttempts': quizAttempts.map((e) => e.toJson()).toList(growable: false),
  };
}

@immutable
class ProjectProgress {
  const ProjectProgress({
    required this.projectId,
    this.completedMilestoneIds = const [],
    this.completedSecurityChecks = const [],
    this.githubRepoUrl = '',
    this.recordedMetrics = const {},
    this.reflectionNotes = '',
    this.lastUpdatedAt,
  });

  final String projectId;
  final List<String> completedMilestoneIds;
  final List<String> completedSecurityChecks;
  final String githubRepoUrl;
  final Map<String, String> recordedMetrics;
  final String reflectionNotes;
  final DateTime? lastUpdatedAt;

  ProjectProgress copyWith({
    List<String>? completedMilestoneIds,
    List<String>? completedSecurityChecks,
    String? githubRepoUrl,
    Map<String, String>? recordedMetrics,
    String? reflectionNotes,
    DateTime? lastUpdatedAt,
  }) {
    return ProjectProgress(
      projectId: projectId,
      completedMilestoneIds:
          completedMilestoneIds ?? this.completedMilestoneIds,
      completedSecurityChecks:
          completedSecurityChecks ?? this.completedSecurityChecks,
      githubRepoUrl: githubRepoUrl ?? this.githubRepoUrl,
      recordedMetrics: recordedMetrics ?? this.recordedMetrics,
      reflectionNotes: reflectionNotes ?? this.reflectionNotes,
      lastUpdatedAt: lastUpdatedAt ?? this.lastUpdatedAt,
    );
  }

  factory ProjectProgress.fromJson(Map<String, dynamic> json) {
    final metricsRaw = json['recordedMetrics'];
    if (metricsRaw != null && metricsRaw is! Map) {
      throw const FormatException('recordedMetrics must be an object');
    }
    return ProjectProgress(
      projectId: _reqStr(json, 'projectId'),
      completedMilestoneIds: _strList(json['completedMilestoneIds']),
      completedSecurityChecks: _strList(json['completedSecurityChecks']),
      githubRepoUrl: json['githubRepoUrl'] as String? ?? '',
      recordedMetrics: (metricsRaw as Map? ?? const {}).map(
        (k, v) => MapEntry(k.toString(), v.toString()),
      ),
      reflectionNotes: json['reflectionNotes'] as String? ?? '',
      lastUpdatedAt: json['lastUpdatedAt'] == null
          ? null
          : DateTime.parse(json['lastUpdatedAt'] as String),
    );
  }

  Map<String, dynamic> toJson() => {
    'projectId': projectId,
    'completedMilestoneIds': completedMilestoneIds,
    'completedSecurityChecks': completedSecurityChecks,
    'githubRepoUrl': githubRepoUrl,
    'recordedMetrics': recordedMetrics,
    'reflectionNotes': reflectionNotes,
    'lastUpdatedAt': lastUpdatedAt?.toUtc().toIso8601String(),
  };
}

@immutable
class DiagnosticResult {
  const DiagnosticResult({
    required this.completedAt,
    required this.correctCount,
    required this.totalCount,
    required this.weakModuleIds,
    required this.confidentModuleIds,
    required this.suggestedStartModuleId,
  });

  final DateTime completedAt;
  final int correctCount;
  final int totalCount;
  final List<String> weakModuleIds;
  final List<String> confidentModuleIds;
  final String suggestedStartModuleId;

  factory DiagnosticResult.fromJson(Map<String, dynamic> json) {
    final correct = json['correctCount'];
    final total = json['totalCount'];
    if (correct is! int ||
        total is! int ||
        total <= 0 ||
        correct < 0 ||
        correct > total) {
      throw const FormatException('Invalid diagnostic result counts');
    }
    return DiagnosticResult(
      completedAt: DateTime.parse(_reqStr(json, 'completedAt')),
      correctCount: correct,
      totalCount: total,
      weakModuleIds: _strList(json['weakModuleIds']),
      confidentModuleIds: _strList(json['confidentModuleIds']),
      suggestedStartModuleId: _reqStr(json, 'suggestedStartModuleId'),
    );
  }

  Map<String, dynamic> toJson() => {
    'completedAt': completedAt.toUtc().toIso8601String(),
    'correctCount': correctCount,
    'totalCount': totalCount,
    'weakModuleIds': weakModuleIds,
    'confidentModuleIds': confidentModuleIds,
    'suggestedStartModuleId': suggestedStartModuleId,
  };
}

@immutable
class LearnerProfile {
  const LearnerProfile({
    this.onboardingCompleted = false,
    this.entryPath = EntryPath.zero,
    this.experienceSummary = 'Starting fresh',
    this.weeklyStudyHours = 6,
    this.studyDays = const [1, 3, 5, 6],
    this.learningGoals = const [
      'Build reliable Python & FastAPI services',
      'Connect n8n workflows safely to AI backends',
    ],
    this.suggestedStartModuleId = 'm01',
    this.diagnosticResult,
  });

  final bool onboardingCompleted;
  final EntryPath entryPath;
  final String experienceSummary;
  final int weeklyStudyHours;
  final List<int> studyDays; // 1 = Monday .. 7 = Sunday
  final List<String> learningGoals;
  final String suggestedStartModuleId;
  final DiagnosticResult? diagnosticResult;

  LearnerProfile copyWith({
    bool? onboardingCompleted,
    EntryPath? entryPath,
    String? experienceSummary,
    int? weeklyStudyHours,
    List<int>? studyDays,
    List<String>? learningGoals,
    String? suggestedStartModuleId,
    DiagnosticResult? diagnosticResult,
    bool clearDiagnosticResult = false,
  }) {
    return LearnerProfile(
      onboardingCompleted: onboardingCompleted ?? this.onboardingCompleted,
      entryPath: entryPath ?? this.entryPath,
      experienceSummary: experienceSummary ?? this.experienceSummary,
      weeklyStudyHours: weeklyStudyHours ?? this.weeklyStudyHours,
      studyDays: studyDays ?? this.studyDays,
      learningGoals: learningGoals ?? this.learningGoals,
      suggestedStartModuleId:
          suggestedStartModuleId ?? this.suggestedStartModuleId,
      diagnosticResult: clearDiagnosticResult
          ? null
          : (diagnosticResult ?? this.diagnosticResult),
    );
  }

  factory LearnerProfile.fromJson(Map<String, dynamic> json) {
    final hours = json['weeklyStudyHours'];
    if (hours is! int || hours < 1 || hours > 60) {
      throw const FormatException('weeklyStudyHours must be between 1 and 60');
    }
    final daysRaw = json['studyDays'];
    if (daysRaw is! List) {
      throw const FormatException(
        'studyDays must be a list of weekday numbers',
      );
    }
    final days = daysRaw
        .map((e) {
          if (e is! int || e < 1 || e > 7) {
            throw const FormatException(
              'studyDays entries must be integers 1..7',
            );
          }
          return e;
        })
        .toList(growable: false);

    return LearnerProfile(
      onboardingCompleted: _reqBool(json, 'onboardingCompleted'),
      entryPath: EntryPath.fromString(_reqStr(json, 'entryPath')),
      experienceSummary: json['experienceSummary'] as String? ?? '',
      weeklyStudyHours: hours,
      studyDays: days,
      learningGoals: _strList(json['learningGoals']),
      suggestedStartModuleId:
          json['suggestedStartModuleId'] as String? ?? 'm01',
      diagnosticResult: json['diagnosticResult'] == null
          ? null
          : DiagnosticResult.fromJson(
              Map<String, dynamic>.from(json['diagnosticResult'] as Map),
            ),
    );
  }

  Map<String, dynamic> toJson() => {
    'onboardingCompleted': onboardingCompleted,
    'entryPath': entryPath.name,
    'experienceSummary': experienceSummary,
    'weeklyStudyHours': weeklyStudyHours,
    'studyDays': studyDays,
    'learningGoals': learningGoals,
    'suggestedStartModuleId': suggestedStartModuleId,
    'diagnosticResult': diagnosticResult?.toJson(),
  };
}

@immutable
class ActivityLogEntry {
  const ActivityLogEntry({
    required this.id,
    required this.timestamp,
    required this.kind,
    required this.title,
    this.route,
  });

  final String id;
  final DateTime timestamp;
  final String kind;
  final String title;
  final String? route;

  factory ActivityLogEntry.fromJson(Map<String, dynamic> json) {
    return ActivityLogEntry(
      id: _reqStr(json, 'id'),
      timestamp: DateTime.parse(_reqStr(json, 'timestamp')),
      kind: _reqStr(json, 'kind'),
      title: _reqStr(json, 'title'),
      route: json['route'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'timestamp': timestamp.toUtc().toIso8601String(),
    'kind': kind,
    'title': title,
    'route': route,
  };
}

class ProgressImportException implements Exception {
  const ProgressImportException(this.message);
  final String message;

  @override
  String toString() => message;
}

@immutable
class LearnerState {
  static const int currentSchemaVersion = 1;

  const LearnerState({
    this.schemaVersion = currentSchemaVersion,
    this.themeMode = AppThemeSetting.system,
    this.profile = const LearnerProfile(),
    this.checkpointProgress = const {},
    this.projectProgress = const {},
    this.moduleChecklistDone = const {},
    this.lastVisitedCheckpointId,
    this.recentActivity = const [],
  });

  final int schemaVersion;
  final AppThemeSetting themeMode;
  final LearnerProfile profile;
  final Map<String, CheckpointProgress> checkpointProgress;
  final Map<String, ProjectProgress> projectProgress;
  final Map<String, List<String>> moduleChecklistDone;
  final String? lastVisitedCheckpointId;
  final List<ActivityLogEntry> recentActivity;

  LearnerState copyWith({
    int? schemaVersion,
    AppThemeSetting? themeMode,
    LearnerProfile? profile,
    Map<String, CheckpointProgress>? checkpointProgress,
    Map<String, ProjectProgress>? projectProgress,
    Map<String, List<String>>? moduleChecklistDone,
    String? lastVisitedCheckpointId,
    bool clearLastVisited = false,
    List<ActivityLogEntry>? recentActivity,
  }) {
    return LearnerState(
      schemaVersion: schemaVersion ?? this.schemaVersion,
      themeMode: themeMode ?? this.themeMode,
      profile: profile ?? this.profile,
      checkpointProgress: checkpointProgress ?? this.checkpointProgress,
      projectProgress: projectProgress ?? this.projectProgress,
      moduleChecklistDone: moduleChecklistDone ?? this.moduleChecklistDone,
      lastVisitedCheckpointId: clearLastVisited
          ? null
          : (lastVisitedCheckpointId ?? this.lastVisitedCheckpointId),
      recentActivity: recentActivity ?? this.recentActivity,
    );
  }

  factory LearnerState.fromJson(Map<String, dynamic> json) {
    final version = json['schemaVersion'];
    if (version is! int) {
      throw const ProgressImportException(
        'Missing or non-integer schemaVersion.',
      );
    }
    if (version < 1 || version > currentSchemaVersion) {
      throw ProgressImportException(
        'Unsupported progress schemaVersion $version (expected 1..$currentSchemaVersion).',
      );
    }
    try {
      final profileRaw = json['profile'];
      if (profileRaw is! Map) {
        throw const FormatException('Missing profile object');
      }
      final cpRaw = json['checkpointProgress'];
      if (cpRaw is! Map) {
        throw const FormatException('checkpointProgress must be an object');
      }
      final projRaw = json['projectProgress'];
      if (projRaw is! Map) {
        throw const FormatException('projectProgress must be an object');
      }
      final checklistRaw = json['moduleChecklistDone'] as Map? ?? const {};
      final activityRaw = json['recentActivity'] as List? ?? const [];

      return LearnerState(
        schemaVersion: version,
        themeMode: AppThemeSetting.fromString(
          json['themeMode'] as String? ?? 'system',
        ),
        profile: LearnerProfile.fromJson(Map<String, dynamic>.from(profileRaw)),
        checkpointProgress: cpRaw.map(
          (k, v) => MapEntry(
            k.toString(),
            CheckpointProgress.fromJson(Map<String, dynamic>.from(v as Map)),
          ),
        ),
        projectProgress: projRaw.map(
          (k, v) => MapEntry(
            k.toString(),
            ProjectProgress.fromJson(Map<String, dynamic>.from(v as Map)),
          ),
        ),
        moduleChecklistDone: checklistRaw.map(
          (k, v) => MapEntry(k.toString(), _strList(v)),
        ),
        lastVisitedCheckpointId: json['lastVisitedCheckpointId'] as String?,
        recentActivity: activityRaw
            .map(
              (e) => ActivityLogEntry.fromJson(
                Map<String, dynamic>.from(e as Map),
              ),
            )
            .toList(growable: false),
      );
    } on FormatException catch (e) {
      throw ProgressImportException('Invalid progress JSON: ${e.message}');
    } catch (e) {
      throw ProgressImportException('Invalid progress payload: $e');
    }
  }

  Map<String, dynamic> toJson() => {
    'schemaVersion': schemaVersion,
    'themeMode': themeMode.name,
    'profile': profile.toJson(),
    'checkpointProgress': checkpointProgress.map(
      (k, v) => MapEntry(k, v.toJson()),
    ),
    'projectProgress': projectProgress.map((k, v) => MapEntry(k, v.toJson())),
    'moduleChecklistDone': moduleChecklistDone,
    'lastVisitedCheckpointId': lastVisitedCheckpointId,
    'recentActivity': recentActivity
        .map((e) => e.toJson())
        .toList(growable: false),
  };
}

String _reqStr(Map<String, dynamic> json, String key) {
  final v = json[key];
  if (v is! String) {
    throw FormatException('Expected string for "$key"');
  }
  return v;
}

bool _reqBool(Map<String, dynamic> json, String key) {
  final v = json[key];
  if (v is! bool) {
    throw FormatException('Expected bool for "$key"');
  }
  return v;
}

List<String> _strList(dynamic value) {
  if (value == null) return const [];
  if (value is! List) {
    throw const FormatException('Expected list of strings');
  }
  return value.map((e) => e.toString()).toList(growable: false);
}
