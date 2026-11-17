import '../models/curriculum_models.dart';
import '../models/learner_state.dart';

enum SearchResultType {
  module('Module'),
  checkpoint('Lesson'),
  glossary('Glossary'),
  project('Project'),
  note('Personal Note');

  const SearchResultType(this.label);
  final String label;
}

class SearchHit {
  const SearchHit({
    required this.type,
    required this.id,
    required this.title,
    required this.subtitle,
    required this.route,
    required this.score,
  });

  final SearchResultType type;
  final String id;
  final String title;
  final String subtitle;
  final String route;
  final int score;
}

abstract final class SearchEngine {
  static List<SearchHit> search({
    required CurriculumBundle bundle,
    required LearnerState learnerState,
    required String query,
    Set<SearchResultType>? types,
  }) {
    final normalized = query.trim().toLowerCase();
    if (normalized.isEmpty) return const [];

    final tokens = normalized
        .split(RegExp(r'\s+'))
        .where((t) => t.isNotEmpty)
        .toList(growable: false);
    if (tokens.isEmpty) return const [];

    final hits = <SearchHit>[];

    bool includesType(SearchResultType t) => types == null || types.contains(t);

    if (includesType(SearchResultType.module)) {
      for (final m in bundle.modules) {
        final score = _scoreFields(tokens, [
          (m.title, 10),
          (m.subtitle, 6),
          (m.outcome, 4),
        ]);
        if (score > 0) {
          hits.add(
            SearchHit(
              type: SearchResultType.module,
              id: m.id,
              title: 'Module ${m.number}: ${m.title}',
              subtitle: m.subtitle,
              route: '/roadmap?module=${m.id}',
              score: score,
            ),
          );
        }
      }
    }

    if (includesType(SearchResultType.checkpoint)) {
      for (final cp in bundle.checkpoints) {
        final score = _scoreFields(tokens, [
          (cp.title, 10),
          (cp.tags.join(' '), 8),
          (cp.summary, 6),
          (cp.plainEnglishExplanation, 3),
          (cp.technicalExplanation, 2),
        ]);
        if (score > 0) {
          final mod = bundle.moduleById[cp.moduleId];
          hits.add(
            SearchHit(
              type: SearchResultType.checkpoint,
              id: cp.id,
              title: cp.title,
              subtitle:
                  'Module ${mod?.number ?? ''} · ${cp.estimatedMinutes} min · ${cp.summary}',
              route: '/lesson/${cp.id}',
              score: score,
            ),
          );
        }
      }
    }

    if (includesType(SearchResultType.glossary)) {
      for (final g in bundle.glossary) {
        final score = _scoreFields(tokens, [
          (g.term, 12),
          (g.category, 5),
          (g.plainEnglish, 5),
          (g.technicalDefinition, 3),
        ]);
        if (score > 0) {
          hits.add(
            SearchHit(
              type: SearchResultType.glossary,
              id: g.id,
              title: g.term,
              subtitle: '${g.category} — ${g.plainEnglish}',
              route: '/glossary?q=${Uri.encodeQueryComponent(g.term)}',
              score: score,
            ),
          );
        }
      }
    }

    if (includesType(SearchResultType.project)) {
      for (final p in bundle.projects) {
        final score = _scoreFields(tokens, [
          (p.title, 10),
          (p.tagline, 6),
          (p.brief, 4),
        ]);
        if (score > 0) {
          hits.add(
            SearchHit(
              type: SearchResultType.project,
              id: p.id,
              title: p.title,
              subtitle: p.tagline,
              route: '/projects/${p.id}',
              score: score,
            ),
          );
        }
      }
    }

    if (includesType(SearchResultType.note)) {
      for (final entry in learnerState.checkpointProgress.entries) {
        final note = entry.value.note.trim();
        if (note.isEmpty) continue;
        final cp = bundle.checkpointById[entry.key];
        final score = _scoreFields(tokens, [(note, 9), (cp?.title ?? '', 4)]);
        if (score > 0) {
          hits.add(
            SearchHit(
              type: SearchResultType.note,
              id: entry.key,
              title: 'Note: ${cp?.title ?? entry.key}',
              subtitle: note.length > 120 ? '${note.substring(0, 120)}…' : note,
              route: '/lesson/${entry.key}',
              score: score,
            ),
          );
        }
      }
    }

    hits.sort((a, b) => b.score.compareTo(a.score));
    return hits;
  }

  static int _scoreFields(
    List<String> tokens,
    List<(String, int)> weightedFields,
  ) {
    var total = 0;
    for (final token in tokens) {
      var tokenMatched = false;
      for (final (text, weight) in weightedFields) {
        final lower = text.toLowerCase();
        if (lower.contains(token)) {
          tokenMatched = true;
          total += weight;
          if (lower.startsWith(token)) {
            total += 2;
          }
        }
      }
      if (!tokenMatched) return 0;
    }
    return total;
  }
}
