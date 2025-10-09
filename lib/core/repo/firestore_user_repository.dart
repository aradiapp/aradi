import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:aradi/core/models/user.dart';
import 'package:aradi/core/models/developer_profile.dart';
import 'package:aradi/core/models/buyer_profile.dart';
import 'package:aradi/core/models/seller_profile.dart';
import 'package:aradi/core/repo/base_repository.dart';

class FirestoreUserRepository implements UserRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final firebase_auth.FirebaseAuth _auth = firebase_auth.FirebaseAuth.instance;

  @override
  Future<User?> getCurrentUser() async {
    final firebaseUser = _auth.currentUser;
    if (firebaseUser == null) return null;

    print('=== FIREBASE AUTH DEBUG ===');
    print('Firebase Auth UID: ${firebaseUser.uid}');
    print('Firebase Auth Email: ${firebaseUser.email}');
    print('Firebase Auth Display Name: ${firebaseUser.displayName}');
    print('============================');

    try {
      final doc = await _firestore.collection('users').doc(firebaseUser.uid).get();
      if (!doc.exists) {
        print('No user document found for UID: ${firebaseUser.uid}');
        return null;
      }
      
      print('=== FIRESTORE USER DEBUG ===');
      print('Document ID: ${doc.id}');
      print('Document Data: ${doc.data()}');
      print('============================');
      
      return User.fromJson(doc.data()!);
    } catch (e) {
      print('Error getting current user: $e');
      return null;
    }
  }

  @override
  Future<User?> getUserById(String userId) async {
    try {
      final doc = await _firestore.collection('users').doc(userId).get();
      if (!doc.exists) return null;
      
      return User.fromJson(doc.data()!);
    } catch (e) {
      print('Error getting user by ID $userId: $e');
      return null;
    }
  }

  @override
  Future<User> createUser(User user) async {
    try {
      await _firestore.collection('users').doc(user.id).set(user.toJson());
      return user;
    } catch (e) {
      print('Error creating user: $e');
      rethrow;
    }
  }

  @override
  Future<User> updateUser(User user) async {
    try {
      print('=== FIRESTORE UPDATE DEBUG ===');
      print('Updating user: ${user.email}');
      print('User ID: ${user.id}');
      print('isKycVerified: ${user.isKycVerified}');
      print('User data: ${user.toJson()}');
      
      await _firestore.collection('users').doc(user.id).update(user.toJson());
      
      print('Firestore update completed successfully');
      print('===============================');
      return user;
    } catch (e) {
      print('Error updating user: $e');
      print('Error type: ${e.runtimeType}');
      print('Error details: ${e.toString()}');
      rethrow;
    }
  }

  @override
  Future<void> deleteUser(String userId) async {
    try {
      await _firestore.collection('users').doc(userId).delete();
    } catch (e) {
      print('Error deleting user: $e');
      rethrow;
    }
  }

  @override
  Future<DeveloperProfile?> getDeveloperProfile(String userId) async {
    try {
      print('=== GETTING DEVELOPER PROFILE DEBUG ===');
      print('Looking for developer profile with userId: $userId');
      
      final doc = await _firestore.collection('developerProfiles').doc(userId).get();
      print('Document exists: ${doc.exists}');
      
      if (!doc.exists) {
        print('No developer profile found for user: $userId');
        return null;
      }
      
      print('Developer profile data: ${doc.data()}');
      final profile = DeveloperProfile.fromJson(doc.data()!);
      print('Successfully parsed developer profile: ${profile.companyName}');
      print('=========================================');
      
      return profile;
    } catch (e) {
      print('Error getting developer profile: $e');
      print('Error type: ${e.runtimeType}');
      return null;
    }
  }

  @override
  Future<DeveloperProfile> createDeveloperProfile(DeveloperProfile profile) async {
    try {
      await _firestore.collection('developerProfiles').doc(profile.userId).set(profile.toJson());
      return profile;
    } catch (e) {
      print('Error creating developer profile: $e');
      rethrow;
    }
  }

  @override
  Future<DeveloperProfile> updateDeveloperProfile(DeveloperProfile profile) async {
    try {
      await _firestore.collection('developerProfiles').doc(profile.userId).update(profile.toJson());
      return profile;
    } catch (e) {
      print('Error updating developer profile: $e');
      rethrow;
    }
  }

  @override
  Future<BuyerProfile?> getBuyerProfile(String userId) async {
    try {
      final doc = await _firestore.collection('buyerProfiles').doc(userId).get();
      if (!doc.exists) return null;
      
      return BuyerProfile.fromJson(doc.data()!);
    } catch (e) {
      print('Error getting buyer profile: $e');
      return null;
    }
  }

  @override
  Future<BuyerProfile> createBuyerProfile(BuyerProfile profile) async {
    try {
      await _firestore.collection('buyerProfiles').doc(profile.userId).set(profile.toJson());
      return profile;
    } catch (e) {
      print('Error creating buyer profile: $e');
      rethrow;
    }
  }

  @override
  Future<BuyerProfile> updateBuyerProfile(BuyerProfile profile) async {
    try {
      await _firestore.collection('buyerProfiles').doc(profile.userId).update(profile.toJson());
      return profile;
    } catch (e) {
      print('Error updating buyer profile: $e');
      rethrow;
    }
  }

  @override
  Future<SellerProfile?> getSellerProfile(String userId) async {
    try {
      final doc = await _firestore.collection('sellerProfiles').doc(userId).get();
      if (!doc.exists) return null;
      
      return SellerProfile.fromJson(doc.data()!);
    } catch (e) {
      print('Error getting seller profile: $e');
      return null;
    }
  }

  @override
  Future<SellerProfile> createSellerProfile(SellerProfile profile) async {
    try {
      await _firestore.collection('sellerProfiles').doc(profile.userId).set(profile.toJson());
      return profile;
    } catch (e) {
      print('Error creating seller profile: $e');
      rethrow;
    }
  }

  @override
  Future<SellerProfile> updateSellerProfile(SellerProfile profile) async {
    try {
      await _firestore.collection('sellerProfiles').doc(profile.userId).update(profile.toJson());
      return profile;
    } catch (e) {
      print('Error updating seller profile: $e');
      rethrow;
    }
  }

  @override
  Future<List<DeveloperProfile>> getAllDevelopers() async {
    try {
      final snapshot = await _firestore.collection('developerProfiles').get();
      return snapshot.docs.map((doc) => DeveloperProfile.fromJson(doc.data())).toList();
    } catch (e) {
      print('Error getting all developers: $e');
      return [];
    }
  }

  @override
  Future<List<SellerProfile>> getAllSellers() async {
    try {
      final snapshot = await _firestore.collection('sellerProfiles').get();
      return snapshot.docs.map((doc) => SellerProfile.fromJson(doc.data())).toList();
    } catch (e) {
      print('Error getting all sellers: $e');
      return [];
    }
  }

  // Admin methods
  Future<List<User>> getPendingKycUsers() async {
    try {
      print('Querying users with isProfileComplete=true and isKycVerified=false');
      
      // Get all users with completed profiles
      final allUsersSnapshot = await _firestore
          .collection('users')
          .where('isProfileComplete', isEqualTo: true)
          .get();
      
      print('Total users with completed profiles: ${allUsersSnapshot.docs.length}');
      for (var doc in allUsersSnapshot.docs) {
        final data = doc.data();
        print('User: ${data['email']}, ProfileComplete: ${data['isProfileComplete']}, KycVerified: ${data['isKycVerified']}, Role: ${data['role']}');
      }
      
      // Filter users where isKycVerified is null or false
      final pendingUsers = allUsersSnapshot.docs.where((doc) {
        final data = doc.data();
        final isKycVerified = data['isKycVerified'];
        return isKycVerified == null || isKycVerified == false;
      }).toList();
      
      print('Filtered ${pendingUsers.length} pending users from ${allUsersSnapshot.docs.length} total users');
      for (var doc in pendingUsers) {
        print('Pending User: ${doc.data()['email']}, ProfileComplete: ${doc.data()['isProfileComplete']}, KycVerified: ${doc.data()['isKycVerified']}');
      }
      
      final users = pendingUsers.map((doc) {
        final userData = doc.data();
        print('=== USER DATA DEBUG ===');
        print('User: ${userData['email']}');
        print('Profile Picture URL: ${userData['profilePictureUrl']}');
        print('Profile Picture URL is null: ${userData['profilePictureUrl'] == null}');
        print('Profile Picture URL is empty: ${userData['profilePictureUrl']?.toString().isEmpty}');
        print('========================');
        return User.fromJson(userData);
      }).toList();
      
      return users;
    } catch (e) {
      print('Error getting pending KYC users: $e');
      return [];
    }
  }

}
