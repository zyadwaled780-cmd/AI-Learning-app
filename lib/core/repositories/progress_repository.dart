import 'dart:convert';

import '../models/curriculum_models.dart';
import '../models/learner_state.dart';
import 'key_value_store.dart';

abstract interface class ProgressRepository {
  Future<LearnerState> load();
  Future<void> save(LearnerState state);
  Future<void> reset();
  String exportJson(LearnerState state);
  LearnerState parseAndValidateImport(
    String rawJson, {
    CurriculumBundle? curriculum,
  });
}

class LocalProgressRepository implements ProgressRepository {
  LocalProgressRepository({required KeyValueStore store}) : _store = store;

  static const String storageKey = 'ai_automation_hero_learner_state_v1';

  final KeyValueStore _store;

  @override
  Future<LearnerState> load() async {
    final raw = await _store.readString(storageKey);
    if (raw == null || raw.trim().isEmpty) {
      return const LearnerState();
    }
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map) {
        return const LearnerState();
      }
      return LearnerState.fromJson(Map<String, dynamic>.from(decoded));
    } catch (_) {
      // Preserve clean startup if local storage contains corrupted data.
      return const LearnerState();
    }
  }

  @override
  Future<void> save(LearnerState state) async {
    final encoded = jsonEncode(state.toJson());
    await _store.writeString(storageKey, encoded);
  }

  @override
  Future<void> reset() async {
    await _store.remove(storageKey);
  }

  @override
  String exportJson(LearnerState state) {
    const encoder = JsonEncoder.withIndent('  ');
    return encoder.convert(state.toJson());
  }

  @override
  LearnerState parseAndValidateImport(
    String rawJson, {
    CurriculumBundle? curriculum,
  }) {
    final trimmed = rawJson.trim();
    if (trimmed.isEmpty) {
      throw const ProgressImportException('Import JSON cannot be empty.');
    }

    final dynamic decoded;
    try {
      decoded = jsonDecode(trimmed);
    } on FormatException catch (e) {
      throw ProgressImportException('Malformed JSON syntax: ${e.message}');
    }

    if (decoded is! Map) {
      throw const ProgressImportException(
        'Top-level JSON value must be an object.',
      );
    }

    final parsed = LearnerState.fromJson(Map<String, dynamic>.from(decoded));

    if (curriculum != null) {
      for (final cpId in parsed.checkpointProgress.keys) {
        if (!curriculum.checkpointById.containsKey(cpId)) {
          throw ProgressImportException(
            'Unknown checkpoint ID in import: "$cpId".',
          );
        }
      }
      for (final projId in parsed.projectProgress.keys) {
        if (!curriculum.projectById.containsKey(projId)) {
          throw ProgressImportException(
            'Unknown project ID in import: "$projId".',
          );
        }
      }
      for (final modId in parsed.moduleChecklistDone.keys) {
        if (!curriculum.moduleById.containsKey(modId)) {
          throw ProgressImportException(
            'Unknown module ID in import: "$modId".',
          );
        }
      }
      if (!curriculum.moduleById.containsKey(
        parsed.profile.suggestedStartModuleId,
      )) {
        throw ProgressImportException(
          'Unknown suggestedStartModuleId: "${parsed.profile.suggestedStartModuleId}".',
        );
      }
    }

    return parsed;
  }
}
