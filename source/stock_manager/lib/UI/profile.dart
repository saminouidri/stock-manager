import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:stock_manager/UI/naviguation.dart';
import 'package:stock_manager/model/firestore_user.dart';
import 'package:stock_manager/repository/user_repository.dart';

/// The `Profile` class is a Dart code that represents a user profile screen with fields for email, old
/// password, and new password, and an update button to change the password.
class Profile extends StatelessWidget {
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController oldPasswordController = TextEditingController();
  final TextEditingController emailController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    late Future<FirestoreUser?> user;
    user = UserRepository.getInstance().getConnected();

    FirebaseAuth.instance.authStateChanges().listen((user) {
      if (user == null) {
        Navigator.pushReplacementNamed(context, '/home');
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircleAvatar(
                      radius: 72.0,
                      backgroundColor: Colors.grey[200],
                      child: const Icon(Icons.person,
                          color: Colors.grey, size: 72.0),
                    ),
                    const SizedBox(width: 24.0),
                    FutureBuilder(
                      future: user,
                      builder: (context, snapshot) => Text(
                          snapshot.hasData ? snapshot.data!.name : "Log in",
                          style: const TextStyle(fontSize: 16.0)),
                    ),
                  ],
                ),
                const SizedBox(height: 40.0),
                const SizedBox(height: 10.0),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // TextFields
                    Expanded(
                      child: TextField(
                        controller: emailController,
                        decoration: const InputDecoration(
                          labelText: 'Email',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Column(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        const Text(
                          'Current email: ',
                          style: TextStyle(fontSize: 12.0),
                        ),
                        FutureBuilder(
                          future: user,
                          builder: (context, snapshot) => Text(
                              snapshot.hasData ? snapshot.data!.name : "Log in",
                              style: const TextStyle(fontSize: 16.0)),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 10.0),
                TextField(
                  controller: oldPasswordController,
                  decoration: const InputDecoration(
                    labelText: 'Old Password',
                    border: OutlineInputBorder(),
                  ),
                  obscureText: true,
                ),
                const SizedBox(height: 10.0),
                TextField(
                  controller: passwordController,
                  decoration: const InputDecoration(
                    labelText: 'New Password',
                    border: OutlineInputBorder(),
                  ),
                  obscureText: true,
                ),
                const SizedBox(height: 20.0),
                ElevatedButton(
                  onPressed: () async {
                    final String oldPassword = oldPasswordController.text;
                    final String newPassword = passwordController.text;
                    final FirebaseAuth firebaseAuth = FirebaseAuth.instance;
                    User? currentUser = firebaseAuth.currentUser;

                    if (currentUser != null) {
                      AuthCredential credential = EmailAuthProvider.credential(
                          email: emailController.text, password: oldPassword);
                      //re-authentication is necessary to have a fresh token for a password change
                      currentUser
                          .reauthenticateWithCredential(credential)
                          .then((value) {
                        currentUser.updatePassword(newPassword).then((_) {
                          ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content:
                                      Text('Password updated successfully!')));
                        }).catchError((err) {
                          ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content: Text('Failed to update password.')));
                        });
                      }).catchError((err) {
                        ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content: Text('Re-authentication failed.')));
                      });
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('User not found.')));
                    }
                  },
                  child: const Text('Update'),
                )
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: CustomNavigationBar(selectedIndex: 3),
    );
  }
}
