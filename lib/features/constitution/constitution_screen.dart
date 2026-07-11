import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/l10n/locale_provider.dart';
import '../../core/models/models.dart';
import '../../core/state/app_state.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/formatters.dart';

/// Katiba / Constitution — every article (the built-in rules plus the group's
/// own additions) is stored in the database, so officers (admins) can add, edit
/// and remove any of them. Everyone else views them read-only.
class ConstitutionScreen extends StatelessWidget {
  const ConstitutionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final locale = context.watch<LocaleProvider>();
    final state = context.watch<AppState>();
    final isAdmin = state.isAdmin;
    final articles = state.amendments;

    return Scaffold(
      appBar: AppBar(
        leading: const BackButton(),
        title: Text(locale.t('constitution_title')),
      ),
      floatingActionButton: isAdmin
          ? FloatingActionButton.extended(
              backgroundColor: AppColors.primary,
              onPressed: () => _editArticle(context, locale),
              icon: const Icon(Icons.add, color: Colors.white),
              label: Text(locale.t('add_article'),
                  style: const TextStyle(color: Colors.white)),
            )
          : null,
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 90),
        children: [
          Text(locale.t('const_intro'),
              style: const TextStyle(
                  color: AppColors.textSecondary, fontSize: 13.5, height: 1.4)),
          const SizedBox(height: 16),
          if (articles.isEmpty)
            Text(isAdmin ? locale.t('no_amendments') : '—',
                style:
                    const TextStyle(color: AppColors.textMuted, fontSize: 13)),
          for (var i = 0; i < articles.length; i++) ...[
            _AmendmentCard(
              index: i + 1,
              amendment: articles[i],
              isAdmin: isAdmin,
              onEdit: () => _editArticle(context, locale, existing: articles[i]),
              onDelete: () => _confirmDelete(context, locale, articles[i]),
            ),
            const SizedBox(height: 12),
          ],
        ],
      ),
    );
  }

  /// Opens the add/edit dialog. Pass [existing] to edit, omit to add.
  Future<void> _editArticle(BuildContext context, LocaleProvider locale,
      {Amendment? existing}) async {
    final titleCtrl = TextEditingController(text: existing?.title ?? '');
    final bodyCtrl = TextEditingController(text: existing?.body ?? '');
    final state = context.read<AppState>();

    final saved = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(existing == null
            ? locale.t('add_article')
            : locale.t('edit_article')),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleCtrl,
                textCapitalization: TextCapitalization.sentences,
                decoration:
                    InputDecoration(labelText: locale.t('amendment_title')),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: bodyCtrl,
                maxLines: 5,
                textCapitalization: TextCapitalization.sentences,
                decoration:
                    InputDecoration(labelText: locale.t('amendment_body')),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(locale.t('cancel')),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(locale.t('save')),
          ),
        ],
      ),
    );

    if (saved == true) {
      if (existing == null) {
        await state.addAmendment(
            title: titleCtrl.text, body: bodyCtrl.text);
      } else {
        await state.updateAmendment(
            id: existing.id, title: titleCtrl.text, body: bodyCtrl.text);
      }
    }
    titleCtrl.dispose();
    bodyCtrl.dispose();
  }

  Future<void> _confirmDelete(
      BuildContext context, LocaleProvider locale, Amendment a) async {
    final state = context.read<AppState>();
    final ok = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(locale.t('delete_article')),
        content: Text(a.title),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(locale.t('cancel')),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: AppColors.fines),
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(locale.t('delete')),
          ),
        ],
      ),
    );
    if (ok == true) await state.deleteAmendment(a.id);
  }
}

class _AmendmentCard extends StatelessWidget {
  final int index;
  final Amendment amendment;
  final bool isAdmin;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _AmendmentCard({
    required this.index,
    required this.amendment,
    required this.isAdmin,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 8, 14),
      decoration: BoxDecoration(
        color: AppColors.cardGreenBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.edit_note_rounded,
                  color: AppColors.primary, size: 22),
              const SizedBox(width: 10),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(top: 1),
                  child: Text('$index. ${amendment.title}',
                      style: const TextStyle(
                          fontWeight: FontWeight.w700, fontSize: 15)),
                ),
              ),
              if (isAdmin) ...[
                _IconBtn(
                    icon: Icons.edit_outlined,
                    color: AppColors.textSecondary,
                    onTap: onEdit),
                _IconBtn(
                    icon: Icons.delete_outline,
                    color: AppColors.fines,
                    onTap: onDelete),
              ],
            ],
          ),
          Padding(
            padding: const EdgeInsets.only(left: 32, right: 8, top: 6),
            child: Text(amendment.body,
                style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 13.5,
                    height: 1.45)),
          ),
          Padding(
            padding: const EdgeInsets.only(left: 32, top: 8),
            child: Text(Fmt.date(amendment.date),
                style:
                    const TextStyle(color: AppColors.textMuted, fontSize: 11.5)),
          ),
        ],
      ),
    );
  }
}

class _IconBtn extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  const _IconBtn(
      {required this.icon, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      visualDensity: VisualDensity.compact,
      icon: Icon(icon, color: color, size: 20),
      onPressed: onTap,
    );
  }
}

