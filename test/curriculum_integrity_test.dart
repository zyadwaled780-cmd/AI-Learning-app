import 'package:ai_automation_hero/core/repositories/curriculum_repository.dart';
import 'package:ai_automation_hero/core/utils/curriculum_validator.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'bundled curriculum passes full schema and relational validation',
    () async {
      final repo = AssetCurriculumRepository();
      final bundle = await repo.loadCurriculum();

      expect(bundle.modules.length, 15);
      expect(bundle.checkpoints.length, greaterThanOrEqualTo(120));
      expect(bundle.checkpoints.length, 186);
      expect(bundle.projects.length, 4);
      expect(bundle.glossary.length, greaterThanOrEqualTo(65));
      expect(bundle.comparisons.length, 10);
      expect(bundle.diagnosticQuestions.length, 10);

      for (var i = 0; i < bundle.modules.length; i++) {
        final m = bundle.modules[i];
        expect(m.number, i + 1);
        final moduleCheckpoints =
            bundle.checkpointsByModuleId[m.id] ?? const [];
        expect(
          moduleCheckpoints.length,
          greaterThanOrEqualTo(8),
          reason: 'Module ${m.id} must have >= 8 substantive checkpoints',
        );
      }

      final validation = CurriculumValidator.validate(bundle);
      expect(validation.errors, isEmpty);
      expect(validation.isValid, isTrue);
    },
  );

  test('curriculum covers essential engineering & n8n bridge topics', () async {
    final bundle = await AssetCurriculumRepository().loadCurriculum();

    final checkpointText = bundle.checkpoints
        .map((c) => '${c.title} ${c.summary} ${c.tags.join(' ')}')
        .join(' ')
        .toLowerCase();

    for (final keyword in [
      'localhost',
      'cors',
      'docker',
      'fastapi',
      'pydantic',
      'langchain',
      'langgraph',
      'rag',
      'cloudflare',
      'n8n',
      'idempotency',
      'prompt injection',
    ]) {
      expect(
        checkpointText.contains(keyword),
        isTrue,
        reason: 'Missing expected curriculum coverage for "$keyword"',
      );
    }

    final glossaryTerms = bundle.glossary
        .map((g) => g.term.toLowerCase())
        .toList(growable: false);
    expect(glossaryTerms.any((t) => t.contains('cloudflare tunnel')), isTrue);
    expect(glossaryTerms.any((t) => t.contains('localhost')), isTrue);
    expect(glossaryTerms.any((t) => t.contains('pydantic')), isTrue);
    expect(glossaryTerms.any((t) => t.contains('langgraph')), isTrue);
  });
}
