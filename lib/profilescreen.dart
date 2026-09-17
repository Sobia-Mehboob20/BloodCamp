import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class OrganizerProfile extends StatefulWidget {
  const OrganizerProfile({super.key});

  @override
  State<OrganizerProfile> createState() => _OrganizerProfileState();
}

class _OrganizerProfileState extends State<OrganizerProfile> {
  final User? currentUser = FirebaseAuth.instance.currentUser;

  bool isUploading = false;

  // Pick image and upload to Firebase Storage
  Future<void> uploadProfilePhoto() async {
    if (currentUser == null) return;

    final ImagePicker picker = ImagePicker();

    final XFile? image = await picker.pickImage(
      source: ImageSource.gallery,
    );

    if (image == null) return;

    setState(() {
      isUploading = true;
    });

    try {
      final File file = File(image.path);

      // Firebase Storage location
      final storageRef = FirebaseStorage.instance
          .ref()
          .child('profile_photos')
          .child('${currentUser!.uid}.jpg');

      // Upload image
      await storageRef.putFile(file);

      // Get image URL
      final String photoUrl =
          await storageRef.getDownloadURL();

      // Save URL in Firestore
      await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser!.uid)
          .update({
        'photoUrl': photoUrl,
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile photo uploaded'),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Upload failed: $e'),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          isUploading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (currentUser == null) {
      return const Scaffold(
        body: Center(
          child: Text('Please login first'),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Organizer Profile'),
      ),

      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(currentUser!.uid)
            .snapshots(),

        builder: (context, snapshot) {
          if (snapshot.connectionState ==
              ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (!snapshot.hasData ||
              !snapshot.data!.exists) {
            return const Center(
              child: Text('Profile not found'),
            );
          }

          final data =
              snapshot.data!.data() as Map<String, dynamic>;

          final String name = data['name'] ?? '';
          final String phone = data['phone'] ?? '';
          final String city = data['city'] ?? '';
          final String bloodGroup =
              data['bloodGroup'] ?? '';
          final String lastDonationDate =
              data['lastDonationDate'] ?? '';
          final String photoUrl =
              data['photoUrl'] ?? '';

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),

            child: Column(
              children: [

                // ---------------- PROFILE PHOTO ----------------

                Stack(
                  children: [

                    CircleAvatar(
                      radius: 60,

                      backgroundImage:
                          photoUrl.isNotEmpty
                              ? NetworkImage(photoUrl)
                              : null,

                      child: photoUrl.isEmpty
                          ? const Icon(
                              Icons.person,
                              size: 60,
                            )
                          : null,
                    ),

                    Positioned(
                      right: 0,
                      bottom: 0,

                      child: GestureDetector(
                        onTap: isUploading
                            ? null
                            : uploadProfilePhoto,

                        child: CircleAvatar(
                          radius: 20,

                          child: isUploading
                              ? const SizedBox(
                                  height: 18,
                                  width: 18,
                                  child:
                                      CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Icon(
                                  Icons.camera_alt,
                                ),
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 30),

                // ---------------- NAME ----------------

                ProfileItem(
                  icon: Icons.person,
                  title: 'Name',
                  value: name,
                ),

                // ---------------- PHONE ----------------

                ProfileItem(
                  icon: Icons.phone,
                  title: 'Phone',
                  value: phone,
                ),

                // ---------------- CITY ----------------

                ProfileItem(
                  icon: Icons.location_city,
                  title: 'City',
                  value: city,
                ),

                // ---------------- BLOOD GROUP ----------------

                ProfileItem(
                  icon: Icons.bloodtype,
                  title: 'Blood Group',
                  value: bloodGroup,
                ),

                // ---------------- LAST DONATION ----------------

                ProfileItem(
                  icon: Icons.calendar_month,
                  title: 'Last Donation Date',
                  value: lastDonationDate,
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}


// ============================================================
// PROFILE ITEM
// ============================================================

class ProfileItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;

  const ProfileItem({
    super.key,
    required this.icon,
    required this.title,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),

      child: ListTile(
        leading: Icon(icon),

        title: Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),

        subtitle: Text(
          value.isEmpty ? 'Not available' : value,
        ),
      ),
    );
  }
}

