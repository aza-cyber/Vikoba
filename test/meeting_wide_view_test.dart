// Renders the wide (desktop/web) meeting dashboard at two widths and asserts it
// lays out without overflow and shows its key sections.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:vikoba/core/l10n/locale_provider.dart';
import 'package:vikoba/core/models/models.dart';
import 'package:vikoba/core/state/app_state.dart';
import 'package:vikoba/features/meetings/meeting_wide_view.dart';

Meeting _openMeeting() => Meeting(
      id: 'm-test',
      number: 15,
      date: DateTime(2026, 7, 2),
      attended: 25,
      total: 30,
      decisions: 3,
      collections: 920000,
      fines: 12000,
      title: '',
      startTime: '10:30 AM',
      location: 'Nyakato Community Hall',
      status: MeetingStatus.open,
      attendance: const [
        Attendance(
            memberId: '1', memberName: 'A', status: AttendanceStatus.present),
        Attendance(
            memberId: '2', memberName: 'B', status: AttendanceStatus.absent),
      ],
    );

Future<void> _pumpAt(WidgetTester tester, Size size,
    {bool editable = true}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  await tester.pumpWidget(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => LocaleProvider()),
        ChangeNotifierProvider.value(value: AppState(Snapshot.empty())),
      ],
      child: MaterialApp(
        home: Scaffold(
          body: MeetingWideView(meeting: _openMeeting(), editable: editable),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('renders on a desktop width without overflow', (tester) async {
    await _pumpAt(tester, const Size(1400, 900));

    // Locale-neutral checks: the view is present, the 8th step badge renders,
    // and the attendance percentage stat (25/30 = 83%) shows.
    expect(find.byType(MeetingWideView), findsOneWidget);
    expect(find.text('8'), findsWidgets); // step number badge
    expect(find.text('83%'), findsOneWidget); // attendance stat
    expect(tester.takeException(), isNull); // no RenderFlex overflow
  });

  testWidgets('renders on a mid-wide width (rail stacks below)',
      (tester) async {
    await _pumpAt(tester, const Size(950, 900));

    expect(find.byType(MeetingWideView), findsOneWidget);
    expect(find.text('8'), findsWidgets);
    expect(tester.takeException(), isNull);
  });

  testWidgets('renders on a phone width without overflow', (tester) async {
    await _pumpAt(tester, const Size(390, 844));

    expect(find.byType(MeetingWideView), findsOneWidget);
    expect(find.text('8'), findsWidgets); // 8th step badge
    expect(tester.takeException(), isNull);
  });

  testWidgets('admin gets the Continue Meeting control', (tester) async {
    await _pumpAt(tester, const Size(1400, 900), editable: true);
    // 'Endelea na Mkutano' = Continue Meeting (Swahili default).
    expect(find.text('Endelea na Mkutano'), findsOneWidget);
  });

  testWidgets('member sees the meeting read-only (no controls)',
      (tester) async {
    await _pumpAt(tester, const Size(1400, 900), editable: false);
    // No admin action for non-admins...
    expect(find.text('Endelea na Mkutano'), findsNothing);
    // ...but the details/steps still render.
    expect(find.byType(MeetingWideView), findsOneWidget);
    expect(find.text('8'), findsWidgets);
    // Step cards carry no tap handler when read-only.
    final steps = tester
        .widgetList<InkWell>(find.byType(InkWell))
        .where((w) => w.onTap != null)
        .length;
    expect(steps, 0);
  });
}
