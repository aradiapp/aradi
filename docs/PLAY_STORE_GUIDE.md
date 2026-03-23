# Publish ARADI to the Google Play Store

Step-by-step guide to put your app on the Android store.

---

## 1. Prerequisites

### 1.1 Google Play Developer account
- Go to [Google Play Console](https://play.google.com/console) and sign in with a Google account.
- Pay the **one-time registration fee** (e.g. $25) if this is your first time.
- Complete identity verification if prompted.

### 1.2 Have ready
- **App icon**: 512×512 px PNG (no transparency), and your existing launcher icon.
- **Feature graphic**: 1024×500 px for the store listing (optional but recommended).
- **Screenshots**: At least 2 phone screenshots (e.g. 1080×1920 or 1080×2340). Up to 8.
- **Privacy policy URL**: Your app has Terms and Privacy; host them on a public URL (e.g. GitHub Pages, your site) and use that link in the store and in-app.
- **Short description**: Max 80 characters.
- **Full description**: Up to 4000 characters (what the app does, features, UAE real estate focus).

---

## 2. App signing (release builds)

Right now the app uses the **debug** keystore for release. For Play Store you should use a **release keystore**.

### Option A – Let Google manage signing (recommended)
1. In Play Console → **Setup** → **App signing**.
2. Enroll in **Google Play App Signing**.
3. For the first upload you can either:
   - **Upload a key** you create (see Option B below), or
   - **Let Google create and manage the key** (you only upload an AAB signed with an upload key).

If you choose “Google create key”, you’ll get an **upload key** to use on your machine. Then:

4. Create an upload keystore and key (one-time):

   **Windows (PowerShell):**
   ```powershell
   cd $env:USERPROFILE
   keytool -genkey -v -keystore upload-keystore.jks -keyalg RSA -keysize 2048 -validity 10000 -alias upload
   ```
   You’ll be asked for a password and details (name, org, etc.). **Keep the keystore file and passwords safe.**

5. Tell Flutter/Gradle to use this key by creating `android/key.properties` (do **not** commit this file; add it to `.gitignore`):

   ```properties
   storePassword=YOUR_KEYSTORE_PASSWORD
   keyPassword=YOUR_KEY_PASSWORD
   keyAlias=upload
   storeFile=C:\\Users\\YourUsername\\upload-keystore.jks
   ```
   Use your real path and passwords. On Mac/Linux use a path like `/Users/you/upload-keystore.jks`.

6. Add `key.properties` to `.gitignore`:
   ```
   android/key.properties
   ```

7. In `android/app/build.gradle.kts`, use the upload key for release (see the snippet in **Section 6** below).

### Option B – You manage the app signing key
- Create a keystore and key as above, then in Play Console upload it as the **app signing key** when prompted. You’re then responsible for backing it up and keeping it secure.

---

## 3. Version and app id

- **Version** in `pubspec.yaml`: `version: 1.0.0+1`  
  - `1.0.0` = versionName (user-visible).  
  - `1` = versionCode (integer; increase for each Play upload, e.g. 1, 2, 3…).
- **Application ID**: The app uses `com.aradi.technologies` (unique on Play). Don’t change it after the first release.

For each new store upload, bump at least the versionCode (e.g. `1.0.0+2`, then `1.0.1+3`).

---

## 4. Build the Android App Bundle (AAB)

Play Store requires an **Android App Bundle** (`.aab`), not an APK.

1. Ensure release signing is set up (Section 2 and 6).
2. From the project root:

   ```bash
   flutter clean
   flutter pub get
   flutter build appbundle
   ```

3. The AAB is generated at:
   ```
   build/app/outputs/bundle/release/app-release.aab
   ```

---

## 5. Create the app in Play Console

1. Open [Play Console](https://play.google.com/console) → **Create app**.
2. Fill in:
   - **App name**: ARADI
   - **Default language**
   - **App or game**: App
   - **Free or paid**: Free (or Paid if you charge)
3. Accept declarations (e.g. export laws, policies). Create the app.

---

## 6. Complete store listing and dashboard

### 6.1 Store listing
- **Main store listing** → add short description, full description, app icon 512×512, feature graphic, screenshots.
- **Privacy policy**: Add the URL of your hosted privacy policy.

### 6.2 App content
- **Privacy policy**: Same URL (required).
- **Ads**: If you don’t use ads, say “No.” If you do, declare it.
- **Target audience**: Choose age groups.
- **News app**: No (unless it is).
- **COVID-19 contact tracing**: No (unless it is).
- **Data safety**: Fill in what data you collect (e.g. email, name, photos for listings, KYC docs). Firebase/Analytics if used.
- **Content rating**: Complete the questionnaire (likely “Everyone” or “Teen” for real estate). Get the rating.
- **Target audience and content**: Set target age and store presence countries (e.g. UAE).

### 6.3 Release
- **Production** (or **Testing** first):
  - Create a new release.
  - Upload `app-release.aab`.
  - Add release name (e.g. “1.0.0 (1)”) and release notes.
  - Save and then **Review release** → **Start rollout to Production** (or to a testing track).

---

## 7. Release signing (upload key)

The project is already set up to use a release keystore when `android/key.properties` exists.

**1. Create the upload keystore** (one-time, see Section 2):

```powershell
keytool -genkey -v -keystore upload-keystore.jks -keyalg RSA -keysize 2048 -validity 10000 -alias upload
```

**2. Create `android/key.properties`** (this file is in `.gitignore`; never commit it):

```properties
storePassword=YOUR_KEYSTORE_PASSWORD
keyPassword=YOUR_KEY_PASSWORD
keyAlias=upload
storeFile=C:\\Users\\YourUsername\\upload-keystore.jks
```

Use your real passwords and path. For `storeFile` you can use forward slashes, e.g. `C:/Users/Remi/upload-keystore.jks`.

**3. Build the bundle:**

```bash
flutter build appbundle
```

If `key.properties` is missing, the release build falls back to the debug keystore (fine for local testing; use a real key for Play).

---

## 8. Keep push notifications (FCM) working

After changing the app’s package name (e.g. to `com.aradi.technologies`), FCM will only work if that package is registered in your Firebase project and you use the correct config file.

**Do this once:**

1. **Firebase Console** → [console.firebase.google.com](https://console.firebase.google.com) → your project (**aradi-app-ed624**).
2. **Project settings** (gear) → **Your apps** → **Add app** → **Android**.
3. **Android package name:** `com.aradi.technologies` (must match `applicationId` in `android/app/build.gradle.kts`).
4. **App nickname:** e.g. “ARADI (Play)” → **Register app**.
5. **Download `google-services.json`** → save it and **replace** `android/app/google-services.json` in the project (overwrite the existing file).
6. **Add SHA-1 for release builds** (so FCM works for the signed Play build):
   - In Firebase, open the new Android app → **Add fingerprint**.
   - Run (from project root, use your keystore path/password if different):
     ```powershell
     keytool -list -v -keystore android/upload-keystore.jks -alias upload
     ```
   - Copy the **SHA-1** line and paste it in Firebase.
7. **Sync / rebuild:**  
   `flutter clean && flutter pub get && flutter build appbundle`

After this, the app (debug and release) will use the Firebase app that matches `com.aradi.technologies`, and push notifications will keep working. No code changes are needed if you’ve already set `applicationId` and replaced `google-services.json`.

---

## 9. Checklist before first submission

- [ ] Google Play Developer account created and fee paid.
- [ ] Privacy policy URL live and linked in Console and in-app.
- [ ] Release signing: upload key in `key.properties` and `build.gradle.kts` (or Google-managed key).
- [ ] `flutter build appbundle` succeeds.
- [ ] Store listing: icon, screenshots, short/full description, feature graphic.
- [ ] App content: Data safety, content rating, target audience, ads declaration.
- [ ] AAB uploaded to a release (Internal / Closed / Open test or Production).
- [ ] Release reviewed and rollout started.

---

## 10. After submission

- First review can take from a few hours to several days.
- You’ll get email about status (approved, rejected, or changes requested).
- Use **Internal testing** or **Closed testing** to test the exact AAB before going to Production.
- For updates: bump version in `pubspec.yaml` (e.g. `1.0.1+2`), build a new AAB, then create a new release in the same track and upload the new AAB.

---

## 11. Useful links

- [Play Console](https://play.google.com/console)
- [App signing (Play)](https://support.google.com/googleplay/android-developer/answer/9842756)
- [Flutter deployment – Android](https://docs.flutter.dev/deployment/android)
- [Data safety form](https://support.google.com/googleplay/android-developer/answer/10787469)
