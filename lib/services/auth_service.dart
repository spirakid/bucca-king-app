// lib/services/auth_service.dart
// REPLACE YOUR ENTIRE FILE WITH THIS CODE

import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // SharedPreferences keys
  static const String _keyIsLoggedIn = 'isLoggedIn';
  static const String _keyUserId = 'userId';
  static const String _keyUserName = 'userName';
  static const String _keyUserEmail = 'userEmail';
  static const String _keyUserPhone = 'userPhone';
  static const String _keyUserAddress = 'userAddress';

  // Getter for current user ID
  String? get userId => _auth.currentUser?.uid;

  // Getter to check if user is logged in
  bool get isLoggedIn => _auth.currentUser != null;

  // Get user's display name
  String getUserName() {
    final name = _auth.currentUser?.displayName;
    if (name != null && name.isNotEmpty) return name;
    return 'User';
  }

  // Get user's email
  String getUserEmail() {
    return _auth.currentUser?.email ?? 'guest@example.com';
  }

  // Get user's initial (first letter of name)
  String getUserInitial() {
    final name = getUserName();
    return name.isNotEmpty ? name[0].toUpperCase() : 'U';
  }

  // Get user's profile data from Firestore
  Future<Map<String, dynamic>?> getUserProfile() async {
    try {
      if (userId == null) {
        print('❌ getUserProfile: No user logged in');
        return null;
      }

      print('📱 Fetching profile for user: $userId');
      
      final doc = await _firestore.collection('users').doc(userId).get();
      
      if (doc.exists && doc.data() != null) {
        final data = doc.data()!;
        print('✅ Profile loaded: ${data['name']}');
        
        // Cache the data locally
        await _cacheUserData(data);
        return data;
      }

      print('⚠️ No Firestore document found, using Firebase Auth data');
      // Fallback to Firebase Auth data
      final fallbackData = {
        'name': _auth.currentUser?.displayName ?? 'User',
        'email': getUserEmail(),
        'phone': '',
        'address': '',
      };
      
      // Create document in Firestore
      await _firestore.collection('users').doc(userId).set(fallbackData);
      return fallbackData;
      
    } catch (e) {
      print('❌ Error getting user profile: $e');
      return {
        'name': _auth.currentUser?.displayName ?? 'User',
        'email': getUserEmail(),
        'phone': '',
        'address': '',
      };
    }
  }

  // Cache user data locally
  Future<void> _cacheUserData(Map<String, dynamic> data) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_keyUserName, data['name'] ?? '');
      await prefs.setString(_keyUserEmail, data['email'] ?? '');
      await prefs.setString(_keyUserPhone, data['phone'] ?? '');
      await prefs.setString(_keyUserAddress, data['address'] ?? '');
      print('💾 User data cached locally');
    } catch (e) {
      print('❌ Error caching user data: $e');
    }
  }

  // Update user's profile
  Future<bool> updateProfile({
    required String name,
    required String phone,
    required String address,
  }) async {
    try {
      if (userId == null) {
        print('❌ updateProfile: No user logged in');
        return false;
      }

      print('📝 Updating profile for: $userId');

      // Update display name in Firebase Auth
      await _auth.currentUser?.updateDisplayName(name);
      
      // Update profile in Firestore
      final userData = {
        'name': name,
        'phone': phone,
        'address': address,
        'email': getUserEmail(),
        'updatedAt': FieldValue.serverTimestamp(),
      };
      
      await _firestore.collection('users').doc(userId).set(
        userData,
        SetOptions(merge: true),
      );
      
      // Cache locally
      await _cacheUserData(userData);
      
      print('✅ Profile updated successfully');
      return true;
    } catch (e) {
      print('❌ Error updating profile: $e');
      return false;
    }
  }

  // Login with email and password
  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    try {
      print('🔐 Attempting login for: $email');
      
      final userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      print('✅ Login successful: ${userCredential.user?.uid}');

      // Save login state locally
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_keyIsLoggedIn, true);
      await prefs.setString(_keyUserId, userCredential.user?.uid ?? '');
      await prefs.setString(_keyUserEmail, email);

      // Load and cache user profile
      if (userCredential.user != null) {
        await getUserProfile();
      }

      return {
        'success': true,
        'message': 'Login successful'
      };
    } on FirebaseAuthException catch (e) {
      print('❌ FirebaseAuth Error: ${e.code} - ${e.message}');
      return {
        'success': false,
        'message': _getAuthErrorMessage(e.code),
      };
    } catch (e) {
      print('❌ Unexpected login error: $e');
      return {
        'success': false,
        'message': 'An unexpected error occurred: $e',
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
      print('📝 Creating account for: $email');
      
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      print('✅ Account created: ${userCredential.user?.uid}');

      // Update display name
      await userCredential.user?.updateDisplayName(name);

      // Create user document in Firestore
      final userData = {
        'name': name,
        'email': email,
        'phone': phone,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      };

      await _firestore.collection('users').doc(userCredential.user?.uid).set(userData);
      print('✅ User document created in Firestore');

      // Save login state locally
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_keyIsLoggedIn, true);
      await prefs.setString(_keyUserId, userCredential.user?.uid ?? '');
      await prefs.setString(_keyUserName, name);
      await prefs.setString(_keyUserEmail, email);
      await prefs.setString(_keyUserPhone, phone);

      print('✅ Signup complete');
      return {
        'success': true,
        'message': 'Account created successfully'
      };
    } on FirebaseAuthException catch (e) {
      print('❌ FirebaseAuth Error: ${e.code} - ${e.message}');
      return {
        'success': false,
        'message': _getAuthErrorMessage(e.code),
      };
    } catch (e) {
      print('❌ Unexpected signup error: $e');
      return {
        'success': false,
        'message': 'An unexpected error occurred: $e',
      };
    }
  }

  // Sign out
  Future<void> signOut() async {
    try {
      print('👋 Signing out user: ${_auth.currentUser?.email}');
      await _auth.signOut();
      await _clearLocalData();
      print('✅ Logout successful');
    } catch (e) {
      print('❌ Error signing out: $e');
    }
  }

  // Clear local data
  Future<void> _clearLocalData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_keyIsLoggedIn);
      await prefs.remove(_keyUserId);
      await prefs.remove(_keyUserName);
      await prefs.remove(_keyUserEmail);
      await prefs.remove(_keyUserPhone);
      await prefs.remove(_keyUserAddress);
      print('🗑️ Local data cleared');
    } catch (e) {
      print('❌ Error clearing local data: $e');
    }
  }

  // Helper method to get error messages
  String _getAuthErrorMessage(String code) {
    switch (code) {
      case 'user-not-found':
        return 'No account found with this email. Please sign up.';
      case 'wrong-password':
        return 'Incorrect password. Please try again.';
      case 'email-already-in-use':
        return 'An account already exists with this email.';
      case 'weak-password':
        return 'Password is too weak. Use at least 6 characters.';
      case 'invalid-email':
        return 'Invalid email address format.';
      case 'invalid-credential':
        return 'Invalid email or password. Please check and try again.';
      case 'network-request-failed':
        return 'Network error. Please check your internet connection.';
      case 'too-many-requests':
        return 'Too many attempts. Please try again later.';
      case 'operation-not-allowed':
        return 'Email/Password sign-in is not enabled. Please contact support.';
      case 'user-disabled':
        return 'This account has been disabled.';
      default:
        return 'Error: $code. Please try again.';
    }
  }

  // Reload user data (useful after updates)
  Future<void> reloadUser() async {
    try {
      await _auth.currentUser?.reload();
      print('🔄 User data reloaded');
    } catch (e) {
      print('❌ Error reloading user: $e');
    }
  }
}