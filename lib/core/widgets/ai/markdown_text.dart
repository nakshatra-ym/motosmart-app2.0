import 'package:flutter/material.dart';

/// Renders the small slice of Markdown a chat model actually emits.
///
/// Not a Markdown implementation — no tables, images, links or nested lists.
/// The assistant is instructed to write plain sentences with the occasional
/// **bold** value and `-` bullet, and this renders exactly that, so asterisks
/// stop leaking through as literal text.
///
/// Text stays selectable, because a rider copying a torque figure or a phone
/// number out of an answer is the point.
class MarkdownText extends StatelessWidget {
  const MarkdownText(
    this.data, {
    super.key,
    required this.style,
    this.codeBackground,
  });

  final String data;
  final TextStyle style;
  final Color? codeBackground;

  @override
  Widget build(BuildContext context) {
    final blocks = _parseBlocks(data);
    if (blocks.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < blocks.length; i++) ...[
          if (i > 0) SizedBox(height: blocks[i].isListItem ? 4 : 10),
          _blockWidget(blocks[i]),
        ],
      ],
    );
  }

  Widget _blockWidget(_Block block) {
    final content = SelectableText.rich(
      TextSpan(children: _inlineSpans(block.text, style, codeBackground)),
      style: style,
    );

    if (!block.isListItem) {
      return block.heading
          ? DefaultTextStyle.merge(
              style: style.copyWith(fontWeight: FontWeight.w700),
              child: SelectableText.rich(
                TextSpan(
                  children: _inlineSpans(
                    block.text,
                    style.copyWith(fontWeight: FontWeight.w700),
                    codeBackground,
                  ),
                ),
              ),
            )
          : content;
    }

    return Padding(
      padding: const EdgeInsets.only(left: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Baseline-ish alignment without a full baseline row: the marker sits
          // on the first line whatever the text wraps to.
          Padding(
            padding: const EdgeInsets.only(top: 1),
            child: Text(
              block.marker!,
              style: style.copyWith(
                color: style.color?.withValues(alpha: 0.55),
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(child: content),
        ],
      ),
    );
  }
}

class _Block {
  const _Block(this.text, {this.marker, this.heading = false});

  final String text;

  /// "•" or "1." when this line is a list item; null for a paragraph.
  final String? marker;
  final bool heading;

  bool get isListItem => marker != null;
}

final _headingRe = RegExp(r'^\s{0,3}#{1,6}\s+(.*)$');
final _bulletRe = RegExp(r'^\s*[-*•]\s+(.*)$');
final _numberedRe = RegExp(r'^\s*(\d{1,2})[.)]\s+(.*)$');

/// Splits into blocks, joining the runs of consecutive plain lines that a model
/// produces as one wrapped paragraph.
List<_Block> _parseBlocks(String source) {
  final blocks = <_Block>[];
  final paragraph = StringBuffer();

  void flush() {
    final text = paragraph.toString().trim();
    if (text.isNotEmpty) blocks.add(_Block(text));
    paragraph.clear();
  }

  for (final line in source.split('\n')) {
    if (line.trim().isEmpty) {
      flush();
      continue;
    }

    final heading = _headingRe.firstMatch(line);
    if (heading != null) {
      flush();
      blocks.add(_Block(heading.group(1)!.trim(), heading: true));
      continue;
    }

    final numbered = _numberedRe.firstMatch(line);
    if (numbered != null) {
      flush();
      blocks.add(_Block(numbered.group(2)!.trim(), marker: '${numbered.group(1)}.'));
      continue;
    }

    final bullet = _bulletRe.firstMatch(line);
    if (bullet != null) {
      flush();
      blocks.add(_Block(bullet.group(1)!.trim(), marker: '•'));
      continue;
    }

    if (paragraph.isNotEmpty) paragraph.write(' ');
    paragraph.write(line.trim());
  }

  flush();
  return blocks;
}

// **bold**, *italic*, _italic_, `code`. Ordered so ** is consumed before *.
final _inlineRe = RegExp(
  r'\*\*(.+?)\*\*|`([^`]+?)`|(?<![\w*])\*(?!\s)(.+?)(?<!\s)\*(?![\w*])|(?<![\w_])_(?!\s)(.+?)(?<!\s)_(?![\w_])',
  dotAll: true,
);

List<InlineSpan> _inlineSpans(String text, TextStyle base, Color? codeBackground) {
  final spans = <InlineSpan>[];
  var index = 0;

  for (final match in _inlineRe.allMatches(text)) {
    if (match.start > index) {
      spans.add(TextSpan(text: text.substring(index, match.start)));
    }

    if (match.group(1) != null) {
      spans.add(TextSpan(
        text: match.group(1),
        style: const TextStyle(fontWeight: FontWeight.w700),
      ));
    } else if (match.group(2) != null) {
      spans.add(TextSpan(
        text: match.group(2),
        style: TextStyle(
          fontFamily: 'monospace',
          fontSize: base.fontSize == null ? null : base.fontSize! * 0.92,
          backgroundColor: codeBackground,
        ),
      ));
    } else {
      spans.add(TextSpan(
        text: match.group(3) ?? match.group(4),
        style: const TextStyle(fontStyle: FontStyle.italic),
      ));
    }

    index = match.end;
  }

  if (index < text.length) spans.add(TextSpan(text: text.substring(index)));
  return spans;
}
