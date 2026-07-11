import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../core/l10n/locale_provider.dart';
import '../../core/state/app_state.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/formatters.dart';

/// A dependency-free data backup: serialises the whole group snapshot to
/// indented JSON that can be copied out (to a note, email, or file). Restoring
/// from a backup needs write access to the store and is a planned follow-up.
class BackupScreen extends StatelessWidget {
  const BackupScreen({super.key});

  String _export(AppState s) {
    final data = <String, dynamic>{
      'group': {'name': s.groupName, 'term': s.term},
      'generatedOn': Fmt.date(DateTime.now()),
      'totals': {
        'cashInHand': s.cashInHand,
        'totalSavings': s.totalSavings,
        'activeLoans': s.activeLoans,
        'socialFundBalance': s.socialFundBalance,
        'finesCollected': s.finesCollected,
      },
      'members': [for (final m in s.members) m.toJson()],
      'loans': [for (final l in s.loans) l.toJson()],
      'savings': [for (final e in s.savings) e.toJson()],
      'fines': [for (final f in s.fines) f.toJson()],
      'officers': [for (final o in s.officers) o.toJson()],
      'meetings': [
        for (final m in s.meetings)
          {
            'number': m.number,
            'date': m.date.toIso8601String(),
            'attended': m.attended,
            'total': m.total,
            'decisions': m.decisions,
            'collections': m.collections,
            'fines': m.fines,
            'title': m.title,
            'status': m.status.name,
          },
      ],
    };
    return const JsonEncoder.withIndent('  ').convert(data);
  }

  @override
  Widget build(BuildContext context) {
    final locale = context.watch<LocaleProvider>();
    final state = context.watch<AppState>();
    final text = _export(state);

    return Scaffold(
      appBar: AppBar(
        leading: const BackButton(),
        title: Text(locale.t('backup_title')),
        actions: [
          IconButton(
            icon: const Icon(Icons.copy_outlined),
            tooltip: locale.t('copy'),
            onPressed: () {
              Clipboard.setData(ClipboardData(text: text));
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  backgroundColor: AppColors.primary,
                  content: Text(locale.t('backup_copied'))));
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Text(locale.t('backup_desc'),
                style: const TextStyle(
                    color: AppColors.textSecondary, fontSize: 13.5)),
          ),
          Expanded(
            child: Container(
              margin: const EdgeInsets.fromLTRB(16, 4, 16, 12),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.border),
              ),
              child: SingleChildScrollView(
                child: SelectableText(
                  text,
                  style: const TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 12,
                      height: 1.4,
                      color: AppColors.textPrimary),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: text));
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      backgroundColor: AppColors.primary,
                      content: Text(locale.t('backup_copied'))));
                },
                icon: const Icon(Icons.copy_all_outlined),
                label: Text(locale.t('copy')),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
