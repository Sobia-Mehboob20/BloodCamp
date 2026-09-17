import 'package:flutter/material.dart';

class HealthTipsScreen extends StatelessWidget {
  const HealthTipsScreen({super.key});

  static const Color blue = Color(0xFF1565C0);
  static const Color darkBlue = Color(0xFF0D47A1);
  static const Color red = Color(0xFFE51C2A);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      

 appBar: AppBar(
  backgroundColor: blue,
  foregroundColor: Colors.white,
  elevation: 0,

  // Back arrow
  leading: IconButton(
    icon: const Icon(
      Icons.arrow_back,
      color: Colors.white,
      size: 24,
    ),
    onPressed: () {
      Navigator.pop(context);
    },
  ),

  // Icon + Health Tips text
  title: Row(
    children: [
      Container(
        width: 30,
        height: 30,
        decoration: BoxDecoration(
          border: Border.all(
            color: Colors.white,
            width: 1.5,
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Icon(
          Icons.favorite_border,
          color: red,
          size: 20,
        ),
      ),

      const SizedBox(width: 10),

      const Text(
        'Health Tips',
        style: TextStyle(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
      ),
    ],
  ),

  // This removes the extra space around the title
  titleSpacing: 0,
),
    
      body: SafeArea(
        child: Column(
          children: [

            // ============================================================
            // MAIN CONTENT
            // ============================================================
            Expanded(
              child: Stack(
                children: [
                  // White content area
                  SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(
                      20,
                      18,
                      20,
                      180,
                    ),
                    child: Column(
                      children: [
                        // ==================================================
                        // EAT WELL
                        // ==================================================
                        _healthTip(
                          icon: Icons.favorite,
                          iconColor: red,
                          circleColor: const Color(0xFFFFE9ED),
                          title: 'Eat well',
                          description:
                              'Have iron-rich foods\n'
                              '(e.g. spinach, dates, eggs).',
                        ),

                        // ==================================================
                        // DRINK WATER
                        // ==================================================
                        _healthTip(
                          icon: Icons.water_drop,
                          iconColor: blue,
                          circleColor: const Color(0xFFEAF5FF),
                          title: 'Drink water',
                          description:
                              'Stay hydrated before\n'
                              'and after donation.',
                        ),

                        // ==================================================
                        // GET ENOUGH REST
                        // ==================================================
                        _healthTip(
                          icon: Icons.nightlight_round,
                          iconColor: blue,
                          circleColor: const Color(0xFFEAF5FF),
                          title: 'Get enough rest',
                          description:
                              'Sleep well the night\n'
                              'before your donation.',
                        ),

                        // ==================================================
                        // AVOID ALCOHOL
                        // ==================================================
                        _healthTip(
                          icon: Icons.local_bar,
                          iconColor: red,
                          circleColor: const Color(0xFFFFEEF0),
                          title: 'Avoid alcohol',
                          description:
                              'Don’t drink alcohol\n'
                              '24 hours before donation.',
                        ),

                        // ==================================================
                        // STAY HEALTHY
                        // ==================================================
                        _healthTip(
                          icon: Icons.favorite,
                          iconColor: const Color.fromARGB(221, 218, 13, 13),
                          circleColor: const Color(0xFFF3F3F3),
                          title: 'Stay healthy',
                          description:
                              'If you feel unwell, wait\n'
                              'and try again later.',
                        ),

                        const SizedBox(height: 8),

                        // ==================================================
                        // SCREENING INSTRUCTIONS
                        // ==================================================
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 9,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF7FAFD),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: const Color(0xFFE51C2A),
                            ),
                          ),
                          child: RichText(
                            textAlign: TextAlign.center,
                            text: const TextSpan(
                              children: [
                                TextSpan(
                                  text: 'Screening Instructions: ',
                                  style: TextStyle(
                                    color: darkBlue,
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                TextSpan(
                                  text:
                                      'Answer all screening questions honestly '
                                      'before donating.',
                                  style: TextStyle(
                                    color: Colors.black54,
                                    fontSize: 15,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(height: 13),

                        // ==================================================
                        // POWERED BY
                        // ==================================================
                        const Text(
                          'Powered by Alkhidmat & Bano Qabil',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: blue,
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),

                        const SizedBox(height: 4),

                        const Text(
                          'Health for a Better Tomorrow',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.grey,
                            fontSize: 14,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // ========================================================
                  // CUSTOM PAINTED BOTTOM BORDER
                  // ========================================================
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 0,
                    child: IgnorePointer(
                      child: SizedBox(
                        height: 125,
                        child: CustomPaint(
                          painter: HealthBottomPainter(
                            blue: blue,
                            red: red,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ======================================================================
  // HEALTH TIP WIDGET
  // ======================================================================
  Widget _healthTip({
    required IconData icon,
    required Color iconColor,
    required Color circleColor,
    required String title,
    required String description,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        vertical: 13,
        horizontal: 2,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // ---------------------------------------------------------------
          // ICON
          // ---------------------------------------------------------------
          Container(
            width: 61,
            height: 61,
            decoration: BoxDecoration(
              color: circleColor,
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: iconColor,
              size: 31,
            ),
          ),

          const SizedBox(width: 17),

          // ---------------------------------------------------------------
          // TEXT
          // ---------------------------------------------------------------
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: darkBlue,
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: const TextStyle(
                    color: Colors.black54,
                    fontSize: 12.5,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ==========================================================================
// CUSTOM PAINTER FOR HEALTH TIPS BOTTOM BORDER
// ==========================================================================
//
// This creates the curved red + blue wave seen in your reference image.
// Red wave is in front, blue wave is underneath.
// ==========================================================================

class HealthBottomPainter extends CustomPainter {
  final Color blue;
  final Color red;

  HealthBottomPainter({
    required this.blue,
    required this.red,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // =========================
    // BLUE BOTTOM WAVE
    // =========================
    final bluePaint = Paint()
      ..color = blue
      ..style = PaintingStyle.fill;

    final bluePath = Path();

    bluePath.moveTo(0, size.height * 0.55);

    bluePath.cubicTo(
      size.width * 0.15,
      size.height * 0.70,
      size.width * 0.30,
      size.height * 0.80,
      size.width * 0.45,
      size.height * 0.72,
    );

    bluePath.cubicTo(
      size.width * 0.62,
      size.height * 0.62,
      size.width * 0.75,
      size.height * 0.40,
      size.width,
      size.height * 0.58,
    );

    bluePath.lineTo(size.width, size.height);
    bluePath.lineTo(0, size.height);
    bluePath.close();

    canvas.drawPath(bluePath, bluePaint);

    // =========================
    // RED WAVE
    // =========================
    final redPaint = Paint()
      ..color = red
      ..style = PaintingStyle.fill;

    final redPath = Path();

    redPath.moveTo(0, size.height * 0.68);

    redPath.cubicTo(
      size.width * 0.16,
      size.height * 0.82,
      size.width * 0.32,
      size.height * 0.88,
      size.width * 0.47,
      size.height * 0.80,
    );

    redPath.cubicTo(
      size.width * 0.62,
      size.height * 0.72,
      size.width * 0.78,
      size.height * 0.60,
      size.width,
      size.height * 0.72,
    );

    redPath.lineTo(size.width, size.height);
    redPath.lineTo(0, size.height);
    redPath.close();

    canvas.drawPath(redPath, redPaint);

    // =========================
    // HEART
    // =========================
    final heartPaint = Paint()
      ..color = red
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final heartX = size.width * 0.74;
    final heartY = size.height * 0.37;

    final heartPath = Path();

    heartPath.moveTo(
      heartX,
      heartY + 30,
    );

    heartPath.cubicTo(
      heartX - 8,
      heartY + 21,
      heartX - 24,
      heartY + 11,
      heartX - 20,
      heartY,
    );

    heartPath.cubicTo(
      heartX - 17,
      heartY - 10,
      heartX - 3,
      heartY - 8,
      heartX,
      heartY + 2,
    );

    heartPath.cubicTo(
      heartX + 4,
      heartY - 8,
      heartX + 18,
      heartY - 10,
      heartX + 21,
      heartY,
    );

    heartPath.cubicTo(
      heartX + 25,
      heartY + 11,
      heartX + 9,
      heartY + 21,
      heartX,
      heartY + 30,
    );

    canvas.drawPath(heartPath, heartPaint);

    // Heart tail
    final tailPath = Path();

    tailPath.moveTo(
      heartX,
      heartY + 29,
    );

    tailPath.cubicTo(
      heartX - 2,
      heartY + 40,
      heartX - 15,
      heartY + 45,
      heartX - 27,
      heartY + 44,
    );

    tailPath.cubicTo(
      heartX - 38,
      heartY + 43,
      heartX - 43,
      heartY + 36,
      heartX - 47,
      heartY + 31,
    );

    canvas.drawPath(tailPath, heartPaint);
  }

  @override
  bool shouldRepaint(covariant HealthBottomPainter oldDelegate) {
    return oldDelegate.blue != blue || oldDelegate.red != red;
  }
}