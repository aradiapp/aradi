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

3. **Configure environment**
   ```bash
   cp env.example .env
   # Edit .env with your configuration
   ```

4. **Run the app**
   ```bash
   flutter run
   ```

### Environment Configuration

The app uses feature flags to control functionality:

```env
# Feature Flags
USE_FIREBASE=false          # Set to true when Firebase is configured
USE_STRIPE=false           # Set to true when Stripe is configured
USE_MOCK_DATA=true         # Set to false when using real backend

# Firebase Configuration (when USE_FIREBASE=true)
FIREBASE_PROJECT_ID=aradi-app
FIREBASE_API_KEY=your_api_key_here
FIREBASE_APP_ID=your_app_id_here
FIREBASE_MESSAGING_SENDER_ID=your_sender_id_here
```

### Firebase Setup (Optional)

1. **Create Firebase project**
   - Go to [Firebase Console](https://console.firebase.google.com/)
   - Create new project
   - Enable Authentication, Firestore, Storage, and Cloud Messaging

2. **Configure Flutter app**
   - Download `google-services.json` (Android) and `GoogleService-Info.plist` (iOS)
   - Place in appropriate platform directories
   - Update environment variables

3. **Enable services**
   ```env
   USE_FIREBASE=true
   USE_MOCK_DATA=false
   ```

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

### Android Build
```bash
flutter build apk --release
flutter build appbundle --release
```

### iOS Build
```bash
flutter build ios --release
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
