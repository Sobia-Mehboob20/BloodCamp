import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:universal_html/html.dart' as html;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

class ThankYouCardScreen extends StatelessWidget {
  const ThankYouCardScreen({super.key, required this.bookingId});

  final String bookingId;

  static const Color blue = Color(0xFF1565C0);
  static const Color darkBlue = Color(0xFF0D47A1);
  static const Color red = Color(0xFFE51C2A);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F8FC),

      appBar: AppBar(
        backgroundColor: blue,
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Thank You Card',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),

      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('bookings')
            .doc(bookingId)
            .snapshots(),

        builder: (context, bookingSnapshot) {
          if (bookingSnapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!bookingSnapshot.hasData || !bookingSnapshot.data!.exists) {
            return const Center(child: Text('Booking not found'));
          }

          final bookingData =
              bookingSnapshot.data!.data() as Map<String, dynamic>;

          final donorId = bookingData['donorId'] ?? '';

          final campName = bookingData['campName'] ?? 'Blood Camp';

          return StreamBuilder<DocumentSnapshot>(
            stream: FirebaseFirestore.instance
                .collection('users')
                .doc(donorId)
                .snapshots(),

            builder: (context, userSnapshot) {
              if (userSnapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              String donorName = 'Donor';

              if (userSnapshot.hasData && userSnapshot.data!.exists) {
                final userData =
                    userSnapshot.data!.data() as Map<String, dynamic>;

                donorName = userData['name']?.toString() ?? 'Donor';
              }

              String donationDate = 'Donation Date';

              final completedAt = bookingData['completedAt'];

              if (completedAt is Timestamp) {
                final date = completedAt.toDate();

                donationDate =
                    '${date.day.toString().padLeft(2, '0')} '
                    '${_monthName(date.month)} '
                    '${date.year}';
              }

              return _buildCard(
                context: context,
                donorName: donorName,
                campName: campName.toString(),
                donationDate: donationDate,
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildCard({
    required BuildContext context,
    required String donorName,
    required String campName,
    required String donationDate,
  }) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(18),

        child: Column(
          children: [
            // ==========================================================
            // THANK YOU CERTIFICATE
            // ==========================================================

            Container(
              width: double.infinity,
              height: 680,

              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(22),

                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.10),
                    blurRadius: 12,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),

              child: ClipRRect(
                borderRadius: BorderRadius.circular(22),

                child: Stack(
                  children: [
                    // ==================================================
                    // TOP BLUE WAVE
                    // ==================================================

                    Positioned(
                      top: -50,
                      left: -70,
                      right: -70,

                      child: Container(
                        height: 105,

                        decoration: const BoxDecoration(
                          color: blue,

                          borderRadius: BorderRadius.vertical(
                            bottom: Radius.elliptical(350, 85),
                          ),
                        ),
                      ),
                    ),

                    // ==================================================
                    // TOP RED WAVE
                    // ==================================================
                    Positioned(
                      top: -38,
                      left: -60,
                      right: -60,

                      child: Container(
                        height: 75,

                        decoration: const BoxDecoration(
                          color: red,

                          borderRadius: BorderRadius.vertical(
                            bottom: Radius.elliptical(340, 65),
                          ),
                        ),
                      ),
                    ),

                    // ==================================================
                    // WHITE CUT-IN
                    // ==================================================
                    Positioned(
                      top: 0,
                      left: -55,
                      right: -55,

                      child: Container(
                        height: 55,

                        decoration: const BoxDecoration(
                          color: Colors.white,

                          borderRadius: BorderRadius.vertical(
                            bottom: Radius.elliptical(320, 50),
                          ),
                        ),
                      ),
                    ),

                    // ==================================================
                    // BOTTOM BLUE WAVE
                    // ==================================================
                    Positioned(
                      bottom: -55,
                      left: -70,
                      right: -70,

                      child: Container(
                        height: 115,

                        decoration: const BoxDecoration(
                          color: blue,

                          borderRadius: BorderRadius.vertical(
                            top: Radius.elliptical(350, 90),
                          ),
                        ),
                      ),
                    ),

                    // ==================================================
                    // BOTTOM RED WAVE
                    // ==================================================
                    Positioned(
                      bottom: -38,
                      left: -55,
                      right: -55,

                      child: Container(
                        height: 80,

                        decoration: const BoxDecoration(
                          color: red,

                          borderRadius: BorderRadius.vertical(
                            top: Radius.elliptical(330, 65),
                          ),
                        ),
                      ),
                    ),

                    // ==================================================
                    // WHITE CUT-IN AT BOTTOM
                    // ==================================================
                    Positioned(
                      bottom: 0,
                      left: -50,
                      right: -50,

                      child: Container(
                        height: 55,

                        decoration: const BoxDecoration(
                          color: Colors.white,

                          borderRadius: BorderRadius.vertical(
                            top: Radius.elliptical(320, 50),
                          ),
                        ),
                      ),
                    ),

                    // ==================================================
                    // MAIN CONTENT
                    // ==================================================
                    Padding(
                      padding: const EdgeInsets.fromLTRB(28, 48, 28, 65),

                      child: Column(
                        children: [
                          // LOGO

                          Image.asset(
                            'assets/images/alkhidmat_logo.png',
                            height: 68,
                            fit: BoxFit.contain,
                          ),

                          const SizedBox(height: 5),

                          RichText(
                            text: const TextSpan(
                              children: [
                                TextSpan(
                                  text: 'Alkhidmat ',
                                  style: TextStyle(
                                    color: blue,
                                    fontSize: 17,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),

                                TextSpan(
                                  text: 'Blood Camp',
                                  style: TextStyle(
                                    color: red,
                                    fontSize: 17,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 25),

                          // THANK YOU
                          const Text(
                            'Thank You',

                            textAlign: TextAlign.center,

                            style: TextStyle(
                              color: darkBlue,
                              fontSize: 38,
                              fontWeight: FontWeight.w600,
                              fontStyle: FontStyle.italic,
                            ),
                          ),

                          const Text(
                            'for being a lifesaver',

                            textAlign: TextAlign.center,

                            style: TextStyle(
                              color: red,
                              fontSize: 19,
                              fontStyle: FontStyle.italic,
                              fontWeight: FontWeight.w600,
                            ),
                          ),

                          const SizedBox(height: 15),

                          // RED BLOOD DROP + HEART
                          Stack(
                            alignment: Alignment.center,

                            children: [
                              const Icon(
                                Icons.water_drop,
                                color: red,
                                size: 65,
                              ),

                              const Padding(
                                padding: EdgeInsets.only(top: 16),

                                child: Icon(
                                  Icons.favorite_border,
                                  color: Colors.white,
                                  size: 21,
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 17),

                          const Text(
                            'This certificate is awarded to',

                            style: TextStyle(
                              color: Colors.black54,
                              fontSize: 11,
                            ),
                          ),

                          const SizedBox(height: 6),

                          // DYNAMIC DONOR NAME
                          Text(
                            donorName,

                            textAlign: TextAlign.center,

                            style: const TextStyle(
                              color: darkBlue,
                              fontSize: 21,
                              fontWeight: FontWeight.bold,
                            ),
                          ),

                          const SizedBox(height: 13),

                          const Text(
                            'for donating blood at',

                            style: TextStyle(
                              color: Colors.black54,
                              fontSize: 11,
                            ),
                          ),

                          const SizedBox(height: 5),

                          // DYNAMIC CAMP
                          Text(
                            campName,

                            textAlign: TextAlign.center,

                            style: const TextStyle(
                              color: darkBlue,
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),

                          const SizedBox(height: 4),

                          // DYNAMIC DATE
                          Text(
                            'on $donationDate',

                            textAlign: TextAlign.center,

                            style: const TextStyle(
                              color: darkBlue,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),

                          const SizedBox(height: 21),

                          const Text(
                            'Your generosity gives hope,\n'
                            'helps lives and builds a healthier community.',

                            textAlign: TextAlign.center,

                            style: TextStyle(
                              color: Colors.black54,
                              fontSize: 11,
                              height: 1.5,
                            ),
                          ),

                          const SizedBox(height: 20),

                          const Text(
                            'Thank you!',

                            style: TextStyle(
                              color: darkBlue,
                              fontSize: 17,
                              fontStyle: FontStyle.italic,
                            ),
                          ),

                          const SizedBox(height: 4),

                          const Text(
                            'Alkhidmat Health Team',

                            style: TextStyle(
                              color: darkBlue,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // ==================================================
                    // BOTTOM HEART DECORATION
                    // ==================================================
                    Positioned(
                      right: 24,
                      bottom: 25,

                      child: Transform.rotate(
                        angle: -0.12,

                        child: const Icon(
                          Icons.favorite_border,
                          color: red,
                          size: 40,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 18),

            // ==========================================================
            // DOWNLOAD BUTTON
            // ==========================================================
            SizedBox(
              width: double.infinity,
              height: 50,

              child: ElevatedButton.icon(
                onPressed: () async {
                  try {
                    await _downloadThankYouCard(
                      donorName: donorName,
                      campName: campName,
                      donationDate: donationDate,
                    );

                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Thank You Card downloaded successfully!',
                          ),
                        ),
                      );
                    }
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Download failed: $e')),
                      );
                    }
                  }
                },

                icon: const Icon(Icons.download),

                label: const Text(
                  'Download Thank You Card',

                  style: TextStyle(fontWeight: FontWeight.bold),
                ),

                style: ElevatedButton.styleFrom(
                  backgroundColor: blue,
                  foregroundColor: Colors.white,

                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  // ================================================================
  // CREATE AND SAVE PDF
  // ================================================================

  Future<void> _downloadThankYouCard({
    required String donorName,
    required String campName,
    required String donationDate,
  }) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,

        margin: const pw.EdgeInsets.all(30),

        build: (pw.Context context) {
          return pw.Container(
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: PdfColors.blue800, width: 3),

              borderRadius: pw.BorderRadius.circular(20),
            ),

            padding: const pw.EdgeInsets.all(35),

            child: pw.Column(
              mainAxisAlignment: pw.MainAxisAlignment.center,

              children: [
                pw.Text(
                  'ALKHIDMAT BLOOD CAMP',

                  style: pw.TextStyle(
                    color: PdfColors.blue800,
                    fontSize: 24,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),

                pw.SizedBox(height: 35),

                pw.Text(
                  'Thank You',

                  style: pw.TextStyle(
                    color: PdfColors.blue900,
                    fontSize: 38,
                    fontWeight: pw.FontWeight.bold,
                    fontStyle: pw.FontStyle.italic,
                  ),
                ),

                pw.SizedBox(height: 8),

                pw.Text(
                  'for being a lifesaver',

                  style: pw.TextStyle(
                    color: PdfColors.red,
                    fontSize: 18,
                    fontStyle: pw.FontStyle.italic,
                  ),
                ),

                pw.SizedBox(height: 35),

                pw.Text(
                  'This certificate is awarded to',

                  style: const pw.TextStyle(
                    color: PdfColors.grey700,
                    fontSize: 13,
                  ),
                ),

                pw.SizedBox(height: 10),

                pw.Text(
                  donorName,

                  textAlign: pw.TextAlign.center,

                  style: pw.TextStyle(
                    color: PdfColors.blue900,
                    fontSize: 25,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),

                pw.SizedBox(height: 25),

                pw.Text(
                  'for donating blood at',

                  style: const pw.TextStyle(
                    color: PdfColors.grey700,
                    fontSize: 13,
                  ),
                ),

                pw.SizedBox(height: 8),

                pw.Text(
                  campName,

                  textAlign: pw.TextAlign.center,

                  style: pw.TextStyle(
                    color: PdfColors.blue900,
                    fontSize: 17,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),

                pw.SizedBox(height: 8),

                pw.Text(
                  'on $donationDate',

                  style: pw.TextStyle(
                    color: PdfColors.blue900,
                    fontSize: 14,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),

                pw.SizedBox(height: 30),

                pw.Text(
                  'Your generosity gives hope, helps lives\n'
                  'and builds a healthier community.',

                  textAlign: pw.TextAlign.center,

                  style: const pw.TextStyle(
                    color: PdfColors.grey700,
                    fontSize: 13,
                    lineSpacing: 5,
                  ),
                ),

                pw.SizedBox(height: 35),

                pw.Text(
                  'Thank you!',

                  style: pw.TextStyle(
                    color: PdfColors.blue900,
                    fontSize: 19,
                    fontStyle: pw.FontStyle.italic,
                  ),
                ),

                pw.SizedBox(height: 5),

                pw.Text(
                  'Alkhidmat Health Team',

                  style: pw.TextStyle(
                    color: PdfColors.blue900,
                    fontSize: 13,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );

    // ================================================================
    // SAVE PDF
    // ================================================================
    final bytes = await pdf.save();

    final blob = html.Blob([bytes], 'application/pdf');

    final url = html.Url.createObjectUrlFromBlob(blob);

    final anchor = html.AnchorElement(href: url)
      ..setAttribute('download', 'thank_you_card.pdf')
      ..click();

    html.Url.revokeObjectUrl(url);
  }

  // ================================================================
  // MONTH NAME
  // ================================================================

  static String _monthName(int month) {
    const months = [
      '',
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];

    return months[month];
  }
}
