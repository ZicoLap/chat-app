import 'package:chat_app/widgets/user_image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'dart:io';

final _firebase = FirebaseAuth.instance;

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  var _isLogin = true;
  final _form = GlobalKey<FormState>();
  var _enteredEmail = "";
  var _enteredPassword = "";
  var _enteredName = "";
  File? _selectedImage;
  var _isAuthentication = false;

  void _submit() async {
    final isValid = _form.currentState!.validate();
    if (!isValid || (!_isLogin && _selectedImage == null)) {
      return;
    }

    _form.currentState!.save();

    try {
      setState(() {
        _isAuthentication = true;
      });

      if (_isLogin) {
        await _firebase.signInWithEmailAndPassword(
          email: _enteredEmail,
          password: _enteredPassword,
        );
      } else {
        final userCredentials = await _firebase.createUserWithEmailAndPassword(
          email: _enteredEmail,
          password: _enteredPassword,
        );

        final storageRef = FirebaseStorage.instance
            .ref()
            .child("user_images")
            .child("${userCredentials.user!.uid}.jpg");

        try {
          await storageRef.putFile(_selectedImage!);
        } catch (error) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Image upload failed: $error')),
          );
          setState(() {
            _isAuthentication = false;
          });
          return;
        }

        final imageUrl = await storageRef.getDownloadURL();

        await FirebaseFirestore.instance
            .collection("users")
            .doc(userCredentials.user!.uid)
            .set({
          "username": _enteredName,
          "email": _enteredEmail,
          "image_url": imageUrl,
        });
      }
    } on FirebaseAuthException catch (error) {
      String message = "Authentication failed.";
      if (error.code == "email-already-in-use") {
        message = "This email address is already in use.";
      } else if (error.code == "wrong-password") {
        message = "Wrong password provided.";
      } else if (error.code == "user-not-found") {
        message = "No user found for this email.";
      }

      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
      setState(() {
        _isAuthentication = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.primary,
      body: Center(
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                margin: const EdgeInsets.only(top: 30, bottom: 20),
                width: 200,
                child: Image.asset("assets/images/chat.png"),
              ),
              Card(
                margin: const EdgeInsets.all(20),
                child: SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Form(
                      key: _form,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (!_isLogin)
                            UserImagePicker(onPickImage: (pickedImage) {
                              _selectedImage = pickedImage;
                            }),
                          TextFormField(
                            decoration: const InputDecoration(labelText: "Email Address"),
                            keyboardType: TextInputType.emailAddress,
                            autocorrect: false,
                            textCapitalization: TextCapitalization.none,
                            validator: (value) {
                              if (value == null || value.trim().isEmpty || !value.contains("@")) {
                                return "Please enter a valid email address.";
                              }
                              return null;
                            },
                            onSaved: (value) {
                              _enteredEmail = value!;
                            },
                          ),
                          if (!_isLogin)
                            TextFormField(
                              decoration: const InputDecoration(labelText: "Username"),
                              enableSuggestions: false,
                              validator: (value) {
                                if (value == null || value.trim().isEmpty || value.trim().length < 4) {
                                  return "Please enter at least 4 characters.";
                                }
                                return null;
                              },
                              onSaved: (value) {
                                _enteredName = value!;
                              },
                            ),
                          TextFormField(
                            decoration: const InputDecoration(labelText: "Password"),
                            obscureText: true,
                            validator: (value) {
                              if (value == null || value.trim().length < 6) {
                                return "Password must be at least 6 characters long.";
                              }
                              return null;
                            },
                            onSaved: (value) {
                              _enteredPassword = value!;
                            },
                          ),
                          const SizedBox(height: 12),
                          if (_isAuthentication)
                            const Padding(
                              padding: EdgeInsets.symmetric(vertical: 16),
                              child: CircularProgressIndicator(),
                            ),
                          if (!_isAuthentication)
                            ElevatedButton(
                              onPressed: _submit,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                              ),
                              child: Text(_isLogin ? "Login" : "Signup"),
                            ),
                          if (!_isAuthentication)
                            TextButton(
                              onPressed: () {
                                setState(() {
                                  _isLogin = !_isLogin;
                                  _selectedImage = null; // Reset selected image
                                });
                              },
                              child: Text(
                                _isLogin ? "Create an account" : "I already have an account.",
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
