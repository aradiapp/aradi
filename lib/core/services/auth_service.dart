import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:aradi/core/models/user.dart';
import 'package:aradi/core/models/developer_profile.dart';
import 'package:aradi/core/models/buyer_profile.dart';
import 'package:aradi/core/models/seller_profile.dart';
import 'package:aradi/core/repo/firestore_user_repository.dart';
import 'package:aradi/core/config/app_config.dart';
import 'package:aradi/core/services/notification_service.dart';

class AuthService {
  final firebase_auth.FirebaseAuth _auth = firebase_auth.FirebaseAuth.instance;
  final FirestoreUserRepository _userRepository = FirestoreUserRepository();

  // Get current user
  firebase_auth.User? get currentUser => _auth.currentUser;
  
  // Get current user as our custom User model
  Future<User?> getCurrentUser() async {
    try {
      final firebaseUser = _auth.currentUser;
      if (firebaseUser == null) return null;
      
      // Get user from Firestore - no fallbacks or assumptions
      return await _userRepository.getCurrentUser();
    } catch (e) {
      print('Error getting current user: $e');
      return null;
    }
  }
  
  // Auth state changes stream
  Stream<firebase_auth.User?> get authStateChanges => _auth.authStateChanges();

  // Sign in with email and password
  Future<User?> signInWithEmailAndPassword(String email, String password) async {
    try {
      print('=== AUTHENTICATION DEBUG ===');
      print('Attempting to sign in with: $email');
      print('Password length: ${password.length}');
      
      final credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      print('Firebase Auth successful!');
      print('Credential user UID: ${credential.user?.uid}');
      print('Credential user email: ${credential.user?.email}');
      print('============================');
      
      if (credential.user != null) {
        try {
          return await _userRepository.getCurrentUser();
        } catch (e) {
          // If user exists in Firebase Auth but not in Firestore, create the profile
          if (email == AppConfig.adminEmail && password == AppConfig.adminPassword) {
            print('Admin user exists in Firebase Auth but not in Firestore, creating profile...');
            final adminUser = User(
              id: credential.user!.uid,
              email: AppConfig.adminEmail,
              name: AppConfig.adminName,
              role: UserRole.admin,
              createdAt: DateTime.now(),
              isEmailVerified: true,
              isProfileComplete: true,
              isKycVerified: true,
            );
            
            await _userRepository.createUser(adminUser);
            print('Admin user profile created successfully');
            return adminUser;
          }
          rethrow;
        }
      }
      return null;
    } on firebase_auth.FirebaseAuthException catch (e) {
      // Handle admin user creation if it doesn't exist in Firestore
      if (email == 'admin@aradi.com' && password == 'Aradi1992') {
        print('Admin user exists in Firebase Auth but not in Firestore, creating profile...');
        try {
          // Create admin user profile in Firestore
          final adminUser = User(
            id: _auth.currentUser?.uid ?? '',
            email: 'admin@aradi.com',
            name: 'Admin',
            role: UserRole.admin,
            createdAt: DateTime.now(),
            isEmailVerified: true,
            isProfileComplete: true,
            isKycVerified: true,
          );
          
          await _userRepository.createUser(adminUser);
          print('Admin user profile created successfully');
          return adminUser;
        } catch (createError) {
          print('Failed to create admin user profile: $createError');
        }
      }
      throw _handleAuthException(e);
    } catch (e) {
      print('Sign in error: $e');
      if (e.toString().contains('PigeonUserDetails') || e.toString().contains('List<Object?>')) {
        // This is a known Firebase Auth type casting issue - try to get user directly
        try {
          final currentUser = _auth.currentUser;
          if (currentUser != null) {
            print('Recovering from Firebase Auth type casting error...');
            
            // Handle admin user creation if it doesn't exist in Firestore
            if (email == AppConfig.adminEmail && password == AppConfig.adminPassword) {
              print('Creating admin user profile during recovery...');
              final adminUser = User(
                id: currentUser.uid,
                email: AppConfig.adminEmail,
                name: AppConfig.adminName,
                role: UserRole.admin,
                createdAt: DateTime.now(),
                isEmailVerified: true,
                isProfileComplete: true,
                isKycVerified: true,
              );
              
              await _userRepository.createUser(adminUser);
              print('Admin user profile created successfully during recovery');
              print('Admin user role stored as: ${adminUser.role.toString().split('.').last}');
              return adminUser;
            }
            
            return await _userRepository.getCurrentUser();
          }
        } catch (recoveryError) {
          print('Recovery failed: $recoveryError');
        }
        throw Exception('Authentication service error. Please try again.');
      }
      throw Exception('Sign in failed: $e');
    }
  }

  // Sign up with email and password
  Future<User?> signUpWithEmailAndPassword({
    required String email,
    required String password,
    required String name,
    required UserRole role,
    String? profilePictureUrl,
  }) async {
    try {
      print('Attempting to create user with email: $email');
      
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      print('Firebase Auth credential created successfully');
      print('User ID: ${credential.user?.uid}');
      
      if (credential.user != null) {
        // Create user object with safe property access
        final user = User(
          id: credential.user!.uid,
          email: email,
          name: name,
          role: role,
          createdAt: DateTime.now(),
          isEmailVerified: false, // Set to false initially to avoid type casting issues
          isProfileComplete: false,
          profilePictureUrl: profilePictureUrl,
        );
        
        print('Creating user in Firestore...');
        await _userRepository.createUser(user);
        print('User created successfully in Firestore');
        return user;
      }
      return null;
    } on firebase_auth.FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      print('Sign up error: $e');
      if (e.toString().contains('PigeonUserDetails') || e.toString().contains('List<Object?>')) {
        // This is a known Firebase Auth type casting issue - try to create user profile
        try {
          final currentUser = _auth.currentUser;
          if (currentUser != null) {
            print('Recovering from Firebase Auth type casting error during sign up...');
            final user = User(
              id: currentUser.uid,
              email: email,
              name: name,
              role: role,
              createdAt: DateTime.now(),
              isEmailVerified: false,
              isProfileComplete: false,
              profilePictureUrl: profilePictureUrl,
            );
            
            await _userRepository.createUser(user);
            return user;
          }
        } catch (recoveryError) {
          print('Recovery failed: $recoveryError');
        }
        throw Exception('Authentication service error. Please try again.');
      }
      throw Exception('Sign up failed: $e');
    }
  }

  // Sign out
  Future<void> signOut() async {
    try {
      await _auth.signOut();
    } catch (e) {
      throw Exception('Sign out failed: $e');
    }
  }

  // Send email verification
  Future<void> sendEmailVerification() async {
    try {
      final user = _auth.currentUser;
      if (user != null && !user.emailVerified) {
        await user.sendEmailVerification();
      }
    } catch (e) {
      throw Exception('Failed to send email verification: $e');
    }
  }

  // Send password reset email
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } on firebase_auth.FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      throw Exception('Failed to send password reset email: $e');
    }
  }

  // Update user profile
  Future<User> updateUserProfile(User user) async {
    try {
      return await _userRepository.updateUser(user);
    } catch (e) {
      throw Exception('Failed to update user profile: $e');
    }
  }

  // Update Developer Profile
  Future<DeveloperProfile> updateDeveloperProfile(DeveloperProfile profile) async {
    try {
      return await _userRepository.updateDeveloperProfile(profile);
    } catch (e) {
      throw Exception('Failed to update developer profile: $e');
    }
  }

  // Update Buyer Profile
  Future<BuyerProfile> updateBuyerProfile(BuyerProfile profile) async {
    try {
      return await _userRepository.updateBuyerProfile(profile);
    } catch (e) {
      throw Exception('Failed to update buyer profile: $e');
    }
  }

  // Update Seller Profile
  Future<SellerProfile> updateSellerProfile(SellerProfile profile) async {
    try {
      return await _userRepository.updateSellerProfile(profile);
    } catch (e) {
      throw Exception('Failed to update seller profile: $e');
    }
  }

  // Create developer profile
  Future<DeveloperProfile> createDeveloperProfile({
    required String userId,
    required String companyName,
    required String companyEmail,
    required String companyPhone,
    required String tradeLicense,
    required String signatoryPassport,
    required BusinessModel businessModel,
    required List<String> areasInterested,
    String? logoUrl,
    String? portfolioPdfUrl,
    String? catalogDocumentUrl,
    int deliveredProjects = 0,
    int underConstruction = 0,
    int teamSize = 0,
    int totalValue = 0,
  }) async {
    try {
      print('=== CREATING DEVELOPER PROFILE DEBUG ===');
      print('User ID: $userId');
      print('Company Name: $companyName');
      print('Company Email: $companyEmail');
      print('Company Phone: $companyPhone');
      print('Trade License: $tradeLicense');
      print('Signatory Passport: $signatoryPassport');
      print('Business Model: $businessModel');
      print('Areas Interested: $areasInterested');
      print('Logo URL: $logoUrl');
      print('Portfolio PDF URL: $portfolioPdfUrl');
      
      final profile = DeveloperProfile(
        id: userId,
        userId: userId,
        companyName: companyName,
        companyEmail: companyEmail,
        companyPhone: companyPhone,
        tradeLicense: tradeLicense,
        signatoryPassport: signatoryPassport,
        businessModel: businessModel,
        areasInterested: areasInterested,
        freeYearStart: DateTime.now(),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        logoUrl: logoUrl,
        portfolioPdfUrl: portfolioPdfUrl,
        catalogDocumentUrl: catalogDocumentUrl,
        deliveredProjects: deliveredProjects,
        underConstruction: underConstruction,
        teamSize: teamSize,
        totalValue: totalValue,
      );
      
      print('Developer profile object created successfully');
      print('Profile data: ${profile.toJson()}');
      
      final result = await _userRepository.createDeveloperProfile(profile);
      print('Developer profile saved to Firestore successfully');
      print('===============================================');
      
      return result;
    } catch (e) {
      print('Error creating developer profile: $e');
      print('Error type: ${e.runtimeType}');
      throw Exception('Failed to create developer profile: $e');
    }
  }

  // Create buyer profile
  Future<BuyerProfile> createBuyerProfile({
    required String userId,
    required String name,
    required String passport,
    required String email,
    required String phone,
    List<String> areasInterested = const [],
    Map<String, double>? gfaRange,
    Map<String, double>? budgetRange,
  }) async {
    try {
      final profile = BuyerProfile(
        id: userId,
        userId: userId,
        name: name,
        passport: passport,
        email: email,
        phone: phone,
        areasInterested: areasInterested,
        gfaRange: gfaRange,
        budgetRange: budgetRange,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      
      return await _userRepository.createBuyerProfile(profile);
    } catch (e) {
      throw Exception('Failed to create buyer profile: $e');
    }
  }

  // Create seller profile
  Future<SellerProfile> createSellerProfile({
    required String userId,
    required String name,
    required String phone,
    required String email,
    required String passportOrEmiratesId,
    String? tradeLicense,
    String? logoUrl,
  }) async {
    try {
      final profile = SellerProfile(
        id: userId,
        userId: userId,
        name: name,
        phone: phone,
        email: email,
        passportOrEmiratesId: passportOrEmiratesId,
        tradeLicense: tradeLicense,
        logoUrl: logoUrl,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      
      return await _userRepository.createSellerProfile(profile);
    } catch (e) {
      throw Exception('Failed to create seller profile: $e');
    }
  }

  // Get user profile by role
  Future<dynamic> getUserProfile(String userId, UserRole role) async {
    switch (role) {
      case UserRole.developer:
        return await _userRepository.getDeveloperProfile(userId);
      case UserRole.buyer:
        return await _userRepository.getBuyerProfile(userId);
      case UserRole.seller:
        return await _userRepository.getSellerProfile(userId);
      case UserRole.admin:
        return await _userRepository.getCurrentUser();
    }
  }

  // Check if user has completed profile
  Future<bool> hasCompletedProfile(String userId, UserRole role) async {
    try {
      final profile = await getUserProfile(userId, role);
      return profile != null;
    } catch (e) {
      return false;
    }
  }

  // Admin methods
  Future<List<User>> getPendingKycUsers() async {
    try {
      print('Getting pending KYC users...');
      final currentUser = await getCurrentUser();
      if (currentUser != null) {
        print('Current admin user: ${currentUser.email}, Role: ${currentUser.role}');
        print('Admin role as string: ${currentUser.role.toString().split('.').last}');
      }
      final users = await _userRepository.getPendingKycUsers();
      print('Found ${users.length} pending KYC users');
      return users;
    } catch (e) {
      print('Error getting pending KYC users: $e');
      rethrow;
    }
  }

  Future<void> approveKycUser(String userId) async {
    try {
      print('=== APPROVAL DEBUG ===');
      print('Approving user ID: $userId');
      
      // Get the target user by ID
      final targetUser = await _userRepository.getUserById(userId);
      if (targetUser == null) throw Exception('Target user not found');
      
      print('Target user found: ${targetUser.email}');
      print('Current isKycVerified: ${targetUser.isKycVerified}');
      
      // Update the target user's KYC status
      final updatedUser = targetUser.copyWith(isKycVerified: true);
      print('Updated isKycVerified: ${updatedUser.isKycVerified}');
      
      await _userRepository.updateUser(updatedUser);
      
      // Verify the update worked
      final verifyUser = await _userRepository.getUserById(userId);
      print('Verification - User isKycVerified after update: ${verifyUser?.isKycVerified}');
      
      print('User $userId approved successfully');
      print('=====================');
    } catch (e) {
      print('Error approving user $userId: $e');
      rethrow;
    }
  }

  Future<void> rejectKycUser(String userId, {String? rejectionReason}) async {
    try {
      // Get the target user by ID
      final targetUser = await _userRepository.getUserById(userId);
      if (targetUser == null) throw Exception('Target user not found');
      
      // Reset the user's profile completion status and mark as rejected
      final updatedUser = targetUser.copyWith(
        isProfileComplete: false,
        isKycVerified: false,
        wasKycRejected: true,
        kycRejectionReason: rejectionReason,
      );
      await _userRepository.updateUser(updatedUser);
      
      // Send rejection notification
      try {
        final notificationService = NotificationService();
        await notificationService.notifyKycRejection(
          recipientId: userId,
          rejectionReason: rejectionReason,
        );
      } catch (e) {
        print('Error sending rejection notification: $e');
        // Don't fail the rejection if notification fails
      }
      
      print('User $userId rejected successfully');
    } catch (e) {
      print('Error rejecting user $userId: $e');
      rethrow;
    }
  }

  // Get profile data for admin review
  Future<DeveloperProfile?> getDeveloperProfile(String userId) async {
    try {
      return await _userRepository.getDeveloperProfile(userId);
    } catch (e) {
      print('Error getting developer profile: $e');
      return null;
    }
  }

  Future<BuyerProfile?> getBuyerProfile(String userId) async {
    try {
      return await _userRepository.getBuyerProfile(userId);
    } catch (e) {
      print('Error getting buyer profile: $e');
      return null;
    }
  }

  Future<SellerProfile?> getSellerProfile(String userId) async {
    try {
      return await _userRepository.getSellerProfile(userId);
    } catch (e) {
      print('Error getting seller profile: $e');
      return null;
    }
  }

  // Handle Firebase Auth exceptions
  String _handleAuthException(firebase_auth.FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return 'No user found with this email address.';
      case 'wrong-password':
        return 'Incorrect password.';
      case 'email-already-in-use':
        return 'An account already exists with this email address.';
      case 'weak-password':
        return 'Password is too weak. Please choose a stronger password.';
      case 'invalid-email':
        return 'Invalid email address.';
      case 'user-disabled':
        return 'This account has been disabled.';
      case 'too-many-requests':
        return 'Too many attempts. Please try again later.';
      default:
        return 'Authentication failed: ${e.message}';
    }
  }

  Future<List<DeveloperProfile>> getVerifiedDevelopers() async {
    try {
      // Get all developer profiles
      final developerProfilesSnapshot = await FirebaseFirestore.instance
          .collection('developerProfiles')
          .get();

      final developerProfiles = developerProfilesSnapshot.docs
          .map((doc) => DeveloperProfile.fromJson(doc.data()))
          .toList();

      // Get all users with developer role and isKycVerified = true
      final usersSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('role', isEqualTo: 'developer')
          .where('isKycVerified', isEqualTo: true)
          .get();

      final verifiedUserIds = usersSnapshot.docs.map((doc) => doc.id).toList();

      // Filter developer profiles to only include verified ones
      final verifiedDevelopers = developerProfiles
          .where((profile) => verifiedUserIds.contains(profile.userId))
          .toList();

      return verifiedDevelopers;
    } catch (e) {
      print('Error fetching verified developers: $e');
      return [];
    }
  }

  // Get developer by ID
  Future<DeveloperProfile?> getDeveloperById(String developerId) async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('developerProfiles')
          .doc(developerId)
          .get();

      if (doc.exists) {
        return DeveloperProfile.fromJson(doc.data()!);
      }
      return null;
    } catch (e) {
      print('Error fetching developer by ID: $e');
      return null;
    }
  }

}
