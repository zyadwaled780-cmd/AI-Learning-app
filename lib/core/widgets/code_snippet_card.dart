import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';

import '../../app/theme/app_tokens.dart';
import '../models/curriculum_models.dart';

class CodeSnippetCard extends StatefulWidget {
  const CodeSnippetCard({super.key, required this.example});

  final CodeExample example;

  @override
  State<CodeSnippetCard> createState() => _CodeSnippetCardState();
}

class _CodeSnippetCardState extends State<CodeSnippetCard> {
  bool _copied = false;

  Future<void> _copyCode() async {
    await Clipboard.setData(ClipboardData(text: widget.example.code));
    if (!mounted) return;
    setState(() => _copied = true);
    Future<void>.delayed(const Duration(seconds: 2), () {
      if (mounted) setState(() => _copied = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        color: AppTokens.codeSurface,
        borderRadius: BorderRadius.circular(AppTokens.radiusMd),
        border: Border.all(color: AppTokens.darkBorder),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            color: AppTokens.codeHeaderSurface,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: AppTokens.darkPrimaryContainer,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    widget.example.language.toUpperCase(),
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: AppTokens.darkPrimary,
                      fontFamily: 'monospace',
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    widget.example.title,
                    style: theme.textTheme.titleSmall?.copyWith(
                      color: AppTokens.codeText,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Semantics(
                  button: true,
                  label: 'Copy code snippet ${widget.example.title}',
                  child: TextButton.icon(
                    onPressed: _copyCode,
                    style: TextButton.styleFrom(
                      foregroundColor: AppTokens.codeText,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                    ),
                    icon: Icon(
                      _copied ? Icons.check_rounded : Icons.copy_rounded,
                      size: 16,
                    ),
                    label: Text(_copied ? 'Copied' : 'Copy'),
                  ),
                ),
              ],
            ),
          ),
          if (widget.example.description.trim().isNotEmpty)
            Container(
              width: double.infinity,
              color: const Color(0xFF162033),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              child: Text(
                widget.example.description,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: const Color(0xFFCBD5E1),
                ),
              ),
            ),
          Scrollbar(
            thumbVisibility: false,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.all(14),
              child: SelectableText(
                widget.example.code,
                style: const TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 13.5,
                  height: 1.5,
                  color: AppTokens.codeText,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
