import 'package:flutter/material.dart';
import '../core/models/models.dart';
import '../core/theme/app_colors.dart';

const String appLogoAsset = 'assets/images/vikoba_logo.png';

/// Shows a confirmation dialog that summarises every entered field ([rows] as
/// label → value) so the user can review the whole entry before it is sent and
/// saved. Returns true only if the user taps confirm; false on cancel/dismiss.
///
/// Callers pass already-localised strings so this stays free of the l10n layer.
Future<bool> showConfirmSummary(
  BuildContext context, {
  required String title,
  required List<(String, String)> rows,
  required String confirmLabel,
  required String cancelLabel,
  String? note,
}) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(title),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (final (label, value) in rows)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 4,
                      child: Text(label,
                          style: const TextStyle(
                              color: AppColors.textMuted, fontSize: 13)),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 5,
                      child: Text(value,
                          textAlign: TextAlign.right,
                          style: const TextStyle(
                              fontWeight: FontWeight.w600, fontSize: 13.5)),
                    ),
                  ],
                ),
              ),
            if (note != null) ...[
              const SizedBox(height: 10),
              Text(note,
                  style: const TextStyle(
                      fontSize: 12, color: AppColors.textMuted)),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(false),
          child: Text(cancelLabel),
        ),
        ElevatedButton(
          onPressed: () => Navigator.of(ctx).pop(true),
          child: Text(confirmLabel),
        ),
      ],
    ),
  );
  return result ?? false;
}

/// Shared Vikoba logo mark used across the app.
class AppLogo extends StatelessWidget {
  final double? size;
  final double? width;
  final double? height;
  final Color backgroundColor;
  final Color borderColor;
  final double borderWidth;
  final EdgeInsetsGeometry padding;

  const AppLogo({
    super.key,
    this.size,
    this.width,
    this.height,
    this.backgroundColor = Colors.white,
    this.borderColor = Colors.white,
    this.borderWidth = 2,
    this.padding = const EdgeInsets.all(4),
  });

  @override
  Widget build(BuildContext context) {
    final logoWidth = width ?? size ?? 96;
    final logoHeight = height ?? size ?? 58;
    return Container(
      width: logoWidth,
      height: logoHeight,
      padding: padding,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
        border: borderWidth > 0
            ? Border.all(color: borderColor, width: borderWidth)
            : null,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: logoHeight * 0.12,
            offset: Offset(0, logoHeight * 0.04),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Image.asset(
        appLogoAsset,
        fit: BoxFit.contain,
        errorBuilder: (_, __, ___) => Container(
          color: AppColors.cardGreenBg,
          alignment: Alignment.center,
          child: Icon(Icons.diversity_3,
              color: AppColors.primary, size: logoHeight * 0.5),
        ),
      ),
    );
  }
}

/// A small colored avatar showing a member's initials.
class MemberAvatar extends StatelessWidget {
  final String initials;
  final double size;
  final Color? color;

  const MemberAvatar({
    super.key,
    required this.initials,
    this.size = 46,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final c = color ?? AppColors.primary;
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: c.withValues(alpha: 0.12),
        shape: BoxShape.circle,
      ),
      child: Text(
        initials,
        style: TextStyle(
          color: c,
          fontWeight: FontWeight.w700,
          fontSize: size * 0.38,
        ),
      ),
    );
  }
}

/// A small red "overdue" indicator for loan rows. The caller passes the
/// already-localized text (e.g. "Overdue by 12 days").
class OverdueLabel extends StatelessWidget {
  final String text;
  const OverdueLabel({super.key, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Icon(Icons.warning_amber_rounded,
            color: AppColors.fines, size: 16),
        const SizedBox(width: 6),
        Text(text,
            style: const TextStyle(
                color: AppColors.fines,
                fontWeight: FontWeight.w600,
                fontSize: 12.5)),
      ],
    );
  }
}

/// Rounded status pill used in member / loan lists.
class StatusChip extends StatelessWidget {
  final String label;
  final Color color;
  final Color background;

  const StatusChip({
    super.key,
    required this.label,
    required this.color,
    required this.background,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w600,
          fontSize: 12,
        ),
      ),
    );
  }
}

/// Card showing one dashboard metric (label + value + icon).
class SummaryCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color accent;
  final Color background;

  const SummaryCard({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    required this.accent,
    required this.background,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(16),
      ),
      // Content is laid out to never overflow the fixed-aspect grid cell, even
      // at large system text scales: the label is capped to two lines and the
      // value shrinks to fit rather than pushing past the card's height.
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: accent, size: 18),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  label,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12.5,
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              maxLines: 1,
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w800,
                color: accent,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Section header with optional trailing action ("View all").
class SectionHeader extends StatelessWidget {
  final String title;
  final String? actionLabel;
  final VoidCallback? onAction;

  const SectionHeader({
    super.key,
    required this.title,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
        ),
        if (actionLabel != null)
          GestureDetector(
            onTap: onAction,
            child: Padding(
              padding: const EdgeInsets.only(left: 8),
              child: Row(
                children: [
                  Text(
                    actionLabel!,
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                  const Icon(Icons.arrow_forward,
                      size: 15, color: AppColors.primary),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

/// Generic labeled white card wrapper.
class AppCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;

  const AppCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border),
          ),
          child: child,
        ),
      ),
    );
  }
}

/// Maps an [IconKey] from the model layer to a Material icon + color.
class IconMapper {
  IconMapper._();

  static IconData icon(IconKey key) {
    switch (key) {
      case IconKey.savings:
        return Icons.savings_outlined;
      case IconKey.loan:
        return Icons.handshake_outlined;
      case IconKey.fine:
        return Icons.gavel_outlined;
      case IconKey.meeting:
        return Icons.event_outlined;
    }
  }

  static Color color(IconKey key) {
    switch (key) {
      case IconKey.savings:
        return AppColors.savings;
      case IconKey.loan:
        return AppColors.loans;
      case IconKey.fine:
        return AppColors.fines;
      case IconKey.meeting:
        return AppColors.meetings;
    }
  }
}

/// A labelled form field used by the data-entry screens.
class LabeledField extends StatelessWidget {
  final String label;
  final Widget child;

  const LabeledField({super.key, required this.label, required this.child});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 8),
        child,
        const SizedBox(height: 16),
      ],
    );
  }
}

/// A dropdown styled to match the app's input fields.
class AppDropdown<T> extends StatelessWidget {
  final T? value;
  final List<T> items;
  final String Function(T) labelOf;
  final ValueChanged<T?> onChanged;
  final String? hint;

  const AppDropdown({
    super.key,
    required this.value,
    required this.items,
    required this.labelOf,
    required this.onChanged,
    this.hint,
  });

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<T>(
      initialValue: value,
      isExpanded: true,
      icon: const Icon(Icons.keyboard_arrow_down, color: AppColors.textMuted),
      hint: hint == null ? null : Text(hint!),
      items: [
        for (final item in items)
          DropdownMenuItem(value: item, child: Text(labelOf(item))),
      ],
      onChanged: onChanged,
    );
  }
}

/// A read-only field that opens a date picker.
class AppDateField extends StatelessWidget {
  final DateTime value;
  final ValueChanged<DateTime> onChanged;

  const AppDateField({
    super.key,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: value,
          firstDate: DateTime(2020),
          lastDate: DateTime(2030),
        );
        if (picked != null) onChanged(picked);
      },
      child: InputDecorator(
        decoration: const InputDecoration(
          suffixIcon: Icon(Icons.calendar_today_outlined,
              size: 18, color: AppColors.textMuted),
        ),
        child: Text(
          '${value.day.toString().padLeft(2, '0')}/'
          '${value.month.toString().padLeft(2, '0')}/${value.year}',
        ),
      ),
    );
  }
}

/// A highlighted result/summary banner (e.g. "Current savings ... TZS 1,250,000").
class HighlightBanner extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final Color background;

  const HighlightBanner({
    super.key,
    required this.label,
    required this.value,
    this.color = AppColors.primary,
    this.background = AppColors.cardGreenBg,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: TextStyle(
                  fontSize: 13,
                  color: color.withValues(alpha: 0.85),
                  fontWeight: FontWeight.w500)),
          const SizedBox(height: 6),
          Text(value,
              style: TextStyle(
                  fontSize: 22, fontWeight: FontWeight.w800, color: color)),
        ],
      ),
    );
  }
}

/// A friendly placeholder shown when a list or section has no data yet, with an
/// icon, a title, an optional explanatory line, and an optional call to action.
/// Replaces the ad-hoc "—" / bespoke empties so every empty view looks the same.
class EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final String? actionLabel;
  final VoidCallback? onAction;
  final EdgeInsetsGeometry padding;

  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.actionLabel,
    this.onAction,
    this.padding = const EdgeInsets.symmetric(horizontal: 24, vertical: 36),
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: padding,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: const BoxDecoration(
                color: AppColors.cardGreenBg,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 34, color: AppColors.primary),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                  fontSize: 15.5,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary),
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 6),
              Text(
                subtitle!,
                textAlign: TextAlign.center,
                style: const TextStyle(
                    fontSize: 13, color: AppColors.textSecondary, height: 1.4),
              ),
            ],
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 18),
              OutlinedButton(onPressed: onAction, child: Text(actionLabel!)),
            ],
          ],
        ),
      ),
    );
  }
}

/// A single rounded grey block used to sketch the shape of loading content.
/// Wrap a group of these in a [Shimmer] to animate them.
class SkeletonBox extends StatelessWidget {
  final double? width;
  final double height;
  final double radius;

  const SkeletonBox({
    super.key,
    this.width,
    this.height = 14,
    this.radius = 8,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: _kSkeletonBase,
        borderRadius: BorderRadius.circular(radius),
      ),
    );
  }
}

const Color _kSkeletonBase = Color(0xFFE9EEEB);
const Color _kSkeletonHighlight = Color(0xFFF5F9F7);

/// Animates a light sweep across its (skeleton) [child] to signal loading.
/// Pure Flutter — no extra package. The child should be built from opaque
/// [SkeletonBox]es so the sweep is painted over them.
class Shimmer extends StatefulWidget {
  final Widget child;
  const Shimmer({super.key, required this.child});

  @override
  State<Shimmer> createState() => _ShimmerState();
}

class _ShimmerState extends State<Shimmer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1200),
  )..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final t = _controller.value;
        return ShaderMask(
          blendMode: BlendMode.srcATop,
          shaderCallback: (bounds) => LinearGradient(
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
            colors: const [
              _kSkeletonBase,
              _kSkeletonHighlight,
              _kSkeletonBase,
            ],
            stops: [
              (t - 0.3).clamp(0.0, 1.0),
              t.clamp(0.0, 1.0),
              (t + 0.3).clamp(0.0, 1.0),
            ],
          ).createShader(bounds),
          child: child,
        );
      },
      child: widget.child,
    );
  }
}

/// An inline warning bar shown when the app can't reach the backend, offering a
/// Retry that re-fetches the snapshot. Used at the top of data screens so a
/// failed load never shows as silently-empty (or all-zero) data.
class ConnectionBanner extends StatelessWidget {
  final String message;
  final String retryLabel;
  final VoidCallback onRetry;

  const ConnectionBanner({
    super.key,
    required this.message,
    required this.retryLabel,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 10, 8, 10),
      decoration: BoxDecoration(
        color: AppColors.cardRedBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.fines.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.cloud_off_rounded, color: AppColors.fines, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 13,
                  fontWeight: FontWeight.w500),
            ),
          ),
          const SizedBox(width: 8),
          TextButton(
            onPressed: onRetry,
            style: TextButton.styleFrom(
              foregroundColor: AppColors.fines,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              minimumSize: const Size(0, 36),
            ),
            child: Text(retryLabel,
                style: const TextStyle(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }
}
