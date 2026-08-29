import 'package:cloud_firestore/cloud_firestore.dart';

class Medication {
  final String id;
  final String name;
  final double dosage;
  final String unit; // e.g. mg, ml, mcg
  final String frequency; // e.g. "Once daily", "Twice daily"
  final String scheduledTime; // e.g. "8:00 AM"
  final String instructions; // e.g. "After breakfast", "With food"
  final int stockCount; // current tablets/capsules remaining
  final int totalCount; // original count (for progress bar)
  final String userEmail; // owner — used to filter Firestore queries

  Medication({
    required this.id,
    required this.name,
    required this.dosage,
    required this.unit,
    required this.frequency,
    required this.scheduledTime,
    required this.instructions,
    required this.stockCount,
    required this.totalCount,
    required this.userEmail,
  });

  // how much stock is left, 0 to 1, used for the progress bars
  double get stockPercentage =>
      totalCount > 0 ? (stockCount / totalCount).clamp(0.0, 1.0) : 0.0;

  // under 25% left counts as low stock
  bool get isLowStock => stockPercentage < 0.25;
  // firestore helpers

  // builds a Medication from a firestore doc
  static Medication fromFirestore(
      QueryDocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data();
    return Medication(
      id: doc.id,
      name: data['name'] ?? '',
      dosage: (data['dosage'] as num?)?.toDouble() ?? 0.0,
      unit: data['unit'] ?? 'mg',
      frequency: data['frequency'] ?? '',
      scheduledTime: data['scheduledTime'] ?? '',
      instructions: data['instructions'] ?? '',
      stockCount: (data['stockCount'] as num?)?.toInt() ?? 0,
      totalCount: (data['totalCount'] as num?)?.toInt() ?? 30,
      userEmail: data['userEmail'] ?? '',
    );
  }

  // turns this into a map for firestore.
  // isLowStock gets saved too (not just calculated) because firestore
  // queries can't compare two fields against each other
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'dosage': dosage,
      'unit': unit,
      'frequency': frequency,
      'scheduledTime': scheduledTime,
      'instructions': instructions,
      'stockCount': stockCount,
      'totalCount': totalCount,
      'userEmail': userEmail,
      'isLowStock': isLowStock,
    };
  }
}
