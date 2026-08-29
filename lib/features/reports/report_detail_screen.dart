import 'dart:io' show File;

import 'package:excel/excel.dart' as xls;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import '../../core/l10n/locale_provider.dart';
import '../../core/models/models.dart';
import '../../core/state/app_state.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/formatters.dart';
import '../../widgets/common.dart';

/// The eight reports the group can generate from its live data.
enum ReportType {
  savings,
  loans,
  repayments,
  fines,
  meetings,
  cashbook,
  shareout,
  members,
}

/// A fully-generated report: a title, headline figures, and a data table —
/// all derived from the current [AppState] snapshot.
class _Report {
  final String title;
  final List<(String, String)> summary;
  final List<String> columns;
  final List<List<String>> rows;
  const _Report({
    required this.title,
    required this.summary,
    required this.columns,
    required this.rows,
  });
}

/// Generates and displays one report on screen. The same data can be copied to
/// the clipboard as plain text (a dependency-free "export").
class ReportDetailScreen extends StatelessWidget {
  final ReportType type;
  const ReportDetailScreen({super.key, required this.type});

  @override
  Widget build(BuildContext context) {
    final locale = context.watch<LocaleProvider>();
    final state = context.watch<AppState>();
    final report = _build(type, state, locale);
    final generatedOn = Fmt.date(DateTime.now());

    return Scaffold(
      appBar: AppBar(
        leading: const BackButton(),
        title: Text(report.title),
        actions: [
          IconButton(
            icon: const Icon(Icons.picture_as_pdf_outlined),
            tooltip: locale.t('download_pdf'),
            onPressed: () => _downloadPdf(context, report, state, locale),
          ),
          IconButton(
            icon: const Icon(Icons.grid_on_outlined),
            tooltip: locale.t('download_excel'),
            onPressed: () => _downloadExcel(context, report, state, locale),
          ),
          IconButton(
            icon: const Icon(Icons.copy_outlined),
            tooltip: locale.t('copy'),
            onPressed: () {
              Clipboard.setData(ClipboardData(
                  text: _asText(report, state, locale, generatedOn)));
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  backgroundColor: AppColors.primary,
                  content: Text(locale.t('report_copied')),
                ),
              );
            },
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        children: [
          // Report header (group + generated timestamp).
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppColors.primary, AppColors.primaryDark],
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(state.groupName,
                    style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 16)),
                const SizedBox(height: 2),
                Text('${locale.t('term_label')}: ${state.term}',
                    style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.85),
                        fontSize: 12.5)),
                const SizedBox(height: 8),
                Text('${locale.t('report_generated_on')}: $generatedOn',
                    style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.9),
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600)),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Headline figures.
          if (report.summary.isNotEmpty) ...[
            SectionHeader(title: locale.t('summary')),
            const SizedBox(height: 10),
            AppCard(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              child: Column(
                children: [
                  for (final s in report.summary)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Flexible(
                            child: Text(s.$1,
                                style: const TextStyle(
                                    fontSize: 13.5,
                                    color: AppColors.textSecondary,
                                    fontWeight: FontWeight.w500)),
                          ),
                          const SizedBox(width: 12),
                          Text(s.$2,
                              style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.textPrimary)),
                        ],
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 18),
          ],

          SizedBox(
            height: 48,
            child: ElevatedButton.icon(
              onPressed: () => _downloadPdf(context, report, state, locale),
              icon: const Icon(Icons.picture_as_pdf_outlined, size: 20),
              label: Text(locale.t('download_pdf')),
            ),
          ),
          const SizedBox(height: 18),

          // Data table.
          SectionHeader(title: report.title),
          const SizedBox(height: 10),
          if (report.rows.isEmpty)
            AppCard(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Text(locale.t('no_records'),
                      style: const TextStyle(color: AppColors.textMuted)),
                ),
              ),
            )
          else
            Container(
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.border),
              ),
              clipBehavior: Clip.antiAlias,
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: DataTable(
                  headingRowColor: WidgetStateProperty.all(AppColors.scaffold),
                  headingTextStyle: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                      color: AppColors.textPrimary),
                  dataTextStyle: const TextStyle(
                      fontSize: 13, color: AppColors.textPrimary),
                  columns: [
                    for (final c in report.columns) DataColumn(label: Text(c)),
                  ],
                  rows: [
                    for (final r in report.rows)
                      DataRow(
                        cells: [for (final cell in r) DataCell(Text(cell))],
                      ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  // ------------------------------------------------------------- generators
  _Report _build(ReportType type, AppState s, LocaleProvider t) {
    switch (type) {
      case ReportType.savings:
        return _Report(
          title: t.t('report_savings'),
          summary: [
            (t.t('total_savings'), Fmt.tzs(s.totalSavings)),
            (t.t('members_count'), '${s.membersCount}'),
          ],
          columns: [t.t('member'), t.t('shares'), t.t('col_amount')],
          rows: [
            for (final m in s.members)
              [m.name, '${m.shares}', Fmt.tzs(m.savings)],
          ],
        );
      case ReportType.loans:
        return _Report(
          title: t.t('report_loans'),
          summary: [
            (t.t('active_loans'), Fmt.tzs(s.activeLoans)),
            (t.t('loans_disbursed'), Fmt.tzs(s.loansDisbursed)),
          ],
          columns: [
            t.t('member'),
            t.t('loan_amount_short'),
            t.t('balance'),
            t.t('col_status'),
          ],
          rows: [
            for (final l in s.loans)
              [
                l.memberName,
                Fmt.tzs(l.principal),
                Fmt.tzs(l.balance),
                _loanStatus(l.status, t),
              ],
          ],
        );
      case ReportType.repayments:
        return _Report(
          title: t.t('report_repayments'),
          summary: [
            (t.t('total_income'), Fmt.tzs(s.repaymentsCollected)),
          ],
          columns: [t.t('member'), t.t('date'), t.t('col_amount')],
          rows: [
            for (final r in s.repayments)
              [r.memberName, Fmt.date(r.date), Fmt.tzs(r.amount)],
          ],
        );
      case ReportType.fines:
        return _Report(
          title: t.t('report_fines'),
          summary: [
            (t.t('fines_collected'), Fmt.tzs(s.finesCollected)),
            (t.t('outstanding_penalties'), '${s.outstandingFines.length}'),
          ],
          columns: [
            t.t('member'),
            t.t('col_reason'),
            t.t('col_amount'),
            t.t('col_status'),
          ],
          rows: [
            for (final f in s.fines)
              [
                f.memberName,
                f.reason,
                Fmt.tzs(f.amount),
                f.paid ? t.t('col_paid') : t.t('col_unpaid'),
              ],
          ],
        );
      case ReportType.meetings:
        return _Report(
          title: t.t('report_meetings'),
          summary: [
            (t.t('meetings'), '${s.meetingsHeld}'),
          ],
          columns: [
            t.t('meeting_no'),
            t.t('date'),
            t.t('attendance'),
            t.t('collections'),
          ],
          rows: [
            for (final m in s.meetings)
              [
                '#${m.number}',
                Fmt.date(m.date),
                '${m.attended}/${m.total}',
                Fmt.tzs(m.collections),
              ],
          ],
        );
      case ReportType.cashbook:
        return _Report(
          title: t.t('report_cashbook'),
          summary: [
            (t.t('total_income'), Fmt.tzs(s.totalIncome)),
            (t.t('total_expenses'), Fmt.tzs(s.totalExpense)),
            (t.t('current_balance'), Fmt.tzs(s.cashInHand)),
          ],
          columns: [t.t('col_item'), t.t('col_amount')],
          rows: [
            [t.t('savings_title'), Fmt.tzs(s.savingsCollected)],
            [t.t('report_repayments'), Fmt.tzs(s.repaymentsCollected)],
            [t.t('fines_collected'), Fmt.tzs(s.finesCollected)],
            [t.t('loans_disbursed'), Fmt.tzs(s.loansDisbursed)],
            [t.t('meeting_expense'), Fmt.tzs(s.meetingExpense)],
            [t.t('other_expense'), Fmt.tzs(s.otherExpense)],
          ],
        );
      case ReportType.shareout:
        final payout = s.shareCapital + s.distributableProfit;
        final perMember = s.membersCount == 0 ? 0.0 : payout / s.membersCount;
        return _Report(
          title: t.t('report_shareout'),
          summary: [
            (t.t('share_capital'), Fmt.tzs(s.shareCapital)),
            (t.t('distributable_profit'), Fmt.tzs(s.distributableProfit)),
            (t.t('total_payout'), Fmt.tzs(payout)),
          ],
          columns: [t.t('col_item'), t.t('col_amount')],
          rows: [
            [t.t('interest_earned'), Fmt.tzs(s.interestEarned)],
            [t.t('fines_income'), Fmt.tzs(s.finesCollected)],
            [t.t('share_capital'), Fmt.tzs(s.shareCapital)],
            [t.t('per_member_payout'), Fmt.tzs(perMember)],
          ],
        );
      case ReportType.members:
        return _Report(
          title: t.t('report_members'),
          summary: [
            (t.t('members_count'), '${s.membersCount}'),
            (t.t('shares'), '${s.totalShares}'),
          ],
          columns: [
            t.t('member'),
            t.t('phone'),
            t.t('shares'),
            t.t('col_status'),
          ],
          rows: [
            for (final m in s.members)
              [
                m.name,
                Fmt.phone(m.phone),
                '${m.shares}',
                m.status == MemberStatus.borrower
                    ? t.t('status_borrower')
                    : t.t('status_active'),
              ],
          ],
        );
    }
  }

  String _loanStatus(LoanStatus status, LocaleProvider t) => switch (status) {
        LoanStatus.ongoing => t.t('tab_ongoing'),
        LoanStatus.paid => t.t('tab_paid'),
        LoanStatus.request => t.t('loan_request'),
        LoanStatus.rejected => t.t('status_rejected'),
      };

  Future<void> _downloadPdf(
    BuildContext context,
    _Report report,
    AppState state,
    LocaleProvider locale,
  ) async {
    final generatedOn = Fmt.date(DateTime.now());
    try {
      final bytes = await _asPdf(report, state, locale, generatedOn);
      await Printing.sharePdf(
        bytes: bytes,
        filename: '${_fileName(report.title)}.pdf',
      );
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppColors.primary,
          content: Text(locale.t('pdf_ready')),
        ),
      );
    } catch (_) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: const Color(0xFFC0392B),
          content: Text(locale.t('pdf_failed')),
        ),
      );
    }
  }

  Future<void> _downloadExcel(
    BuildContext context,
    _Report report,
    AppState state,
    LocaleProvider locale,
  ) async {
    final generatedOn = Fmt.date(DateTime.now());
    try {
      final bytes = _asExcel(report, state, locale, generatedOn);
      final filename = '${_fileName(report.title)}.xlsx';
      // On the web there is no filesystem, so hand the bytes to share_plus
      // directly (it makes a blob download). On mobile/desktop, stage the bytes
      // in the temp dir and share that file — mirroring the PDF flow.
      final XFile xfile;
      if (kIsWeb) {
        xfile = XFile.fromData(bytes, mimeType: _xlsxMime, name: filename);
      } else {
        final dir = await getTemporaryDirectory();
        final file = File('${dir.path}/$filename');
        await file.writeAsBytes(bytes, flush: true);
        xfile = XFile(file.path, mimeType: _xlsxMime, name: filename);
      }
      await Share.shareXFiles([xfile], subject: report.title);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppColors.primary,
          content: Text(locale.t('excel_ready')),
        ),
      );
    } catch (_) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: const Color(0xFFC0392B),
          content: Text(locale.t('excel_failed')),
        ),
      );
    }
  }

  static const _xlsxMime =
      'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet';

  /// Builds a real .xlsx workbook: a header block (group / term / generated
  /// date), the summary figures, then the data table — the same content as the
  /// PDF, but as spreadsheet cells the treasurer can sort and total.
  Uint8List _asExcel(
    _Report report,
    AppState state,
    LocaleProvider locale,
    String generatedOn,
  ) {
    final book = xls.Excel.createExcel();
    // Rename the default sheet rather than adding a second one (which would
    // leave an empty 'Sheet1' behind).
    final defaultSheet = book.getDefaultSheet()!;
    const sheetName = 'Report';
    book.rename(defaultSheet, sheetName);
    final sheet = book[sheetName];

    final titleStyle = xls.CellStyle(bold: true, fontSize: 14);
    final headerStyle = xls.CellStyle(
      bold: true,
      backgroundColorHex: xls.ExcelColor.fromHexString('#E8F5E9'),
    );
    final labelStyle = xls.CellStyle(bold: true);

    var row = 0;

    void writeRow(List<String> values, {xls.CellStyle? style}) {
      for (var col = 0; col < values.length; col++) {
        final cell = sheet.cell(
            xls.CellIndex.indexByColumnRow(columnIndex: col, rowIndex: row));
        cell.value = xls.TextCellValue(values[col]);
        if (style != null) cell.cellStyle = style;
      }
      row++;
    }

    // Header block.
    writeRow([report.title], style: titleStyle);
    writeRow(['${state.groupName} — ${locale.t('term_label')}: ${state.term}']);
    writeRow(['${locale.t('report_generated_on')}: $generatedOn']);
    row++; // blank spacer

    // Summary figures (label / value pairs).
    if (report.summary.isNotEmpty) {
      writeRow([locale.t('summary')], style: labelStyle);
      for (final item in report.summary) {
        writeRow([item.$1, item.$2]);
      }
      row++; // blank spacer
    }

    // Data table.
    if (report.rows.isEmpty) {
      writeRow([locale.t('no_records')]);
    } else {
      writeRow(report.columns, style: headerStyle);
      for (final r in report.rows) {
        writeRow(r);
      }
    }

    final encoded = book.encode();
    if (encoded == null) {
      throw StateError('Excel encoding returned no bytes');
    }
    return Uint8List.fromList(encoded);
  }

  Future<Uint8List> _asPdf(
    _Report report,
    AppState state,
    LocaleProvider locale,
    String generatedOn,
  ) async {
    final pdf = pw.Document();
    final tableRows = report.rows.isEmpty
        ? [
            [locale.t('no_records')]
          ]
        : report.rows;
    final tableHeaders = report.rows.isEmpty ? [report.title] : report.columns;

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(28),
        header: (context) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(
              report.title,
              style: pw.TextStyle(
                fontSize: 20,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.green800,
              ),
            ),
            pw.SizedBox(height: 4),
            pw.Text(
              '${state.groupName} - ${locale.t('term_label')}: ${state.term}',
              style: const pw.TextStyle(fontSize: 10),
            ),
            pw.Text(
              '${locale.t('report_generated_on')}: $generatedOn',
              style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700),
            ),
            pw.Divider(color: PdfColors.green800),
          ],
        ),
        footer: (context) => pw.Align(
          alignment: pw.Alignment.centerRight,
          child: pw.Text(
            '${context.pageNumber} / ${context.pagesCount}',
            style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey600),
          ),
        ),
        build: (context) => [
          if (report.summary.isNotEmpty) ...[
            pw.Text(
              locale.t('summary'),
              style: pw.TextStyle(
                fontSize: 13,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
            pw.SizedBox(height: 8),
            pw.Table(
              border: pw.TableBorder.all(color: PdfColors.grey300),
              children: [
                for (final item in report.summary)
                  pw.TableRow(
                    children: [
                      _pdfCell(item.$1, bold: true),
                      _pdfCell(item.$2, alignRight: true),
                    ],
                  ),
              ],
            ),
            pw.SizedBox(height: 18),
          ],
          pw.Text(
            report.title,
            style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 8),
          pw.TableHelper.fromTextArray(
            headers: tableHeaders,
            data: tableRows,
            border: pw.TableBorder.all(color: PdfColors.grey300),
            headerDecoration: const pw.BoxDecoration(color: PdfColors.green50),
            headerStyle: pw.TextStyle(
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.green900,
            ),
            cellStyle: const pw.TextStyle(fontSize: 9),
            cellAlignment: pw.Alignment.centerLeft,
            headerAlignment: pw.Alignment.centerLeft,
            cellPadding:
                const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 5),
          ),
        ],
      ),
    );

    return pdf.save();
  }

  pw.Widget _pdfCell(
    String text, {
    bool bold = false,
    bool alignRight = false,
  }) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      child: pw.Align(
        alignment:
            alignRight ? pw.Alignment.centerRight : pw.Alignment.centerLeft,
        child: pw.Text(
          text,
          style: pw.TextStyle(
            fontSize: 10,
            fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
          ),
        ),
      ),
    );
  }

  String _fileName(String title) {
    final cleaned = title
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
        .replaceAll(RegExp(r'_+'), '_')
        .replaceAll(RegExp(r'^_|_$'), '');
    final date = DateTime.now().toIso8601String().substring(0, 10);
    return '${cleaned.isEmpty ? 'report' : cleaned}_$date';
  }

  /// Plain-text rendering used for the clipboard "export".
  String _asText(_Report r, AppState s, LocaleProvider t, String generatedOn) {
    final b = StringBuffer();
    b.writeln(r.title);
    b.writeln('${s.groupName} — ${t.t('term_label')}: ${s.term}');
    b.writeln('${t.t('report_generated_on')}: $generatedOn');
    b.writeln();
    for (final item in r.summary) {
      b.writeln('${item.$1}: ${item.$2}');
    }
    b.writeln();
    b.writeln(r.columns.join('\t'));
    for (final row in r.rows) {
      b.writeln(row.join('\t'));
    }
    return b.toString();
  }
}
