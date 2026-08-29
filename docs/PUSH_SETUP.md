# Push Notifications (Firebase Cloud Messaging) — Activation Guide

The app and backend are **fully wired for push**. All the code is in place; the
only remaining work is creating a Firebase project (which only you can do with
your Google account) and dropping its credentials in. Until you do, push simply
stays disabled — the app and server run normally.

## What's already built

**App (Flutter)**
- `firebase_core` + `firebase_messaging` dependencies.
- `lib/core/services/push_service.dart` — initialises FCM defensively (a missing
  config can never crash the app), requests permission, gets the device token,
  handles token refresh and foreground messages.
- On login (password **or** SMS), the device token is registered with the
  backend; on logout it is removed.

**Backend (`vikoba_api`)**
- `device_tokens` table (migration v8) — one row per device, per member.
- `POST /devices/register` and `POST /devices/unregister` endpoints.
- `lib/fcm.dart` — FCM HTTP v1 sender (service-account OAuth2), with a no-op
  fallback when unconfigured.
- Notifications already fire on: **loan approved**, **new meeting**, **new fine**.

## Step 1 — Create the Firebase project

1. Go to <https://console.firebase.google.com> → **Add project**.
2. Inside the project, enable **Cloud Messaging** (Build → Messaging).

## Step 2 — Wire up the Android app

Easiest path (recommended) — from `c:\dev\Vikoba`:

```bash
dart pub global activate flutterfire_cli
flutterfire configure
```

Select your Firebase project and the Android platform. This generates
`lib/firebase_options.dart`, adds `android/app/google-services.json`, and applies
the Google Services Gradle plugin.

> If you configure manually instead: place `google-services.json` in
> `android/app/`, add the `com.google.gms.google-services` plugin to
> `android/settings.gradle.kts` and apply it in `android/app/build.gradle.kts`.

Then rebuild the APK:

```bash
flutter build apk --release
```

## Step 3 — Give the backend a service account

1. Firebase console → **Project settings → Service accounts →
   Generate new private key**. This downloads a JSON file.
2. Put it somewhere safe on the server, e.g. `C:\dev\vikoba_api\fcm-service-account.json`.
3. Set the environment variable before starting the server (see
   `start-server.bat`):

   ```bat
   set FCM_SERVICE_ACCOUNT=C:\dev\vikoba_api\fcm-service-account.json
   ```

On boot you'll no longer see the `FCM (noop)` lines — sends go to real devices.
The server reads the project id straight from the JSON, so there's nothing else
to configure.

## How to verify it works

1. Start the server with `FCM_SERVICE_ACCOUNT` set.
2. Install the rebuilt APK on a real Android device and log in.
3. As an admin, approve a loan / schedule a meeting / add a fine for that member.
4. The device receives a notification.

## Notes

- **iOS** additionally needs an APNs key uploaded in the Firebase console and the
  Push Notifications capability enabled in Xcode. Android needs neither.
- **Web** push needs a VAPID key passed to `getToken` — not wired here; the
  service safely disables push on web.
- Tokens FCM reports as dead (uninstalled apps) are pruned automatically by the
  backend on the next send.
