import 'package:flutter/material.dart';

import '../config/design.dart';

/// The building blocks of the **Registration Document** world. Every screen is
/// assembled from these rather than from bare `Card`s, so the identity holds
/// across 26 screens without each one re-inventing it.

/// A record: ruled paper stock with an optional coloured spine.
///
/// The spine is a 3dp bar along the leading edge that carries the record's state
/// — the same way a file's edge is colour-tabbed in a filing cabinet. It is part
/// of the world's grammar, not a decorative left-border on a generic card.
class DocSheet extends StatelessWidget {
  const DocSheet({
    super.key,
    required this.child,
    this.spine,
    this.onTap,
    this.padding = const EdgeInsets.all(Ds.s4),
    this.tint,
    this.emphasis = false,
  });

  final Widget child;

  /// State colour for the leading edge. Null draws no spine.
  final Color? spine;
  final VoidCallback? onTap;
  final EdgeInsets padding;

  /// A wash over the stock, for records that need to read as urgent at a glance.
  final Color? tint;

  /// Raises the sheet off the ground for the one record that leads a screen.
  final bool emphasis;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(Ds.rMd);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: tint ?? Ds.surfaceRaised,
        borderRadius: radius,
        border: Border.all(color: emphasis ? Ds.lineStrong : Ds.line),
        boxShadow: emphasis ? Ds.lift(3) : null,
      ),
      child: ClipRRect(
        borderRadius: radius,
        child: Material(
          type: MaterialType.transparency,
          child: InkWell(
            onTap: onTap,
            // Without a spine the sheet is a plain padded box, which lets it size
            // itself normally. With one, IntrinsicHeight is what allows the bar
            // to stretch to the content's height — a `stretch` Row alone hands
            // its children an infinite height constraint and fails to lay out.
            child: spine == null
                ? Padding(padding: padding, child: child)
                : IntrinsicHeight(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Container(width: 3, color: spine),
                        Expanded(
                          child: Padding(padding: padding, child: child),
                        ),
                      ],
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}

/// A registration plate: the app's identity mark.
///
/// Only ever wraps a real identifier — a registration number, a VIN, a ticket or
/// lead reference. Using it for decoration would make the one honest signal in
/// the interface meaningless.
class PlateMark extends StatelessWidget {
  const PlateMark({
    super.key,
    required this.text,
    this.size = 15,
    this.commercial = false,
    this.dense = false,
  });

  final String text;
  final double size;

  /// Black on yellow, as a commercial vehicle's plate reads. Signals active,
  /// assigned, working — never merely "important".
  final bool commercial;
  final bool dense;

  @override
  Widget build(BuildContext context) {
    final bg = commercial ? Ds.caution : Ds.ink;
    final fg = commercial ? Ds.ink : const Color(0xFFF7F5EF);
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: dense ? Ds.s2 : Ds.s3,
        vertical: dense ? 4 : 6,
      ),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(Ds.rSm),
        border: Border.all(color: bg == Ds.ink ? Ds.ink : Ds.caution),
      ),
      child: Text(text, style: Ds.figure(size, color: fg)),
    );
  }
}

/// A pre-printed field: small caps label with its value beneath.
///
/// The form-field pattern the whole app reads by — every detail view is a stack
/// of these rather than a run of `ListTile`s.
class DocField extends StatelessWidget {
  const DocField({
    super.key,
    required this.label,
    this.value,
    this.valueWidget,
    this.emphasis = false,
  });

  final String label;
  final String? value;
  final Widget? valueWidget;

  /// Sets the value in the figure register — for money, distance, counts.
  final bool emphasis;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label.toUpperCase(), style: Ds.label()),
        const SizedBox(height: 3),
        valueWidget ??
            Text(
              (value == null || value!.isEmpty) ? '—' : value!,
              style: emphasis
                  ? Ds.figure(17)
                  : text.titleMedium?.copyWith(color: Ds.ink),
            ),
      ],
    );
  }
}

/// A rubber stamp: the mark of a judgement, and who made it.
///
/// Slightly rotated and outlined, as a stamp lands. Used for AI verdicts and
/// verification states, and it always names its source — the product must never
/// present a heuristic fallback as if a model produced it.
class DocStamp extends StatelessWidget {
  const DocStamp({
    super.key,
    required this.label,
    this.color = Ds.alert,
    this.icon,
    this.filled = false,
    this.tilt = -0.03,
  });

  final String label;
  final Color color;
  final IconData? icon;

  /// Solid ink instead of an outline, for the one state that must dominate.
  final bool filled;
  final double tilt;

  @override
  Widget build(BuildContext context) {
    return Transform.rotate(
      angle: tilt,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: Ds.s2, vertical: 3),
        decoration: BoxDecoration(
          color: filled ? color : color.withValues(alpha: 0.07),
          border: Border.all(color: color, width: 1.4),
          borderRadius: BorderRadius.circular(Ds.rSm),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 11.5, color: filled ? Colors.white : color),
              const SizedBox(width: 4),
            ],
            Text(
              label.toUpperCase(),
              style: Ds.label(color: filled ? Colors.white : color)
                  .copyWith(fontSize: 10, letterSpacing: 1.0),
            ),
          ],
        ),
      ),
    );
  }
}

/// A validity band, read the way an insurance or PUC sticker is read.
///
/// Carries a status word, an optional date, and a filled proportion — so "due in
/// three days" and "overdue" are the same object at different points in its life
/// rather than two unrelated chips.
class ValidityBand extends StatelessWidget {
  const ValidityBand({
    super.key,
    required this.status,
    required this.color,
    this.detail,
    this.progress,
  });

  final String status;
  final Color color;
  final String? detail;

  /// 0 = fresh, 1 = expired. Null hides the bar.
  final double? progress;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(Ds.s3, Ds.s2, Ds.s3, Ds.s2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(Ds.rSm),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  status.toUpperCase(),
                  style: Ds.label(color: color).copyWith(fontSize: 10.5),
                ),
              ),
              if (detail != null)
                Text(detail!, style: Ds.figure(12.5, weight: 640, color: color)),
            ],
          ),
          if (progress != null) ...[
            const SizedBox(height: 6),
            ClipRRect(
              borderRadius: BorderRadius.circular(Ds.rPill),
              child: LinearProgressIndicator(
                value: progress!.clamp(0.0, 1.0),
                minHeight: 4,
                backgroundColor: color.withValues(alpha: 0.15),
                valueColor: AlwaysStoppedAnimation(color),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// The header of a section within a page: a title with a hairline rule running
/// to the edge, as a form divides its parts. Replaces the bare bold `Text` that
/// section headings default to.
class DocSectionHeader extends StatelessWidget {
  const DocSectionHeader({
    super.key,
    required this.title,
    this.trailing,
    this.count,
  });

  final String title;
  final Widget? trailing;

  /// A tabular count set beside the title, for "3 due today"-style sections.
  final int? count;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: Ds.s3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(title.toUpperCase(), style: Ds.label(color: Ds.inkSoft)),
          if (count != null) ...[
            const SizedBox(width: Ds.s2),
            Text('$count', style: Ds.figure(12, weight: 700, color: Ds.ink)),
          ],
          const SizedBox(width: Ds.s3),
          const Expanded(child: Divider(color: Ds.line, height: 1)),
          if (trailing != null) ...[
            const SizedBox(width: Ds.s3),
            trailing!,
          ],
        ],
      ),
    );
  }
}

/// The perforated tear line between a document and its detachable counterfoil.
/// Used where one record genuinely splits into a stub — a booking and its
/// receipt, a summary and its detail.
class PerforationLine extends StatelessWidget {
  const PerforationLine({super.key, this.color = Ds.lineStrong});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 1,
      child: LayoutBuilder(
        builder: (context, constraints) {
          const dash = 5.0;
          const gap = 4.0;
          final count = (constraints.maxWidth / (dash + gap)).floor().clamp(1, 400);
          return Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(
              count,
              (_) => Container(width: dash, height: 1, color: color),
            ),
          );
        },
      ),
    );
  }
}

/// Caps a page's content at a readable measure and centres it, so a tablet gets
/// a document rather than a phone layout stretched across 1000dp.
class DocPage extends StatelessWidget {
  const DocPage({
    super.key,
    required this.child,
    this.maxWidth = Ds.readingMax,
  });

  final Widget child;
  final double maxWidth;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: child,
      ),
    );
  }
}
