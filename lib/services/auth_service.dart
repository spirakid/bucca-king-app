import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Getter for current user ID
  String get userId => _auth.currentUser?.uid ?? '';

  // Getter to check if user is logged in
  bool get isLoggedIn => _auth.currentUser != null;

  // Get user's display name
  String getUserName() {
    return _auth.currentUser?.displayName ?? 'User';
  }

  // Get user's email
  String getUserEmail() {
    return _auth.currentUser?.email ?? '';
  }

  // Get user's initial (first letter of name)
  String getUserInitial() {
    final name = getUserName();
    return name.isNotEmpty ? name[0].toUpperCase() : 'U';
  }

  // Get user's profile data
  Future<Map<String, dynamic>> getUserProfile() async {
    try {
      final doc = await _firestore.collection('users').doc(userId).get();
      return doc.data() ?? {
        'name': getUserName(),
        'email': getUserEmail(),
        'phone': '',
      };
    } catch (e) {
      return {
        'name': getUserName(),
        'email': getUserEmail(),
        'phone': '',
      };
    }
  }

  // Update user's profile
  Future<bool> updateProfile({
    required String name,
    required String phone,
  }) async {
    try {
      // Update display name in Firebase Auth
      await _auth.currentUser?.updateDisplayName(name);
      
      // Update profile in Firestore
      await _firestore.collection('users').doc(userId).set({
        'name': name,
        'phone': phone,
        'email': getUserEmail(),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      
      return true;
    } catch (e) {
      print('Error updating profile: $e');
      return false;
    }
  }

  // Login with email and password
  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    try {
      final userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return {'success': true};
    } on FirebaseAuthException catch (e) {
      return {
        'success': false,
        'message': _getAuthErrorMessage(e.code),
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'An unexpected error occurred',
      };
    }
  }

  // Sign up with email and password
  Future<Map<String, dynamic>> signUp({
    required String name,
    required String email,
    required String phone,
    required String password,
  }) async {
    try {
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      await userCredential.user?.updateDisplayName(name);

      await _firestore.collection('users').doc(userCredential.user?.uid).set({
        'name': name,
        'email': email,
        'phone': phone,
        'createdAt': FieldValue.serverTimestamp(),
      });

      return {'success': true};
    } on FirebaseAuthException catch (e) {
      return {
        'success': false,
        'message': _getAuthErrorMessage(e.code),
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'An unexpected error occurred',
      };
    }
  }

  // Sign out
  Future<void> signOut() async {
    await _auth.signOut();
  }

  // Helper method to get error messages
  String _getAuthErrorMessage(String code) {
    switch (code) {
      case 'user-not-found':
        return 'No user found with this email';
      case 'wrong-password':
        return 'Wrong password provided';
      case 'email-already-in-use':
        return 'An account already exists with this email';
      case 'weak-password':
        return 'The password provided is too weak';
      case 'invalid-email':
        return 'Invalid email address';
      default:
        return 'An error occurred. Please try again';
    }
  }
}