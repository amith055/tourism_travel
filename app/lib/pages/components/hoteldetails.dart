import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class HotelDetailsPage extends StatefulWidget {
  final String hotelId;

  const HotelDetailsPage({super.key, required this.hotelId});

  @override
  State<HotelDetailsPage> createState() => _HotelDetailsPageState();
}

class _HotelDetailsPageState extends State<HotelDetailsPage> {
  Map<String, dynamic>? hotelData;
  bool loading = true;

  @override
  void initState() {
    super.initState();
    fetchHotelDetails();
  }

  Future<void> fetchHotelDetails() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('hotels')
          .doc(widget.hotelId)
          .get();

      if (doc.exists) {
        setState(() {
          hotelData = doc.data();
          loading = false;
        });
      } else {
        setState(() => loading = false);
      }
    } catch (e) {
      print('Error fetching hotel details: $e');
      setState(() => loading = false);
    }
  }

  Widget _buildPhotoSection(String title, List<dynamic>? photos) {
    if (photos == null || photos.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        SizedBox(
          height: 120,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: photos.length,
            itemBuilder: (context, index) {
              return Container(
                margin: const EdgeInsets.only(right: 8),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Image.network(
                    photos[index],
                    width: 160,
                    height: 120,
                    fit: BoxFit.cover,
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(child: CircularProgressIndicator(color: Colors.white)),
      );
    }

    if (hotelData == null) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: Text(
            "Hotel not found.",
            style: TextStyle(color: Colors.white70),
          ),
        ),
      );
    }

    final basicInfo = hotelData!['basicInfo'] ?? {};
    final ownerInfo = hotelData!['ownerInfo'] ?? {};
    final photos = hotelData!['photos'] ?? {};

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text(basicInfo['name'] ?? 'Hotel Details'),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Divider(color: Colors.white24),
            Text(
              "Hotel Information",
              style: const TextStyle(
                color: Colors.tealAccent,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              "Type: ${basicInfo['type'] ?? 'N/A'}\n"
              "Address: ${basicInfo['address'] ?? 'N/A'}\n"
              "City: ${basicInfo['city'] ?? 'N/A'}\n"
              "Email: ${basicInfo['contactEmail'] ?? 'N/A'}",
              style: const TextStyle(color: Colors.white70, height: 1.5),
            ),

            const SizedBox(height: 16),

            // 👤 Owner Info
            Text(
              "Owner Information",
              style: const TextStyle(
                color: Colors.tealAccent,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              "Name: ${ownerInfo['name'] ?? 'N/A'}\n"
              "Contact: ${ownerInfo['contact'] ?? 'N/A'}\n"
              "Email: ${ownerInfo['email'] ?? 'N/A'}",
              style: const TextStyle(color: Colors.white70, height: 1.5),
            ),

            const SizedBox(height: 30),

            _buildPhotoSection(
              "Exterior",
              (photos['exterior'] as List?)?.cast<String>(),
            ),

            // 🍽️ Dining Photos
            _buildPhotoSection(
              "Dining",
              (photos['dining'] as List?)?.cast<String>(),
            ),

            // 🛏️ Room Photos
            _buildPhotoSection(
              "Rooms",
              (photos['rooms'] as List?)?.cast<String>(),
            ),
            const SizedBox(height: 30),
            // 🏨 Book Now Button
            Center(
              child: ElevatedButton(
                onPressed: () {
                  _showBookingDialog(context, hotelData!);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.tealAccent,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 40,
                    vertical: 14,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: const Text(
                  "Book Now",
                  style: TextStyle(color: Colors.black, fontSize: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showBookingDialog(BuildContext context, Map<String, dynamic> hotel) {
    int selectedPeople = 1;
    bool paymentDone = false;
    List<TextEditingController> nameControllers = [TextEditingController()];
    var pricePerPerson =
        int.tryParse(hotel['pricing']['price12h'].toString()) ?? 1000;

    DateTime? selectedCheckInDate;
    int totalBill = pricePerPerson;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              title: Text(
                "Book ${hotel['basicInfo']['name'] ?? 'Hotel'}",
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              content: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("Number of People:"),
                    const SizedBox(height: 8),
                    DropdownButton<int>(
                      value: selectedPeople,
                      isExpanded: true,
                      items: List.generate(10, (index) {
                        int value = index + 1;
                        return DropdownMenuItem(
                          value: value,
                          child: Text(value.toString()),
                        );
                      }),
                      onChanged: (value) {
                        if (value != null) {
                          setState(() {
                            selectedPeople = value;
                            totalBill = pricePerPerson * selectedPeople;

                            if (nameControllers.length < selectedPeople) {
                              nameControllers.addAll(
                                List.generate(
                                  selectedPeople - nameControllers.length,
                                  (_) => TextEditingController(),
                                ),
                              );
                            } else if (nameControllers.length >
                                selectedPeople) {
                              nameControllers.removeRange(
                                selectedPeople,
                                nameControllers.length,
                              );
                            }
                          });
                        }
                      },
                    ),

                    const SizedBox(height: 12),
                    const Text(
                      "Enter Names:",
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 8),
                    Column(
                      children: List.generate(selectedPeople, (index) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4.0),
                          child: TextField(
                            controller: nameControllers[index],
                            decoration: InputDecoration(
                              hintText: "Person ${index + 1} name",
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 12,
                              ),
                            ),
                          ),
                        );
                      }),
                    ),

                    const SizedBox(height: 15),
                    const Text(
                      "Check-in Date:",
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 8),
                    InkWell(
                      onTap: () async {
                        DateTime now = DateTime.now();
                        final pickedDate = await showDatePicker(
                          context: context,
                          initialDate: now,
                          firstDate: now,
                          lastDate: DateTime(now.year + 2),
                        );
                        if (pickedDate != null) {
                          setState(() {
                            selectedCheckInDate = pickedDate;
                          });
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          vertical: 12,
                          horizontal: 12,
                        ),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              selectedCheckInDate == null
                                  ? "Select check-in date"
                                  : "${selectedCheckInDate!.day}/${selectedCheckInDate!.month}/${selectedCheckInDate!.year}",
                              style: const TextStyle(fontSize: 14),
                            ),
                            const Icon(Icons.calendar_today, size: 18),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 15),
                    Row(
                      children: [
                        Checkbox(
                          value: paymentDone,
                          onChanged: (val) {
                            setState(() {
                              paymentDone = val ?? false;
                            });
                          },
                        ),
                        const Text("Payment done"),
                      ],
                    ),

                    const SizedBox(height: 10),
                    Text(
                      "Total Bill: ₹$totalBill",
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.teal,
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("Cancel"),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.teal),
                  onPressed: () async {
                    bool allNamesFilled = nameControllers.every(
                      (controller) => controller.text.trim().isNotEmpty,
                    );

                    if (!allNamesFilled) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text("Please fill all names"),
                          backgroundColor: Colors.red,
                        ),
                      );
                      return;
                    }

                    if (selectedCheckInDate == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text("Please select a check-in date"),
                          backgroundColor: Colors.red,
                        ),
                      );
                      return;
                    }

                    if (!paymentDone) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            "Please confirm payment before booking",
                          ),
                          backgroundColor: Colors.red,
                        ),
                      );
                      return;
                    }

                    // ✅ Save booking to Firestore
                    try {
                      final user = FirebaseAuth.instance.currentUser;
                      if (user == null) return;

                      final bookingData = {
                        'userId': user.uid,
                        'userEmail': user.email,
                        'hotelId': hotel['ownerId'],
                        'hotelName': hotel['basicInfo']['name'],
                        'people': selectedPeople,
                        'names': nameControllers.map((c) => c.text).toList(),
                        'checkInDate': selectedCheckInDate,
                        'totalBill': totalBill,
                        'paymentDone': paymentDone,
                        'bookedAt': FieldValue.serverTimestamp(),
                      };

                      final hotelQuery = await FirebaseFirestore.instance
                          .collection('hotels')
                          .where(
                            'basicInfo.name',
                            isEqualTo: hotel['basicInfo']['name'],
                          )
                          .limit(1)
                          .get();

                      if (hotelQuery.docs.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text("Hotel not found in Firestore!"),
                            backgroundColor: Colors.red,
                          ),
                        );
                        return;
                      }

                      final hotelDoc = hotelQuery.docs.first;
                      final hotelId = hotelDoc.id;
                      // Save in hotels/{hotelId}/bookedUsers
                      final hotelRef = FirebaseFirestore.instance
                          .collection('hotels')
                          .doc(hotelId)
                          .collection('bookedUsers')
                          .doc();

                      await hotelRef.set(bookingData);
                      final userQuery = await FirebaseFirestore.instance
                          .collection('users')
                          .where(
                            'email',
                            isEqualTo: user.email,
                          ) // user.email from FirebaseAuth
                          .limit(1)
                          .get();

                      if (userQuery.docs.isEmpty) {
                        print("User not found in Firestore!");
                        return;
                      }

                      final userDoc = userQuery.docs.first;
                      final userId = userDoc.id;
                      // Save in users/{userId}/myBookedHotels
                      final userRef = FirebaseFirestore.instance
                          .collection('users')
                          .doc(userId)
                          .collection('myBookedHotels')
                          .doc(hotelRef.id);

                      await userRef.set(bookingData);

                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            "✅ Booking confirmed for $selectedPeople people at ${hotel['name']} on ${selectedCheckInDate!.day}/${selectedCheckInDate!.month}/${selectedCheckInDate!.year}! Total: ₹$totalBill",
                          ),
                          backgroundColor: Colors.teal,
                        ),
                      );
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text("Error saving booking: $e"),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  },
                  child: const Text(
                    "Confirm Booking",
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
