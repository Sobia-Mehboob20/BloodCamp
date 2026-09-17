import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'camp_detail_screen.dart';

class CampListScreen extends StatefulWidget {
  const CampListScreen({super.key});

  @override
  State<CampListScreen> createState() => _CampListScreenState();
}

class _CampListScreenState extends State<CampListScreen> {
  String selectedCity = 'All Cities';
  String searchText = '';

  final TextEditingController searchController =
      TextEditingController();

  final List<String> cities = [
    'All Cities',
    'Rawalpindi',
    'Islamabad',
    'Karachi',
    'Lahore',
  ];

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  // =====================================================
  // GET CAMP STATUS
  // =====================================================

  String getCampStatus(Timestamp timestamp) {
    final campDate = timestamp.toDate();

    final now = DateTime.now();

    final today = DateTime(
      now.year,
      now.month,
      now.day,
    );

    final date = DateTime(
      campDate.year,
      campDate.month,
      campDate.day,
    );

    if (date.isBefore(today)) {
      return 'Past';
    } else if (date.isAtSameMomentAs(today)) {
      return 'Today';
    } else {
      return 'Upcoming';
    }
  }

  // =====================================================
  // FORMAT DATE
  // =====================================================

  String formatDate(Timestamp timestamp) {
    final date = timestamp.toDate();

    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/'
        '${date.year}';
  }

  // =====================================================
  // BUILD
  // =====================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,

      // =================================================
      // APP BAR
      // =================================================

      appBar: AppBar(
        backgroundColor: const Color(0xFF1565C0),
        foregroundColor: Colors.white,
        elevation: 0,
      
        title: const Text(
          'Blood Camps',
          style: TextStyle(
            fontWeight: FontWeight.bold,
           
          ),
        ),
      ),

      body: Column(
        children: [

          // =================================================
          // CITY DROPDOWN
          // =================================================

          Container(
            color: const Color(0xFF1565C0),
            padding: const EdgeInsets.fromLTRB(
              16,
              8,
              16,
              18,
            ),
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 15,
              ),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: selectedCity,
                  isExpanded: true,

                  icon: const Icon(
                    Icons.keyboard_arrow_down,
                    color: Color(0xFF1565C0),
                  ),

                  items: cities.map((city) {
                    return DropdownMenuItem<String>(
                      value: city,
                      child: Text(
                        city,
                        style: const TextStyle(
                          fontSize: 15,
                          color: Colors.black87,
                        ),
                      ),
                    );
                  }).toList(),

                  onChanged: (value) {
                    if (value == null) return;

                    setState(() {
                      selectedCity = value;
                    });
                  },
                ),
              ),
            ),
          ),

          // =================================================
          // SEARCH BAR
          // =================================================

          Padding(
            padding: const EdgeInsets.fromLTRB(
              16,
              18,
              16,
              10,
            ),
            child: TextField(
              controller: searchController,

              onChanged: (value) {
                setState(() {
                  searchText = value.toLowerCase();
                });
              },

              decoration: InputDecoration(
                hintText: 'Search blood camps',

                prefixIcon: const Icon(
                  Icons.search,
                  color: Color(0xFF1565C0),
                ),

                suffixIcon: searchText.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          searchController.clear();

                          setState(() {
                            searchText = '';
                          });
                        },
                      )
                    : null,

                filled: true,
                fillColor: Colors.white,

                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),

                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),

                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(
                    color: Color(0xFF1565C0),
                    width: 1.5,
                  ),
                ),
              ),
            ),
          ),

          // =================================================
          // CAMP LIST
          // =================================================

          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('camps')
                  .snapshots(),

              builder: (context, snapshot) {

                // -------------------------------------------
                // LOADING
                // -------------------------------------------

                if (snapshot.connectionState ==
                    ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(
                      color: Color(0xFF1565C0),
                    ),
                  );
                }

                // -------------------------------------------
                // ERROR
                // -------------------------------------------

                if (snapshot.hasError) {
                  return const Center(
                    child: Text(
                      'Something went wrong while loading camps.',
                    ),
                  );
                }

                // -------------------------------------------
                // NO DATA
                // -------------------------------------------

                if (!snapshot.hasData ||
                    snapshot.data!.docs.isEmpty) {
                  return const Center(
                    child: Text(
                      'No blood camps available.',
                    ),
                  );
                }

                // =================================================
                // FILTER CAMPS
                // =================================================

                final camps =
                    snapshot.data!.docs.where((doc) {

                  final data =
                      doc.data() as Map<String, dynamic>;

                  // -------------------------------------------
                  // LOCATION
                  // -------------------------------------------

                  final location =
                      (data['location'] ?? '')
                          .toString()
                          .toLowerCase();

                  // -------------------------------------------
                  // CITY
                  // -------------------------------------------

                  final city =
                      (data['city'] ?? '')
                          .toString()
                          .toLowerCase();

                  // -------------------------------------------
                  // CAMP NAME
                  // -------------------------------------------

                  final name =
                      (data['name'] ?? '')
                          .toString()
                          .toLowerCase();

                  // -------------------------------------------
                  // CITY FILTER
                  // -------------------------------------------

                  final matchesCity =
                      selectedCity == 'All Cities' ||
                      city ==
                          selectedCity.toLowerCase();

                  // -------------------------------------------
                  // SEARCH FILTER
                  // -------------------------------------------

                  final matchesSearch =
                      searchText.isEmpty ||
                      name.contains(searchText) ||
                      location.contains(searchText) ||
                      city.contains(searchText);

                  return matchesCity && matchesSearch;
                }).toList();

                // =================================================
                // NO FILTER RESULTS
                // =================================================

                if (camps.isEmpty) {
                  return const Center(
                    child: Text(
                      'No camps found.',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey,
                      ),
                    ),
                  );
                }

                // =================================================
                // LIST VIEW
                // =================================================

                return ListView.builder(
                  padding: const EdgeInsets.fromLTRB(
                    16,
                    8,
                    16,
                    20,
                  ),

                  itemCount: camps.length,

                  itemBuilder: (context, index) {

                    final doc = camps[index];

                    final data =
                        doc.data() as Map<String, dynamic>;

                    // -------------------------------------------
                    // CAMP DATA
                    // -------------------------------------------

                    final name =
                        data['name'] ?? 'Blood Camp';

                    final location =
                        data['location'] ??
                        'Location unavailable';

                    final startTime =
                        data['startTime'] ?? '';

                    final endTime =
                        data['endTime'] ?? '';

                    final city =
                        data['city'] ?? '';

                    // -------------------------------------------
                    // TOTAL SLOTS
                    // -------------------------------------------

                    final totalSlots =
                        (data['slotCapacity'] as num?)
                                ?.toInt() ??
                            0;

                    // -------------------------------------------
                    // BOOKED SLOTS
                    // -------------------------------------------

                    final bookedSlots =
                        (data['bookedSlots'] as num?)
                                ?.toInt() ??
                            0;

                    // -------------------------------------------
                    // BLOOD GROUPS
                    // -------------------------------------------

                    final bloodGroups =
                        data['bloodGroupNeeded'] is List
                            ? List<String>.from(
                                data['bloodGroupNeeded'],
                              )
                            : <String>[];

                    // -------------------------------------------
                    // DATE
                    // -------------------------------------------

                    final dateValue = data['date'];

                    if (dateValue is! Timestamp) {
                      return const SizedBox();
                    }

                    // -------------------------------------------
                    // STATUS
                    // -------------------------------------------

                    final status =
                        getCampStatus(dateValue);

                    // =================================================
                    // CAMP CARD
                    // =================================================

                    return _campCard(
                      campId: doc.id,
                      name: name.toString(),
                      location: location.toString(),
                       city: city.toString(),
                      date: formatDate(dateValue),
                      startTime: startTime.toString(),
                      endTime: endTime.toString(),
                      status: status,
                      totalSlots: totalSlots,
                      bookedSlots: bookedSlots,
                      bloodGroups: bloodGroups,
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // =====================================================
  // CAMP CARD
  // =====================================================

  Widget _campCard({
    required String campId,
    required String name,
    required String location,
    required String date,
    required String startTime,
    required String endTime,
    required String status,
    required String city,
    required int totalSlots,
    required int bookedSlots,
    required List<String> bloodGroups,
  }) {
    Color statusColor;

    if (status == 'Upcoming') {
      statusColor = const Color(0xFF1565C0);
    } else if (status == 'Today') {
      statusColor = const Color(0xFFE51C2A);
    } else {
      statusColor = Colors.grey;
    }

    return Card(
      margin: const EdgeInsets.only(
        bottom: 14,
      ),

      elevation: 2,

      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        
      ),

      child: Padding(
        padding: const EdgeInsets.all(16),

        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,

          children: [

            // =================================================
            // CAMP NAME + STATUS
            // =================================================

            Row(
              crossAxisAlignment:
                  CrossAxisAlignment.start,

              children: [

                Expanded(
                  child: Text(
                    name,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0D47A1),
                    ),
                  ),
                ),

                Container(
                  padding:
                      const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),

                  decoration: BoxDecoration(
                    border: Border.all(
          color: const Color.fromARGB(255, 28, 112, 207),
        ),
                    color:
                        statusColor.withOpacity(0.1),
                    borderRadius:
                        BorderRadius.circular(20),
                  ),

                  child: Text(
                    status,
                    style: TextStyle(
                      color: statusColor,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 14),

            // =================================================
            // DATE
            // =================================================

            _infoRow(
              Icons.calendar_today,
              date,
            ),

            const SizedBox(height: 8),

            // =================================================
            // TIME
            // =================================================

            _infoRow(
              Icons.access_time,
              '$startTime - $endTime',
            ),

            const SizedBox(height: 8),

            // =================================================
            // LOCATION
            // =================================================

            _infoRow(
              Icons.location_on,
            '$location, $city',
            ),

            const SizedBox(height: 12),

            // =================================================
            // BLOOD GROUPS
            // =================================================

            const Text(
              'Blood groups needed',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),

            const SizedBox(height: 7),

            Wrap(
              spacing: 6,
              runSpacing: 6,

              children:
                  bloodGroups.map((group) {

                return Container(
                  padding:
                      const EdgeInsets.symmetric(
                    horizontal: 9,
                    vertical: 5,
                  ),

                  decoration: BoxDecoration(
                    color: const Color(0xFFE51C2A)
                        .withOpacity(0.08),

                    borderRadius:
                        BorderRadius.circular(8),
                  ),

                  child: Text(
                    group,
                    style: const TextStyle(
                      color: Color(0xFFE51C2A),
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                );
              }).toList(),
            ),

            const SizedBox(height: 14),

            // =================================================
            // CAPACITY + VIEW DETAILS
            // =================================================

            Row(
              children: [

                const Icon(
                  Icons.people_outline,
                  size: 19,
                  color: Colors.grey,
                ),

                const SizedBox(width: 7),

                // ---------------------------------------------
                // BOOKED / TOTAL
                // ---------------------------------------------

                Text(
                  '$bookedSlots / $totalSlots',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1565C0),
                    fontSize: 13,
                  ),
                ),

                const SizedBox(width: 5),

                const Text(
                  'slots',
                  style: TextStyle(
                    color: Colors.grey,
                    fontSize: 13,
                  ),
                ),

                const Spacer(),

                // ---------------------------------------------
                // VIEW DETAILS
                // ---------------------------------------------

                if (status != 'Past')
                  TextButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              CampDetailScreen(
                            campId: campId,
                            name: name,
                            date: date,
                            location: location,
                              city: city,
                            startTime: startTime,
                            endTime: endTime,
                            status: status,
                            slotCapacity:
                                totalSlots.toString(),
                            bloodGroups:
                                bloodGroups,
                          ),
                        ),
                      );
                    },

                    child: const Text(
                      'View Details',
                      style: TextStyle(
                        color: Color(0xFF1565C0),
                        fontWeight: FontWeight.bold,
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

  // =====================================================
  // INFORMATION ROW
  // =====================================================

  Widget _infoRow(
    IconData icon,
    String text,
  ) {
    return Row(
      children: [

        Icon(
          icon,
          size: 18,
          color: const Color(0xFF1565C0),
        ),

        const SizedBox(width: 9),

        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              fontSize: 14,
              color: Colors.black87,
            ),
          ),
        ),
      ],
    );
  }
}