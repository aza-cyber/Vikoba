# VICOBA — *Pamoja Tujijenge*

A bilingual (Swahili 🇹🇿 / English) Flutter UI prototype for managing a Village
Community Bank (VICOBA / VSLA) group — savings, loans, fines, meetings,
cashbook, reports and member management.

This is the **frontend UI prototype** built to match the reference mockups. It
runs entirely on **mock data** (no backend yet) so you can click through every
screen and demo the full experience.

---

## ✨ What's included

| Module | Swahili | Screen(s) |
| --- | --- | --- |
| Authentication | Ingia | Login with phone + password, language toggle |
| Dashboard | Dashibodi | Group banner, 6 KPI cards, recent activity |
| Members | Wanachama | Searchable list, status chips, member profile + tabs |
| Savings | Akiba | Record savings form with live balance |
| Loans | Mikopo | Ongoing / Paid / Requests tabs, 4-step "Give Loan" wizard, repayment |
| Fines | Faini | Record fine form |
| Meetings | Mikutano | Attendance ring, agenda / decisions / collections |
| Cashbook | Cashbook | Income vs expenses, current balance |
| Reports | Ripoti | Report catalog + export action |
| Settings | Mipangilio | Group / users / language settings |

Tap the **green ➕ button** for quick actions (add savings, give loan,
repayment, add fine). Switch language anytime from the login screen, **More**
tab, or **Settings**.

---

## 🚀 Run it

### 1. Install the Flutter SDK (one-time)

Flutter is **not yet installed** on this machine. Install it:

- **Recommended:** follow <https://docs.flutter.dev/get-started/install/windows>
- Or via winget (PowerShell):
  ```powershell
  winget install --id=Google.Flutter -e
  ```
- Then verify:
  ```powershell
  flutter --version
  flutter doctor
  ```
  `flutter doctor` will tell you what else you need (Android Studio for an
  emulator, Chrome for web, or "Desktop" support for Windows).

### 2. Generate the platform folders

This repo contains the app source (`lib/`, `pubspec.yaml`) but not the
generated `android/ios/web/windows` folders. Create them once — this preserves
your existing `lib/` and `pubspec.yaml`:

```powershell
cd "c:\Users\user\OneDrive\Desktop\Vikoba"
flutter create .
```

### 3. Install dependencies & run

```powershell
flutter pub get
flutter run            # pick a device when prompted
# or target a specific platform:
flutter run -d chrome    # web (fastest to preview)
flutter run -d windows   # Windows desktop
```

---

## 🧱 Project structure

```
lib/
├── main.dart                      # App root, MaterialApp, locale wiring
├── core/
│   ├── theme/                     # Colors + Material 3 theme (VICOBA green)
│   ├── l10n/                      # Bilingual string table + LocaleProvider
│   ├── models/                    # Member, Loan, SavingEntry, Fine, Meeting…
│   ├── data/                      # MockData (Upendo Women Group sample)
│   └── utils/                     # Money / date formatters
├── widgets/
│   └── common.dart                # SummaryCard, StatusChip, AppCard, AppDropdown…
└── features/
    ├── auth/                      # Login
    ├── shell/                     # Bottom-nav shell, More grid, quick actions
    ├── dashboard/                 # Dashibodi
    ├── members/                   # List + profile
    ├── savings/  loans/  fines/
    ├── meetings/ cashbook/
    └── reports/  settings/
```

## 🌍 Localization

Swahili is the default locale. All app text flows through
`LocaleProvider.t('key')`, backed by `core/l10n/app_strings.dart`. Add a key to
both the `sw` and `en` maps and it's instantly available everywhere.

---

## 🛣️ Next steps (toward the full app)

This prototype covers **Phase 1–3** UI from the build plan. To make it a real
product:

1. **Backend** — Node.js (Express/NestJS) + PostgreSQL with the tables already
   modelled in `core/models/` (Users, Members, Savings, Loans, Repayments,
   Fines, Meetings, Attendance, Transactions, ShareOuts, Settings).
2. **Auth** — phone + OTP (Firebase / SMS) and JWT, replacing the mock login.
3. **State + API layer** — swap `MockData` for a repository that calls the API
   (e.g. `dio` + `riverpod`/`provider`).
4. **PDF/Excel reports**, push notifications (FCM), and the Share-Out engine.

---

> ⚠️ If `flutter pub get`/build reports an error on the dropdown `value:`
> parameter on a very new SDK, change `value:` to `initialValue:` in
> `lib/widgets/common.dart` (`AppDropdown`). Both behave the same here.
