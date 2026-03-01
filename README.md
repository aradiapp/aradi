# ARADI - Real Estate Development Platform

ARADI is a comprehensive Flutter application that connects real estate developers, buyers, and sellers in the UAE market. The platform facilitates land transactions, joint ventures, and development partnerships with advanced matching algorithms and secure negotiation workflows.

## 🚀 Features

### Core Functionality
- **Multi-Role Platform**: Developer, Buyer, and Seller roles with specialized workflows
- **Land Listings**: Comprehensive land information with photos, permissions, and pricing
- **Smart Matching**: AI-powered matching between developers and land listings
- **Offer Management**: Buy offers and Joint Venture proposals with validation
- **Negotiation System**: Real-time messaging and offer tracking
- **Subscription Management**: Buyer subscription system for access to listings
- **KYC Verification**: Role-specific verification processes
- **Push Notifications**: FCM integration for real-time updates

### Business Logic
- **Buy Offer Validation**: Ensures offers within ±20% of asking price
- **JV Proposal Validation**: Ensures partnership percentages sum to 100%
- **Developer Free Year**: First year free for new developer profiles
- **Listing Verification**: Broker-administered verification workflow
- **Matching Algorithm**: Weighted scoring based on area, permissions, GFA, and preferences

## 🏗️ Architecture

### Tech Stack
- **Framework**: Flutter 3.x with Dart null-safety
- **State Management**: Riverpod with code generation
- **Routing**: Go Router for navigation
- **Forms**: Flutter Form Builder with validation
- **Backend**: Firebase (Firestore, Auth, Storage, FCM)
- **Architecture**: Feature-first + Clean Architecture

### Project Structure
```
lib/
├── app/                    # App configuration
│   ├── theme/             # Theme system
│   ├── router/            # Navigation
│   └── providers/         # App-level providers
├── core/                  # Core functionality
│   ├── models/            # Data models
│   ├── services/          # Business logic services
│   ├── repo/              # Repository interfaces
│   └── utils/             # Utility functions
├── features/              # Feature modules
│   ├── onboarding/        # User onboarding
│   ├── auth/              # Authentication
│   ├── developer/         # Developer features
│   ├── buyer/             # Buyer features
│   ├── seller/            # Seller features
│   ├── negotiations/      # Offer management
│   ├── admin/             # Admin/broker features
│   └── notifications/     # Push notifications
└── shared/                # Shared components
    └── widgets/           # Reusable UI components
```

## 🛠️ Setup Instructions

### Prerequisites
- Flutter SDK 3.10.0 or higher
- Dart SDK 3.0.0 or higher
- Android Studio / VS Code with Flutter extensions
- Firebase project (optional for development)

### Installation

1. **Clone the repository**
   ```bash
   git clone <repository-url>
   cd aradi
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Run the app** (no config step: script uses `env.example` and creates `.env` if needed)
   ```bash
   dart run scripts/run_with_env.dart
   ```
   Or with explicit flags (values from `env.example`):
   ```bash
   flutter run --dart-define=USE_FIREBASE=true --dart-define=FIREBASE_PROJECT_ID=aradi-app-ed624 --dart-define=FIREBASE_API_KEY=AIzaSyCiq_6o977MK_jlJXdKDmhzDrtBMViBFJY --dart-define=FIREBASE_APP_ID=1:766361317085:android:b753416f89fb5b805ef534 --dart-define=FIREBASE_MESSAGING_SENDER_ID=766361317085 --dart-define=FIREBASE_STORAGE_BUCKET=aradi-app-ed624.firebasestorage.app
   ```

### Environment Configuration

Config is in `env.example` (real values). `dart run scripts/run_with_env.dart` creates `.env` from it if missing and passes `--dart-define` to Flutter so nothing is bundled into the APK.

- **Local dev**: Just run `dart run scripts/run_with_env.dart`.
- **CI/Release**: Use the same `--dart-define` flags; values are in `env.example`.

### Firebase Setup

Firebase config is in `env.example`. Ensure `google-services.json` (Android) and `GoogleService-Info.plist` (iOS) are in place, then run `dart run scripts/run_with_env.dart` or use the `--dart-define` commands from the README.

### Code Generation

The app uses Riverpod code generation. Run after making changes:

```bash
# Generate code
flutter packages pub run build_runner build

# Watch for changes
flutter packages pub run build_runner watch

# Clean and rebuild
flutter packages pub run build_runner clean
flutter packages pub run build_runner build
```

## 📱 App Flow

### User Journey
1. **Splash Screen** → App branding and initialization
2. **Role Selection** → Choose Developer, Buyer, or Seller role
3. **KYC Verification** → Complete role-specific verification
4. **Role Home** → Access role-specific features and listings

### Role-Specific Features

#### Developer
- View land listings sorted by matching score
- Submit buy offers and JV proposals
- Manage profile and business statistics
- Access negotiation threads

#### Buyer
- Browse verified land listings (subscription required)
- View listing details and photos
- Submit offers within price bounds
- Track negotiation progress

#### Seller
- List land for sale with comprehensive details
- Specify desired developers
- Manage listing status and verification
- Browse developer profiles

## 🧪 Testing

### Unit Tests
```bash
flutter test test/unit/
```

### Widget Tests
```bash
flutter test test/widget/
```

### Integration Tests
```bash
flutter test test/integration/
```

### Test Coverage
```bash
flutter test --coverage
genhtml coverage/lcov.info -o coverage/html
```

## 🔧 Development

### Code Style
- Follow Flutter style guide
- Use `flutter_lints` for code quality
- Implement proper error handling
- Add comprehensive documentation

### State Management
- Use Riverpod for state management
- Implement proper error states
- Handle loading states consistently
- Use code generation for providers

### Navigation
- Use Go Router for navigation
- Implement deep linking support
- Handle route parameters properly
- Maintain navigation state

### Forms
- Use Flutter Form Builder
- Implement proper validation
- Handle form submission states
- Provide user feedback

## 📦 Build & Deploy

### Secure build (no .env bundled in APK)

- Config is from `--dart-define` at compile time; use `env.example` values or `dart run scripts/run_with_env.dart` for builds.
- **Obfuscation**: `flutter build apk --obfuscate --split-debug-info=build/app/outputs/symbols` plus the same `--dart-define` flags.

### Android Build
```bash
flutter build apk --release --dart-define=USE_FIREBASE=true --dart-define=FIREBASE_PROJECT_ID=aradi-app-ed624 --dart-define=FIREBASE_API_KEY=AIzaSyCiq_6o977MK_jlJXdKDmhzDrtBMViBFJY --dart-define=FIREBASE_APP_ID=1:766361317085:android:b753416f89fb5b805ef534 --dart-define=FIREBASE_MESSAGING_SENDER_ID=766361317085 --dart-define=FIREBASE_STORAGE_BUCKET=aradi-app-ed624.firebasestorage.app
```
```bash
flutter build appbundle --release --dart-define=USE_FIREBASE=true --dart-define=FIREBASE_PROJECT_ID=aradi-app-ed624 --dart-define=FIREBASE_API_KEY=AIzaSyCiq_6o977MK_jlJXdKDmhzDrtBMViBFJY --dart-define=FIREBASE_APP_ID=1:766361317085:android:b753416f89fb5b805ef534 --dart-define=FIREBASE_MESSAGING_SENDER_ID=766361317085 --dart-define=FIREBASE_STORAGE_BUCKET=aradi-app-ed624.firebasestorage.app
```

### iOS Build
```bash
flutter build ios --release --dart-define=USE_FIREBASE=true --dart-define=FIREBASE_PROJECT_ID=aradi-app-ed624 --dart-define=FIREBASE_API_KEY=AIzaSyCiq_6o977MK_jlJXdKDmhzDrtBMViBFJY --dart-define=FIREBASE_APP_ID=1:766361317085:android:b753416f89fb5b805ef534 --dart-define=FIREBASE_MESSAGING_SENDER_ID=766361317085 --dart-define=FIREBASE_STORAGE_BUCKET=aradi-app-ed624.firebasestorage.app
```

### Web Build
```bash
flutter build web --release
```

## 🚀 Deployment

### Android
1. Build APK/AAB
2. Upload to Google Play Console
3. Configure release notes and metadata

### iOS
1. Build iOS app
2. Upload to App Store Connect
3. Configure app store metadata

### Web
1. Build web app
2. Deploy to hosting service (Firebase Hosting, Netlify, etc.)

## 🔒 Security

### Data Protection
- Implement proper authentication
- Use secure storage for sensitive data
- Validate all user inputs
- Implement rate limiting

### Firebase Security Rules
- Configure Firestore security rules
- Set up Storage security rules
- Implement proper user authorization

## 📊 Monitoring & Analytics

### Firebase Analytics
- Track user engagement
- Monitor app performance
- Analyze user behavior

### Crash Reporting
- Implement crash reporting
- Monitor app stability
- Track error rates

## 🤝 Contributing

### Development Process
1. Fork the repository
2. Create feature branch
3. Implement changes
4. Add tests
5. Submit pull request

### Code Review
- All changes require review
- Ensure code quality standards
- Verify test coverage
- Check for security issues

## 📄 License

This project is proprietary software. All rights reserved.

## 🆘 Support

### Documentation
- Check inline code documentation
- Review model definitions
- Examine service implementations

### Issues
- Report bugs via issue tracker
- Provide detailed reproduction steps
- Include device and OS information

### Contact
- Development team: [team@aradi.com]
- Technical support: [support@aradi.com]

## 🔄 Updates

### Version History
- **v1.0.0**: Initial release with core features
- **v1.1.0**: Enhanced matching algorithm
- **v1.2.0**: Advanced negotiation features

### Roadmap
- [ ] Advanced analytics dashboard
- [ ] Mobile app for brokers
- [ ] Integration with external APIs
- [ ] Multi-language support
- [ ] Advanced reporting features

---

**ARADI** - Building the future of real estate development in the UAE.
