import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'register_screen.dart';
import 'donor_home_screen.dart';
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final Color blue = const Color(0xFF1565C0);
  final Color darkBlue = const Color(0xFF0D47A1);
  final Color red = const Color(0xFFE51C2A);

  bool isLoading = false;

  // ------------------------------------------------------------
  // LOGIN
  // ------------------------------------------------------------

  Future<void> _showLoginDialog() async {
    final emailController = TextEditingController();
    final passwordController = TextEditingController();

    bool obscurePassword = true;

    await showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text(
                'Login',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(
                      labelText: 'Email',
                      prefixIcon: Icon(Icons.email),
                      border: OutlineInputBorder(),
                    ),
                  ),

                  const SizedBox(height: 15),

                  TextField(
                    controller: passwordController,
                    obscureText: obscurePassword,
                    decoration: InputDecoration(
                      labelText: 'Password',
                      prefixIcon: const Icon(Icons.lock),
                      border: const OutlineInputBorder(),
                      suffixIcon: IconButton(
                        icon: Icon(
                          obscurePassword
                              ? Icons.visibility
                              : Icons.visibility_off,
                        ),
                        onPressed: () {
                          setDialogState(() {
                            obscurePassword = !obscurePassword;
                          });
                        },
                      ),
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(dialogContext);
                  },
                  child: const Text('Cancel'),
                ),

                ElevatedButton(
                  onPressed: isLoading
                      ? null
                      : () async {
                          await _login(
                            emailController.text.trim(),
                            passwordController.text.trim(),
                            dialogContext,
                          );
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: blue,
                    foregroundColor: Colors.white,
                  ),
                  child: isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text('Login'),
                ),
              ],
            );
          },
        );
      },
    );

    emailController.dispose();
    passwordController.dispose();
  }

  Future<void> _login(
    String email,
    String password,
    BuildContext dialogContext,
  ) async {
    if (email.isEmpty || password.isEmpty) {
      _showMessage('Please enter email and password.');
      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      // 1. Login using Firebase Authentication
      final UserCredential credential = await FirebaseAuth.instance
          .signInWithEmailAndPassword(email: email, password: password);

      // 2. Get the logged-in user's Firebase UID
      final User? user = credential.user;

      if (user == null) {
        _showMessage('Login failed. Please try again.');
        return;
      }

      // 3. Find this user's profile in Firestore
      final DocumentSnapshot userDocument = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      // 4. Check if the Firestore user document exists
      if (!userDocument.exists) {
        _showMessage('User profile not found. Please contact administrator.');

        await FirebaseAuth.instance.signOut();
        return;
      }

      // 5. Get the role from Firestore
      final data = userDocument.data() as Map<String, dynamic>;

      final String? role = data['role'] as String?;

      if (role == null || role.isEmpty) {
        _showMessage('User role is missing. Please contact administrator.');

        await FirebaseAuth.instance.signOut();
        return;
      }

      // Close login dialog
      if (mounted) {
        Navigator.pop(dialogContext);
      }

      // 6. Navigate according to the Firestore role
      if (!mounted) return;

      if (role == 'donor') {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const DonorHomeScreen()),
        );
      } else if (role == 'staff') {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const StaffDashboard()),
        );
      } else if (role == 'organizer') {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const OrganizerDashboard()),
        );
      } else {
        _showMessage('Invalid user role. Please contact administrator.');

        await FirebaseAuth.instance.signOut();
      }
    } on FirebaseAuthException catch (e) {
      String message;

      switch (e.code) {
        case 'invalid-credential':
          message = 'Incorrect email or password.';
          break;

        case 'invalid-email':
          message = 'Please enter a valid email address.';
          break;

        case 'user-disabled':
          message = 'This account has been disabled.';
          break;

        case 'too-many-requests':
          message = 'Too many attempts. Please try again later.';
          break;

        case 'network-request-failed':
          message = 'Please check your internet connection.';
          break;

        default:
          message = e.message ?? 'Login failed. Please try again.';
      }

      _showMessage(message);
    } catch (e) {
      _showMessage('Something went wrong. Please try again.');
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  // ------------------------------------------------------------
  // REGISTER
  // ------------------------------------------------------------

  void _register() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const RegisterScreen()),
    );
  }

  // ------------------------------------------------------------
  // DEMO ACCOUNT MESSAGE
  // ------------------------------------------------------------

  void _demoAccountMessage() {
    _showMessage('Please login or register first.');
  }

  // ------------------------------------------------------------
  // MESSAGE
  // ------------------------------------------------------------

  void _showMessage(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Stack(
          children: [
            SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(25, 30, 25, 180),
              child: Column(
                children: [
                  // ------------------------------------------------
                  // LOGO
                  // ------------------------------------------------

                  Image.asset(
                    'assets/images/alkhidmat_logo.png',
                    height: 100,
                    errorBuilder: (context, error, stackTrace) {
                      return Icon(Icons.bloodtype, size: 100, color: red);
                    },
                  ),

                  const SizedBox(height: 15),

                  // ------------------------------------------------
                  // APP NAME
                  // ------------------------------------------------
                  RichText(
                    text: TextSpan(
                      children: [
                        TextSpan(
                          text: 'Alkhidmat ',
                          style: TextStyle(
                            color: blue,
                            fontSize: 30,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        TextSpan(
                          text: 'Blood Camp',
                          style: TextStyle(
                            color: red,
                            fontSize: 30,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 15),

                  // ------------------------------------------------
                  // DESCRIPTION
                  // ------------------------------------------------
                  const Text(
                    'Book a blood camp slot, check in donors, and\n'
                    'keep a safe record of blood group and last donation.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.black54,
                      fontSize: 15,
                      height: 1.5,
                    ),
                  ),

                  const SizedBox(height: 30),

                  // ------------------------------------------------
                  // LOGIN BUTTON
                  // ------------------------------------------------
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: _showLoginDialog,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: blue,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Login',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  // ------------------------------------------------
                  // REGISTER BUTTON
                  // ------------------------------------------------
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: OutlinedButton(
                      onPressed: _register,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: blue,
                        side: BorderSide(color: blue, width: 1.5),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Register',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 30),

                  // ------------------------------------------------
                  // DEMO ACCOUNTS
                  // ------------------------------------------------
                  Text(
                    'Demo Accounts',
                    style: TextStyle(
                      color: darkBlue,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 15),

                  // DONOR
                  RoleCard(
                    icon: Icons.person,
                    title: 'Donor',
                    email: 'donor@alkhidmat.org',
                    color: red,
                    onTap: _demoAccountMessage,
                  ),

                  const SizedBox(height: 12),

                  // STAFF
                  RoleCard(
                    icon: Icons.medical_services,
                    title: 'Staff',
                    email: 'staff@alkhidmat.org',
                    color: blue,
                    onTap: _demoAccountMessage,
                  ),

                  const SizedBox(height: 12),

                  // ORGANIZER
                  RoleCard(
                    icon: Icons.admin_panel_settings,
                    title: 'Organizer',
                    email: 'organizer@alkhidmat.org',
                    color: darkBlue,
                    onTap: _demoAccountMessage,
                  ),
                  const SizedBox(height: 20),

const Text(
  'Powered by Alkhidmat & Bano Qabil',
  textAlign: TextAlign.center,
  style: TextStyle(
    color: Colors.black54,
    fontSize: 12,
    fontWeight: FontWeight.bold,
  ),
),
                ],
              ),
            ),

            // ------------------------------------------------------
            // FOOTER
            // ------------------------------------------------------
               Positioned(
  bottom: 0,
  left: 0,
  right: 0,
  child: SizedBox(
    height: 100,
    child: CustomPaint(
      painter: FooterPainter(
        red: red,
        blue: blue,
      ),
    ),
  ),
),               
             
          ],
        ),
      ),
    );
  }
}

// ================================================================
// ROLE CARD
// ================================================================

class RoleCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String email;
  final Color color;
  final VoidCallback onTap;

  const RoleCard({
    super.key,
    required this.icon,
    required this.title,
    required this.email,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(15),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: color.withOpacity(0.25)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 25,
              backgroundColor: color.withOpacity(0.1),
              child: Icon(icon, color: color, size: 28),
            ),

            const SizedBox(width: 15),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: color,
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    email,
                    style: const TextStyle(color: Colors.black54, fontSize: 13),
                  ),
                ],
              ),
            ),

            Icon(Icons.arrow_forward_ios, size: 16, color: color),
          ],
        ),
      ),
    );
  }
}

// ================================================================
// FOOTER PAINTER
// ================================================================

class FooterPainter extends CustomPainter {
  final Color red;
  final Color blue;

  FooterPainter({required this.red, required this.blue});

  @override
  void paint(Canvas canvas, Size size) {
    final redPaint = Paint()
      ..color = red
      ..style = PaintingStyle.fill;

    final bluePaint = Paint()
      ..color = blue
      ..style = PaintingStyle.fill;

    final redPath = Path();

    redPath.moveTo(0, size.height * 0.45);
    redPath.quadraticBezierTo(
      size.width * 0.25,
      size.height * 0.15,
      size.width * 0.5,
      size.height * 0.45,
    );
    redPath.quadraticBezierTo(
      size.width * 0.75,
      size.height * 0.75,
      size.width,
      size.height * 0.45,
    );

    redPath.lineTo(size.width, size.height);
    redPath.lineTo(0, size.height);
    redPath.close();

    canvas.drawPath(redPath, redPaint);

    final bluePath = Path();

    bluePath.moveTo(0, size.height * 0.65);
    bluePath.quadraticBezierTo(
      size.width * 0.25,
      size.height * 0.35,
      size.width * 0.5,
      size.height * 0.65,
    );
    bluePath.quadraticBezierTo(
      size.width * 0.75,
      size.height * 0.95,
      size.width,
      size.height * 0.65,
    );

    bluePath.lineTo(size.width, size.height);
    bluePath.lineTo(0, size.height);
    bluePath.close();

    canvas.drawPath(bluePath, bluePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return false;
  }
}

// ================================================================
// TEMPORARY DASHBOARDS
// Replace these later with the actual screens.
// ================================================================

class DonorDashboard extends StatelessWidget {
  const DonorDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return const SimpleDashboard(
      title: 'Donor Dashboard',
      message: 'Welcome, Donor!',
    );
  }
}

class StaffDashboard extends StatelessWidget {
  const StaffDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return const SimpleDashboard(
      title: 'Staff Dashboard',
      message: 'Welcome, Staff!',
    );
  }
}

class OrganizerDashboard extends StatelessWidget {
  const OrganizerDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return const SimpleDashboard(
      title: 'Organizer Dashboard',
      message: 'Welcome, Organizer!',
    );
  }
}

class SimpleDashboard extends StatelessWidget {
  final String title;
  final String message;

  const SimpleDashboard({
    super.key,
    required this.title,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Center(
        child: Text(
          message,
          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}
