import 'package:aradi/core/models/land_listing.dart';
import 'package:aradi/core/models/developer_profile.dart';

class MatchingService {
  // Weighted scoring system
  static const double _areaMatchWeight = 0.25;
  static const double _permissionMatchWeight = 0.20;
  static const double _gfaFitWeight = 0.15;
  static const double _budgetFitWeight = 0.15;
  static const double _desiredDeveloperBoostWeight = 0.15;
  static const double _developerSizeBoostWeight = 0.10;

  /// Calculate matching score between a developer profile and a land listing
  /// Returns a score between 0.0 and 100.0
  static double score(DeveloperProfile developer, LandListing listing) {
    double totalScore = 0.0;

    // Area match (developer's interested areas vs listing area)
    final areaScore = _calculateAreaMatch(developer, listing);
    totalScore += areaScore * _areaMatchWeight;

    // Permission match (developer's capabilities vs listing permissions)
    final permissionScore = _calculatePermissionMatch(developer, listing);
    totalScore += permissionScore * _permissionMatchWeight;

    // GFA fit (developer's project size vs listing GFA)
    final gfaScore = _calculateGFAFit(developer, listing);
    totalScore += gfaScore * _gfaFitWeight;

    // Budget fit (optional - if developer has budget constraints)
    final budgetScore = _calculateBudgetFit(developer, listing);
    totalScore += budgetScore * _budgetFitWeight;

    // Desired developer boost (if seller specifically wants this developer)
    final desiredDeveloperScore = _calculateDesiredDeveloperBoost(developer, listing);
    totalScore += desiredDeveloperScore * _desiredDeveloperBoostWeight;

    // Developer size boost (larger developers get slight boost)
    final developerSizeScore = _calculateDeveloperSizeBoost(developer);
    totalScore += developerSizeScore * _developerSizeBoostWeight;

    // Ensure score is within bounds
    return totalScore.clamp(0.0, 100.0);
  }

  /// Calculate area match score (0-100)
  static double _calculateAreaMatch(DeveloperProfile developer, LandListing listing) {
    if (developer.areasInterested.isEmpty) return 50.0; // Neutral score if no preferences
    
    final isInterested = developer.areasInterested.contains(listing.area);
    if (isInterested) return 100.0;
    
    // Check for partial matches (e.g., "Dubai Marina" vs "Dubai")
    for (final interestedArea in developer.areasInterested) {
      if (listing.area.contains(interestedArea) || interestedArea.contains(listing.area)) {
        return 75.0; // Partial match
      }
    }
    
    return 25.0; // No match
  }

  /// Calculate permission match score (0-100)
  static double _calculatePermissionMatch(DeveloperProfile developer, LandListing listing) {
    // This would need to be enhanced based on developer's actual capabilities
    // For now, we'll use a simplified approach
    
    // Developers with "both" business model get higher scores for mixed permissions
    if (developer.businessModel == BusinessModel.both) {
      if (listing.permissions.length > 1) return 100.0;
      return 80.0;
    }
    
    // Business-focused developers prefer commercial
    if (developer.businessModel == BusinessModel.business) {
      if (listing.permissions.contains(PermissionType.commercial)) return 100.0;
      if (listing.permissions.contains(PermissionType.mix)) return 75.0;
      return 50.0;
    }
    
    // Venture-focused developers prefer residential
    if (developer.businessModel == BusinessModel.venture) {
      if (listing.permissions.contains(PermissionType.residential)) return 100.0;
      if (listing.permissions.contains(PermissionType.mix)) return 75.0;
      return 50.0;
    }
    
    return 50.0; // Default neutral score
  }

  /// Calculate GFA fit score (0-100)
  static double _calculateGFAFit(DeveloperProfile developer, LandListing listing) {
    // Use team size and project history to estimate capacity
    final estimatedCapacity = developer.teamSize * 100; // Rough estimate: 100 sqm per team member
    
    if (estimatedCapacity == 0) return 50.0; // Neutral if no team info
    
    final ratio = listing.gfa / estimatedCapacity;
    
    if (ratio <= 0.5) return 100.0; // Perfect fit - well within capacity
    if (ratio <= 1.0) return 90.0;  // Good fit - within capacity
    if (ratio <= 1.5) return 70.0;  // Acceptable fit - slightly over capacity
    if (ratio <= 2.0) return 50.0;  // Challenging fit - over capacity
    return 30.0; // Difficult fit - significantly over capacity
  }

  /// Calculate budget fit score (0-100)
  static double _calculateBudgetFit(DeveloperProfile developer, LandListing listing) {
    // This would need actual budget data from developer profile
    // For now, return neutral score
    return 50.0;
  }

  /// Calculate desired developer boost score (0-100)
  static double _calculateDesiredDeveloperBoost(DeveloperProfile developer, LandListing listing) {
    if (listing.desiredDevelopers.isEmpty) return 50.0; // No preference
    
    final isDesired = listing.desiredDevelopers.contains(developer.id);
    if (isDesired) return 100.0; // Maximum boost
    
    // Check if company name matches any desired developers
    for (final desiredId in listing.desiredDevelopers) {
      if (desiredId.toLowerCase().contains(developer.companyName.toLowerCase()) ||
          developer.companyName.toLowerCase().contains(desiredId.toLowerCase())) {
        return 75.0; // Partial match
      }
    }
    
    return 50.0; // No match
  }

  /// Calculate developer size boost score (0-100)
  static double _calculateDeveloperSizeBoost(DeveloperProfile developer) {
    // Larger developers get a slight boost due to credibility
    if (developer.teamSize >= 50) return 100.0;
    if (developer.teamSize >= 25) return 90.0;
    if (developer.teamSize >= 10) return 80.0;
    if (developer.teamSize >= 5) return 70.0;
    if (developer.teamSize >= 2) return 60.0;
    return 50.0; // Solo developer
  }

  /// Sort listings by matching score for a developer
  static List<LandListing> sortByMatchingScore(
    List<LandListing> listings,
    DeveloperProfile developer,
  ) {
    final scoredListings = listings.map((listing) {
      final score = MatchingService.score(developer, listing);
      return _ScoredListing(listing: listing, score: score);
    }).toList();

    // Sort by score (highest first)
    scoredListings.sort((a, b) => b.score.compareTo(a.score));

    // Return sorted listings
    return scoredListings.map((scored) => scored.listing).toList();
  }

  /// Sort developers by matching score for a listing
  static List<DeveloperProfile> sortDevelopersByMatchingScore(
    List<DeveloperProfile> developers,
    LandListing listing,
  ) {
    final scoredDevelopers = developers.map((developer) {
      final score = MatchingService.score(developer, listing);
      return _ScoredDeveloper(developer: developer, score: score);
    }).toList();

    // Sort by score (highest first)
    scoredDevelopers.sort((a, b) => b.score.compareTo(a.score));

    // Return sorted developers
    return scoredDevelopers.map((scored) => scored.developer).toList();
  }
}

// Helper classes for sorting
class _ScoredListing {
  final LandListing listing;
  final double score;

  _ScoredListing({required this.listing, required this.score});
}

class _ScoredDeveloper {
  final DeveloperProfile developer;
  final double score;

  _ScoredDeveloper({required this.developer, required this.score});
}
