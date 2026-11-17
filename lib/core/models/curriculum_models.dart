import 'package:flutter/foundation.dart';

enum DifficultyLevel {
  beginner('Beginner'),
  intermediate('Intermediate'),
  advanced('Advanced');

  const DifficultyLevel(this.label);
  final String label;

  static DifficultyLevel fromString(String value) {
    return DifficultyLevel.values.firstWhere(
      (e) => e.name == value.trim().toLowerCase(),
      orElse: () => throw FormatException('Unknown difficulty level: $value'),
    );
  }
}

@immutable
class ResourceLink {
  const ResourceLink({
    required this.title,
    required this.url,
    required this.source,
    required this.reviewedAt,
  });

  final String title;
  final String url;
  final String source;
  final String reviewedAt;

  factory ResourceLink.fromJson(Map<String, dynamic> json) {
    return ResourceLink(
      title: _requireString(json, 'title'),
      url: _requireString(json, 'url'),
      source: _requireString(json, 'source'),
      reviewedAt: _requireString(json, 'reviewedAt'),
    );
  }

  Map<String, dynamic> toJson() => {
    'title': title,
    'url': url,
    'source': source,
    'reviewedAt': reviewedAt,
  };
}

@immutable
class CodeExample {
  const CodeExample({
    required this.title,
    required this.description,
    required this.language,
    required this.code,
  });

  final String title;
  final String description;
  final String language;
  final String code;

  factory CodeExample.fromJson(Map<String, dynamic> json) {
    return CodeExample(
      title: _requireString(json, 'title'),
      description: _requireString(json, 'description'),
      language: _requireString(json, 'language'),
      code: _requireString(json, 'code'),
    );
  }

  Map<String, dynamic> toJson() => {
    'title': title,
    'description': description,
    'language': language,
    'code': code,
  };
}

@immutable
class ComparisonRow {
  const ComparisonRow({
    required this.aspect,
    required this.left,
    required this.right,
  });

  final String aspect;
  final String left;
  final String right;

  factory ComparisonRow.fromJson(Map<String, dynamic> json) {
    return ComparisonRow(
      aspect: _requireString(json, 'aspect'),
      left: _requireString(json, 'left'),
      right: _requireString(json, 'right'),
    );
  }

  Map<String, dynamic> toJson() => {
    'aspect': aspect,
    'left': left,
    'right': right,
  };
}

@immutable
class ComparisonCard {
  const ComparisonCard({
    required this.id,
    required this.title,
    required this.leftTitle,
    required this.rightTitle,
    required this.summary,
    required this.rows,
    required this.whenToChooseLeft,
    required this.whenToChooseRight,
    required this.checkpointIds,
  });

  final String id;
  final String title;
  final String leftTitle;
  final String rightTitle;
  final String summary;
  final List<ComparisonRow> rows;
  final String whenToChooseLeft;
  final String whenToChooseRight;
  final List<String> checkpointIds;

  factory ComparisonCard.fromJson(Map<String, dynamic> json) {
    return ComparisonCard(
      id: _requireString(json, 'id'),
      title: _requireString(json, 'title'),
      leftTitle: _requireString(json, 'leftTitle'),
      rightTitle: _requireString(json, 'rightTitle'),
      summary: _requireString(json, 'summary'),
      rows: _requireList(json, 'rows')
          .map(
            (e) => ComparisonRow.fromJson(Map<String, dynamic>.from(e as Map)),
          )
          .toList(growable: false),
      whenToChooseLeft: _requireString(json, 'whenToChooseLeft'),
      whenToChooseRight: _requireString(json, 'whenToChooseRight'),
      checkpointIds: _stringList(json['checkpointIds']),
    );
  }
}

@immutable
class QuizOption {
  const QuizOption({
    required this.id,
    required this.text,
    required this.isCorrect,
    required this.explanation,
  });

  final String id;
  final String text;
  final bool isCorrect;
  final String explanation;

  factory QuizOption.fromJson(Map<String, dynamic> json) {
    return QuizOption(
      id: _requireString(json, 'id'),
      text: _requireString(json, 'text'),
      isCorrect: json['isCorrect'] as bool? ?? false,
      explanation: _requireString(json, 'explanation'),
    );
  }
}

@immutable
class QuizQuestion {
  const QuizQuestion({
    required this.id,
    required this.prompt,
    required this.scenarioContext,
    required this.kind,
    required this.options,
    required this.takeaway,
  });

  final String id;
  final String prompt;
  final String scenarioContext;
  final String kind;
  final List<QuizOption> options;
  final String takeaway;

  factory QuizQuestion.fromJson(Map<String, dynamic> json) {
    return QuizQuestion(
      id: _requireString(json, 'id'),
      prompt: _requireString(json, 'prompt'),
      scenarioContext: (json['scenarioContext'] as String?) ?? '',
      kind: (json['kind'] as String?) ?? 'multiple_choice',
      options: _requireList(json, 'options')
          .map((e) => QuizOption.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList(growable: false),
      takeaway: _requireString(json, 'takeaway'),
    );
  }
}

@immutable
class Checkpoint {
  const Checkpoint({
    required this.id,
    required this.moduleId,
    required this.order,
    required this.title,
    required this.summary,
    required this.difficulty,
    required this.estimatedMinutes,
    required this.prerequisiteIds,
    required this.learningObjectives,
    required this.plainEnglishExplanation,
    required this.technicalExplanation,
    required this.whyItMatters,
    required this.whenToUse,
    required this.whenNotToUse,
    required this.examples,
    required this.comparisonCardIds,
    required this.practiceTask,
    required this.acceptanceCriteria,
    required this.commonMistakes,
    required this.quizQuestions,
    required this.resourceLinks,
    required this.tags,
  });

  final String id;
  final String moduleId;
  final int order;
  final String title;
  final String summary;
  final DifficultyLevel difficulty;
  final int estimatedMinutes;
  final List<String> prerequisiteIds;
  final List<String> learningObjectives;
  final String plainEnglishExplanation;
  final String technicalExplanation;
  final String whyItMatters;
  final String whenToUse;
  final String whenNotToUse;
  final List<CodeExample> examples;
  final List<String> comparisonCardIds;
  final String practiceTask;
  final List<String> acceptanceCriteria;
  final List<String> commonMistakes;
  final List<QuizQuestion> quizQuestions;
  final List<ResourceLink> resourceLinks;
  final List<String> tags;

  factory Checkpoint.fromJson(Map<String, dynamic> json) {
    return Checkpoint(
      id: _requireString(json, 'id'),
      moduleId: _requireString(json, 'moduleId'),
      order: json['order'] as int? ?? 0,
      title: _requireString(json, 'title'),
      summary: _requireString(json, 'summary'),
      difficulty: DifficultyLevel.fromString(
        _requireString(json, 'difficulty'),
      ),
      estimatedMinutes: json['estimatedMinutes'] as int? ?? 20,
      prerequisiteIds: _stringList(json['prerequisiteIds']),
      learningObjectives: _stringList(json['learningObjectives']),
      plainEnglishExplanation: _requireString(json, 'plainEnglishExplanation'),
      technicalExplanation: _requireString(json, 'technicalExplanation'),
      whyItMatters: _requireString(json, 'whyItMatters'),
      whenToUse: _requireString(json, 'whenToUse'),
      whenNotToUse: _requireString(json, 'whenNotToUse'),
      examples: _requireList(json, 'examples')
          .map((e) => CodeExample.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList(growable: false),
      comparisonCardIds: _stringList(json['comparisonCardIds']),
      practiceTask: _requireString(json, 'practiceTask'),
      acceptanceCriteria: _stringList(json['acceptanceCriteria']),
      commonMistakes: _stringList(json['commonMistakes']),
      quizQuestions: _requireList(json, 'quizQuestions')
          .map(
            (e) => QuizQuestion.fromJson(Map<String, dynamic>.from(e as Map)),
          )
          .toList(growable: false),
      resourceLinks: _requireList(json, 'resourceLinks')
          .map(
            (e) => ResourceLink.fromJson(Map<String, dynamic>.from(e as Map)),
          )
          .toList(growable: false),
      tags: _stringList(json['tags']),
    );
  }
}

@immutable
class ModuleMiniProject {
  const ModuleMiniProject({
    required this.title,
    required this.brief,
    required this.steps,
    required this.acceptanceCriteria,
  });

  final String title;
  final String brief;
  final List<String> steps;
  final List<String> acceptanceCriteria;

  factory ModuleMiniProject.fromJson(Map<String, dynamic> json) {
    return ModuleMiniProject(
      title: _requireString(json, 'title'),
      brief: _requireString(json, 'brief'),
      steps: _stringList(json['steps']),
      acceptanceCriteria: _stringList(json['acceptanceCriteria']),
    );
  }
}

@immutable
class LearningModule {
  const LearningModule({
    required this.id,
    required this.number,
    required this.title,
    required this.subtitle,
    required this.outcome,
    required this.difficulty,
    required this.prerequisiteModuleIds,
    required this.prerequisiteRationale,
    required this.miniProject,
    required this.masteryChecklist,
    required this.resourceLinks,
  });

  final String id;
  final int number;
  final String title;
  final String subtitle;
  final String outcome;
  final DifficultyLevel difficulty;
  final List<String> prerequisiteModuleIds;
  final String prerequisiteRationale;
  final ModuleMiniProject miniProject;
  final List<String> masteryChecklist;
  final List<ResourceLink> resourceLinks;

  factory LearningModule.fromJson(Map<String, dynamic> json) {
    return LearningModule(
      id: _requireString(json, 'id'),
      number: json['number'] as int,
      title: _requireString(json, 'title'),
      subtitle: _requireString(json, 'subtitle'),
      outcome: _requireString(json, 'outcome'),
      difficulty: DifficultyLevel.fromString(
        _requireString(json, 'difficulty'),
      ),
      prerequisiteModuleIds: _stringList(json['prerequisiteModuleIds']),
      prerequisiteRationale: _requireString(json, 'prerequisiteRationale'),
      miniProject: ModuleMiniProject.fromJson(
        Map<String, dynamic>.from(json['miniProject'] as Map),
      ),
      masteryChecklist: _stringList(json['masteryChecklist']),
      resourceLinks: _requireList(json, 'resourceLinks')
          .map(
            (e) => ResourceLink.fromJson(Map<String, dynamic>.from(e as Map)),
          )
          .toList(growable: false),
    );
  }
}

@immutable
class CapstoneMilestone {
  const CapstoneMilestone({
    required this.id,
    required this.stage,
    required this.title,
    required this.description,
    required this.verificationChecks,
  });

  final String id;
  final String stage;
  final String title;
  final String description;
  final List<String> verificationChecks;

  factory CapstoneMilestone.fromJson(Map<String, dynamic> json) {
    return CapstoneMilestone(
      id: _requireString(json, 'id'),
      stage: _requireString(json, 'stage'),
      title: _requireString(json, 'title'),
      description: _requireString(json, 'description'),
      verificationChecks: _stringList(json['verificationChecks']),
    );
  }
}

@immutable
class RubricCriterion {
  const RubricCriterion({
    required this.criterion,
    required this.emerging,
    required this.productionReady,
  });

  final String criterion;
  final String emerging;
  final String productionReady;

  factory RubricCriterion.fromJson(Map<String, dynamic> json) {
    return RubricCriterion(
      criterion: _requireString(json, 'criterion'),
      emerging: _requireString(json, 'emerging'),
      productionReady: _requireString(json, 'productionReady'),
    );
  }
}

@immutable
class MetricTemplate {
  const MetricTemplate({
    required this.id,
    required this.label,
    required this.unit,
    required this.hint,
  });

  final String id;
  final String label;
  final String unit;
  final String hint;

  factory MetricTemplate.fromJson(Map<String, dynamic> json) {
    return MetricTemplate(
      id: _requireString(json, 'id'),
      label: _requireString(json, 'label'),
      unit: _requireString(json, 'unit'),
      hint: _requireString(json, 'hint'),
    );
  }
}

@immutable
class CapstoneProject {
  const CapstoneProject({
    required this.id,
    required this.number,
    required this.title,
    required this.tagline,
    required this.brief,
    required this.relatedModuleIds,
    required this.requirements,
    required this.architectureDiagram,
    required this.milestones,
    required this.deliverables,
    required this.testCases,
    required this.rubric,
    required this.evalDatasetSuggestions,
    required this.securityChecklist,
    required this.metricTemplates,
    required this.portfolioReadmeTemplate,
  });

  final String id;
  final int number;
  final String title;
  final String tagline;
  final String brief;
  final List<String> relatedModuleIds;
  final List<String> requirements;
  final String architectureDiagram;
  final List<CapstoneMilestone> milestones;
  final List<String> deliverables;
  final List<String> testCases;
  final List<RubricCriterion> rubric;
  final List<String> evalDatasetSuggestions;
  final List<String> securityChecklist;
  final List<MetricTemplate> metricTemplates;
  final String portfolioReadmeTemplate;

  factory CapstoneProject.fromJson(Map<String, dynamic> json) {
    return CapstoneProject(
      id: _requireString(json, 'id'),
      number: json['number'] as int,
      title: _requireString(json, 'title'),
      tagline: _requireString(json, 'tagline'),
      brief: _requireString(json, 'brief'),
      relatedModuleIds: _stringList(json['relatedModuleIds']),
      requirements: _stringList(json['requirements']),
      architectureDiagram: _requireString(json, 'architectureDiagram'),
      milestones: _requireList(json, 'milestones')
          .map(
            (e) =>
                CapstoneMilestone.fromJson(Map<String, dynamic>.from(e as Map)),
          )
          .toList(growable: false),
      deliverables: _stringList(json['deliverables']),
      testCases: _stringList(json['testCases']),
      rubric: _requireList(json, 'rubric')
          .map(
            (e) =>
                RubricCriterion.fromJson(Map<String, dynamic>.from(e as Map)),
          )
          .toList(growable: false),
      evalDatasetSuggestions: _stringList(json['evalDatasetSuggestions']),
      securityChecklist: _stringList(json['securityChecklist']),
      metricTemplates: _requireList(json, 'metricTemplates')
          .map(
            (e) => MetricTemplate.fromJson(Map<String, dynamic>.from(e as Map)),
          )
          .toList(growable: false),
      portfolioReadmeTemplate: _requireString(json, 'portfolioReadmeTemplate'),
    );
  }
}

@immutable
class GlossaryTerm {
  const GlossaryTerm({
    required this.id,
    required this.term,
    required this.category,
    required this.plainEnglish,
    required this.technicalDefinition,
    required this.example,
    required this.relatedCheckpointIds,
  });

  final String id;
  final String term;
  final String category;
  final String plainEnglish;
  final String technicalDefinition;
  final String example;
  final List<String> relatedCheckpointIds;

  factory GlossaryTerm.fromJson(Map<String, dynamic> json) {
    return GlossaryTerm(
      id: _requireString(json, 'id'),
      term: _requireString(json, 'term'),
      category: _requireString(json, 'category'),
      plainEnglish: _requireString(json, 'plainEnglish'),
      technicalDefinition: _requireString(json, 'technicalDefinition'),
      example: _requireString(json, 'example'),
      relatedCheckpointIds: _stringList(json['relatedCheckpointIds']),
    );
  }
}

@immutable
class DiagnosticQuestion {
  const DiagnosticQuestion({
    required this.id,
    required this.domain,
    required this.moduleId,
    required this.prompt,
    required this.options,
  });

  final String id;
  final String domain;
  final String moduleId;
  final String prompt;
  final List<QuizOption> options;

  factory DiagnosticQuestion.fromJson(Map<String, dynamic> json) {
    return DiagnosticQuestion(
      id: _requireString(json, 'id'),
      domain: _requireString(json, 'domain'),
      moduleId: _requireString(json, 'moduleId'),
      prompt: _requireString(json, 'prompt'),
      options: _requireList(json, 'options')
          .map((e) => QuizOption.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList(growable: false),
    );
  }
}

@immutable
class CurriculumBundle {
  CurriculumBundle({
    required this.version,
    required this.lastReviewedAt,
    required List<LearningModule> modules,
    required List<Checkpoint> checkpoints,
    required List<CapstoneProject> projects,
    required List<GlossaryTerm> glossary,
    required List<ComparisonCard> comparisons,
    required List<DiagnosticQuestion> diagnosticQuestions,
  }) : modules = List.unmodifiable(modules),
       checkpoints = List.unmodifiable(checkpoints),
       projects = List.unmodifiable(projects),
       glossary = List.unmodifiable(glossary),
       comparisons = List.unmodifiable(comparisons),
       diagnosticQuestions = List.unmodifiable(diagnosticQuestions),
       moduleById = {for (final m in modules) m.id: m},
       checkpointById = {for (final c in checkpoints) c.id: c},
       projectById = {for (final p in projects) p.id: p},
       comparisonById = {for (final comp in comparisons) comp.id: comp},
       checkpointsByModuleId = _groupByModule(modules, checkpoints);

  final String version;
  final String lastReviewedAt;
  final List<LearningModule> modules;
  final List<Checkpoint> checkpoints;
  final List<CapstoneProject> projects;
  final List<GlossaryTerm> glossary;
  final List<ComparisonCard> comparisons;
  final List<DiagnosticQuestion> diagnosticQuestions;

  final Map<String, LearningModule> moduleById;
  final Map<String, Checkpoint> checkpointById;
  final Map<String, CapstoneProject> projectById;
  final Map<String, ComparisonCard> comparisonById;
  final Map<String, List<Checkpoint>> checkpointsByModuleId;

  int get totalEstimatedMinutes =>
      checkpoints.fold<int>(0, (sum, c) => sum + c.estimatedMinutes);

  int moduleEstimatedMinutes(String moduleId) {
    final list = checkpointsByModuleId[moduleId] ?? const [];
    return list.fold<int>(0, (sum, c) => sum + c.estimatedMinutes);
  }

  static Map<String, List<Checkpoint>> _groupByModule(
    List<LearningModule> modules,
    List<Checkpoint> checkpoints,
  ) {
    final map = <String, List<Checkpoint>>{
      for (final m in modules) m.id: <Checkpoint>[],
    };
    for (final c in checkpoints) {
      map.putIfAbsent(c.moduleId, () => <Checkpoint>[]).add(c);
    }
    for (final entry in map.entries) {
      entry.value.sort((a, b) => a.order.compareTo(b.order));
    }
    return map.map((k, v) => MapEntry(k, List.unmodifiable(v)));
  }
}

String _requireString(Map<String, dynamic> json, String key) {
  final value = json[key];
  if (value is! String) {
    throw FormatException('Expected string for key "$key"');
  }
  return value;
}

List<dynamic> _requireList(Map<String, dynamic> json, String key) {
  final value = json[key];
  if (value is! List) {
    throw FormatException('Expected list for key "$key"');
  }
  return value;
}

List<String> _stringList(dynamic value) {
  if (value == null) return const [];
  if (value is! List) {
    throw const FormatException('Expected list of strings');
  }
  return value.map((e) => e.toString()).toList(growable: false);
}
