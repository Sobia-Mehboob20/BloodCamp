import 'package:flutter/material.dart';
import 'book_slot_screen.dart';

class CampDetailScreen extends StatelessWidget {
  final String campId;
  final String name;
  final String date;
  final String location;
  final String city;
  final String startTime;
  final String endTime;
  final String status;
  final String slotCapacity;
  final List<String> bloodGroups;

  const CampDetailScreen({
    super.key,
    required this.campId,
    required this.name,
    required this.date,
    required this.location,
    required this.city,
    required this.startTime,
    required this.endTime,
    required this.status,
    required this.slotCapacity,
    required this.bloodGroups,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,

      appBar: AppBar(
        backgroundColor: const Color(0xFF1565C0),
        foregroundColor: Colors.white,
        title: const Text(
          'Camp Details',
         
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(18),

        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,

          children: [
            // ================= CAMP NAME =================
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),

              decoration: BoxDecoration(
                border: Border.all(
          color: const Color.fromARGB(255, 28, 112, 207),
        ),
                color: const Color(0xFFEAF5FF),
                borderRadius: BorderRadius.circular(18),
              ),

              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,

                children: [
                  const Icon(
                    Icons.bloodtype,
                    color: Color(0xFFE51C2A),
                    size: 45,
                  ),

                  const SizedBox(height: 12),

                  Text(
                    name,
                    style: const TextStyle(
                      color: Color(0xFF0D47A1),
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 8),

                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),

                    decoration: BoxDecoration(
                     color: status == 'Today'
                          ? const Color(0xFFFFE5E5)
                          : const Color(0xFFE5F0FF),
                      borderRadius: BorderRadius.circular(20),
                    ),

                    child: Text(
                      status,
                      style: TextStyle(
                        color: status == 'Today'
                            ? const Color(0xFFE51C2A)
                            : const Color(0xFF1565C0),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 18),

            // ================= INFORMATION =================

            _infoCard(
              icon: Icons.calendar_today,
              title: 'Date',
              value: date,
            ),

            _infoCard(
              icon: Icons.access_time,
              title: 'Time',
              value: '$startTime - $endTime',
            ),

            _infoCard(
              icon: Icons.location_on,
              title: 'Location',
              value: '$location, $city',
            ),

            const SizedBox(height: 8),

            // ================= BLOOD GROUPS =================

            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),

              decoration: BoxDecoration(
                border: Border.all(
          color: const Color.fromARGB(255, 28, 112, 207),
        ),
                color: Colors.white,
                borderRadius: BorderRadius.circular(15),
              ),

              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,

                children: [
                  const Text(
                    'Blood Groups Needed',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0D47A1),
                    ),
                  ),

                  const SizedBox(height: 12),

                  Wrap(
                    spacing: 8,
                    runSpacing: 8,

                    children: bloodGroups.map((group) {
                      return Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 7,
                        ),

                        decoration: BoxDecoration(
          
                          color: const Color(0xFFFFE8E8),
                          borderRadius: BorderRadius.circular(8),
                        ),

                        child: Text(
                          group,
                          style: const TextStyle(
                            color: Color(0xFFE51C2A),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 18),

            // ================= WHAT TO BRING =================

            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),

              decoration: BoxDecoration(
                border: Border.all(
          color: const Color.fromARGB(255, 28, 112, 207),
        ),
                color: Colors.white,
                borderRadius: BorderRadius.circular(15),
              ),

              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,

                children: [
                  const Row(
                    children: [
                      Icon(
                        Icons.backpack_outlined,
                        color: Color(0xFF1565C0),
                        size: 24,
                      ),

                      SizedBox(width: 10),

                      Text(
                        'What to Bring',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF0D47A1),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  _bringItem(
                    icon: Icons.credit_card,
                    text: 'CNIC / ID Card',
                  ),

                  _bringItem(
                    icon: Icons.restaurant,
                    text: 'Light Meal + Water',
                  ),

                  _bringItem(
                    icon: Icons.checkroom,
                    text: 'Comfortable Clothes',
                  ),
                ],
              ),
            ),

            const SizedBox(height: 25),

            // ================= BOOK BUTTON =================

            if (status != 'Past')
              SizedBox(
                width: double.infinity,
                height: 52,

                child: ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => BookSlotScreen(
                          campId: campId,
                          campName: name,
                          date: date,
                          location: location,
                          startTime: startTime,
                          endTime: endTime,
                          slotCapacity: slotCapacity,
                        ),
                      ),
                    );
                  },

                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFE51C2A),
                    foregroundColor: Colors.white,

                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),

                  child: const Text(
                    'Book a Slot',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // ================= INFORMATION CARD =================

  Widget _infoCard({
    required IconData icon,
    required String title,
    required String value,
  }) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),

      decoration: BoxDecoration(
        border: Border.all(
          color: const Color.fromARGB(255, 28, 112, 207),
        ),
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
      ),

      child: Row(
        children: [
          Icon(
            icon,
            color: const Color(0xFF1565C0),
            size: 25,
          ),

          const SizedBox(width: 14),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,

              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.grey,
                    fontSize: 12,
                  ),
                ),

                const SizedBox(height: 3),

                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ================= WHAT TO BRING ITEM =================

  Widget _bringItem({
    required IconData icon,
    required String text,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),

      child: Row(
        children: [
          Icon(
            icon,
            color: const Color(0xFF1565C0),
            size: 22,
          ),

          const SizedBox(width: 12),

          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 15,
                color: Colors.black87,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}