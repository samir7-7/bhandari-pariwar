# Play Store Submission Guide

## 1. Host the privacy policy

The repo is now configured for Firebase Hosting:

- Firebase project: `bhandari-pariwar`
- Hosted privacy policy file: `public/privacy-policy.html`
- Optional landing page: `public/index.html`
- In-app link location: `Settings > Privacy Policy`

Before deploying:

1. Replace the placeholder email in:
   - `privacy_policy.html`
   - `public/privacy-policy.html`
2. If you update the privacy policy text later, keep both files in sync.
3. If you use a custom domain instead of the default Firebase Hosting URL,
   update the URL in `lib/screens/settings/settings_screen.dart`.

Deploy commands:

```powershell
firebase login
firebase deploy --only hosting
```

Expected public URLs after deploy:

- `https://bhandari-pariwar.web.app/privacy-policy.html`
- `https://bhandari-pariwar.firebaseapp.com/privacy-policy.html`

Use one of those URLs in Google Play Console under:

- `Grow > Store presence > App details > Privacy policy`

## 2. Recommended Google Play Data safety answers

These answers are based on the current codebase as reviewed on April 7, 2026.
You are still responsible for verifying them before submitting.

### Overview

- `Does your app collect or share any of the required user data types?`
  - Recommended: `Yes`
- `Is all user data collected by your app encrypted in transit?`
  - Recommended: `Yes`
- `Do you provide a way for users to request that their data is deleted?`
  - Recommended: `Yes`
  - Reason: the privacy policy provides a contact route for deletion requests.

### Sharing

- Recommended overall answer: `No, data is not shared with third parties`

Reason:

- Firebase and Supabase are acting as service providers for the app.
- Under Google Play's current Data safety guidance, service-provider transfers
  do not need to be disclosed as `sharing`.

### Data types likely to declare as collected

- `Personal info > Name`
  - Why: family member names, committee names, administrator account name data
- `Personal info > Email address`
  - Why: admin login email, family member email fields
- `Personal info > Phone number`
  - Why: member and committee phone numbers
- `Personal info > Address`
  - Why: birthplace, current address, permanent address
- `Photos and videos > Photos`
  - Why: profile photos, gallery photos, notice images, memorial and committee photos
- `Identifiers > User IDs`
  - Why: Firebase Authentication user ID, creator/updater identifiers
- `Identifiers > Device or other IDs`
  - Why: Firebase Cloud Messaging device token

### Data types I do not currently recommend declaring

- `Location`
- `Contacts`
- `Messages`
- `Payment info`
- `Health and fitness`
- `App activity`
- `Web browsing`
- `Files and docs`
- `Audio files`

I did not find code paths that intentionally collect those categories.

## 3. Suggested usage labels in Data safety

For the collected data above, the most likely purposes are:

- `App functionality`
- `Developer communications`
  - only for notice push notifications
- `Account management`
  - for admin authentication

Do not select advertising, fraud prevention, analytics, or personalization
unless you later add code that actually does those things.

## 4. Suggested handling labels

For most collected types:

- `Collected`
- `Not shared`
- `Required or optional`:
  - Use `Required` if the feature cannot work without it for any users
  - Use `Optional` where entry is user/admin choice

Conservative recommendations:

- Name: `Required`
- Email address: `Required`
- Phone number: `Optional`
- Address: `Optional`
- Photos: `Optional`
- User IDs: `Required`
- Device or other IDs: `Optional`

## 5. Account deletion / data deletion

Recommended answers:

- `Does your app allow users to create an account?`
  - Recommended: `No`

Reason:

- The current app contains admin login, but it does not provide a normal
  end-user in-app sign-up flow.
- Admin accounts are created outside the app.

If Google Play asks about data deletion:

- Point to the hosted privacy policy URL
- Use the support/privacy email you place in the policy

## 6. Release notes for this app

Current data-related behavior in the codebase:

- No ads SDK detected
- No dedicated analytics SDK detected
- Push notifications are enabled through Firebase Cloud Messaging
- Images are stored in Supabase Storage
- Structured content is stored in Firebase Firestore
- Local language and notification preferences are stored on-device

## 7. Important publishing caution

Before release, verify Firebase and Firestore access control.

This repo previously allowed anonymous Firebase sign-in during startup while
Firestore write rules allowed any authenticated user to write. That combination
is not appropriate for a production app that claims admin-only editing.

If you change authentication, Firestore rules, or data collection behavior,
update both:

- the privacy policy
- the Google Play Data safety form
