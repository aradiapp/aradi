# 🔥 Firebase Setup Guide for ARADI

## Step 1: Create Firebase Project

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Click "Create a project"
3. Project name: `aradi-app` (or your preferred name)
4. Enable Google Analytics (optional)
5. Create project

## Step 2: Configure Android App

1. In Firebase Console → Project Settings → General
2. Click "Add app" → Android
3. **Android package name**: Check your `android/app/build.gradle.kts` file for the `applicationId`
4. **App nickname**: `ARADI Android`
5. **Download `google-services.json`**
6. **Place it in**: `android/app/google-services.json`

## Step 3: Configure iOS App

1. Click "Add app" → iOS
2. **iOS bundle ID**: `com.aradi.app`
3. **App nickname**: `ARADI iOS`
4. **Download `GoogleService-Info.plist`**
5. **Place it in**: `ios/Runner/GoogleService-Info.plist`

## Step 4: Enable Firebase Services

### Authentication
1. Go to Authentication → Sign-in method
2. Enable "Email/Password"
3. Save

### Firestore Database
1. Go to Firestore Database → Create database
2. Start in **test mode** (we'll update rules later)
3. Choose a location (closest to your users)

### Storage
1. Go to Storage → Get started
2. Start in **test mode**
3. Choose a location (same as Firestore)

### Cloud Messaging
1. Go to Cloud Messaging
2. This is automatically enabled

## Step 5: Get Configuration Values

1. Go to Project Settings → General
2. Scroll down to "Your apps" section
3. Click on your Android app
4. Copy these values:

```
Project ID: your-project-id
Web API Key: your-api-key
App ID: your-app-id
Messaging Sender ID: your-sender-id
Storage Bucket: your-project-id.appspot.com
```

## Step 6: Update Environment File

1. Copy `env.example` to `.env`
2. Replace the placeholder values with your actual Firebase config:

```env
# Feature Flags
USE_FIREBASE=true
USE_MOCK_DATA=false

# Firebase Configuration
FIREBASE_PROJECT_ID=your-actual-project-id
FIREBASE_API_KEY=your-actual-api-key
FIREBASE_APP_ID=your-actual-app-id
FIREBASE_MESSAGING_SENDER_ID=your-actual-sender-id
FIREBASE_STORAGE_BUCKET=your-actual-project-id.appspot.com
```

## Step 7: Deploy Security Rules

1. Install Firebase CLI: `npm install -g firebase-tools`
2. Login: `firebase login`
3. Initialize: `firebase init firestore`
4. Deploy rules: `firebase deploy --only firestore:rules`

## Step 8: Test the Setup

1. Run the app: `flutter run`
2. Try to sign up with a test email
3. Check Firebase Console → Authentication to see the user
4. Check Firestore Database to see the user document

## Troubleshooting

### Common Issues:

1. **"Firebase not initialized"**
   - Check that `USE_FIREBASE=true` in your `.env` file
   - Verify all Firebase config values are correct

2. **"Permission denied"**
   - Check Firestore security rules
   - Make sure user is authenticated

3. **"File upload failed"**
   - Check Storage security rules
   - Verify Storage is enabled

4. **"FCM token not generated"**
   - Check that Cloud Messaging is enabled
   - Verify app permissions

### Security Rules

The `firestore.rules` file contains the security rules. Deploy them using:
```bash
firebase deploy --only firestore:rules
```

## Next Steps

Once Firebase is configured:

1. Test user registration and login
2. Test file uploads
3. Test real-time data updates
4. Test push notifications
5. Deploy to production

## Production Checklist

- [ ] Firebase project created
- [ ] Android app configured
- [ ] iOS app configured (if needed)
- [ ] Authentication enabled
- [ ] Firestore database created
- [ ] Storage enabled
- [ ] Security rules deployed
- [ ] Environment variables set
- [ ] App tested with real data
- [ ] Push notifications working
