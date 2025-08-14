import 'dart:convert';
import 'dart:math';
import 'package:crypto/crypto.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:optionxi/Helpers/global_snackbar_get.dart';
import 'package:optionxi/Login_Signup/login.dart';
import 'package:optionxi/homepage.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supabase;

class AuthService {
  final firebase_auth.FirebaseAuth _firebaseAuth =
      firebase_auth.FirebaseAuth.instance;
  final supabase.SupabaseClient _supabaseClient =
      supabase.Supabase.instance.client;

  /// Generates a secure random string for Apple Sign In nonce.
  String _generateNonce([int length = 32]) {
    final random = Random.secure();
    final values = List<int>.generate(length, (i) => random.nextInt(256));
    return base64Url.encode(values);
  }

  //----------------------------------------------------------------------------
  // ## Auth State Management
  //----------------------------------------------------------------------------

  /// Listens to Firebase auth state and navigates the user accordingly.
  Widget handleAuthState() {
    return StreamBuilder<firebase_auth.User?>(
      stream: _firebaseAuth.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasData && snapshot.data != null) {
          // User is logged in to Firebase.
          // Sync and authenticate with Supabase in the background.
          _syncAndAuthWithSupabase(snapshot.data!);
          return const Homepage();
        } else {
          // User is not logged in.
          return const ModernTradingLoginPage();
        }
      },
    );
  }

  //----------------------------------------------------------------------------
  // ## Data Syncing & Supabase Authentication
  //----------------------------------------------------------------------------

  /// Syncs Firebase user data to Supabase and authenticates with Supabase.
  Future<void> _syncAndAuthWithSupabase(firebase_auth.User firebaseUser) async {
    try {
      // First, authenticate with Supabase using the Firebase ID token
      await _authenticateWithSupabase(firebaseUser);

      // Then sync/update user data
      await _syncUserDataWithSupabase(firebaseUser);
    } catch (e) {
      debugPrint('Error syncing and authenticating with Supabase: $e');
    }
  }

  /// Authenticates with Supabase using Firebase ID token.
  Future<void> _authenticateWithSupabase(
      firebase_auth.User firebaseUser) async {
    try {
      // For Firebase ID token authentication, we need to use a custom approach
      // since Supabase doesn't have direct Firebase provider support
      await _customFirebaseSupabaseAuth(firebaseUser);
    } catch (e) {
      debugPrint('Error authenticating with Supabase: $e');
      // Fallback: try to sign in with email/password
      await _fallbackSupabaseAuth(firebaseUser);
    }
  }

  /// Custom authentication method for Firebase users in Supabase.
  Future<void> _customFirebaseSupabaseAuth(
      firebase_auth.User firebaseUser) async {
    try {
      if (firebaseUser.email != null) {
        // Use email/password authentication with a deterministic password
        final password = _generateTemporaryPassword(firebaseUser.uid);

        try {
          // Try to sign in first
          await _supabaseClient.auth.signInWithPassword(
            email: firebaseUser.email!,
            password: password,
          );
          debugPrint('Successfully signed in to Supabase with email/password');
        } catch (e) {
          // If sign in fails, try to sign up
          final response = await _supabaseClient.auth.signUp(
            email: firebaseUser.email!,
            password: password,
            data: {
              'firebase_uid': firebaseUser.uid,
              'display_name': firebaseUser.displayName,
              'photo_url': firebaseUser.photoURL,
            },
          );
          if (response.user != null) {
            debugPrint(
                'Successfully signed up and authenticated with Supabase');
          }
        }
      } else {
        // For users without email (like some phone auth), use anonymous auth
        await _supabaseClient.auth.signInAnonymously();
        debugPrint('Signed in to Supabase anonymously');
      }
    } catch (e) {
      debugPrint('Custom Firebase-Supabase authentication failed: $e');
      throw e;
    }
  }

  /// Fallback authentication method for Supabase.
  Future<void> _fallbackSupabaseAuth(firebase_auth.User firebaseUser) async {
    try {
      if (firebaseUser.email != null) {
        // Try to sign up/in with email (using deterministic password)
        final tempPassword = _generateTemporaryPassword(firebaseUser.uid);

        try {
          // Try to sign in first
          await _supabaseClient.auth.signInWithPassword(
            email: firebaseUser.email!,
            password: tempPassword,
          );
        } catch (e) {
          // If sign in fails, try to sign up
          await _supabaseClient.auth.signUp(
            email: firebaseUser.email!,
            password: tempPassword,
            data: {
              'firebase_uid': firebaseUser.uid,
              'display_name': firebaseUser.displayName,
              'photo_url': firebaseUser.photoURL,
            },
          );
        }
      } else {
        // For users without email, use anonymous authentication
        await _supabaseClient.auth.signInAnonymously();
      }
    } catch (e) {
      debugPrint('Fallback Supabase authentication failed: $e');
    }
  }

  /// Generates a temporary password based on Firebase UID for Supabase auth.
  String _generateTemporaryPassword(String firebaseUid) {
    // Create a deterministic password based on Firebase UID
    final bytes = utf8.encode(firebaseUid + 'your_app_secret_key');
    final digest = sha256.convert(bytes);
    return digest.toString().substring(0, 16); // Use first 16 characters
  }

  /// Syncs Firebase user data to the Supabase 'users' table.
  Future<void> _syncUserDataWithSupabase(
      firebase_auth.User firebaseUser) async {
    try {
      final userData = {
        'firebase_uid': firebaseUser.uid,
        'email': firebaseUser.email,
        'display_name': firebaseUser.displayName,
        'photo_url': firebaseUser.photoURL,
        'phone': firebaseUser.phoneNumber,
        'last_sign_in': DateTime.now().toIso8601String(),
      };

      final response = await _supabaseClient
          .from('users')
          .select('firebase_uid')
          .eq('firebase_uid', firebaseUser.uid)
          .maybeSingle();

      if (response == null) {
        // User does not exist, create a new record.
        await _supabaseClient.from('users').insert({
          ...userData,
          'created_at': DateTime.now().toIso8601String(),
        });
      } else {
        // User exists, update their record.
        await _supabaseClient
            .from('users')
            .update(userData)
            .eq('firebase_uid', firebaseUser.uid);
      }
    } catch (e) {
      debugPrint('Error syncing user data with Supabase: $e');
    }
  }

  //----------------------------------------------------------------------------
  // ## Authentication Methods (Firebase + Supabase)
  //----------------------------------------------------------------------------

  /// Signs in with Google, then authenticates with both Firebase and Supabase.
  Future<firebase_auth.UserCredential?> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
      if (googleUser == null) return null;

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      // Authenticate with Firebase
      final firebase_auth.AuthCredential firebaseCredential =
          firebase_auth.GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final userCredential =
          await _firebaseAuth.signInWithCredential(firebaseCredential);

      if (userCredential.user != null) {
        // Authenticate with Supabase using Google OAuth
        await _authenticateWithSupabaseGoogle(googleAuth);
        // Sync user data
        await _syncUserDataWithSupabase(userCredential.user!);
      }
      return userCredential;
    } catch (e) {
      _handleAuthError(e);
      return null;
    }
  }

  /// Authenticates with Supabase using Google OAuth tokens.
  Future<void> _authenticateWithSupabaseGoogle(
      GoogleSignInAuthentication googleAuth) async {
    try {
      // Use the correct Google OAuth provider
      await _supabaseClient.auth.signInWithIdToken(
        provider: supabase.OAuthProvider.google,
        idToken: googleAuth.idToken!,
        accessToken: googleAuth.accessToken,
      );
      debugPrint('Successfully authenticated with Supabase using Google');
    } catch (e) {
      debugPrint('Error authenticating with Supabase using Google: $e');
      // Fallback to email/password method
      final firebaseUser = _firebaseAuth.currentUser;
      if (firebaseUser != null) {
        await _customFirebaseSupabaseAuth(firebaseUser);
      }
    }
  }

  /// Signs in with Apple, then authenticates with both Firebase and Supabase.
  Future<firebase_auth.UserCredential?> signInWithApple() async {
    try {
      final rawNonce = _generateNonce();
      final hashedNonce = sha256.convert(utf8.encode(rawNonce)).toString();

      final appleCredential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
        nonce: hashedNonce,
      );

      // Authenticate with Firebase
      final oauthCredential =
          firebase_auth.OAuthProvider("apple.com").credential(
        idToken: appleCredential.identityToken,
        rawNonce: rawNonce,
      );

      final userCredential =
          await _firebaseAuth.signInWithCredential(oauthCredential);
      final firebaseUser = userCredential.user;

      if (firebaseUser != null) {
        // Update Firebase profile if needed
        bool needsUpdate = false;
        if ((firebaseUser.displayName ?? '').isEmpty &&
            appleCredential.givenName != null) {
          await firebaseUser.updateDisplayName(
            '${appleCredential.givenName ?? ''} ${appleCredential.familyName ?? ''}'
                .trim(),
          );
          needsUpdate = true;
        }

        if (needsUpdate) await firebaseUser.reload();

        // Authenticate with Supabase using Apple OAuth
        await _authenticateWithSupabaseApple(appleCredential, rawNonce);
        // Sync user data
        await _syncUserDataWithSupabase(firebaseUser);
        return userCredential;
      }
      return null;
    } catch (e) {
      _handleAuthError(e);
      return null;
    }
  }

  /// Authenticates with Supabase using Apple OAuth.
  Future<void> _authenticateWithSupabaseApple(
      AuthorizationCredentialAppleID appleCredential, String rawNonce) async {
    try {
      // Use the correct Apple OAuth provider
      await _supabaseClient.auth.signInWithIdToken(
        provider: supabase.OAuthProvider.apple,
        idToken: appleCredential.identityToken!,
        nonce: rawNonce,
      );
      debugPrint('Successfully authenticated with Supabase using Apple');
    } catch (e) {
      debugPrint('Error authenticating with Supabase using Apple: $e');
      // Fallback to email/password method
      final firebaseUser = _firebaseAuth.currentUser;
      if (firebaseUser != null) {
        await _customFirebaseSupabaseAuth(firebaseUser);
      }
    }
  }

  /// Verifies the OTP and signs the user in with both Firebase and Supabase.
  Future<void> verifyOtp(String verificationId, String smsCode) async {
    try {
      final credential = firebase_auth.PhoneAuthProvider.credential(
        verificationId: verificationId,
        smsCode: smsCode,
      );
      final result = await _firebaseAuth.signInWithCredential(credential);

      if (result.user != null) {
        // Authenticate with Supabase (fallback method for phone auth)
        await _authenticateWithSupabase(result.user!);
        await _syncUserDataWithSupabase(result.user!);
        GlobalSnackBarGet().showGetSucess("Success", "Successfully Logged In");
      }
    } on firebase_auth.FirebaseAuthException catch (e) {
      if (e.code == 'invalid-verification-code') {
        GlobalSnackBarGet()
            .showGetError("Error", "The OTP entered is invalid.");
      } else {
        GlobalSnackBarGet()
            .showGetError("Error", e.message ?? "Something went wrong.");
      }
    } catch (e) {
      GlobalSnackBarGet()
          .showGetError("Error", "An unexpected error occurred.");
    }
  }

  /// Signs the user out from both Firebase and Supabase.
  Future<void> logOut() async {
    await _firebaseAuth.signOut();
    await _supabaseClient.auth.signOut();
    await GoogleSignIn().signOut();
  }

  //----------------------------------------------------------------------------
  // ## Auth Status Checking
  //----------------------------------------------------------------------------

  /// Checks if user is authenticated with both Firebase and Supabase.
  bool get isAuthenticated {
    return _firebaseAuth.currentUser != null &&
        _supabaseClient.auth.currentUser != null;
  }

  /// Gets current Firebase user.
  firebase_auth.User? get currentFirebaseUser => _firebaseAuth.currentUser;

  /// Gets current Supabase user.
  supabase.User? get currentSupabaseUser => _supabaseClient.auth.currentUser;

  //----------------------------------------------------------------------------
  // ## Data Fetching & Updating
  //----------------------------------------------------------------------------

  /// Gets the current user's data from the Supabase 'users' table.
  Future<Map<String, dynamic>?> getSupabaseUserData() async {
    try {
      final firebaseUser = _firebaseAuth.currentUser;
      if (firebaseUser == null) return null;

      final response = await _supabaseClient
          .from('users')
          .select()
          .eq('firebase_uid', firebaseUser.uid)
          .maybeSingle();

      return response;
    } catch (e) {
      debugPrint('Error getting Supabase user data: $e');
      return null;
    }
  }

  /// Updates the current user's data in the Supabase 'users' table.
  Future<bool> updateSupabaseUserData(Map<String, dynamic> data) async {
    try {
      final firebaseUser = _firebaseAuth.currentUser;
      if (firebaseUser == null) return false;

      await _supabaseClient
          .from('users')
          .update(data)
          .eq('firebase_uid', firebaseUser.uid);

      return true;
    } catch (e) {
      debugPrint('Error updating Supabase user data: $e');
      return false;
    }
  }

  //----------------------------------------------------------------------------
  // ## Error Handling Utility
  //----------------------------------------------------------------------------

  /// A centralized method to handle common authentication errors.
  void _handleAuthError(dynamic e) {
    if (e is PlatformException && e.code == GoogleSignIn.kNetworkError) {
      GlobalSnackBarGet().showGetError(
          "Network Error", "Please check your internet connection.");
    } else if (e is firebase_auth.FirebaseAuthException) {
      GlobalSnackBarGet().showGetError(
          "Authentication Error", e.message ?? "An error occurred.");
    } else {
      GlobalSnackBarGet().showGetError(
          "Error", "An unexpected error occurred. Please try again.");
    }
  }
}
