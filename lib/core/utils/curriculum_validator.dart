import '../models/curriculum_models.dart';

class CurriculumValidationResult {
  const CurriculumValidationResult({
    required this.isValid,
    required this.errors,
  });

  final bool isValid;
  final List<String> errors;
}

abstract final class CurriculumValidator {
  static CurriculumValidationResult validate(CurriculumBundle bundle) {
    final errors = <String>[];

    if (bundle.modules.length < 15) {
      errors.add(
        'Expected at least 15 modules, found ${bundle.modules.length}.',
      );
    }
    if (bundle.checkpoints.length < 120) {
      errors.add(
        'Expected at least 120 checkpoints, found ${bundle.checkpoints.length}.',
      );
    }
    if (bundle.projects.length < 4) {
      errors.add(
        'Expected at least 4 capstone projects, found ${bundle.projects.length}.',
      );
    }

    // Check unique module IDs and sequential numbers.
    final moduleIds = <String>{};
    for (final module in bundle.modules) {
      if (!moduleIds.add(module.id)) {
        errors.add('Duplicate module id: ${module.id}');
      }
      if (module.outcome.trim().isEmpty) {
        errors.add('Module ${module.id} has an empty outcome.');
      }
      if (module.masteryChecklist.isEmpty) {
        errors.add('Module ${module.id} has an empty masteryChecklist.');
      }
      if (module.miniProject.title.trim().isEmpty ||
          module.miniProject.brief.trim().isEmpty) {
        errors.add('Module ${module.id} is missing miniProject details.');
      }
      final cps = bundle.checkpointsByModuleId[module.id] ?? const [];
      if (cps.length < 8) {
        errors.add(
          'Module ${module.id} has only ${cps.length} checkpoints (minimum 8 required).',
        );
      }
    }

    for (final module in bundle.modules) {
      for (final prereq in module.prerequisiteModuleIds) {
        if (!moduleIds.contains(prereq)) {
          errors.add(
            'Module ${module.id} references unknown prerequisite module $prereq.',
          );
        }
        if (prereq == module.id) {
          errors.add('Module ${module.id} cannot depend on itself.');
        }
      }
    }

    // Check unique comparison IDs.
    final comparisonIds = <String>{};
    for (final card in bundle.comparisons) {
      if (!comparisonIds.add(card.id)) {
        errors.add('Duplicate comparison id: ${card.id}');
      }
    }

    // Check unique checkpoint IDs & content quality.
    final checkpointIds = <String>{};
    for (final cp in bundle.checkpoints) {
      if (!checkpointIds.add(cp.id)) {
        errors.add('Duplicate checkpoint id: ${cp.id}');
      }
      if (!moduleIds.contains(cp.moduleId)) {
        errors.add(
          'Checkpoint ${cp.id} references unknown module ${cp.moduleId}.',
        );
      }
      if (cp.estimatedMinutes <= 0) {
        errors.add('Checkpoint ${cp.id} has non-positive estimatedMinutes.');
      }
      if (cp.title.trim().isEmpty ||
          cp.summary.trim().isEmpty ||
          cp.plainEnglishExplanation.trim().isEmpty ||
          cp.technicalExplanation.trim().isEmpty ||
          cp.whyItMatters.trim().isEmpty ||
          cp.whenToUse.trim().isEmpty ||
          cp.whenNotToUse.trim().isEmpty ||
          cp.practiceTask.trim().isEmpty) {
        errors.add('Checkpoint ${cp.id} has empty core instructional text.');
      }
      if (cp.learningObjectives.isEmpty ||
          cp.acceptanceCriteria.isEmpty ||
          cp.commonMistakes.isEmpty ||
          cp.examples.isEmpty ||
          cp.resourceLinks.isEmpty) {
        errors.add(
          'Checkpoint ${cp.id} is missing objectives, examples, criteria, mistakes, or resources.',
        );
      }
      if (cp.quizQuestions.isEmpty) {
        errors.add('Checkpoint ${cp.id} must have at least 1 quiz question.');
      }
      for (final q in cp.quizQuestions) {
        if (q.options.length < 2) {
          errors.add('Quiz ${q.id} in ${cp.id} must have >= 2 options.');
        }
        final correctCount = q.options.where((o) => o.isCorrect).length;
        if (correctCount != 1) {
          errors.add(
            'Quiz ${q.id} in ${cp.id} must have exactly 1 correct option (found $correctCount).',
          );
        }
        for (final opt in q.options) {
          if (opt.explanation.trim().isEmpty) {
            errors.add(
              'Option ${opt.id} in quiz ${q.id} (${cp.id}) has empty explanation.',
            );
          }
        }
      }
      for (final compId in cp.comparisonCardIds) {
        if (!comparisonIds.contains(compId)) {
          errors.add(
            'Checkpoint ${cp.id} references unknown comparisonCardId $compId.',
          );
        }
      }
      for (final res in cp.resourceLinks) {
        final uri = Uri.tryParse(res.url);
        if (uri == null || !uri.isAbsolute || uri.scheme != 'https') {
          errors.add(
            'Checkpoint ${cp.id} has invalid HTTPS resource URL: ${res.url}',
          );
        }
      }
    }

    // Validate checkpoint prerequisites & detect cycles.
    for (final cp in bundle.checkpoints) {
      for (final prereq in cp.prerequisiteIds) {
        if (!checkpointIds.contains(prereq)) {
          errors.add(
            'Checkpoint ${cp.id} references unknown prerequisite $prereq.',
          );
        }
        if (prereq == cp.id) {
          errors.add('Checkpoint ${cp.id} cannot depend on itself.');
        }
      }
    }
    _detectCheckpointCycles(bundle, errors);

    // Validate projects.
    final projectIds = <String>{};
    for (final project in bundle.projects) {
      if (!projectIds.add(project.id)) {
        errors.add('Duplicate project id: ${project.id}');
      }
      for (final mId in project.relatedModuleIds) {
        if (!moduleIds.contains(mId)) {
          errors.add('Project ${project.id} references unknown module $mId.');
        }
      }
      if (project.milestones.isEmpty ||
          project.rubric.isEmpty ||
          project.securityChecklist.isEmpty) {
        errors.add(
          'Project ${project.id} is missing milestones, rubric, or security checklist.',
        );
      }
    }

    // Validate glossary.
    final glossaryIds = <String>{};
    for (final term in bundle.glossary) {
      if (!glossaryIds.add(term.id)) {
        errors.add('Duplicate glossary id: ${term.id}');
      }
      for (final cpId in term.relatedCheckpointIds) {
        if (!checkpointIds.contains(cpId)) {
          errors.add(
            'Glossary term ${term.id} references unknown checkpoint $cpId.',
          );
        }
      }
    }

    // Validate diagnostic questions.
    for (final dq in bundle.diagnosticQuestions) {
      if (!moduleIds.contains(dq.moduleId)) {
        errors.add(
          'Diagnostic question ${dq.id} references unknown module ${dq.moduleId}.',
        );
      }
      if (dq.options.where((o) => o.isCorrect).length != 1) {
        errors.add(
          'Diagnostic question ${dq.id} must have exactly 1 correct option.',
        );
      }
    }

    return CurriculumValidationResult(
      isValid: errors.isEmpty,
      errors: List.unmodifiable(errors),
    );
  }

  static void _detectCheckpointCycles(
    CurriculumBundle bundle,
    List<String> errors,
  ) {
    final visiting = <String>{};
    final visited = <String>{};

    void dfs(String id) {
      if (visited.contains(id)) return;
      if (!visiting.add(id)) {
        errors.add('Cycle detected in checkpoint prerequisites involving $id.');
        return;
      }
      final cp = bundle.checkpointById[id];
      if (cp != null) {
        for (final prereq in cp.prerequisiteIds) {
          if (bundle.checkpointById.containsKey(prereq)) {
            dfs(prereq);
          }
        }
      }
      visiting.remove(id);
      visited.add(id);
    }

    for (final cp in bundle.checkpoints) {
      dfs(cp.id);
    }
  }
}
