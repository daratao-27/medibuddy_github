import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import '../services/firebase_service.dart';
import '../models/medication.dart';

// one shared FirebaseService for the whole app
final firebaseServiceProvider = Provider<FirebaseService>((ref) {
  return FirebaseService();
});

// rebuilds anything watching this when the user logs in/out
final authStateProvider = StreamProvider<User?>((ref) {
  return FirebaseAuth.instance.authStateChanges();
});

// current filter, e.g. 'all', 'lowStock', or a frequency like 'Once daily'
final medFilterProvider = StateProvider<String>((ref) => 'all');

// current sort order: name_asc, name_desc, stock_asc, stock_desc
final medSortProvider = StateProvider<String>((ref) => 'name_asc');

// meds for the logged-in user, filtered/sorted on the firestore side
final medicationsProvider = StreamProvider<List<Medication>>((ref) {
  final authState = ref.watch(authStateProvider);
  final filter = ref.watch(medFilterProvider);
  final sortKey = ref.watch(medSortProvider);

  return authState.when(
    data: (user) {
      if (user == null) return Stream.value([]);
      if (user.email == null) return Stream.value([]);
      final service = ref.read(firebaseServiceProvider);
      return service.medicationsStreamFiltered(
        user.email!,
        filter: filter,
        sortKey: sortKey,
      );
    },
    loading: () => Stream.value([]),
    error: (_, __) => Stream.value([]),
  );
});

// total meds + low stock count, using a firestore count() query.
// re-runs whenever the meds list changes so it stays accurate
final medStatsProvider = FutureProvider.autoDispose<Map<String, int>>((ref) async {
  ref.watch(medicationsProvider); // rerun on every meds update

  final authState = ref.watch(authStateProvider);
  final email = authState.value?.email;
  if (email == null) return {'total': 0, 'lowStock': 0};

  final service = ref.read(firebaseServiceProvider);
  return service.getMedicationStats(email);
});
