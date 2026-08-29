import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../models/cart_item.dart';
import '../models/medication.dart';

class FirebaseService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // registers a new user and saves their display name
  Future<UserCredential> register(
    String fullName,
    String email,
    String password,
  ) async {
    final credential = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
    await credential.user?.updateDisplayName(fullName);
    return credential;
  }

  // signs in with email + password
  Future<UserCredential> login(String email, String password) async {
    if (kIsWeb) {
      await _auth.setPersistence(Persistence.LOCAL);
    }
    return _auth.signInWithEmailAndPassword(email: email, password: password);
  }

  // signs out
  Future<void> logOut() {
    return _auth.signOut();
  }

  // sends a password reset email
  Future<void> forgotPassword(String email) {
    return _auth.sendPasswordResetEmail(email: email);
  }

  // gets whoever is currently signed in
  User? getCurrentUser() => _auth.currentUser;

  // updates the display name
  Future<void> updateDisplayName(String newName) async {
    await _auth.currentUser?.updateDisplayName(newName);
  }

  // changes the password
  Future<void> updatePassword(String newPassword) async {
    await _auth.currentUser?.updatePassword(newPassword);
  }

  // sends a verification email
  Future<void> sendEmailVerification() async {
    await _auth.currentUser?.sendEmailVerification();
  }

  // google sign-in, opens the account picker popup on web
  Future<UserCredential?> signInWithGoogle() async {
    final GoogleSignInAccount? googleUser = await GoogleSignIn(
      clientId:
          '958612893819-n8do3svf4nt8n4kqrtkfj5prshtiet0r.apps.googleusercontent.com',
    ).signIn();
    if (googleUser == null) return null;
    final googleAuth = await googleUser.authentication;
    final credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );
    return await _auth.signInWithCredential(credential);
  }

  // github sign-in, same idea as google
  Future<UserCredential> signInWithGitHub() async {
    final provider = GithubAuthProvider();
    return await _auth.signInWithPopup(provider);
  }

  // adds a new medication
  Future<void> addMedication(Medication med) {
    return _db.collection('medications').add(med.toMap());
  }

  // saves the user's cart to firestore
  Future<void> saveCart(String userEmail, List<CartItem> items) async {
    final cartRef = _db.collection('carts').doc(userEmail);
    await cartRef.set({
      'userEmail': userEmail,
      'items': items
          .map((item) => {
                'name': item.name,
                'quantity': item.quantity,
                'pricePerUnit': item.pricePerUnit,
                'image': item.image,
                'packSize': item.packSize,
              })
          .toList(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  // loads the user's cart from firestore
  Future<List<CartItem>> loadCart(String userEmail) async {
    final snapshot = await _db.collection('carts').doc(userEmail).get();
    if (!snapshot.exists) return [];

    final data = snapshot.data();
    final items = data?['items'] as List<dynamic>? ?? [];

    return items.map<CartItem>((item) {
      final map = item as Map<String, dynamic>;
      return CartItem(
        name: map['name'] ?? '',
        quantity: (map['quantity'] as num?)?.toInt() ?? 1,
        pricePerUnit: (map['pricePerUnit'] as num?)?.toDouble() ?? 0.0,
        image: map['image'] ?? '',
        packSize: (map['packSize'] as num?)?.toInt() ?? 1,
      );
    }).toList();
  }

  // clears the cart after checkout is done
  Future<void> clearCart(String userEmail) async {
    await _db.collection('carts').doc(userEmail).delete();
  }

  // finds a med by name for a user, returns the first match or null
  Future<DocumentSnapshot<Map<String, dynamic>>?> getMedicationByName(
      String name, String userEmail) async {
    final query = await _db
        .collection('medications')
        .where('userEmail', isEqualTo: userEmail)
        .where('name', isEqualTo: name)
        .limit(1)
        .get();

    if (query.docs.isEmpty) return null;
    return query.docs.first;
  }

  // updates an existing medication
  Future<void> updateMedication(String id, Medication med) {
    return _db.collection('medications').doc(id).update(med.toMap());
  }

  // deletes a medication by id
  Future<void> deleteMedication(String id) {
    return _db.collection('medications').doc(id).delete();
  }

  // stream of meds for the current user
  Stream<List<Medication>> medicationsStream(String userEmail) {
    return _db
        .collection('medications')
        .where('userEmail', isEqualTo: userEmail)
        .snapshots()
        .map(
          (snap) =>
              snap.docs.map((doc) => Medication.fromFirestore(doc)).toList(),
        );
  }

  // same as above but with filter + sort applied on the firestore side.
  // filter: 'all', 'lowStock', 'criticalStock', or a frequency like 'Once daily'
  // sortKey: 'name_asc', 'name_desc', 'stock_asc', 'stock_desc'
  Stream<List<Medication>> medicationsStreamFiltered(
    String userEmail, {
    String filter = 'all',
    String sortKey = 'name_asc',
  }) {
    Query<Map<String, dynamic>> query =
        _db.collection('medications').where('userEmail', isEqualTo: userEmail);

    if (filter == 'lowStock') {
      query = query.where('isLowStock', isEqualTo: true);
    } else if (filter == 'criticalStock') {
      // two conditions on stockCount = a range filter
      query = query
          .where('stockCount', isGreaterThanOrEqualTo: 0)
          .where('stockCount', isLessThanOrEqualTo: 5);
    } else if (filter != 'all') {
      query = query.where('frequency', isEqualTo: filter);
    }

    // firestore wants the first orderBy to match the range filter field,
    // so criticalStock always sorts by stockCount
    switch (filter == 'criticalStock' ? 'stock_asc' : sortKey) {
      case 'name_desc':
        query = query.orderBy('name', descending: true);
        break;
      case 'stock_asc':
        query = query.orderBy('stockCount');
        break;
      case 'stock_desc':
        query = query.orderBy('stockCount', descending: true);
        break;
      case 'name_asc':
      default:
        query = query.orderBy('name');
        break;
    }

    return query.snapshots().map(
          (snap) =>
              snap.docs.map((doc) => Medication.fromFirestore(doc)).toList(),
        );
  }

  // uses firestore's count() so we don't have to download every doc
  // just to count them
  Future<Map<String, int>> getMedicationStats(String userEmail) async {
    final totalSnap = await _db
        .collection('medications')
        .where('userEmail', isEqualTo: userEmail)
        .count()
        .get();

    final lowStockSnap = await _db
        .collection('medications')
        .where('userEmail', isEqualTo: userEmail)
        .where('isLowStock', isEqualTo: true)
        .count()
        .get();

    return {
      'total': totalSnap.count ?? 0,
      'lowStock': lowStockSnap.count ?? 0,
    };
  }
}
