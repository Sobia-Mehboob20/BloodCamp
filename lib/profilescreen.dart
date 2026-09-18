import 'dart:convert';
import 'dart:typed_data';
import 'organizerHome.dart';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
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

  // ============================================================
  // PICK PROFILE PHOTO + SAVE AS BASE64 IN FIRESTORE
  // ============================================================

  Future<void> uploadProfilePhoto() async {
    if (currentUser == null) return;

    final ImagePicker picker = ImagePicker();

    final XFile? image = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 70,
    );

    if (image == null) return;

    setState(() {
      isUploading = true;
    });

    try {
      // Read selected image as bytes
      final Uint8List imageBytes = await image.readAsBytes();

      // Convert image bytes to Base64
      final String base64Image = base64Encode(imageBytes);

      // Save Base64 image in Firestore
      await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser!.uid)
          .update({
        'profileImage': base64Image,
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile photo updated'),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update photo: $e'),
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
  title: const Text(
    'Profile',
    style: TextStyle(
      color: Colors.white,
    ),
  ),
  centerTitle: true,
  backgroundColor: const Color(0xFF1565C0),
  iconTheme: const IconThemeData(
    color: Colors.white,
  ),
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

      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(currentUser!.uid)
            .snapshots(),

        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(
              child: Text('Profile not found'),
            );
          }

          final data =
              snapshot.data!.data() as Map<String, dynamic>;

          final String profileImage =
              data['profileImage'] ?? '';

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),

            child: Column(
              children: [

                // ==================================================
                // PROFILE PHOTO
                // ==================================================

                Stack(
                  children: [

                    CircleAvatar(
                      radius: 60,

                      backgroundImage: profileImage.isNotEmpty
                          ? MemoryImage(
                              base64Decode(profileImage),
                            )
                          : null,

                      child: profileImage.isEmpty
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
                                  child: CircularProgressIndicator(
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

                const SizedBox(height: 35),

                // ==================================================
                // ORGANIZER
                // ==================================================

                ProfileItem(
                  icon: Icons.admin_panel_settings,
                  title: 'Role',
                  value: 'Organizer',
                ),

                // ==================================================
                // PHONE
                // ==================================================

                ProfileItem(
                  icon: Icons.phone,
                  title: 'Phone',
                  value: '0300-1234567',
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

        subtitle: Text(value),
      ),
    );
  }
}