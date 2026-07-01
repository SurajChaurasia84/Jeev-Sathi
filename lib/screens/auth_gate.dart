import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../main.dart';
import 'onboarding_screen.dart';
import 'edit_profile_screen.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        // If Firebase is checking authentication state, show a clean loading indicator
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            backgroundColor: Color(0xFFF8FAFC),
            body: Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF10B981)),
              ),
            ),
          );
        }

        // If the user is authenticated, check their profile details in Firestore
        if (snapshot.hasData && snapshot.data != null) {
          final user = snapshot.data!;
          return StreamBuilder<DocumentSnapshot>(
            stream: FirebaseFirestore.instance
                .collection('users')
                .doc(user.uid)
                .snapshots(),
            builder: (context, userSnap) {
              if (userSnap.connectionState == ConnectionState.waiting) {
                return const Scaffold(
                  backgroundColor: Color(0xFFF8FAFC),
                  body: Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF10B981)),
                    ),
                  ),
                );
              }

              if (userSnap.hasData && userSnap.data!.exists) {
                final userData = userSnap.data!.data() as Map<String, dynamic>?;
                final name = userData?['displayName'] ?? userData?['name'];
                final phone = userData?['phoneNumber'] ?? userData?['phone'];
                final address = userData?['address'] ?? userData?['village'];

                if (name == null || name.toString().trim().isEmpty ||
                    phone == null || phone.toString().trim().isEmpty ||
                    address == null || address.toString().trim().isEmpty) {
                  // Profile is incomplete! Force completion.
                  return const EditProfileScreen(forceCompleteProfile: true);
                }

                return const MainNavigationScreen();
              } else {
                // User document doesn't exist yet, force profile creation.
                return const EditProfileScreen(forceCompleteProfile: true);
              }
            },
          );
        }

        // Otherwise, show the Onboarding screen
        return const OnboardingScreen();
      },
    );
  }
}

