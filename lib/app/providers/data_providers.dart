import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:aradi/core/services/auth_service.dart';
import 'package:aradi/core/services/file_upload_service.dart';
import 'package:aradi/core/repo/firestore_user_repository.dart';
import 'package:aradi/core/repo/firestore_listing_repository.dart';
import 'package:aradi/core/repo/firestore_negotiation_repository.dart';
import 'package:aradi/core/models/user.dart';
import 'package:aradi/core/models/land_listing.dart';
import 'package:aradi/core/models/offer.dart';
import 'package:aradi/core/models/negotiation.dart';
import 'package:aradi/core/models/developer_profile.dart';
import 'package:aradi/core/models/buyer_profile.dart';
import 'package:aradi/core/models/seller_profile.dart';

// Service Providers
final authServiceProvider = Provider<AuthService>((ref) => AuthService());
final fileUploadServiceProvider = Provider<FileUploadService>((ref) => FileUploadService());
final userRepositoryProvider = Provider<FirestoreUserRepository>((ref) => FirestoreUserRepository());
final listingRepositoryProvider = Provider<FirestoreListingRepository>((ref) => FirestoreListingRepository());
final negotiationRepositoryProvider = Provider<FirestoreNegotiationRepository>((ref) => FirestoreNegotiationRepository());

// Auth State Provider
final authStateProvider = StreamProvider<User?>((ref) {
  final authService = ref.watch(authServiceProvider);
  return authService.authStateChanges.asyncMap((firebaseUser) async {
    if (firebaseUser == null) return null;
    return await authService.getCurrentUser();
  });
});

// Current User Provider
final currentUserProvider = FutureProvider<User?>((ref) async {
  final authService = ref.watch(authServiceProvider);
  return await authService.getCurrentUser();
});

// User Profile Providers
final developerProfileProvider = FutureProvider.family<DeveloperProfile?, String>((ref, userId) async {
  final userRepository = ref.watch(userRepositoryProvider);
  return await userRepository.getDeveloperProfile(userId);
});

final buyerProfileProvider = FutureProvider.family<BuyerProfile?, String>((ref, userId) async {
  final userRepository = ref.watch(userRepositoryProvider);
  return await userRepository.getBuyerProfile(userId);
});

final sellerProfileProvider = FutureProvider.family<SellerProfile?, String>((ref, userId) async {
  final userRepository = ref.watch(userRepositoryProvider);
  return await userRepository.getSellerProfile(userId);
});

// Listings Providers
final allListingsProvider = FutureProvider<List<LandListing>>((ref) async {
  final listingRepository = ref.watch(listingRepositoryProvider);
  return await listingRepository.getAllListings();
});

final listingsBySellerProvider = FutureProvider.family<List<LandListing>, String>((ref, sellerId) async {
  final listingRepository = ref.watch(listingRepositoryProvider);
  return await listingRepository.getListingsBySeller(sellerId);
});

final listingByIdProvider = FutureProvider.family<LandListing?, String>((ref, listingId) async {
  final listingRepository = ref.watch(listingRepositoryProvider);
  return await listingRepository.getListingById(listingId);
});

// Offers Providers
final offersForListingProvider = FutureProvider.family<List<Offer>, String>((ref, listingId) async {
  final listingRepository = ref.watch(listingRepositoryProvider);
  return await listingRepository.getOffersForListing(listingId);
});

final offersByDeveloperProvider = FutureProvider.family<List<Offer>, String>((ref, developerId) async {
  final listingRepository = ref.watch(listingRepositoryProvider);
  return await listingRepository.getOffersByDeveloper(developerId);
});

// Negotiations Providers
final negotiationsForUserProvider = FutureProvider.family<List<Negotiation>, String>((ref, userId) async {
  final negotiationRepository = ref.watch(negotiationRepositoryProvider);
  return await negotiationRepository.getNegotiationsForUser(userId);
});

final negotiationByIdProvider = FutureProvider.family<Negotiation?, String>((ref, negotiationId) async {
  final negotiationRepository = ref.watch(negotiationRepositoryProvider);
  return await negotiationRepository.getNegotiationById(negotiationId);
});

final messagesForNegotiationProvider = FutureProvider.family<List<NegotiationMessage>, String>((ref, negotiationId) async {
  final negotiationRepository = ref.watch(negotiationRepositoryProvider);
  return await negotiationRepository.getMessagesForNegotiation(negotiationId);
});

final unreadMessageCountProvider = FutureProvider.family<int, String>((ref, userId) async {
  final negotiationRepository = ref.watch(negotiationRepositoryProvider);
  return await negotiationRepository.getUnreadMessageCount(userId);
});

// All Developers Provider
final allDevelopersProvider = FutureProvider<List<DeveloperProfile>>((ref) async {
  final userRepository = ref.watch(userRepositoryProvider);
  return await userRepository.getAllDevelopers();
});

// All Sellers Provider
final allSellersProvider = FutureProvider<List<SellerProfile>>((ref) async {
  final userRepository = ref.watch(userRepositoryProvider);
  return await userRepository.getAllSellers();
});

// Search Providers
final searchListingsProvider = FutureProvider.family<List<LandListing>, Map<String, dynamic>>((ref, filters) async {
  final listingRepository = ref.watch(listingRepositoryProvider);
  return await listingRepository.searchListings(
    location: filters['location'],
    area: filters['area'],
    minPrice: filters['minPrice'],
    maxPrice: filters['maxPrice'],
    permissions: filters['permissions'],
    ownershipType: filters['ownershipType'],
  );
});

// Profile Completion Providers
final hasCompletedProfileProvider = FutureProvider.family<bool, Map<String, dynamic>>((ref, params) async {
  final authService = ref.watch(authServiceProvider);
  final userId = params['userId'] as String;
  final role = params['role'] as UserRole;
  return await authService.hasCompletedProfile(userId, role);
});
