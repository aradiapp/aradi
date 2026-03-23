# Add the Android app in Firebase (so sign-in and push work)

Your app uses the package **`com.aradi.technologies`**. Firebase must have an Android app with that package. If it doesn’t, **sign-in (Auth) fails**, and then Firestore and Storage deny access because you’re not authenticated.

**You don’t need to change Firestore or Storage rules.** They already allow any signed-in user. The only step is to register the Android app below.

---

## Steps (do this once)

### 1. Open your project
- Go to [Firebase Console](https://console.firebase.google.com)
- Open the project **aradi-app-ed624** (or whatever your project is called)

### 2. Add the Android app
- Click the **gear** next to “Project overview” → **Project settings**
- Scroll to **“Your apps”**
- If you already see an Android app with a different package (e.g. `com.aradi.app`), don’t delete it
- Click **“Add app”** → choose the **Android** icon

### 3. Register the app
- **Android package name:** type exactly  
  **`com.aradi.technologies`**
- **App nickname:** e.g. `ARADI` (optional)
- **Debug signing certificate SHA-1:** optional for now (you can add it later)
- Click **“Register app”**

### 4. Download the config file
- On the next step, click **“Download google-services.json”**
- Save the file
- **Replace** the file in your project with this one:  
  **`android/app/google-services.json`**  
  (overwrite the existing file)

### 5. Add SHA-1 for release (so FCM works on the Play build)
- Still in Project settings → Your apps → click the new **Android** app (`com.aradi.technologies`)
- Find **“SHA certificate fingerprints”** → **“Add fingerprint”**
- On your PC (PowerShell, project folder):

  ```powershell
  keytool -list -v -keystore android/upload-keystore.jks -alias upload
  ```

- When asked, use the password from **`android/keystore-passwords.txt`**
- Copy the **SHA1** value (e.g. `A1:B2:C3:...`)
- Paste it in Firebase → **Save**

### 6. Rebuild the app
```bash
flutter clean
flutter pub get
flutter build appbundle
```

---

After this, sign-in (Auth) should work, so Firestore and Storage will work too with your existing rules. No changes are needed to Firestore or Storage rules for the new package.
