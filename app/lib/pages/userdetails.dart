import 'dart:io';
import 'package:app/pages/myspace/about.dart';
import 'package:app/pages/myspace/changepass.dart';
import 'package:app/pages/myspace/chatpage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:app/pages/myspace/mycontributions.dart';
import 'package:app/pages/myspace/myprofile.dart';
import 'ApiFunctions/functions.dart';

class ProfileScreen extends StatefulWidget {
  final VoidCallback onLogout;
  final dynamic email;

  const ProfileScreen({super.key, required this.onLogout, required this.email});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

// global placeholders
var fname;
var lname;
var simpledata;

class _ProfileScreenState extends State<ProfileScreen> {
  File? _profileImage;
  String? _profileImageUrl; // <-- fetched from Firestore

  @override
  void initState() {
    super.initState();
    fetchDetails();
  }

  Future<void> fetchDetails() async {
    try {
      QuerySnapshot snapshot =
          await FirebaseFirestore.instance
              .collection('users')
              .where('email', isEqualTo: widget.email)
              .get();

      if (snapshot.docs.isNotEmpty) {
        simpledata = snapshot.docs.first;

        setState(() {
          fname = simpledata['firstName'];
          lname = simpledata['lastName'];
          if (simpledata['profileImage'] != null) {
            _profileImageUrl = simpledata['profileImage'];
          }
        });
      }
    } catch (e) {
      print("Error fetching user details: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: const Text("Profile", style: TextStyle(color: Colors.white)),
        centerTitle: true,
      ),
      body:
          simpledata == null
              ? const Center(child: CircularProgressIndicator())
              : Column(
                children: [
                  // Profile section
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        Stack(
                          alignment: Alignment.bottomRight,
                          children: [
                            CircleAvatar(
                              radius: 55,
                              backgroundColor: Colors.grey[800],
                              backgroundImage:
                                  _profileImage != null
                                      ? FileImage(_profileImage!)
                                      : (_profileImageUrl != null &&
                                          _profileImageUrl!.isNotEmpty)
                                      ? NetworkImage(_profileImageUrl!)
                                      : null,
                              child:
                                  (_profileImage == null &&
                                          (_profileImageUrl == null ||
                                              _profileImageUrl!.isEmpty))
                                      ? const Icon(
                                        Icons.person,
                                        size: 55,
                                        color: Colors.white,
                                      )
                                      : null,
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          "$fname $lname",
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        Text(
                          widget.email,
                          style: const TextStyle(
                            fontSize: 15,
                            color: Colors.white70,
                          ),
                        ),
                        const SizedBox(height: 8),
                      ],
                    ),
                  ),

                  const Divider(color: Colors.white24),

                  // Menu section
                  Expanded(
                    child: ListView(
                      children: [
                        simpledata['is_contributor']
                            ? buildListTile("My Contributions", Icons.star, () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder:
                                      (context) => MyContributionPage(
                                        email: widget.email,
                                      ),
                                ),
                              );
                            })
                            : buildListTile(
                              "Become a Contributor",
                              Icons.star,
                              () {
                                showPopupMenu(context, () {
                                  setState(() {
                                    fetchDetails();
                                  });
                                });
                              },
                            ),

                        buildListTile("Edit Profile", Icons.edit, () async {
                          // Example inside ProfileScreen
                          final shouldReload = await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder:
                                  (context) =>
                                      MyProfilePage(email: widget.email),
                            ),
                          );

                          // ✅ If user saved changes, reload data
                          if (shouldReload == true) {
                            fetchDetails(); // or setState(() => load data again)
                          }
                        }),
                        buildListTile("My Trips", Icons.card_travel, () {}),
                        buildListTile("Favorites", Icons.favorite, () {}),
                        buildListTile("Change Password", Icons.lock, () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ChangePasswordPage(),
                            ),
                          );
                        }),
                        buildListTile("Settings", Icons.settings, () {}),
                        buildListTile("About", Icons.info, () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => AboutPage(),
                            ),
                          );
                        }),
                        buildListTile("AI Assistant", Icons.chat, () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => Ai_assistant(),
                            ),
                          );
                        }),
                        buildListTile(
                          "Logout",
                          Icons.logout,
                          widget.onLogout,
                          color: Colors.redAccent,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
    );
  }

  Widget buildListTile(
    String title,
    IconData icon,
    VoidCallback onTap, {
    Color color = Colors.white,
  }) {
    return ListTile(
      leading: Icon(icon, color: color),
      title: Text(title, style: TextStyle(color: color)),
      trailing: const Icon(
        Icons.arrow_forward_ios,
        size: 16,
        color: Colors.white70,
      ),
      onTap: onTap,
    );
  }
}

/// POPUP FOR CONTRIBUTOR TERMS
void showPopupMenu(BuildContext context, VoidCallback onRefresh) {
  bool isChecked = false;
  final ScrollController scrollController = ScrollController();
  bool isAtBottom = false;

  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (BuildContext context) {
      return StatefulBuilder(
        builder: (context, setState) {
          scrollController.addListener(() {
            if (scrollController.offset >=
                    scrollController.position.maxScrollExtent &&
                !scrollController.position.outOfRange) {
              setState(() {
                isAtBottom = true;
              });
            }
          });

          return Dialog(
            insetPadding: const EdgeInsets.symmetric(
              horizontal: 20,
              vertical: 40,
            ),
            alignment: Alignment.center,
            backgroundColor: Colors.transparent,
            child: Container(
              padding: const EdgeInsets.all(20),
              width: 520,
              decoration: BoxDecoration(
                color: const Color(0xFF0D0D0D),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white24, width: 1.2),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.6),
                    blurRadius: 15,
                    spreadRadius: 2,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    "Terms and Conditions",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Divider(color: Colors.white24),
                  const SizedBox(height: 10),
                  SizedBox(
                    height: 450,
                    child: SingleChildScrollView(
                      controller: scrollController,
                      child: const Text(
                        """Welcome to LokVisit!

Please read these Terms and Conditions carefully before using our app. By accessing or using LokVisit, you agree to be bound by these terms.

1. *Acceptance of Terms*
By using this app, you agree to comply with and be legally bound by these terms of service.

2. *User Responsibilities*
Users must provide accurate information and respect community guidelines. Misuse, spam, or offensive content may result in suspension.

3. *Content Submission*
By submitting cultural or tourism-related data, you grant LokVisit the right to display and use it for informational and promotional purposes.

4. *Privacy Policy*
Your data is collected and stored securely. We do not share personal information without your consent.

5. *Location Access*
This app uses location services to display nearby cultural and tourist places. You may disable location access anytime in your device settings.

6. **Verification**
All submitted places, images, and location data will undergo verification by our team or organization before publishing. Duplicates or copied places will be rejected.

7. **Rewards**
Rewards are offered upon successful verification of your submissions. The reward type and quantity are determined by the organization and may vary.

8. **Liability Disclaimer**
LokVisit is not responsible for any inaccuracies or losses arising from user-submitted data or third-party integrations.

9. *Modifications*
We may update these terms periodically. Continued use of the app signifies your acceptance of any changes.

10. **Contact**
For any questions or concerns, please contact us at lokvisit.support@gmail.com.

Thank you for contributing to LokVisit and helping promote culture and tourism responsibly!""",
                        style: TextStyle(
                          color: Colors.white70,
                          height: 1.5,
                          fontSize: 14,
                        ),
                        textAlign: TextAlign.justify,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (isAtBottom)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Checkbox(
                          value: isChecked,
                          activeColor: Colors.greenAccent,
                          onChanged: (value) {
                            setState(() {
                              isChecked = value ?? false;
                            });
                          },
                        ),
                        const Text(
                          "I agree to the Terms & Conditions",
                          style: TextStyle(color: Colors.white70),
                        ),
                      ],
                    )
                  else
                    const Text(
                      "Scroll down to read all terms...",
                      style: TextStyle(color: Colors.white38, fontSize: 12),
                    ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFFF3B30),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 12,
                          ),
                        ),
                        onPressed: () => Navigator.of(context).pop(false),
                        child: const Text("Reject"),
                      ),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              isChecked
                                  ? const Color(0xFF00E676)
                                  : const Color(0xFF2F2F2F),
                          foregroundColor:
                              isChecked ? Colors.black : Colors.white54,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 30,
                            vertical: 12,
                          ),
                        ),
                        onPressed:
                            isChecked
                                ? () async {
                                  await updateContributorStatus(
                                    context,
                                    simpledata['email'],
                                  );
                                  Navigator.of(context).pop(true);
                                  onRefresh();
                                }
                                : null,
                        child: const Text(
                          "Become Contributor",
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      );
    },
  );
}
