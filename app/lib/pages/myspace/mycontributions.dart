import 'package:lokvista_app/pages/apifunctions/functions.dart';
import 'package:lokvista_app/pages/components/add_place_form.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class MyContributionPage extends StatefulWidget {
  final dynamic email;
  const MyContributionPage({super.key, required this.email});

  @override
  _MyContributionPageState createState() => _MyContributionPageState();
}

class _MyContributionPageState extends State<MyContributionPage> {
  var credits;
  var count;

  @override
  void initState() {
    super.initState();
    fetchUserData();
  }

  Future<void> fetchUserData() async {
    final FirebaseFirestore firestore = FirebaseFirestore.instance;
    final querySnapshot = await firestore
        .collection('users')
        .where('email', isEqualTo: widget.email)
        .get();

    try {
      if (querySnapshot.docs.isNotEmpty) {
        final userDoc = querySnapshot.docs.first;
        setState(() {
          count = userDoc['count'];
          credits = userDoc['credits'];
        });
      }
    } catch (e) {
      showSnackBar(context, "Error: $e");
    }
  }

  // 🔹 Stream of user's submitted places
  Stream<QuerySnapshot> getUserPlaces() {
    return FirebaseFirestore.instance
        .collection('usersubmittedplaces')
        .where('useremail', isEqualTo: widget.email)
        .snapshots();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,

      appBar: AppBar(
        title: const Text("My Contributions"),
        foregroundColor: Colors.white,
        backgroundColor: Colors.black,
        actions: [
          // ➕ Add new contribution icon
          IconButton(
            icon: const Icon(
              Icons.add_circle_outline,
              color: Colors.cyanAccent,
            ),
            tooltip: "Add Contribution",
            onPressed: () => showPopUp(context, widget.email),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10.0),
            child: Row(
              children: [
                const Icon(Icons.monetization_on, color: Colors.amberAccent),
                const SizedBox(width: 5),
                Text(
                  credits != null ? "$credits" : "...",
                  style: const TextStyle(
                    color: Colors.amberAccent,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),

      // 🔹 StreamBuilder showing live contributions
      body: StreamBuilder<QuerySnapshot>(
        stream: getUserPlaces(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: Colors.cyanAccent),
            );
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Color.fromARGB(255, 91, 91, 91),
                          Color.fromARGB(255, 150, 150, 150),
                        ],
                      ),
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      onPressed: () => showPopUp(context, widget.email),
                      icon: const Icon(Icons.add),
                      color: Colors.white,
                      iconSize: 40,
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    "You have not made any contributions yet",
                    style: TextStyle(color: Colors.white),
                  ),
                ],
              ),
            );
          }

          final places = snapshot.data!.docs;

          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: places.length,
            itemBuilder: (context, index) {
              final place = places[index];
              final placeId = place.id;
              final name = place['name'] ?? 'Unnamed Place';
              final city = place['city'] ?? 'Unknown City';
              final isVerified = place['verified'] ?? false;

              return FutureBuilder<QuerySnapshot>(
                future: FirebaseFirestore.instance
                    .collection('usersubmittedplaces')
                    .doc(placeId)
                    .collection('images')
                    .limit(1)
                    .get(),
                builder: (context, imgSnapshot) {
                  String? imageUrl;
                  if (imgSnapshot.hasData &&
                      imgSnapshot.data!.docs.isNotEmpty) {
                    imageUrl = imgSnapshot.data!.docs.first['url'];
                  }

                  return Card(
                    color: const Color(0xFF1E1E1E),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    margin: const EdgeInsets.symmetric(vertical: 10),
                    child: ListTile(
                      contentPadding: const EdgeInsets.all(12),

                      // Image preview
                      leading: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: imageUrl != null
                            ? Image.network(
                                imageUrl,
                                width: 70,
                                height: 70,
                                fit: BoxFit.cover,
                              )
                            : Container(
                                width: 70,
                                height: 70,
                                color: Colors.grey[800],
                                child: const Icon(
                                  Icons.image_not_supported,
                                  color: Colors.white54,
                                ),
                              ),
                      ),

                      title: Text(
                        name,
                        style: const TextStyle(
                          color: Colors.cyanAccent,
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            city,
                            style: const TextStyle(color: Colors.white70),
                          ),
                          const SizedBox(height: 5),
                          Row(
                            children: [
                              Icon(
                                isVerified
                                    ? Icons.verified_rounded
                                    : Icons.hourglass_bottom_rounded,
                                color: isVerified
                                    ? Colors.greenAccent
                                    : Colors.amberAccent,
                                size: 18,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                isVerified
                                    ? "Verified"
                                    : "Pending Verification",
                                style: TextStyle(
                                  color: isVerified
                                      ? Colors.greenAccent
                                      : Colors.amberAccent,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      trailing: const Icon(
                        Icons.arrow_forward_ios,
                        color: Colors.cyanAccent,
                        size: 18,
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}

// 🔹 Dialog for selecting contribution type
void showPopUp(BuildContext context, String email) {
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return Dialog(
        backgroundColor: const Color.fromARGB(255, 39, 39, 39),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(25.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                "Select your area of contribution",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.8,
                ),
              ),
              const SizedBox(height: 25),

              // Tourism Place Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () async {
                    Navigator.pop(context);
                    final result = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            AddPlaceForm(email: email, area: "tourist"),
                      ),
                    );
                    if (result == true && context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text("Contribution added successfully!"),
                        ),
                      );
                    }
                  },
                  icon: const Icon(Icons.place, color: Colors.black),
                  label: const Text(
                    "Tourist Place",
                    style: TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.cyanAccent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    elevation: 6,
                  ),
                ),
              ),

              const SizedBox(height: 15),

              // Cultural Event Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () async {
                    Navigator.pop(context);
                    final result = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            AddPlaceForm(email: email, area: "cultural"),
                      ),
                    );
                    if (result == true && context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text("Contribution added successfully!"),
                        ),
                      );
                    }
                  },
                  icon: const Icon(Icons.festival, color: Colors.black),
                  label: const Text(
                    "Cultural Event",
                    style: TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.cyanAccent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    elevation: 6,
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // Cancel Button
              Align(
                alignment: Alignment.bottomRight,
                child: TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text(
                    "Cancel",
                    style: TextStyle(
                      color: Colors.redAccent,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}
