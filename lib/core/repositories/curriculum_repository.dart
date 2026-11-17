import 'dart:convert';

import 'package:flutter/services.dart';

import '../models/curriculum_models.dart';
import '../utils/curriculum_validator.dart';

abstract interface class CurriculumRepository {
  Future<CurriculumBundle> loadCurriculum();
}

class AssetCurriculumRepository implements CurriculumRepository {
  AssetCurriculumRepository({AssetBundle? assetBundle})
    : _bundle = assetBundle ?? rootBundle;

  final AssetBundle _bundle;

  static const List<String> checkpointAssetFiles = [
    'assets/curriculum/checkpoints_01_03.json',
    'assets/curriculum/checkpoints_04_06.json',
    'assets/curriculum/checkpoints_07_09.json',
    'assets/curriculum/checkpoints_10_12.json',
    'assets/curriculum/checkpoints_13_15.json',
  ];

  @override
  Future<CurriculumBundle> loadCurriculum() async {
    final modulesJson = await _loadJsonMap('assets/curriculum/modules.json');
    final comparisonsJson = await _loadJsonMap(
      'assets/curriculum/comparisons.json',
    );
    final projectsJson = await _loadJsonMap('assets/curriculum/projects.json');
    final glossaryJson = await _loadJsonMap('assets/curriculum/glossary.json');
    final diagnosticJson = await _loadJsonMap(
      'assets/curriculum/diagnostic.json',
    );

    final modules =
        _asList(modulesJson['modules'])
            .map(
              (e) =>
                  LearningModule.fromJson(Map<String, dynamic>.from(e as Map)),
            )
            .toList(growable: false)
          ..sort((a, b) => a.number.compareTo(b.number));

    final checkpoints = <Checkpoint>[];
    for (final file in checkpointAssetFiles) {
      final chunk = await _loadJsonMap(file);
      for (final raw in _asList(chunk['checkpoints'])) {
        checkpoints.add(
          Checkpoint.fromJson(Map<String, dynamic>.from(raw as Map)),
        );
      }
    }

    final comparisons = _asList(comparisonsJson['comparisons'])
        .map(
          (e) => ComparisonCard.fromJson(Map<String, dynamic>.from(e as Map)),
        )
        .toList(growable: false);

    final projects =
        _asList(projectsJson['projects'])
            .map(
              (e) =>
                  CapstoneProject.fromJson(Map<String, dynamic>.from(e as Map)),
            )
            .toList(growable: false)
          ..sort((a, b) => a.number.compareTo(b.number));

    final glossary =
        _asList(glossaryJson['terms'])
            .map(
              (e) => GlossaryTerm.fromJson(Map<String, dynamic>.from(e as Map)),
            )
            .toList(growable: false)
          ..sort(
            (a, b) => a.term.toLowerCase().compareTo(b.term.toLowerCase()),
          );

    final diagnosticQuestions = _asList(diagnosticJson['questions'])
        .map(
          (e) =>
              DiagnosticQuestion.fromJson(Map<String, dynamic>.from(e as Map)),
        )
        .toList(growable: false);

    final bundle = CurriculumBundle(
      version: modulesJson['version'] as String? ?? '1.0.0',
      lastReviewedAt: modulesJson['lastReviewedAt'] as String? ?? '2026-11-17',
      modules: modules,
      checkpoints: checkpoints,
      projects: projects,
      glossary: glossary,
      comparisons: comparisons,
      diagnosticQuestions: diagnosticQuestions,
    );

    final validation = CurriculumValidator.validate(bundle);
    if (!validation.isValid) {
      throw StateError(
        'Curriculum validation failed:\n${validation.errors.take(10).join('\n')}',
      );
    }

    return bundle;
  }

  Future<Map<String, dynamic>> _loadJsonMap(String path) async {
    final raw = await _bundle.loadString(path);
    final decoded = jsonDecode(raw);
    if (decoded is! Map) {
      throw FormatException('Expected top-level JSON object in $path');
    }
    return Map<String, dynamic>.from(decoded);
  }

  List<dynamic> _asList(dynamic value) {
    if (value is! List) {
      throw const FormatException('Expected JSON array');
    }
    return value;
  }
}
