import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Get current user
  User? get currentUser => _auth.currentUser;

  // Get current user ID (nullable) and non-null string
  String? get currentUserId => _auth.currentUser?.uid;
  String get userId => _auth.currentUser?.uid ?? '';

  // Stream of auth state changes
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Check if user is logged in (uses cached flag + firebase)
  Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    final isLoggedIn = prefs.getBool('isLoggedIn') ?? false;
    return isLoggedIn && _auth.currentUser != null;
  }

  // ----- Authentication (sign up / login) -----

  // Sign up (named params order matches UI: name, email, phone, password)
  Future<Map<String, dynamic>> signUp({
    required String name,
    required String email,
    required String phone,
    required String password,
  }) async {
    try {
      // Create user with Firebase Auth
      UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      User? user = result.user;

      if (user != null) {
        // Update display name
        await user.updateDisplayName(name);

        // Create user document in Firestore
        await _firestore.collection('users').doc(user.uid).set({
          'uid': user.uid,
          'name': name,
          'email': email,
          'phone': phone,
          'createdAt': FieldValue.serverTimestamp(),
        });

        // Save login state & cached fields
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('isLoggedIn', true);
        await prefs.setString('userId', user.uid);
        await prefs.setString('userName', name);
        await prefs.setString('userEmail', email);

        return {
          'success': true,
          'user': user,
          'message': 'Account created successfully'
        };
      }

      return {'success': false, 'message': 'Failed to create account'};
    } on FirebaseAuthException catch (e) {
      String message = 'An error occurred';

      switch (e.code) {
        case 'weak-password':
          message = 'The password is too weak';
          break;
        case 'email-already-in-use':
          message = 'An account already exists with this email';
          break;
        case 'invalid-email':
          message = 'Invalid email address';
          break;
        default:
          message = e.message ?? 'An error occurred';
      }

      return {'success': false, 'message': message};
    } catch (e) {
      return {'success': false, 'message': 'Something went wrong: $e'};
    }
  }

  // Sign in (keeps original name signIn)
  Future<Map<String, dynamic>> signIn({
    required String email,
    required String password,
  }) async {
    try {
      UserCredential result = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      User? user = result.user;

      if (user != null) {
        // Get user data from Firestore
        DocumentSnapshot userDoc =
            await _firestore.collection('users').doc(user.uid).get();

        String userName = user.displayName ?? 'User';

        if (userDoc.exists) {
          final data = userDoc.data() as Map<String, dynamic>?;
          if (data != null) {
            userName = (data['name'] as String?) ?? userName;
          }
        }

        // Save login state & cached fields
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('isLoggedIn', true);
        await prefs.setString('userId', user.uid);
        await prefs.setString('userName', userName);
        await prefs.setString('userEmail', user.email ?? email);

        return {
          'success': true,
          'user': user,
          'userName': userName,
          'message': 'Login successful'
        };
      }

      return {'success': false, 'message': 'Failed to sign in'};
    } on FirebaseAuthException catch (e) {
      String message = 'An error occurred';

      switch (e.code) {
        case 'user-not-found':
          message = 'No account found with this email';
          break;
        case 'wrong-password':
          message = 'Incorrect password';
          break;
        case 'invalid-email':
          message = 'Invalid email address';
          break;
        case 'user-disabled':
          message = 'This account has been disabled';
          break;
        default:
          message = e.message ?? 'An error occurred';
      }

      return {'success': false, 'message': message};
    } catch (e) {
      return {'success': false, 'message': 'Something went wrong: $e'};
    }
  }

  // Convenience alias: login (used by UI)
  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) =>
      signIn(email: email, password: password);

  // ----- User data / profile helpers -----

  // Get user document from Firestore
  Future<Map<String, dynamic>?> getUserData() async {
    try {
      if (currentUser == null) return null;

      DocumentSnapshot userDoc =
          await _firestore.collection('users').doc(currentUser!.uid).get();

      if (userDoc.exists) {
        return userDoc.data() as Map<String, dynamic>;
      }

      return null;
    } catch (e) {
      print('Error getting user data: $e');
      return null;
    }
  }

  // Alias expected by some screens
  Future<Map<String, dynamic>?> getUserProfile() => getUserData();

  // Get cached user name
  Future<String> getCachedUserName() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('userName') ?? 'User';
  }

  // Get cached user email
  Future<String> getCachedUserEmail() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('userEmail') ?? '';
  }

  // Synchronous helpers used by UI (fall back to Firebase user if cache unavailable)
  String getUserName() {
    return _auth.currentUser?.displayName ?? 'User';
  }

  String getUserEmail() {
    return _auth.currentUser?.email ?? '';
  }

  String getUserInitial() {
    final name = getUserName();
    return name.isNotEmpty ? name[0].toUpperCase() : 'U';
  }

  // Update user profile in Auth + Firestore
  Future<Map<String, dynamic>> updateUserProfile({
    required String name,
    required String phone,
  }) async {
    try {
      if (currentUser == null) {
        return {'success': false, 'message': 'No user logged in'};
      }

      // Update display name
      await currentUser!.updateDisplayName(name);

      // Update Firestore
      await _firestore.collection('users').doc(currentUser!.uid).update({
        'name': name,
        'phone': phone,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Update cached data
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('userName', name);

      return {'success': true, 'message': 'Profile updated successfully'};
    } catch (e) {
      return {'success': false, 'message': 'Failed to update profile: $e'};
    }
  }

  // Alias expected by some screens
  Future<bool> updateProfile({
    required String name,
    required String phone,
  }) async {
    final res = await updateUserProfile(name: name, phone: phone);
    return res['success'] == true;
  }

  // Sign out
  Future<void> signOut() async {
    try {
      await _auth.signOut();

      // Clear saved login state
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();
    } catch (e) {
      print('Error signing out: $e');
      rethrow;
    }
  }
}