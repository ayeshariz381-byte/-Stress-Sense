import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum UserRole { student, consultant, none }

class AuthProvider extends ChangeNotifier {
  static const _kRole     = 'auth_role';
  static const _kRemember = 'auth_remember';
  static const _kName     = 'auth_name';

  late FirebaseAuth _auth;
  late FirebaseFirestore _db;

  UserRole _role   = UserRole.none;
  String   _email  = '';
  String   _uid    = '';
  String   _name   = '';
  bool     _loaded = false;

  AuthProvider() {
    _auth = FirebaseAuth.instance;
    _db   = FirebaseFirestore.instance;
  }

  // Getters
  UserRole get role        => _role;
  String   get email       => _email;
  String   get uid         => _uid;
  String   get name        => _name;
  bool     get isLoaded    => _loaded;
  bool     get isLoggedIn  => _role != UserRole.none;
  bool     get isStudent   => _role == UserRole.student;
  bool     get isConsultant => _role == UserRole.consultant;

  String get displayName {
    if (_name.isNotEmpty) return _name;
    if (_email.isEmpty) return 'User';
    return _email.split('@').first;
  }

  Future<void> initialize() async {
    final prefs   = await SharedPreferences.getInstance();
    final roleStr = prefs.getString(_kRole) ?? '';
    final user    = _auth.currentUser;

    if (user != null && roleStr.isNotEmpty) {
      _uid   = user.uid;
      _email = user.email ?? '';
      _role  = _roleFromString(roleStr);
      _name  = prefs.getString(_kName) ?? '';
    }
    _loaded = true;
    notifyListeners();
  }

  // --- Reset Password ---
  Future<void> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email.trim());
    } on FirebaseAuthException catch (e) {
      throw _friendlyError(e.code);
    } catch (e) {
      throw 'An error occurred. Please try again.';
    }
  }

  // --- Student Auth ---
  Future<String?> loginAsStudent({
    required String email,
    required String password,
    String? name,
    bool rememberMe = false,
    bool isRegister = false,
  }) async {
    try {
      UserCredential cred;
      if (isRegister) {
        cred = await _auth.createUserWithEmailAndPassword(
          email: email.trim(),
          password: password.trim(),
        );
        _name = name?.trim() ?? '';
        await _db.collection('users').doc(cred.user!.uid).set({
          'email': email.trim(),
          'name': _name,
          'role': 'student',
          'createdAt': FieldValue.serverTimestamp(),
        });
      } else {
        cred = await _auth.signInWithEmailAndPassword(
          email: email.trim(),
          password: password.trim(),
        );

        // Check role — make sure they are not logging in as consultant
        final doc = await _db
            .collection('users')
            .doc(cred.user!.uid)
            .get();
        final role = doc.data()?['role'] ?? 'student';

        if (role == 'consultant') {
          await _auth.signOut();
          return 'Please use the Consultant login instead.';
        }

        _name = doc.data()?['name'] ?? '';
      }

      _uid   = cred.user!.uid;
      _email = email.trim();
      _role  = UserRole.student;

      await _updateLastLogin();
      await _saveLocalState(UserRole.student, rememberMe);
      notifyListeners();
      return null;
    } on FirebaseAuthException catch (e) {
      return _friendlyError(e.code);
    } catch (e) {
      return 'An unexpected error occurred.';
    }
  }

  // --- Consultant Auth ---
  Future<String?> loginAsConsultant({
    required String email,
    required String password,
    bool rememberMe = false,
  }) async {
    try {
      UserCredential cred = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password.trim(),
      );

      // Check Firestore role
      final doc = await _db
          .collection('users')
          .doc(cred.user!.uid)
          .get();

      if (!doc.exists) {
        await _auth.signOut();
        return 'Account not found in the system.';
      }

      final role = (doc.data()?['role'] ?? '').toString().toLowerCase();

      if (role != 'consultant') {
        await _auth.signOut();
        return 'This account is not authorized as a consultant.';
      }

      _uid   = cred.user!.uid;
      _email = email.trim();
      _name  = doc.data()?['name'] ?? '';
      _role  = UserRole.consultant;

      await _updateLastLogin();
      await _saveLocalState(UserRole.consultant, rememberMe);
      notifyListeners();
      return null;
    } on FirebaseAuthException catch (e) {
      return _friendlyError(e.code);
    } catch (e) {
      return 'An unexpected error occurred.';
    }
  }

  // --- Logout ---
  Future<void> logout() async {
    await _auth.signOut();
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    _role  = UserRole.none;
    _uid   = '';
    _name  = '';
    _email = '';
    notifyListeners();
  }

  Future<void> _updateLastLogin() async {
    await _db.collection('users').doc(_uid).set({
      'lastLogin': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> _saveLocalState(UserRole role, bool remember) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kRole, _roleToString(role));
    await prefs.setString(_kName, _name);
    await prefs.setBool(_kRemember, remember);
  }

  String _roleToString(UserRole r) => r.name;

  UserRole _roleFromString(String s) =>
      UserRole.values.firstWhere(
        (e) => e.name == s,
        orElse: () => UserRole.none,
      );

  String _friendlyError(String code) {
    switch (code) {
      case 'user-not-found':          return 'No account found with this email.';
      case 'wrong-password':          return 'Incorrect password.';
      case 'invalid-email':           return 'The email format is invalid.';
      case 'invalid-credential':      return 'Incorrect email or password.';
      case 'network-request-failed':  return 'Network error. Check your connection.';
      case 'user-disabled':           return 'This account has been disabled.';
      default:                        return 'Authentication failed. Please try again.';
    }
  }
}