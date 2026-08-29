import 'dart:typed_data';
import 'package:excel/excel.dart' as xls;

/// Which column holds what. [phoneCol] and [sharesCol] may be [noColumn] (-1)
/// when the sheet has no such column; [nameCol] is always required. [hasHeader]
/// means the first row is a header and is skipped when reading data.
class MemberColumnMapping {
  static const noColumn = -1;

  final int nameCol;
  final int phoneCol;
  final int sharesCol;
  final bool hasHeader;

  const MemberColumnMapping({
    required this.nameCol,
    this.phoneCol = noColumn,
    this.sharesCol = noColumn,
    required this.hasHeader,
  });

  MemberColumnMapping copyWith({
    int? nameCol,
    int? phoneCol,
    int? sharesCol,
    bool? hasHeader,
  }) =>
      MemberColumnMapping(
        nameCol: nameCol ?? this.nameCol,
        phoneCol: phoneCol ?? this.phoneCol,
        sharesCol: sharesCol ?? this.sharesCol,
        hasHeader: hasHeader ?? this.hasHeader,
      );
}

/// A decoded members workbook: the raw cell grid plus a suggested column
/// mapping. The UI reads [columnCount]/[firstRow] to offer manual mapping and
/// re-runs [parseWithMapping] whenever the admin changes it. [fatalKey] is set
/// (and the grid empty) when the file is unusable.
class MemberWorkbook {
  final List<List<String>> grid;
  final int columnCount;
  final MemberColumnMapping suggested;
  final String? fatalKey;

  const MemberWorkbook({
    required this.grid,
    required this.columnCount,
    required this.suggested,
    this.fatalKey,
  });

  bool get isUsable => fatalKey == null && grid.isNotEmpty;

  /// The first row's cell values — used as header labels when [suggested]
  /// (or the admin) says the first row is a header.
  List<String> get firstRow => grid.isEmpty ? const [] : grid.first;
}

/// One parsed row with a validation verdict. [errorKey] is a locale key
/// describing why the row can't be imported, or null when it's good to add.
class ImportedMemberRow {
  final int rowNumber; // 1-based row in the sheet, for human-readable errors
  final String name;
  final String phone;
  final int shares;
  final String? errorKey;

  const ImportedMemberRow({
    required this.rowNumber,
    required this.name,
    required this.phone,
    required this.shares,
    this.errorKey,
  });

  bool get isValid => errorKey == null;
}

/// The outcome of applying a mapping to a workbook.
class MemberImport {
  final List<ImportedMemberRow> rows;
  final String? fatalKey;

  const MemberImport(this.rows, {this.fatalKey});

  List<ImportedMemberRow> get validRows =>
      rows.where((r) => r.isValid).toList();
  int get validCount => validRows.length;
  int get invalidCount => rows.length - validCount;
}

const _nameAliases = {'name', 'jina', 'member', 'mwanachama', 'full name'};
const _phoneAliases = {
  'phone',
  'simu',
  'namba',
  'namba ya simu',
  'number',
  'phone number',
  'mobile'
};
const _sharesAliases = {'shares', 'hisa', 'share', 'idadi ya hisa'};

/// Last-9-digits phone key — the same lenient match the backend/app use so a
/// number stored as 0712... or +255712... compares equal.
String normalizeImportPhone(String p) {
  final digits = p.replaceAll(RegExp(r'\D'), '');
  return digits.length > 9 ? digits.substring(digits.length - 9) : digits;
}

int? _parseShares(String s) {
  final cleaned = s.replaceAll(RegExp(r'[,\s]'), '');
  if (cleaned.isEmpty) return 0;
  final asInt = int.tryParse(cleaned);
  if (asInt != null) return asInt;
  final asDouble = double.tryParse(cleaned);
  if (asDouble != null) return asDouble.toInt();
  return null; // not a number
}

String _cellString(xls.Data? cell) {
  final v = cell?.value;
  if (v == null) return '';
  if (v is xls.TextCellValue) return v.value.toString();
  if (v is xls.IntCellValue) return v.value.toString();
  if (v is xls.DoubleCellValue) return v.value.toString();
  if (v is xls.BoolCellValue) return v.value.toString();
  return v.toString();
}

/// Decodes an uploaded .xlsx into a [MemberWorkbook] with an auto-detected
/// column mapping. Pure and side-effect free (testable). The admin can override
/// the [MemberWorkbook.suggested] mapping and re-run [parseWithMapping].
MemberWorkbook readMemberWorkbook(Uint8List bytes) {
  xls.Excel book;
  try {
    book = xls.Excel.decodeBytes(bytes);
  } catch (_) {
    return const MemberWorkbook(
        grid: [], columnCount: 0, suggested: _emptyMapping, fatalKey: 'import_unreadable');
  }
  if (book.tables.isEmpty) {
    return const MemberWorkbook(
        grid: [], columnCount: 0, suggested: _emptyMapping, fatalKey: 'import_empty');
  }
  final sheet = book.tables[book.tables.keys.first]!;
  final grid = sheet.rows
      .map((r) => r.map(_cellString).map((s) => s.trim()).toList())
      .toList();
  if (grid.isEmpty) {
    return const MemberWorkbook(
        grid: [], columnCount: 0, suggested: _emptyMapping, fatalKey: 'import_empty');
  }
  final columnCount =
      grid.fold<int>(0, (m, r) => r.length > m ? r.length : m);

  // Auto-detect the mapping from the first row's headers.
  final header = grid.first.map((h) => h.toLowerCase()).toList();
  final ni = header.indexWhere(_nameAliases.contains);
  final pi = header.indexWhere(_phoneAliases.contains);
  final si = header.indexWhere(_sharesAliases.contains);
  final hasHeader = ni >= 0 || pi >= 0;
  final suggested = MemberColumnMapping(
    nameCol: hasHeader ? (ni >= 0 ? ni : 0) : 0,
    phoneCol: hasHeader
        ? pi
        : (columnCount > 1 ? 1 : MemberColumnMapping.noColumn),
    sharesCol: hasHeader
        ? si
        : (columnCount > 2 ? 2 : MemberColumnMapping.noColumn),
    hasHeader: hasHeader,
  );

  return MemberWorkbook(
      grid: grid, columnCount: columnCount, suggested: suggested);
}

const _emptyMapping = MemberColumnMapping(nameCol: 0, hasHeader: false);

/// Applies [mapping] to [wb], validating each data row: a missing name, an
/// unparseable share count, or a phone that duplicates an existing member
/// ([existingPhones], normalized) or an earlier row in the same file.
MemberImport parseWithMapping(
  MemberWorkbook wb,
  MemberColumnMapping mapping, {
  required Set<String> existingPhones,
}) {
  if (!wb.isUsable) return MemberImport(const [], fatalKey: wb.fatalKey);

  final startRow = mapping.hasHeader ? 1 : 0;
  final seenPhones = <String>{};
  final rows = <ImportedMemberRow>[];
  for (var i = startRow; i < wb.grid.length; i++) {
    final r = wb.grid[i];
    String cell(int col) =>
        (col >= 0 && col < r.length) ? r[col] : '';
    final name = cell(mapping.nameCol);
    final phone = cell(mapping.phoneCol);
    final sharesText = cell(mapping.sharesCol);

    // Silently skip blank rows (common trailing rows in a spreadsheet).
    if (name.isEmpty && phone.isEmpty && sharesText.isEmpty) continue;

    String? error;
    var shares = 0;
    final parsedShares = _parseShares(sharesText);
    if (name.isEmpty) {
      error = 'import_missing_name';
    } else if (parsedShares == null || parsedShares < 0) {
      error = 'import_bad_shares';
    } else {
      shares = parsedShares;
      final np = normalizeImportPhone(phone);
      if (np.isNotEmpty) {
        if (existingPhones.contains(np)) {
          error = 'import_duplicate';
        } else if (!seenPhones.add(np)) {
          error = 'import_duplicate_file';
        }
      }
    }

    rows.add(ImportedMemberRow(
      rowNumber: i + 1,
      name: name,
      phone: phone,
      shares: shares,
      errorKey: error,
    ));
  }

  if (rows.isEmpty) return const MemberImport([], fatalKey: 'import_empty');
  return MemberImport(rows);
}

/// Convenience: decode + auto-map + parse in one call (used where manual mapping
/// isn't offered, and by the parser tests).
MemberImport parseMemberWorkbook(
  Uint8List bytes, {
  required Set<String> existingPhones,
}) {
  final wb = readMemberWorkbook(bytes);
  return parseWithMapping(wb, wb.suggested, existingPhones: existingPhones);
}
