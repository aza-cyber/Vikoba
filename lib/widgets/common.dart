import 'package:flutter/material.dart';
import '../core/models/models.dart';
import '../core/theme/app_colors.dart';

const String appLogoAsset = 'assets/images/vikoba_logo.png';

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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
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
                  style: const TextStyle(
                    fontSize: 12.5,
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w800,
              color: accent,
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
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        if (actionLabel != null)
          GestureDetector(
            onTap: onAction,
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
