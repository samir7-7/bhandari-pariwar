# Bhandari Pariwar - Setup Guide

## Prerequisites

Install the following before proceeding:

1. **Flutter SDK** (3.5+): https://docs.flutter.dev/get-started/install
2. **Firebase CLI**: `npm install -g firebase-tools`
3. **FlutterFire CLI**: `dart pub global activate flutterfire_cli`
4. **Android Studio** (for Android builds) or **Xcode** (for iOS builds)

---

## Step 1: Generate Flutter Platform Folders

The project has all Dart source code but needs Flutter's platform scaffolding.

```bash
cd d:\Bhandari Pariwar\bhandari_pariwar
flutter create . --org com.bhandaripariwar --project-name bhandari_pariwar
```

This generates `android/`, `ios/`, `web/`, `test/`, etc. without overwriting existing files.

---

## Step 2: Install Dependencies

```bash
flutter pub get
```

---

## Step 2b: Configure Supabase Storage (Required for Photo Upload/Replace/Delete)

If photo upload fails with 403 unauthorized, run this one-shot SQL in Supabase SQL Editor.
It is safe to run multiple times.

```sql
-- Ensure the photos bucket exists and is publicly readable.
insert into storage.buckets (id, name, public)
values ('photos', 'photos', true)
on conflict (id) do update set public = true;

-- Drop old policies so this script is re-runnable.
drop policy if exists "photos_public_read" on storage.objects;
drop policy if exists "photos_insert_anon" on storage.objects;
drop policy if exists "photos_insert_authenticated" on storage.objects;
drop policy if exists "photos_update_anon" on storage.objects;
drop policy if exists "photos_update_authenticated" on storage.objects;
drop policy if exists "photos_delete_anon" on storage.objects;
drop policy if exists "photos_delete_authenticated" on storage.objects;

-- Public read for images in photos bucket.
create policy "photos_public_read"
on storage.objects
for select
to public
using (bucket_id = 'photos');

-- Upload permissions.
create policy "photos_insert_anon"
on storage.objects
for insert
to anon
with check (bucket_id = 'photos');

create policy "photos_insert_authenticated"
on storage.objects
for insert
to authenticated
with check (bucket_id = 'photos');

-- Update permissions (needed for overwrite/metadata changes).
create policy "photos_update_anon"
on storage.objects
for update
to anon
using (bucket_id = 'photos')
with check (bucket_id = 'photos');

create policy "photos_update_authenticated"
on storage.objects
for update
to authenticated
using (bucket_id = 'photos')
with check (bucket_id = 'photos');

-- Delete permissions (needed when replacing/removing old photos).
create policy "photos_delete_anon"
on storage.objects
for delete
to anon
using (bucket_id = 'photos');

create policy "photos_delete_authenticated"
on storage.objects
for delete
to authenticated
using (bucket_id = 'photos');
```

Optional:

- Authentication -> Providers -> Anonymous -> Enabled

Note:

- Anonymous provider can stay disabled if you use anon-role storage policies above.
- If you enable anonymous sign-in, uploads will also work through a temporary session.

The app upload behavior is now:

- pick large image -> auto-resize/compress before upload
- upload a new unique file path in bucket `photos`
- if this is an edit, delete old photo from Supabase Storage

---

## Step 3: Set Up Firebase Project

### 3a. Create Firebase Project

1. Go to https://console.firebase.google.com
2. Click "Add Project" → name it "Bhandari Pariwar"
3. Disable Google Analytics (not needed)
4. Wait for project creation

### 3b. Enable Firebase Services

In the Firebase Console, enable:

- **Authentication** → Sign-in methods → Email/Password → Enable
- **Firestore Database** → Create database → Start in production mode
- **Storage** → Get started → Start in production mode
- **Cloud Messaging** → Enabled by default

### 3c. Create Admin Account

In Firebase Console → Authentication → Users → Add User:

- Email: your admin email
- Password: your admin password

### 3d. Connect Firebase to Flutter

```bash
firebase login
flutterfire configure --project=YOUR_PROJECT_ID
```

This generates `lib/firebase_options.dart`. The app already imports Firebase but you need
to update `main.dart` to use it:

Replace this line in `lib/main.dart`:

```dart
await Firebase.initializeApp();
```

With:

```dart
await Firebase.initializeApp(
  options: DefaultFirebaseOptions.currentPlatform,
);
```

And add this import at the top of `main.dart`:

```dart
import 'package:bhandari_pariwar/firebase_options.dart';
```

---

## Step 4: Deploy Firestore Rules

```bash
cd firebase
firebase deploy --only firestore:rules
firebase deploy --only storage
```

Or copy `firebase/firestore.rules` and `firebase/storage.rules` content into
the Firebase Console → Firestore → Rules and Storage → Rules tabs.

---

## Step 5: Deploy Cloud Functions

```bash
cd firebase/functions
npm install
cd ..
firebase deploy --only functions
```

This deploys the `onNoticeCreated` function that sends push notifications.

---

## Step 6: Seed Initial Data (Optional)

In Firebase Console → Firestore, create these documents manually:

### Root ancestor (collection: `members`)

```
Document ID: auto
{
  "name": { "en": "Ancestor Name", "hi": "पूर्वज का नाम" },
  "gender": "male",
  "birthDate": "1900-01-01",
  "deathDate": "1980-01-01",
  "isAlive": false,
  "parentId": null,
  "spouseId": null,
  "birthOrder": 0,
  "createdAt": <server timestamp>,
  "updatedAt": <server timestamp>
}
```

After creating the root male ancestor, create the root female ancestor and
link them via `spouseId` pointing to each other.

### About content (collection: `content`)

```
Document ID: family_overview
{
  "title": { "en": "Our Family", "hi": "हमारा परिवार" },
  "body": { "en": "The Bhandari family...", "hi": "भंडारी परिवार..." },
  "updatedAt": <server timestamp>
}

Document ID: history
{
  "title": { "en": "History & Sayings", "hi": "इतिहास और कहावतें" },
  "sections": [],
  "updatedAt": <server timestamp>
}

Document ID: committee
{
  "members": [],
  "updatedAt": <server timestamp>
}
```

---

## Step 7: Run the App

### Android

```bash
flutter run -d android
```

### iOS

```bash
cd ios && pod install && cd ..
flutter run -d ios
```

---

## Step 8: Build for Release

### Android (AAB for Play Store)

```bash
flutter build appbundle --release
```

Output: `build/app/outputs/bundle/release/app-release.aab`

### iOS (requires Mac + Xcode)

```bash
flutter build ios --release
```

Then archive and upload via Xcode.

---

## Step 9: App Store Preparation

### Required before submission:

1. **Privacy Policy URL** — Host a simple page stating:
   - No personal data collected from users
   - Anonymous push notification tokens stored
   - Family data managed by authorized administrators

2. **App Icons** — Replace default Flutter icons:
   - Android: `android/app/src/main/res/mipmap-*`
   - iOS: `ios/Runner/Assets.xcassets/AppIcon.appiconset`

3. **Splash Screen** — Customize `android/app/src/main/res/drawable/launch_background.xml`
   and iOS `LaunchScreen.storyboard`

4. **App Store Metadata**:
   - Screenshots (6.5" iPhone, 12.9" iPad, Phone + 7" Tablet for Android)
   - Description in both languages
   - Category: Lifestyle or Social Networking
   - Age Rating: 4+ (no objectionable content)

---

## Project Structure

```
bhandari_pariwar/
├── pubspec.yaml                          # Dependencies
├── l10n.yaml                             # Localization config
├── analysis_options.yaml                 # Linter rules
├── firebase/
│   ├── firestore.rules                   # Firestore security rules
│   ├── storage.rules                     # Storage security rules
│   └── functions/
│       ├── index.js                      # Cloud Functions (push notifications)
│       └── package.json
└── lib/
    ├── main.dart                         # App entry point
    ├── app.dart                          # MaterialApp with router + theme
    ├── config/
    │   ├── routes.dart                   # GoRouter configuration
    │   └── theme.dart                    # App theme (colors, typography)
    ├── l10n/
    │   ├── app_en.arb                    # English strings
    │   └── app_hi.arb                    # Hindi strings
    ├── models/
    │   ├── member.dart                   # Family member model
    │   ├── notice.dart                   # Notice/announcement model
    │   ├── about_content.dart            # About section model
    │   └── committee_member.dart         # Committee member model
    ├── services/
    │   ├── auth_service.dart             # Firebase Auth
    │   ├── member_service.dart           # Member CRUD
    │   ├── notice_service.dart           # Notice CRUD
    │   ├── content_service.dart          # About/committee CRUD
    │   ├── notification_service.dart     # FCM token management
    │   └── storage_service.dart          # Photo uploads
    ├── providers/
    │   ├── auth_provider.dart            # Admin auth state
    │   ├── family_tree_provider.dart     # Members, tree layout, search
    │   ├── notice_provider.dart          # Notices state
    │   ├── content_provider.dart         # About content state
    │   └── settings_provider.dart        # Language, notifications prefs
    ├── screens/
    │   ├── splash/splash_screen.dart     # Language selection
    │   ├── home/home_screen.dart         # Tab navigation
    │   ├── family_tree/                  # Family tree view
    │   ├── member_detail/                # Member profile sheet
    │   ├── notices/                      # Notices list + detail
    │   ├── about/                        # About + committee
    │   ├── settings/                     # Settings
    │   └── admin/                        # Admin login, add/edit forms
    └── widgets/
        ├── tree/
        │   ├── tree_canvas.dart          # InteractiveViewer + node rendering
        │   ├── tree_layout.dart          # Tree position algorithm
        │   ├── tree_line_painter.dart    # Connection lines (CustomPainter)
        │   └── tree_node_widget.dart     # Individual tree node
        └── common/
            ├── loading_widget.dart
            └── app_error_widget.dart
```
