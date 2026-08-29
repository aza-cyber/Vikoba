// Verifies the bulk-member Excel parser: column detection, share defaulting,
// and validation (missing name, bad shares, duplicate phones) — exercised by
// generating a real .xlsx with the same package and parsing it back.

import 'dart:typed_data';
import 'package:excel/excel.dart' as xls;
import 'package:flutter_test/flutter_test.dart';
import 'package:vikoba/features/members/member_import.dart';

Uint8List _workbook(List<List<Object>> rows) {
  final book = xls.Excel.createExcel();
  final sheet = book[book.getDefaultSheet()!];
  for (final row in rows) {
    sheet.appendRow(row
        .map<xls.CellValue?>(
            (v) => v is int ? xls.IntCellValue(v) : xls.TextCellValue('$v'))
        .toList());
  }
  return Uint8List.fromList(book.encode()!);
}

void main() {
  test('parses header + rows, detects columns, defaults shares', () {
    final bytes = _workbook([
      ['Name', 'Phone', 'Shares'],
      ['Asha Juma', '0712345678', 3],
      ['John Mollel', '0755000000', ''], // blank shares -> 0
    ]);
    final result = parseMemberWorkbook(bytes, existingPhones: {});
    expect(result.fatalKey, isNull);
    expect(result.rows, hasLength(2));
    expect(result.validCount, 2);
    expect(result.rows[0].name, 'Asha Juma');
    expect(result.rows[0].shares, 3);
    expect(result.rows[1].shares, 0);
  });

  test('reads first three columns when there is no header', () {
    final bytes = _workbook([
      ['Asha Juma', '0712345678', 2],
    ]);
    final result = parseMemberWorkbook(bytes, existingPhones: {});
    expect(result.rows, hasLength(1));
    expect(result.rows.single.name, 'Asha Juma');
    expect(result.rows.single.shares, 2);
    expect(result.rows.single.isValid, true);
  });

  test('flags missing name, bad shares, and duplicate phones', () {
    final bytes = _workbook([
      ['Name', 'Phone', 'Shares'],
      ['', '0712000000', 1], // missing name
      ['Bad Shares', '0713000000', 'x'], // unparseable shares
      ['Dup Existing', '0714000000', 2], // duplicates an existing member
      ['Dup File A', '0715000000', 1],
      ['Dup File B', '0715000000', 1], // duplicates the row above
    ]);
    final result = parseMemberWorkbook(
      bytes,
      existingPhones: {normalizeImportPhone('0714000000')},
    );
    expect(result.rows, hasLength(5));
    expect(result.rows[0].errorKey, 'import_missing_name');
    expect(result.rows[1].errorKey, 'import_bad_shares');
    expect(result.rows[2].errorKey, 'import_duplicate');
    expect(result.rows[3].isValid, true);
    expect(result.rows[4].errorKey, 'import_duplicate_file');
    expect(result.validCount, 1);
    expect(result.invalidCount, 4);
  });

  test('an empty workbook is a fatal, not a crash', () {
    final result = parseMemberWorkbook(_workbook([]), existingPhones: {});
    expect(result.fatalKey, 'import_empty');
    expect(result.rows, isEmpty);
  });

  test('a manual mapping reads columns in any order and skips the header', () {
    final bytes = _workbook([
      ['Mobile', 'Count', 'Person'], // unusual order
      ['0712000000', 5, 'Neema'],
    ]);
    final wb = readMemberWorkbook(bytes);
    final result = parseWithMapping(
      wb,
      const MemberColumnMapping(
          nameCol: 2, phoneCol: 0, sharesCol: 1, hasHeader: true),
      existingPhones: {},
    );
    expect(result.rows, hasLength(1));
    expect(result.rows.single.name, 'Neema');
    expect(result.rows.single.phone, '0712000000');
    expect(result.rows.single.shares, 5);
    expect(result.rows.single.isValid, true);
  });

  test('toggling the header flag includes or excludes the first row', () {
    final bytes = _workbook([
      ['Asha', '0712000000', 2],
      ['John', '0713000000', 3],
    ]);
    final wb = readMemberWorkbook(bytes);
    const cols =
        MemberColumnMapping(nameCol: 0, phoneCol: 1, sharesCol: 2, hasHeader: false);

    final asData = parseWithMapping(wb, cols, existingPhones: {});
    expect(asData.rows, hasLength(2)); // both rows are members

    final asHeader = parseWithMapping(
        wb, cols.copyWith(hasHeader: true),
        existingPhones: {});
    expect(asHeader.rows, hasLength(1)); // first row skipped
    expect(asHeader.rows.single.name, 'John');
  });

  test('an unmapped phone column disables duplicate detection', () {
    final bytes = _workbook([
      ['Asha', '0712000000', 1],
      ['Asha Again', '0712000000', 1], // same phone
    ]);
    final wb = readMemberWorkbook(bytes);
    // Map only name + shares; no phone column -> no phone, no dup flags.
    final result = parseWithMapping(
      wb,
      const MemberColumnMapping(
          nameCol: 0,
          phoneCol: MemberColumnMapping.noColumn,
          sharesCol: 2,
          hasHeader: false),
      existingPhones: {},
    );
    expect(result.validCount, 2);
    expect(result.rows.every((r) => r.phone.isEmpty), true);
  });
}
