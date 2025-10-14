import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthService {
  // Singleton pattern
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  // Current user getter
  User? get currentUser => _auth.currentUser;
  
  // User ID getters
  String get userId => _auth.currentUser?.uid ?? '';
  String? get currentUserId => _auth.currentUser?.uid;
  
  // Check if logged in (getter - NO parentheses)
  bool get isLoggedIn => _auth.currentUser != null;
  
  // Auth state stream
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // ========== EMAIL/PASSWORD SIGNUP ==========
  Future<Map<String, dynamic>> signUp({
    required String name,
    required String email,
    required String phone,
    required String password,
  }) async {
    try {
      UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      User? user = result.user;
      if (user == null) {
        return {'success': false, 'message': 'Failed to create account'};
      }

      await user.updateDisplayName(name);

      await _firestore.collection('users').doc(user.uid).set({
        'uid': user.uid,
        'name': name,
        'email': email,
        'phone': phone,
        'address': '',
        'createdAt': FieldValue.serverTimestamp(),
      });

      await _cacheUserData(user.uid, name, email);

      return {
        'success': true,
        'user': user,
        'message': 'Account created successfully'
      };
    } on FirebaseAuthException catch (e) {
      return {'success': false, 'message': _getAuthErrorMessage(e.code)};
    } catch (e) {
      return {'success': false, 'message': 'Something went wrong: $e'};
    }
  }

  // ========== EMAIL/PASSWORD LOGIN ==========
  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    try {
      UserCredential result = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      User? user = result.user;
      if (user == null) {
        return {'success': false, 'message': 'Failed to sign in'};
      }

      DocumentSnapshot userDoc = await _firestore
          .collection('users')
          .doc(user.uid)
          .get();

      String userName = user.displayName ?? 'User';
      if (userDoc.exists) {
        final rawData = userDoc.data();
        if (rawData is Map<String, dynamic>) {
          userName = rawData['name'] ?? userName;
        }
      }

      await _cacheUserData(user.uid, userName, user.email ?? email);

      return {
        'success': true,
        'user': user,
        'userName': userName,
        'message': 'Login successful'
      };
    } on FirebaseAuthException catch (e) {
      return {'success': false, 'message': _getAuthErrorMessage(e.code)};
    } catch (e) {
      return {'success': false, 'message': 'Something went wrong: $e'};
    }
  }

  // ========== GOOGLE SIGN IN ==========
  Future<Map<String, dynamic>> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      
      if (googleUser == null) {
        return {'success': false, 'message': 'Google sign-in cancelled'};
      }

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      UserCredential result = await _auth.signInWithCredential(credential);
      User? user = result.user;

      if (user == null) {
        return {'success': false, 'message': 'Failed to sign in with Google'};
      }

      DocumentSnapshot userDoc = await _firestore
          .collection('users')
          .doc(user.uid)
          .get();

      if (!userDoc.exists) {
        await _firestore.collection('users').doc(user.uid).set({
          'uid': user.uid,
          'name': user.displayName ?? 'User',
          'email': user.email ?? '',
          'phone': '',
          'address': '',
          'createdAt': FieldValue.serverTimestamp(),
        });
      }

      await _cacheUserData(
        user.uid,
        user.displayName ?? 'User',
        user.email ?? '',
      );

      return {
        'success': true,
        'user': user,
        'userName': user.displayName ?? 'User',
        'message': 'Google sign-in successful'
      };
    } catch (e) {
      return {'success': false, 'message': 'Google sign-in failed: $e'};
    }
  }

  // ========== GET USER DATA ==========
  Future<Map<String, dynamic>?> getUserProfile() async {
    try {
      if (currentUser == null) return null;

      DocumentSnapshot doc = await _firestore
          .collection('users')
          .doc(currentUser!.uid)
          .get();

      if (doc.exists) {
        final rawData = doc.data();
        if (rawData is Map<String, dynamic>) {
          // Ensure all required fields exist
          return {
            'name': rawData['name'] ?? currentUser!.displayName ?? '',
            'phone': rawData['phone'] ?? '',
            'address': rawData['address'] ?? '',
            'email': rawData['email'] ?? currentUser!.email ?? '',
            'uid': rawData['uid'] ?? currentUser!.uid,
          };
        } else {
          // If data exists but is not the expected format, return defaults
          return {
            'name': currentUser!.displayName ?? '',
            'phone': '',
            'address': '',
            'email': currentUser!.email ?? '',
            'uid': currentUser!.uid,
          };
        }
      } else {
        // Create a basic profile if doesn't exist
        final basicProfile = {
          'name': currentUser!.displayName ?? '',
          'phone': '',
          'address': '',
          'email': currentUser!.email ?? '',
          'uid': currentUser!.uid,
          'createdAt': FieldValue.serverTimestamp(),
        };
        
        // Create the document
        await _firestore.collection('users').doc(currentUser!.uid).set(basicProfile);
        
        return basicProfile;
      }
    } catch (e) {
      print('Error getting user profile: $e');
      return null;
    }
  }

  // ========== SYNCHRONOUS USER INFO (for UI) ==========
  String getUserName() {
    return currentUser?.displayName ?? 'User';
  }

  String getUserEmail() {
    return currentUser?.email ?? '';
  }

  String getUserInitial() {
    final name = getUserName();
    return name.isNotEmpty ? name[0].toUpperCase() : 'U';
  }

  // ========== CACHED USER DATA ==========
  Future<String> getCachedUserName() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('userName') ?? getUserName();
  }

  // ========== UPDATE USER PROFILE ==========
  Future<Map<String, dynamic>> updateUserProfile({
    required String name,
    required String phone,
    required String address,
  }) async {
    try {
      User? user = _auth.currentUser;
      if (user == null) {
        return {'success': false, 'message': 'User not authenticated'};
      }

      // Update display name in Firebase Auth
      await user.updateDisplayName(name);

      // Update user data in Firestore (use set with merge to create if doesn't exist)
      await _firestore.collection('users').doc(user.uid).set({
        'name': name,
        'phone': phone,
        'address': address,
        'updatedAt': FieldValue.serverTimestamp(),
        'uid': user.uid,
        'email': user.email ?? '',
      }, SetOptions(merge: true));

      // Update cached data
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('userName', name);

      return {
        'success': true,
        'message': 'Profile updated successfully'
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Failed to update profile: $e'
      };
    }
  }

  // ========== SIGN OUT ==========
  Future<void> signOut() async {
    try {
      await _auth.signOut();
      await _googleSignIn.signOut();
      
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();
    } catch (e) {
      print('Error signing out: $e');
      rethrow;
    }
  }

  // ========== PRIVATE HELPERS ==========
  Future<void> _cacheUserData(String uid, String name, String email) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isLoggedIn', true);
    await prefs.setString('userId', uid);
    await prefs.setString('userName', name);
    await prefs.setString('userEmail', email);
  }

  String _getAuthErrorMessage(String code) {
    switch (code) {
      case 'weak-password':
        return 'The password is too weak';
      case 'email-already-in-use':
        return 'An account already exists with this email';
      case 'invalid-email':
        return 'Invalid email address';
      case 'user-not-found':
        return 'No account found with this email';
      case 'wrong-password':
        return 'Incorrect password';
      case 'user-disabled':
        return 'This account has been disabled';
      default:
        return 'An error occurred. Please try again';
    }
  }
}