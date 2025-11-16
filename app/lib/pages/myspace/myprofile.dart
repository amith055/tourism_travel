import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';

class MyProfilePage extends StatefulWidget {
  final String email;

  const MyProfilePage({super.key, required this.email});

  @override
  State<MyProfilePage> createState() => _MyProfilePageState();
}

class _MyProfilePageState extends State<MyProfilePage> {
  final TextEditingController firstNameController = TextEditingController();
  final TextEditingController lastNameController = TextEditingController();
  final TextEditingController mobileController = TextEditingController();

  bool isLoading = true;
  bool isSaving = false; // 👈 new variable
  bool hasMobile = false;
  String? profileImageUrl;
  File? _pickedImage;

  @override
  void initState() {
    super.initState();
    fetchUserData();
  }

  Future<void> fetchUserData() async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('email', isEqualTo: widget.email)
          .limit(1)
          .get();

      if (snapshot.docs.isNotEmpty) {
        final userData = snapshot.docs.first.data();
        setState(() {
          firstNameController.text = userData['firstName'] ?? '';
          lastNameController.text = userData['lastName'] ?? '';
          mobileController.text = userData['mobile_number'] ?? '';
          hasMobile = userData['mobile_number'] != null;
          profileImageUrl = userData['profileImage'];
          isLoading = false;
        });
      } else {
        setState(() => isLoading = false);
      }
    } catch (e) {
      print('Error fetching user data: $e');
      setState(() => isLoading = false);
    }
  }

  // Pick image from gallery
  Future<void> _pickImage() async {
    final pickedFile = await ImagePicker().pickImage(
      source: ImageSource.gallery,
    );
    if (pickedFile != null) {
      setState(() {
        _pickedImage = File(pickedFile.path);
      });
    }
  }

  // Upload to Firebase Storage and update Firestore
  Future<void> _uploadImageToFirebase() async {
    if (_pickedImage == null) return;

    try {
      final storageRef = FirebaseStorage.instance.ref().child(
        'profile_images/${widget.email}_${DateTime.now().millisecondsSinceEpoch}.jpg',
      );

      final uploadTask = await storageRef.putFile(_pickedImage!);
      final downloadUrl = await uploadTask.ref.getDownloadURL();

      final userQuery = await FirebaseFirestore.instance
          .collection('users')
          .where('email', isEqualTo: widget.email)
          .limit(1)
          .get();

      if (userQuery.docs.isNotEmpty) {
        final docId = userQuery.docs.first.id;
        await FirebaseFirestore.instance.collection('users').doc(docId).update({
          'profileImage': downloadUrl,
        });
      }

      setState(() {
        profileImageUrl = downloadUrl;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile picture updated successfully!')),
      );
    } catch (e) {
      print('Image upload error: $e');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to upload image: $e')));
    }
  }

  // ✅ Save changes function
  Future<void> _saveChanges() async {
    setState(() => isSaving = true);

    try {
      final userQuery = await FirebaseFirestore.instance
          .collection('users')
          .where('email', isEqualTo: widget.email)
          .limit(1)
          .get();

      if (userQuery.docs.isNotEmpty) {
        final docId = userQuery.docs.first.id;

        // Upload image if new one picked
        if (_pickedImage != null) {
          await _uploadImageToFirebase();
        }

        await FirebaseFirestore.instance.collection('users').doc(docId).update({
          'firstName': firstNameController.text.trim(),
          'lastName': lastNameController.text.trim(),
          'mobile_number': mobileController.text.trim(),
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Profile updated successfully!")),
        );
      }
      Navigator.pop(context, true); // Go back after saving
    } catch (e) {
      print('Error saving profile: $e');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Failed to update profile: $e")));
    }

    setState(() => isSaving = false);
  }

  InputDecoration _inputDecoration(String label, {Widget? suffixIcon}) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: Colors.grey),
      filled: true,
      fillColor: const Color(0xFF1E1E1E),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Colors.blueAccent, width: 1.2),
      ),
      suffixIcon: suffixIcon,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text("My Profile", style: TextStyle(color: Colors.white)),
        foregroundColor: Colors.white,
        backgroundColor: Colors.black,
        elevation: 0,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.white))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Profile Image
                  Center(
                    child: Stack(
                      alignment: Alignment.bottomRight,
                      children: [
                        CircleAvatar(
                          radius: 60,
                          backgroundColor: Colors.grey[800],
                          backgroundImage: _pickedImage != null
                              ? FileImage(_pickedImage!)
                              : (profileImageUrl != null &&
                                    profileImageUrl!.isNotEmpty)
                              ? NetworkImage(profileImageUrl!)
                              : null,
                          child:
                              (_pickedImage == null &&
                                  (profileImageUrl == null ||
                                      profileImageUrl!.isEmpty))
                              ? const Icon(
                                  Icons.person,
                                  size: 60,
                                  color: Colors.white,
                                )
                              : null,
                        ),
                        Positioned(
                          bottom: 0,
                          right: 4,
                          child: InkWell(
                            onTap: _pickImage,
                            child: const CircleAvatar(
                              radius: 20,
                              backgroundColor: Colors.blueAccent,
                              child: Icon(Icons.edit, color: Colors.white),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 25),

                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      "Profile Information",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  TextField(
                    controller: firstNameController,
                    style: const TextStyle(color: Colors.white),
                    decoration: _inputDecoration("First Name"),
                  ),
                  const SizedBox(height: 16),

                  TextField(
                    controller: lastNameController,
                    style: const TextStyle(color: Colors.white),
                    decoration: _inputDecoration("Last Name"),
                  ),
                  const SizedBox(height: 16),

                  TextField(
                    controller: mobileController,
                    keyboardType: TextInputType.phone,
                    style: const TextStyle(color: Colors.white),
                    decoration: _inputDecoration(
                      "Mobile Number",
                      suffixIcon: hasMobile
                          ? const Icon(
                              Icons.verified,
                              color: Colors.greenAccent,
                            )
                          : const Icon(
                              Icons.verified_outlined,
                              color: Colors.grey,
                            ),
                    ),
                  ),
                  const SizedBox(height: 30),

                  // ✅ Save Button or Loader
                  isSaving
                      ? const Center(
                          child: CircularProgressIndicator(
                            color: Colors.blueAccent,
                          ),
                        )
                      : ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blueAccent,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 60,
                              vertical: 14,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
                          ),
                          onPressed: _saveChanges,
                          child: const Text(
                            "Save Changes",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              letterSpacing: 1.1,
                            ),
                          ),
                        ),
                ],
              ),
            ),
    );
  }
}
