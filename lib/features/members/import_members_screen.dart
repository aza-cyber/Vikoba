import 'dart:io';

import 'package:excel/excel.dart' as xls;
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/l10n/locale_provider.dart';
import '../../core/state/app_state.dart';
import '../../core/theme/app_colors.dart';
import '../../widgets/common.dart';
import 'member_import.dart';

/// Admin-only bulk member import: pick an .xlsx, review the parsed rows (valid vs
/// flagged), confirm, then add every valid member in one batch. A downloadable
/// template shows the expected Name / Phone / Shares layout.
class ImportMembersScreen extends StatefulWidget {
  const ImportMembersScreen({super.key});

  @override
  State<ImportMembersScreen> createState() => _ImportMembersScreenState();
}

class _ImportMembersScreenState extends State<ImportMembersScreen> {
  MemberWorkbook? _workbook;
  MemberColumnMapping? _mapping;
  MemberImport? _parsed;
  Set<String> _existingPhones = const {};
  String? _fileName;
  bool _busy = false;

  static const _xlsxMime =
      'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet';

  Future<void> _pick(LocaleProvider locale) async {
    final appState = context.read<AppState>();
    setState(() => _busy = true);
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: const ['xlsx'],
        withData: true,
      );
      if (result == null) {
        if (mounted) setState(() => _busy = false);
        return; // cancelled
      }
      final file = result.files.single;
      final bytes = file.bytes;
      if (bytes == null) {
        _snack(locale.t('import_unreadable'), error: true);
        if (mounted) setState(() => _busy = false);
        return;
      }
      final existing = <String>{
        for (final m in appState.members)
          if (m.phone.trim().isNotEmpty) normalizeImportPhone(m.phone)
      };
      final workbook = readMemberWorkbook(Uint8List.fromList(bytes));
      if (!mounted) return;
      setState(() {
        _workbook = workbook;
        _mapping = workbook.suggested;
        _existingPhones = existing;
        _fileName = file.name;
        _parsed = parseWithMapping(workbook, workbook.suggested,
            existingPhones: existing);
        _busy = false;
      });
    } catch (_) {
      if (!mounted) return;
      _snack(locale.t('import_unreadable'), error: true);
      setState(() => _busy = false);
    }
  }

  /// Re-parses the current workbook with an updated column mapping.
  void _remap(MemberColumnMapping mapping) {
    final wb = _workbook;
    if (wb == null) return;
    setState(() {
      _mapping = mapping;
      _parsed =
          parseWithMapping(wb, mapping, existingPhones: _existingPhones);
    });
  }

  /// The label for a column index: its header text (when the first row is a
  /// header) or "Column N".
  String _columnLabel(LocaleProvider locale, int col) {
    final wb = _workbook;
    final mapping = _mapping;
    if (wb != null && mapping != null && mapping.hasHeader && col < wb.firstRow.length) {
      final h = wb.firstRow[col].trim();
      if (h.isNotEmpty) return h;
    }
    return locale.t('column_label').replaceFirst('{n}', '${col + 1}');
  }

  Future<void> _import(LocaleProvider locale, MemberImport parsed) async {
    final appState = context.read<AppState>();
    final valid = parsed.validRows;
    if (valid.isEmpty) {
      _snack(locale.t('no_valid_rows'), error: true);
      return;
    }
    final ok = await showConfirmSummary(
      context,
      title: locale.t('confirm_details'),
      rows: [
        (locale.t('valid_rows'), '${valid.length}'),
        (locale.t('invalid_rows'), '${parsed.invalidCount}'),
      ],
      confirmLabel: locale.t('import_action'),
      cancelLabel: locale.t('cancel'),
      note: locale.t('please_review'),
    );
    if (!ok || !mounted) return;

    setState(() => _busy = true);
    final (added, failed) = await appState.importMembers([
      for (final r in valid) (name: r.name, phone: r.phone, shares: r.shares)
    ]);
    if (!mounted) return;
    setState(() => _busy = false);
    _snack(locale
        .t('imported_summary')
        .replaceFirst('{a}', '$added')
        .replaceFirst('{b}', '$failed'));
    Navigator.of(context).maybePop();
  }

  Future<void> _downloadTemplate(LocaleProvider locale) async {
    try {
      final book = xls.Excel.createExcel();
      final sheet = book[book.getDefaultSheet()!];
      sheet.appendRow([
        xls.TextCellValue('Name'),
        xls.TextCellValue('Phone'),
        xls.TextCellValue('Shares'),
      ]);
      sheet.appendRow([
        xls.TextCellValue('Asha Juma'),
        xls.TextCellValue('0712345678'),
        xls.IntCellValue(3),
      ]);
      final bytes = Uint8List.fromList(book.encode()!);
      const filename = 'members_template.xlsx';
      final XFile xfile;
      if (kIsWeb) {
        xfile = XFile.fromData(bytes, mimeType: _xlsxMime, name: filename);
      } else {
        final dir = await getTemporaryDirectory();
        final f = File('${dir.path}/$filename');
        await f.writeAsBytes(bytes, flush: true);
        xfile = XFile(f.path, mimeType: _xlsxMime, name: filename);
      }
      await Share.shareXFiles([xfile], subject: locale.t('download_template'));
    } catch (_) {
      _snack(locale.t('excel_failed'), error: true);
    }
  }

  void _snack(String message, {bool error = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      backgroundColor: error ? const Color(0xFFC0392B) : AppColors.primary,
      content: Text(message),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final locale = context.watch<LocaleProvider>();
    final parsed = _parsed;

    return Scaffold(
      appBar: AppBar(
        title: Text(locale.t('import_members')),
        actions: [
          IconButton(
            tooltip: locale.t('download_template'),
            icon: const Icon(Icons.download_outlined),
            onPressed: _busy ? null : () => _downloadTemplate(locale),
          ),
        ],
      ),
      body: _busy && parsed == null
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
              children: [
                Text(locale.t('import_hint'),
                    style: const TextStyle(color: AppColors.textSecondary)),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: _busy ? null : () => _pick(locale),
                  icon: const Icon(Icons.upload_file_outlined),
                  label: Text(_fileName ?? locale.t('choose_file')),
                ),
                if (_workbook?.isUsable == true) ...[
                  const SizedBox(height: 16),
                  _mappingCard(locale),
                ],
                if (parsed != null) ...[
                  const SizedBox(height: 16),
                  if (parsed.fatalKey != null)
                    _fatal(locale.t(parsed.fatalKey!))
                  else ...[
                    Row(
                      children: [
                        _CountChip(
                            label: locale.t('valid_rows'),
                            count: parsed.validCount,
                            color: AppColors.primary),
                        const SizedBox(width: 10),
                        _CountChip(
                            label: locale.t('invalid_rows'),
                            count: parsed.invalidCount,
                            color: AppColors.fines),
                      ],
                    ),
                    const SizedBox(height: 12),
                    for (final r in parsed.rows)
                      _RowTile(row: r, locale: locale),
                  ],
                ],
              ],
            ),
      bottomNavigationBar: (parsed != null &&
              parsed.fatalKey == null &&
              parsed.validCount > 0)
          ? SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                child: ElevatedButton.icon(
                  onPressed: _busy ? null : () => _import(locale, parsed),
                  icon: const Icon(Icons.group_add_outlined),
                  label: Text(
                      '${locale.t('import_action')} (${parsed.validCount})'),
                ),
              ),
            )
          : null,
    );
  }

  /// Lets the admin override which column maps to Name / Phone / Shares (and
  /// whether the first row is a header), re-parsing the preview on every change.
  Widget _mappingCard(LocaleProvider locale) {
    final wb = _workbook!;
    final mapping = _mapping!;
    const none = MemberColumnMapping.noColumn;
    final allCols = List.generate(wb.columnCount, (i) => i);
    final optionalCols = [none, ...allCols];
    String optionalLabel(int i) =>
        i == none ? locale.t('col_none') : _columnLabel(locale, i);

    return AppCard(
      padding: const EdgeInsets.fromLTRB(14, 6, 14, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(locale.t('first_row_header')),
            value: mapping.hasHeader,
            onChanged: (v) => _remap(mapping.copyWith(hasHeader: v)),
          ),
          LabeledField(
            label: locale.t('name_column'),
            child: AppDropdown<int>(
              value: mapping.nameCol.clamp(0, wb.columnCount - 1),
              items: allCols,
              labelOf: (i) => _columnLabel(locale, i),
              onChanged: (i) =>
                  _remap(mapping.copyWith(nameCol: i ?? mapping.nameCol)),
            ),
          ),
          LabeledField(
            label: locale.t('phone_column'),
            child: AppDropdown<int>(
              value: mapping.phoneCol,
              items: optionalCols,
              labelOf: optionalLabel,
              onChanged: (i) =>
                  _remap(mapping.copyWith(phoneCol: i ?? none)),
            ),
          ),
          LabeledField(
            label: locale.t('shares_column'),
            child: AppDropdown<int>(
              value: mapping.sharesCol,
              items: optionalCols,
              labelOf: optionalLabel,
              onChanged: (i) =>
                  _remap(mapping.copyWith(sharesCol: i ?? none)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _fatal(String message) => Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.cardRedBg,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            const Icon(Icons.error_outline, color: AppColors.fines),
            const SizedBox(width: 10),
            Expanded(
                child: Text(message,
                    style: const TextStyle(color: AppColors.fines))),
          ],
        ),
      );
}

class _CountChip extends StatelessWidget {
  final String label;
  final int count;
  final Color color;
  const _CountChip(
      {required this.label, required this.count, required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Column(
          children: [
            Text('$count',
                style: TextStyle(
                    fontWeight: FontWeight.w800, fontSize: 20, color: color)),
            Text(label,
                style:
                    const TextStyle(fontSize: 12, color: AppColors.textMuted)),
          ],
        ),
      ),
    );
  }
}

class _RowTile extends StatelessWidget {
  final ImportedMemberRow row;
  final LocaleProvider locale;
  const _RowTile({required this.row, required this.locale});

  @override
  Widget build(BuildContext context) {
    final ok = row.isValid;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: AppCard(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Icon(ok ? Icons.check_circle_outline : Icons.error_outline,
                color: ok ? AppColors.primary : AppColors.fines, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(row.name.isEmpty ? '—' : row.name,
                      style: const TextStyle(
                          fontWeight: FontWeight.w700, fontSize: 14)),
                  const SizedBox(height: 2),
                  Text(
                    ok
                        ? '${row.phone.isEmpty ? '—' : row.phone} · ${locale.t('shares')}: ${row.shares}'
                        : '${locale.t('row_label')} ${row.rowNumber} · ${locale.t(row.errorKey!)}',
                    style: TextStyle(
                        fontSize: 12,
                        color: ok ? AppColors.textMuted : AppColors.fines),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
