import 'package:flutter/material.dart';
import 'staff_dashboard.dart';

class StaffSignInScreen extends StatefulWidget {
  const StaffSignInScreen({super.key});

  @override
  State<StaffSignInScreen> createState() => _StaffSignInScreenState();
}

class _StaffSignInScreenState extends State<StaffSignInScreen> {
  final TextEditingController emailController =
      TextEditingController(text: 'staff@alkhidmat.org');

  final TextEditingController passwordController =
      TextEditingController(text: '123456');

  bool obscurePassword = true;

  // =========================
  // COLORS
  // =========================

  static const Color blue = Color(0xFF0867B2);
  static const Color darkBlue = Color(0xFF064D8C);
  static const Color red = Color(0xFFE91E2B);

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  // =========================
  // LOGIN
  // =========================

  void login() {
    final email = emailController.text.trim();
    final password = passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter email and password'),
        ),
      );
      return;
    }

    // Temporary demo login.
    // Firebase Authentication will be connected later.

    if (email == 'staff@alkhidmat.org' && password == '123456') {
      Navigator.pushReplacement(
  context,
  MaterialPageRoute(
    builder: (context) => const StaffDashboardScreen(),
  ),
);

      // Later we will navigate to:
      // Staff Roster Screen
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Invalid email or password'),
          backgroundColor: red,
        ),
      );
    }
  }

  // =========================
  // SELECT DEMO ACCOUNT
  // =========================

  void selectDemoAccount(String email) {
    setState(() {
      emailController.text = email;
      passwordController.text = '123456';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [

              // ==================================
              // TOP BLUE SECTION
              // ==================================

              Container(
                height: 105,
                width: double.infinity,
                decoration: const BoxDecoration(
                  color: blue,
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(45),
                    bottomRight: Radius.circular(45),
                  ),
                ),
              ),

              // ==================================
              // LOGO
              // ==================================

              Transform.translate(
                offset: const Offset(0, -58),
                child: Column(
                  children: [

                    const BloodDropLogo(),

                    const SizedBox(height: 5),

                    const Text(
                      'Alkhidmat',
                      style: TextStyle(
                        color: blue,
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const Text(
                      'Blood Camp',
                      style: TextStyle(
                        color: darkBlue,
                        fontSize: 23,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 4),

                    const Text(
                      'Donate Blood • Save Lives',
                      style: TextStyle(
                        color: red,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),

                    const SizedBox(height: 20),

                    // ==================================
                    // TITLE
                    // ==================================

                    const Text(
                      'Camp Staff Login',
                      style: TextStyle(
                        fontSize: 21,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF222222),
                      ),
                    ),

                    const SizedBox(height: 5),

                    const Text(
                      'Sign in to access your camp dashboard',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey,
                      ),
                    ),

                    const SizedBox(height: 20),

                    // ==================================
                    // LOGIN FORM
                    // ==================================

                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 22),
                      child: Column(
                        children: [

                          // Email
                          const Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              'Phone Number / Email',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),

                          const SizedBox(height: 7),

                          TextField(
                            controller: emailController,
                            keyboardType:
                                TextInputType.emailAddress,
                            decoration: InputDecoration(
                              hintText: 'Enter email or phone number',
                              hintStyle: const TextStyle(
                                fontSize: 13,
                                color: Colors.grey,
                              ),
                              prefixIcon: const Icon(
                                Icons.person_outline,
                                color: blue,
                              ),
                              border: OutlineInputBorder(
                                borderRadius:
                                    BorderRadius.circular(9),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius:
                                    BorderRadius.circular(9),
                                borderSide: const BorderSide(
                                  color: Color(0xFFD5DCE2),
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius:
                                    BorderRadius.circular(9),
                                borderSide: const BorderSide(
                                  color: blue,
                                  width: 1.5,
                                ),
                              ),
                            ),
                          ),

                          const SizedBox(height: 14),

                          // Password
                          const Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              'Password',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),

                          const SizedBox(height: 7),

                          TextField(
                            controller: passwordController,
                            obscureText: obscurePassword,
                            decoration: InputDecoration(
                              hintText: 'Enter password',
                              hintStyle: const TextStyle(
                                fontSize: 13,
                                color: Colors.grey,
                              ),
                              prefixIcon: const Icon(
                                Icons.lock_outline,
                                color: blue,
                              ),
                              suffixIcon: IconButton(
                                onPressed: () {
                                  setState(() {
                                    obscurePassword =
                                        !obscurePassword;
                                  });
                                },
                                icon: Icon(
                                  obscurePassword
                                      ? Icons.visibility_outlined
                                      : Icons.visibility_off_outlined,
                                  color: Colors.grey,
                                ),
                              ),
                              border: OutlineInputBorder(
                                borderRadius:
                                    BorderRadius.circular(9),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius:
                                    BorderRadius.circular(9),
                                borderSide: const BorderSide(
                                  color: Color(0xFFD5DCE2),
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius:
                                    BorderRadius.circular(9),
                                borderSide: const BorderSide(
                                  color: blue,
                                  width: 1.5,
                                ),
                              ),
                            ),
                          ),

                          const SizedBox(height: 18),

                          // ==================================
                          // LOGIN BUTTON
                          // ==================================

                          SizedBox(
                            width: double.infinity,
                            height: 47,
                            child: ElevatedButton(
                              onPressed: login,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: red,
                                foregroundColor: Colors.white,
                                elevation: 2,
                                shape: RoundedRectangleBorder(
                                  borderRadius:
                                      BorderRadius.circular(9),
                                ),
                              ),
                              child: const Text(
                                'Login',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),

                          const SizedBox(height: 14),

                          // OR
                          Row(
                            children: [
                              const Expanded(
                                child: Divider(),
                              ),

                              Padding(
                                padding:
                                    const EdgeInsets.symmetric(
                                  horizontal: 12,
                                ),
                                child: Text(
                                  'OR',
                                  style: TextStyle(
                                    color: Colors.grey.shade600,
                                    fontSize: 11,
                                  ),
                                ),
                              ),

                              const Expanded(
                                child: Divider(),
                              ),
                            ],
                          ),

                          const SizedBox(height: 14),

                          // ==================================
                          // DEMO ACCOUNTS
                          // ==================================

                          const Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              'Demo Accounts',
                              style: TextStyle(
                                color: darkBlue,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                          ),

                          const SizedBox(height: 9),

                          DemoAccountCard(
                            icon: Icons.person,
                            title: 'Donor',
                            email: 'donor@alkhidmat.org',
                            iconColor: blue,
                            onTap: () {
                              selectDemoAccount(
                                'donor@alkhidmat.org',
                              );
                            },
                          ),

                          const SizedBox(height: 8),

                          DemoAccountCard(
                            icon: Icons.medical_services_outlined,
                            title: 'Staff',
                            email: 'staff@alkhidmat.org',
                            iconColor: red,
                            selected: true,
                            onTap: () {
                              selectDemoAccount(
                                'staff@alkhidmat.org',
                              );
                            },
                          ),

                          const SizedBox(height: 8),

                          DemoAccountCard(
                            icon:
                                Icons.admin_panel_settings_outlined,
                            title: 'Organizer',
                            email: 'organizer@alkhidmat.org',
                            iconColor: blue,
                            onTap: () {
                              selectDemoAccount(
                                'organizer@alkhidmat.org',
                              );
                            },
                          ),

                          const SizedBox(height: 16),

                          // ==================================
                          // REGISTER
                          // ==================================

                          Row(
                            mainAxisAlignment:
                                MainAxisAlignment.center,
                            children: [
                              const Text(
                                "Don't have an account? ",
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey,
                                ),
                              ),

                              GestureDetector(
                                onTap: () {},
                                child: const Text(
                                  'Register',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: red,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 25),

                          // ==================================
                          // BOTTOM DECORATION
                          // ==================================

                          const BottomDecoration(),

                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}


// ============================================================
// BLOOD DROP LOGO
// ============================================================

class BloodDropLogo extends StatelessWidget {
  const BloodDropLogo({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 82,
      width: 70,
      child: Stack(
        alignment: Alignment.center,
        children: [

          CustomPaint(
            size: const Size(60, 78),
            painter: BloodDropPainter(),
          ),

          const Icon(
            Icons.favorite,
            color: Colors.white,
            size: 25,
          ),
        ],
      ),
    );
  }
}


// ============================================================
// BLOOD DROP PAINTER
// ============================================================

class BloodDropPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {

    final paint = Paint()
      ..color = const Color(0xFFE91E2B)
      ..style = PaintingStyle.fill;

    final path = Path();

    path.moveTo(
      size.width / 2,
      0,
    );

    path.cubicTo(
      size.width * 0.25,
      size.height * 0.35,
      0,
      size.height * 0.55,
      0,
      size.height * 0.72,
    );

    path.cubicTo(
      0,
      size.height * 0.90,
      size.width * 0.25,
      size.height,
      size.width / 2,
      size.height,
    );

    path.cubicTo(
      size.width * 0.75,
      size.height,
      size.width,
      size.height * 0.90,
      size.width,
      size.height * 0.72,
    );

    path.cubicTo(
      size.width,
      size.height * 0.55,
      size.width * 0.75,
      size.height * 0.35,
      size.width / 2,
      0,
    );

    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(
    covariant CustomPainter oldDelegate,
  ) {
    return false;
  }
}


// ============================================================
// DEMO ACCOUNT CARD
// ============================================================

class DemoAccountCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String email;
  final Color iconColor;
  final bool selected;
  final VoidCallback onTap;

  const DemoAccountCard({
    super.key,
    required this.icon,
    required this.title,
    required this.email,
    required this.iconColor,
    required this.onTap,
    this.selected = false,
  });

  @override
  Widget build(BuildContext context) {

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(9),

      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: 11,
          vertical: 9,
        ),

        decoration: BoxDecoration(
          color: selected
              ? const Color(0xFFFFF2F3)
              : const Color(0xFFF8FAFC),

          borderRadius: BorderRadius.circular(9),

          border: Border.all(
            color: selected
                ? const Color(0xFFE91E2B)
                : const Color(0xFFE0E5EA),
          ),
        ),

        child: Row(
          children: [

            Container(
              height: 36,
              width: 36,

              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.12),
                shape: BoxShape.circle,
              ),

              child: Icon(
                icon,
                color: iconColor,
                size: 20,
              ),
            ),

            const SizedBox(width: 10),

            Expanded(
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,

                children: [

                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 2),

                  Text(
                    email,
                    style: const TextStyle(
                      fontSize: 10,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            ),

            Icon(
              selected
                  ? Icons.check_circle
                  : Icons.arrow_forward_ios,
              size: selected ? 18 : 12,
              color: selected
                  ? const Color(0xFFE91E2B)
                  : Colors.grey,
            ),
          ],
        ),
      ),
    );
  }
}


// ============================================================
// BOTTOM BLUE + RED DECORATION
// ============================================================

class BottomDecoration extends StatelessWidget {
  const BottomDecoration({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 45,
      width: double.infinity,
      child: CustomPaint(
        painter: BottomDecorationPainter(),
      ),
    );
  }
}


class BottomDecorationPainter extends CustomPainter {

  @override
  void paint(Canvas canvas, Size size) {

    final bluePaint = Paint()
      ..color = const Color(0xFF0867B2);

    final redPaint = Paint()
      ..color = const Color(0xFFE91E2B);

    // Blue wave
    final bluePath = Path();

    bluePath.moveTo(
      0,
      size.height * 0.50,
    );

    bluePath.quadraticBezierTo(
      size.width * 0.25,
      0,
      size.width * 0.52,
      size.height * 0.55,
    );

    bluePath.quadraticBezierTo(
      size.width * 0.78,
      size.height,
      size.width,
      size.height * 0.35,
    );

    bluePath.lineTo(
      size.width,
      size.height,
    );

    bluePath.lineTo(
      0,
      size.height,
    );

    bluePath.close();

    canvas.drawPath(
      bluePath,
      bluePaint,
    );


    // Red wave
    final redPath = Path();

    redPath.moveTo(
      0,
      size.height * 0.72,
    );

    redPath.quadraticBezierTo(
      size.width * 0.30,
      size.height * 0.25,
      size.width * 0.60,
      size.height * 0.78,
    );

    redPath.quadraticBezierTo(
      size.width * 0.82,
      size.height,
      size.width,
      size.height * 0.62,
    );

    redPath.lineTo(
      size.width,
      size.height,
    );

    redPath.lineTo(
      0,
      size.height,
    );

    redPath.close();

    canvas.drawPath(
      redPath,
      redPaint,
    );
  }

  @override
  bool shouldRepaint(
    covariant CustomPainter oldDelegate,
  ) {
    return false;
  }
}