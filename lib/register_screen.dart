import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'donor_home_screen.dart';
import 'login_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  // ------------------------------------------------------------
  // COLORS
  // ------------------------------------------------------------

  final Color blue = const Color(0xFF1565C0);
  final Color red = const Color(0xFFE51C2A);
  final Color darkBlue = const Color(0xFF0D47A1);

  // ------------------------------------------------------------
  // FORM
  // ------------------------------------------------------------

  final _formKey = GlobalKey<FormState>();

  // ------------------------------------------------------------
  // CONTROLLERS
  // ------------------------------------------------------------

  final nameController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmPasswordController = TextEditingController();
  final phoneController = TextEditingController();
  final cityController = TextEditingController();

  // ------------------------------------------------------------
  // VARIABLES
  // ------------------------------------------------------------

  String? selectedBloodGroup;

  bool obscurePassword = true;
  bool obscureConfirmPassword = true;
  bool isLoading = false;

  final List<String> bloodGroups = [
    'A+',
    'A-',
    'B+',
    'B-',
    'AB+',
    'AB-',
    'O+',
    'O-',
  ];

  // ------------------------------------------------------------
  // REGISTER DONOR
  // ------------------------------------------------------------

  Future<void> _registerDonor() async {
    // Check form validation
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // Check password match
    if (passwordController.text != confirmPasswordController.text) {
      _showMessage('Passwords do not match.');
      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      // --------------------------------------------------------
      // 1. CREATE FIREBASE AUTH ACCOUNT
      // --------------------------------------------------------

      final UserCredential credential =
          await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
      );

      final User? user = credential.user;

      if (user == null) {
        _showMessage('Registration failed. Please try again.');
        return;
      }

      // --------------------------------------------------------
      // 2. CREATE USER DOCUMENT IN FIRESTORE
      // --------------------------------------------------------

      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .set({
        'name': nameController.text.trim(),
        'email': emailController.text.trim(),
        'phone': phoneController.text.trim(),
        'city': cityController.text.trim(),
        'bloodGroup': selectedBloodGroup,
        'lastDonationAt': null,
        'role': 'donor',
        'createdAt': FieldValue.serverTimestamp(),
      });

      // --------------------------------------------------------
      // 3. SHOW SUCCESS MESSAGE
      // --------------------------------------------------------

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Registration successful!'),
          behavior: SnackBarBehavior.floating,
        ),
      );

      // --------------------------------------------------------
      // 4. MOVE TO DONOR HOME
      // --------------------------------------------------------

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => const DonorHomeScreen(),
        ),
      );
    } on FirebaseAuthException catch (e) {
      String message;

      switch (e.code) {
        case 'email-already-in-use':
          message = 'This email is already registered.';
          break;

        case 'invalid-email':
          message = 'Please enter a valid email address.';
          break;

        case 'weak-password':
          message = 'Password is too weak.';
          break;

        case 'network-request-failed':
          message = 'Please check your internet connection.';
          break;

        default:
          message = e.message ?? 'Registration failed.';
      }

      _showMessage(message);
    } catch (e) {
      _showMessage(
        'Something went wrong. Please try again.',
      );
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  // ------------------------------------------------------------
  // SHOW MESSAGE
  // ------------------------------------------------------------

  void _showMessage(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // ------------------------------------------------------------
  // DISPOSE
  // ------------------------------------------------------------

  @override
  void dispose() {
    nameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    phoneController.dispose();
    cityController.dispose();

    super.dispose();
  }

  // ------------------------------------------------------------
  // UI
  // ------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,

      // ----------------------------------------------------------
      // APP BAR
      // ----------------------------------------------------------

      appBar: AppBar(
        title: const Text(
          'Donor Registration',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: blue,
        foregroundColor: Colors.white,
      ),

      // ----------------------------------------------------------
      // BODY
      // ----------------------------------------------------------

      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(25),

          child: Form(
            key: _formKey,

            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ------------------------------------------------
                // LOGO
                // ------------------------------------------------

                Center(
                  child: Image.asset(
                    'assets/images/alkhidmat_logo.png',
                    height: 80,
                    errorBuilder: (
                      context,
                      error,
                      stackTrace,
                    ) {
                      return Icon(
                        Icons.bloodtype,
                        size: 80,
                        color: red,
                      );
                    },
                  ),
                ),

                const SizedBox(height: 15),

                // ------------------------------------------------
                // TITLE
                // ------------------------------------------------

                Center(
                  child: Text(
                    'Create Donor Account',
                    style: TextStyle(
                      color: darkBlue,
                      fontSize: 25,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),

                const SizedBox(height: 8),

                const Center(
                  child: Text(
                    'Register to book blood camp slots',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.black54,
                      fontSize: 14,
                    ),
                  ),
                ),

                const SizedBox(height: 30),

                // ------------------------------------------------
                // FULL NAME
                // ------------------------------------------------

                const Text(
                  'Full Name',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 7),

                TextFormField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    hintText: 'Enter your full name',
                    prefixIcon: Icon(Icons.person),
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null ||
                        value.trim().isEmpty) {
                      return 'Please enter your name';
                    }

                    return null;
                  },
                ),

                const SizedBox(height: 18),

                // ------------------------------------------------
                // EMAIL
                // ------------------------------------------------

                const Text(
                  'Email',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 7),

                TextFormField(
                  controller: emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    hintText: 'Enter your email',
                    prefixIcon: Icon(Icons.email),
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null ||
                        value.trim().isEmpty) {
                      return 'Please enter your email';
                    }

                    if (!value.contains('@')) {
                      return 'Please enter a valid email';
                    }

                    return null;
                  },
                ),

                const SizedBox(height: 18),

                // ------------------------------------------------
                // PASSWORD
                // ------------------------------------------------

                const Text(
                  'Password',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 7),

                TextFormField(
                  controller: passwordController,
                  obscureText: obscurePassword,
                  decoration: InputDecoration(
                    hintText: 'Create a password',
                    prefixIcon: const Icon(Icons.lock),
                    border: const OutlineInputBorder(),
                    suffixIcon: IconButton(
                      icon: Icon(
                        obscurePassword
                            ? Icons.visibility
                            : Icons.visibility_off,
                      ),
                      onPressed: () {
                        setState(() {
                          obscurePassword =
                              !obscurePassword;
                        });
                      },
                    ),
                  ),
                  validator: (value) {
                    if (value == null ||
                        value.isEmpty) {
                      return 'Please enter a password';
                    }

                    if (value.length < 6) {
                      return 'Password must be at least 6 characters';
                    }

                    return null;
                  },
                ),

                const SizedBox(height: 18),

                // ------------------------------------------------
                // CONFIRM PASSWORD
                // ------------------------------------------------

                const Text(
                  'Confirm Password',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 7),

                TextFormField(
                  controller: confirmPasswordController,
                  obscureText: obscureConfirmPassword,
                  decoration: InputDecoration(
                    hintText: 'Re-enter your password',
                    prefixIcon:
                        const Icon(Icons.lock_outline),
                    border: const OutlineInputBorder(),
                    suffixIcon: IconButton(
                      icon: Icon(
                        obscureConfirmPassword
                            ? Icons.visibility
                            : Icons.visibility_off,
                      ),
                      onPressed: () {
                        setState(() {
                          obscureConfirmPassword =
                              !obscureConfirmPassword;
                        });
                      },
                    ),
                  ),
                  validator: (value) {
                    if (value == null ||
                        value.isEmpty) {
                      return 'Please confirm your password';
                    }

                    return null;
                  },
                ),

                const SizedBox(height: 18),

                // ------------------------------------------------
                // PHONE
                // ------------------------------------------------

                const Text(
                  'Phone Number',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 7),

                TextFormField(
                  controller: phoneController,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                    hintText: '03XXXXXXXXX',
                    prefixIcon: Icon(Icons.phone),
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
  if (value == null ||
      value.trim().isEmpty) {
    return 'Please enter your phone number';
  }

  if (value.trim().length != 11) {
    return 'Phone number must be exactly 11 digits';
  }

  if (!RegExp(r'^[0-9]+$').hasMatch(value.trim())) {
    return 'Phone number must contain only digits';
  }

  return null;
},
                ),

                const SizedBox(height: 18),

                // ------------------------------------------------
                // CITY
                // ------------------------------------------------

                const Text(
                  'City',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 7),

                TextFormField(
                  controller: cityController,
                  decoration: const InputDecoration(
                    hintText: 'Enter your city',
                    prefixIcon:
                        Icon(Icons.location_city),
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null ||
                        value.trim().isEmpty) {
                      return 'Please enter your city';
                    }

                    return null;
                  },
                ),

                const SizedBox(height: 18),

                // ------------------------------------------------
                // BLOOD GROUP
                // ------------------------------------------------

                const Text(
                  'Blood Group (Optional)',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 7),

                DropdownButtonFormField<String>(
                  value: selectedBloodGroup,

                  decoration: const InputDecoration(
                    hintText: 'Select blood group',
                    prefixIcon:
                        Icon(Icons.bloodtype),
                    border: OutlineInputBorder(),
                  ),

                  items: bloodGroups.map((group) {
                    return DropdownMenuItem(
                      value: group,
                      child: Text(group),
                    );
                  }).toList(),

                  onChanged: (value) {
                    setState(() {
                      selectedBloodGroup = value;
                    });
                  },
                ),

                const SizedBox(height: 30),

                // ------------------------------------------------
                // CREATE ACCOUNT BUTTON
                // ------------------------------------------------

                SizedBox(
                  width: double.infinity,
                  height: 52,

                  child: ElevatedButton(
                    onPressed:
                        isLoading ? null : _registerDonor,

                    style: ElevatedButton.styleFrom(
                      backgroundColor: red,
                      foregroundColor: Colors.white,

                      shape: RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(12),
                      ),
                    ),

                    child: isLoading
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child:
                                CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : const Text(
                            'Create Donor Account',
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ),

                const SizedBox(height: 20),

                // ------------------------------------------------
                // LOGIN LINK
                // ------------------------------------------------

                Row(
                  mainAxisAlignment:
                      MainAxisAlignment.center,

                  children: [
                    const Text(
                      'Already have an account? ',
                      style: TextStyle(
                        color: Colors.black54,
                      ),
                    ),

                    TextButton(
                      onPressed: () {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                const LoginScreen(),
                          ),
                        );
                      },

                      child: Text(
                        'Login',
                        style: TextStyle(
                          color: blue,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}