import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'assignStaff.dart';
import 'organizerHome.dart';

class StaffScreen extends StatelessWidget {
  const StaffScreen({super.key});

  static const Color primaryBlue = Color(0xFF1565C0);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FA),

      appBar:AppBar(
  title: const Text('Staff' ,
  style: TextStyle(
      color: Colors.white,
    ), ),
    centerTitle: true,
  backgroundColor: const Color(0xFF1565C0),
  
  leading: IconButton(
    icon: const Icon(Icons.arrow_back),
    onPressed: () {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => const OrganizerHome(),
        ),
      );
    },
  ),
),
       
      
      

      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .where('role', isEqualTo: 'staff')
            .snapshots(),

        builder: (context, snapshot) {
          if (snapshot.connectionState ==
              ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (snapshot.hasError) {
            return const Center(
              child: Text(
                'Unable to load staff.',
              ),
            );
          }

          final staffDocs = snapshot.data?.docs ?? [];

          if (staffDocs.isEmpty) {
            return _emptyStaff();
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: staffDocs.length,

            itemBuilder: (context, index) {
              final doc = staffDocs[index];

              final data =
                  doc.data() as Map<String, dynamic>;

              return _staffCard(data);
            },
          );
        },
      ),

      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: primaryBlue,
        foregroundColor: Colors.white,

        onPressed: () {
          _assignStaff(context);
        },

        icon: const Icon(Icons.person_add),
        label: const Text('Assign Staff'),
      ),
    );
  }

  // ============================
  // NO STAFF
  // ============================

  Widget _emptyStaff() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(30),

        child: Column(
          mainAxisAlignment:
              MainAxisAlignment.center,

          children: [
            Icon(
              Icons.people_outline,
              size: 65,
              color: Colors.grey.shade400,
            ),

            const SizedBox(height: 15),

            const Text(
              'No Staff Available',
              textAlign: TextAlign.center,

              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: primaryBlue,
              ),
            ),

            const SizedBox(height: 8),

            Text(
              'Staff members will appear here.',
              textAlign: TextAlign.center,

              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================
  // STAFF CARD
  // ============================

  Widget _staffCard(
    Map<String, dynamic> staff,
  ) {
    final String name =
        staff['name']?.toString() ?? 'Staff';

    final String email =
        staff['email']?.toString() ?? 'No email';

    final String phone =
        staff['phone']?.toString() ?? 'No phone';

    final String assignedCamp =
        staff['assignedCampId']?.toString() ?? '';

    return Card(
      margin:
          const EdgeInsets.only(bottom: 15),

      elevation: 2,

      shape: RoundedRectangleBorder(
        borderRadius:
            BorderRadius.circular(16),
      ),

      child: Padding(
        padding:
            const EdgeInsets.all(18),

        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,

          children: [
            // NAME
            Text(
              name,

              style: const TextStyle(
                fontSize: 19,
                fontWeight: FontWeight.bold,
                color: primaryBlue,
              ),
            ),

            const SizedBox(height: 5),

            // EMAIL
            _infoRow(
              Icons.email_outlined,
              email,
            ),

            const SizedBox(height: 12),

            // PHONE
            _infoRow(
              Icons.phone_outlined,
              phone,
            ),

            const SizedBox(height: 15),

            const Divider(),

            const SizedBox(height: 10),

            // ASSIGNED CAMP
            Row(
              children: [
                const Icon(
                  Icons.campaign_outlined,
                  size: 20,
                  color: primaryBlue,
                ),

                const SizedBox(width: 10),

                Expanded(
                  child: Text(
                    assignedCamp.isEmpty
                        ? 'Not assigned to a camp'
                        : 'Assigned Camp: $assignedCamp',

                    style: TextStyle(
                      fontSize: 14,
                      color: assignedCamp.isEmpty
                          ? Colors.grey.shade600
                          : primaryBlue,
                      fontWeight:
                          assignedCamp.isEmpty
                              ? FontWeight.normal
                              : FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ============================
  // INFO ROW
  // ============================

  Widget _infoRow(
    IconData icon,
    String text,
  ) {
    return Row(
      children: [
        Icon(
          icon,
          size: 20,
          color: primaryBlue,
        ),

        const SizedBox(width: 10),

        Expanded(
          child: Text(
            text,

            style: const TextStyle(
              fontSize: 14,
            ),
          ),
        ),
      ],
    );
  }

  // ============================
  // ASSIGN STAFF
  // ============================

  void _assignStaff(
    BuildContext context,
  ) {
    Navigator.push(
      context,

      MaterialPageRoute(
        builder: (context) =>
            const AssignStaffScreen(),
      ),
    );
  }
}