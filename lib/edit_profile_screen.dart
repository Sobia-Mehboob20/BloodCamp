import 'dart:convert';
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _cityController = TextEditingController();

  final ImagePicker _imagePicker = ImagePicker();

  String? selectedBloodGroup;

  // Stores image bytes temporarily before saving to Firestore
  Uint8List? selectedImageBytes;

  bool isLoading = true;
  bool isSaving = false;

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

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final User? user = _auth.currentUser;

    if (user == null) {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
      return;
    }

    try {
      final DocumentSnapshot<Map<String, dynamic>> snapshot =
          await _firestore.collection('users').doc(user.uid).get();

      if (snapshot.exists) {
        final data = snapshot.data();

        if (data != null) {
          _nameController.text = data['name']?.toString() ?? '';
          _phoneController.text = data['phone']?.toString() ?? '';
          _cityController.text = data['city']?.toString() ?? '';

          final String? bloodGroup = data['bloodGroup']?.toString();

          if (bloodGroup != null && bloodGroups.contains(bloodGroup)) {
            selectedBloodGroup = bloodGroup;
          }

          // Load existing Base64 image from Firestore
          final String? base64Image =
              data['profileImage']?.toString();

          if (base64Image != null && base64Image.isNotEmpty) {
            try {
              selectedImageBytes = base64Decode(base64Image);
            } catch (e) {
              selectedImageBytes = null;
            }
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not load profile: $e'),
          ),
        );
      }
    }

    if (mounted) {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _pickImage() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
        maxWidth: 800,
        maxHeight: 800,
      );

      if (image != null) {
        final Uint8List bytes = await image.readAsBytes();

        setState(() {
          selectedImageBytes = bytes;
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Profile picture selected successfully',
              ),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Could not select image: $e',
            ),
          ),
        );
      }
    }
  }

  Future<void> _saveProfile() async {
    final User? user = _auth.currentUser;

    if (user == null) {
      return;
    }

    if (_nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter your name'),
        ),
      );
      return;
    }

    setState(() {
      isSaving = true;
    });

    try {
      final Map<String, dynamic> profileData = {
        'name': _nameController.text.trim(),
        'phone': _phoneController.text.trim(),
        'city': _cityController.text.trim(),
        'bloodGroup': selectedBloodGroup ?? '',
      };

      // Convert image bytes to Base64 and save in Firestore
      if (selectedImageBytes != null) {
        profileData['profileImage'] =
            base64Encode(selectedImageBytes!);
      }

      await _firestore
          .collection('users')
          .doc(user.uid)
          .update(profileData);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Profile updated successfully',
            ),
          ),
        );

        // Return to Profile Screen
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Could not update profile: $e',
            ),
          ),
        );
      }
    }

    if (mounted) {
      setState(() {
        isSaving = false;
      });
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _cityController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const Color blue = Color(0xFF1565C0);
    const Color darkBlue = Color(0xFF0D47A1);
    const Color red = Color(0xFFE51C2A);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: blue,
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Edit Profile',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: isLoading
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : SafeArea(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    const SizedBox(height: 25),
                    Stack(
                      children: [
                        CircleAvatar(
                          radius: 58,
                          backgroundColor:
                              const Color(0xFFEAF3FF),
                          backgroundImage:
                              selectedImageBytes != null
                                  ? MemoryImage(
                                      selectedImageBytes!,
                                    )
                                  : null,
                          child: selectedImageBytes == null
                              ? const Icon(
                                  Icons.person,
                                  size: 65,
                                  color: Colors.grey,
                                )
                              : null,
                        ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: InkWell(
                            onTap: _pickImage,
                            borderRadius:
                                BorderRadius.circular(25),
                            child: Container(
                              height: 42,
                              width: 42,
                              decoration:
                                  const BoxDecoration(
                                color: blue,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.camera_alt,
                                color: Colors.white,
                                size: 21,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'Tap the camera icon to change your picture',
                      style: TextStyle(
                        color: Colors.grey,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 30),
                    Padding(
                      padding:
                          const EdgeInsets.symmetric(
                        horizontal: 20,
                      ),
                      child: Column(
                        crossAxisAlignment:
                            CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Personal Information',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: darkBlue,
                            ),
                          ),
                          const SizedBox(height: 20),
                          TextField(
                            controller: _nameController,
                            decoration: InputDecoration(
                              labelText: 'Full Name',
                              prefixIcon: const Icon(
                                Icons.person_outline,
                              ),
                              border:
                                  OutlineInputBorder(
                                borderRadius:
                                    BorderRadius.circular(
                                  12,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          TextField(
                            controller:
                                _phoneController,
                            keyboardType:
                                TextInputType.phone,
                            decoration: InputDecoration(
                              labelText:
                                  'Phone Number',
                              prefixIcon: const Icon(
                                Icons.phone_outlined,
                              ),
                              border:
                                  OutlineInputBorder(
                                borderRadius:
                                    BorderRadius.circular(
                                  12,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          TextField(
                            controller:
                                _cityController,
                            decoration: InputDecoration(
                              labelText: 'City',
                              prefixIcon: const Icon(
                                Icons.location_city,
                              ),
                              border:
                                  OutlineInputBorder(
                                borderRadius:
                                    BorderRadius.circular(
                                  12,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          DropdownButtonFormField<String>(
                            value: selectedBloodGroup,
                            decoration:
                                InputDecoration(
                              labelText:
                                  'Blood Group',
                              prefixIcon: const Icon(
                                Icons.bloodtype_outlined,
                                color: red,
                              ),
                              border:
                                  OutlineInputBorder(
                                borderRadius:
                                    BorderRadius.circular(
                                  12,
                                ),
                              ),
                            ),
                            items:
                                bloodGroups.map(
                              (String group) {
                                return DropdownMenuItem<
                                    String>(
                                  value: group,
                                  child: Text(group),
                                );
                              },
                            ).toList(),
                            onChanged:
                                (String? value) {
                              setState(() {
                                selectedBloodGroup =
                                    value;
                              });
                            },
                          ),
                          const SizedBox(height: 30),
                          SizedBox(
                            width: double.infinity,
                            height: 52,
                            child:
                                ElevatedButton(
                              onPressed: isSaving
                                  ? null
                                  : _saveProfile,
                              style:
                                  ElevatedButton
                                      .styleFrom(
                                backgroundColor:
                                    blue,
                                foregroundColor:
                                    Colors.white,
                                shape:
                                    RoundedRectangleBorder(
                                  borderRadius:
                                      BorderRadius
                                          .circular(
                                    12,
                                  ),
                                ),
                              ),
                              child: isSaving
                                  ? const SizedBox(
                                      height: 24,
                                      width: 24,
                                      child:
                                          CircularProgressIndicator(
                                        color:
                                            Colors.white,
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : const Text(
                                      'Save Changes',
                                      style:
                                          TextStyle(
                                        fontSize: 16,
                                        fontWeight:
                                            FontWeight
                                                .bold,
                                      ),
                                    ),
                            ),
                          ),
                          const SizedBox(height: 15),
                          SizedBox(
                            width: double.infinity,
                            height: 52,
                            child:
                                OutlinedButton(
                              onPressed: () {
                                Navigator.pop(
                                  context,
                                );
                              },
                              style:
                                  OutlinedButton
                                      .styleFrom(
                                foregroundColor:
                                    blue,
                                side:
                                    const BorderSide(
                                  color: blue,
                                ),
                                shape:
                                    RoundedRectangleBorder(
                                  borderRadius:
                                      BorderRadius
                                          .circular(
                                    12,
                                  ),
                                ),
                              ),
                              child: const Text(
                                'Cancel',
                                style:
                                    TextStyle(
                                  fontSize: 16,
                                  fontWeight:
                                      FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 35),
                    Container(
                      width: double.infinity,
                      padding:
                          const EdgeInsets.only(
                        top: 18,
                        bottom: 20,
                      ),
                      decoration:
                          const BoxDecoration(
                        border: Border(
                          top: BorderSide(
                            color:
                                Color(0xFFE0E0E0),
                            width: 1,
                          ),
                        ),
                      ),
                      child: const Column(
                        children: [
                          Text(
                            '♥',
                            style: TextStyle(
                              color: red,
                              fontSize: 25,
                            ),
                          ),
                          SizedBox(height: 5),
                          Text(
                            'Powered by Alkhidmat & Bano Qabil',
                            style: TextStyle(
                              color: Colors.grey,
                              fontSize: 13,
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