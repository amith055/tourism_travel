import 'package:app/pages/contributors_pages/mycontributions.dart';
import 'package:flutter/material.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'ApiFunctions/functions.dart';

class ProfileScreen extends StatefulWidget {
  final VoidCallback onLogout;

  final dynamic email; // Add this

  const ProfileScreen({super.key, required this.onLogout, required this.email});
  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

var fname;
var lname;
var simpledata;

class _ProfileScreenState extends State<ProfileScreen> {
  File? _profileImage;

  @override
  void initState() {
    super.initState();

    fetchdetails();
  }

  Future<void>? fetchdetails() async {
    QuerySnapshot data =
        await FirebaseFirestore.instance
            .collection('users')
            .where('email', isEqualTo: widget.email)
            .get();
    simpledata = data.docs[0];
    setState(() {
      fname = simpledata['firstName'];
      lname = simpledata['lastName'];
    });
  }

  Future<void> _pickProfileImage() async {
    final pickedFile = await ImagePicker().pickImage(
      source: ImageSource.gallery,
    );

    if (pickedFile != null) {
      setState(() {
        _profileImage = File(pickedFile.path);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
      ),
      body:
          simpledata == null
              ? Center(child: CircularProgressIndicator())
              : Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        Stack(
                          alignment: Alignment.bottomRight,
                          children: [
                            CircleAvatar(
                              radius: 50,
                              backgroundColor: Colors.grey[800],
                              backgroundImage:
                                  _profileImage != null
                                      ? FileImage(_profileImage!)
                                      : null,
                              child:
                                  _profileImage == null
                                      ? Icon(
                                        Icons.person,
                                        size: 50,
                                        color: Colors.white,
                                      )
                                      : null,
                            ),
                            Positioned(
                              bottom: 0,
                              right: 4,
                              child: GestureDetector(
                                onTap: _pickProfileImage,
                                child: CircleAvatar(
                                  radius: 16,
                                  backgroundColor: Colors.blue,
                                  child: Icon(
                                    Icons.edit,
                                    size: 16,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 12),
                        Text(
                          "$fname $lname",
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        Text(
                          widget.email,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        SizedBox(height: 4),
                      ],
                    ),
                  ),
                  Divider(color: Colors.grey),

                  // Menu List
                  Expanded(
                    child: ListView(
                      children: [
                        simpledata['is_contributor']
                            ? buildListTile("My Contributions", () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder:
                                      (context) => MyContributionPage(
                                        email: widget.email,
                                      ),
                                ),
                              );
                            }, Icons.star)
                            : buildListTile("Become a Contributor", () {
                              showPopupMenu(context, () {
                                setState(() {
                                  fetchdetails();
                                });
                              });
                            }, Icons.star),
                        buildListTile("Edit Profile", () {}, Icons.edit),
                        buildListTile("My Trips", () {}, Icons.card_travel),
                        buildListTile("Favorites", () {}, Icons.favorite),
                        buildListTile("Change Password", () {}, Icons.lock),
                        buildListTile("Settings", () {}, Icons.settings),
                        buildListTile("About", () {}, Icons.info),
                        buildListTile(
                          "Help & Legal",
                          () {},
                          Icons.help_outline,
                        ),
                        buildListTile(
                          "Logout",
                          widget.onLogout,
                          Icons.logout,
                          color: Colors.red,
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
    func,
    IconData icon, {
    Color color = Colors.white,
  }) {
    return ListTile(
      leading: Icon(icon, color: color),
      title: Text(title, style: TextStyle(color: color)),
      trailing: Icon(Icons.arrow_forward_ios, size: 16, color: color),
      onTap: func,
    );
  }
}

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
              width: 520, // wider popup box
              decoration: BoxDecoration(
                color: const Color(0xFF0D0D0D), // modern solid black background
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
                      letterSpacing: 0.4,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  Divider(color: Colors.white.withOpacity(0.2), thickness: 1),
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

6. *Verification*
All submitted places, images, and location data will undergo verification by our team or organization before publishing. Duplicates or copied places will be rejected.

7. *Rewards*
Rewards are offered upon successful verification of your submissions. The reward type and quantity are determined by the organization and may vary.

8. *Liability Disclaimer*
LokVisit is not responsible for any inaccuracies or losses arising from user-submitted data or third-party integrations.

9. *Modifications*
We may update these terms periodically. Continued use of the app signifies your acceptance of any changes.

10. *Contact*
For any questions or concerns, please contact us at lokvisit.support@gmail.com.

Thank you for contributing to LokVisit and helping promote culture and tourism responsibly!""",
                        style: TextStyle(
                          color: Color(0xFFD8D8D8),
                          height: 1.45,
                          fontSize: 14.5,
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
                          style: TextStyle(color: Colors.white70, fontSize: 14),
                        ),
                      ],
                    )
                  else
                    const Text(
                      "Scroll down to read all terms...",
                      style: TextStyle(color: Colors.white38, fontSize: 12),
                    ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(
                            0xFFFF3B30,
                          ), // modern red
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 12,
                          ),
                          elevation: 3,
                        ),
                        onPressed: () {
                          Navigator.of(context).pop(false);
                        },
                        child: const Text(
                          "Reject",
                          style: TextStyle(fontWeight: FontWeight.w500),
                        ),
                      ),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              isChecked
                                  ? const Color(0xFF00E676) // neon green
                                  : const Color.fromARGB(
                                    255,
                                    78,
                                    102,
                                    75,
                                  ), // inactive dark gray
                          foregroundColor:
                              isChecked ? Colors.black : Colors.white54,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 30,
                            vertical: 12,
                          ),
                          elevation: 3,
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
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 15,
                          ),
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
