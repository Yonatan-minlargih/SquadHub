import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Stream<User?> get authStateChanges => _auth.authStateChanges();
  User? get currentUser => _auth.currentUser;

  Future<UserCredential> signIn(String email, String password) async {
    return await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  Future<UserCredential> signUp(String email, String password) async {
    return await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }

  Future<void> updateDisplayName(String name) async {
    await _auth.currentUser?.updateDisplayName(name);
  }

  Future<void> reloadUser() async {
    await _auth.currentUser?.reload();
  }

  Future<DocumentSnapshot<Map<String, dynamic>>> getUserDoc(String uid) async {
    return await _firestore.collection('users').doc(uid).get();
  }

  Future<void> createUserDoc({
    required String uid,
    required String name,
    required String email,
    String? squadId,
  }) async {
    final data = {
      'name': name,
      'email': email,
      'status': 'free',
      'avatarUrl': name.substring(0, 1).toUpperCase(),
      'notificationsEnabled': true,
      'createdAt': FieldValue.serverTimestamp(),
    };
    if (squadId != null) {
      data['squadId'] = squadId;
    }
    await _firestore.collection('users').doc(uid).set(data);
  }

  Future<int> getSquadMemberCount(String squadId) async {
    final snapshot = await _firestore
        .collection('users')
        .where('squadId', isEqualTo: squadId)
        .get();
    return snapshot.docs.length;
  }

  Future<void> updateUserSquad(String uid, String squadId) async {
    await _firestore.collection('users').doc(uid).update({'squadId': squadId});
  }

  Future<void> updateNotificationPreference(String uid, bool enabled) async {
    await _firestore.collection('users').doc(uid).update({
      'notificationsEnabled': enabled,
    });
  }

  Future<void> leaveSquad(String uid) async {
    await _firestore.collection('users').doc(uid).update({
      'squadId': FieldValue.delete(),
    });
  }
}
