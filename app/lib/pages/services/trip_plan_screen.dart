import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:lokvista_app/pages/screens/place_map_screen.dart';
import '../models/place.dart';

class TripPlanScreen extends StatefulWidget {
  final List<PlaceModel> topPlaces;
  final double totalDistance;
  final String geminiApiKey;
  final String startAddress;
  final String endAddress;

  const TripPlanScreen({
    super.key,
    required this.topPlaces,
    required this.totalDistance,
    required this.geminiApiKey,
    required this.startAddress,
    required this.endAddress,
  });

  @override
  State<TripPlanScreen> createState() => _TripPlanScreenState();
}

class _TripPlanScreenState extends State<TripPlanScreen>
    with SingleTickerProviderStateMixin {
  bool _loading = false;
  List<Map<String, String>> _structuredPlan = [];

  late AnimationController _controller;
  late Animation<double> _fadeAnim;

  int _estimatedDays = 1;
  static const double _avgKmPerDay = 300.0; // typical by car
  static const int _placesPerDay = 5;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnim = CurvedAnimation(parent: _controller, curve: Curves.easeInOut);

    _calculateTripDays();
    _generateAITripPlan();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// 🚗 Estimate how many days are needed
  void _calculateTripDays() {
    // example: 850 km → ceil(850 / 300) = 3 days
    _estimatedDays = (widget.totalDistance / _avgKmPerDay).ceil().clamp(1, 10);

    debugPrint(
      "🧭 Estimated Days: $_estimatedDays based on distance ${widget.totalDistance} km",
    );
  }

  /// 🔮 Generate AI-powered trip plan
  Future<void> _generateAITripPlan() async {
    if (widget.topPlaces.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("No Gemini AI places available.")),
      );
      return;
    }

    setState(() {
      _loading = true;
      _structuredPlan = [];
    });

    try {
      // Split the total Gemini top places into chunks of 5 per day
      List<List<PlaceModel>> dailyPlans = [];
      int index = 0;
      while (index < widget.topPlaces.length) {
        dailyPlans.add(
          widget.topPlaces.skip(index).take(_placesPerDay).toList(),
        );
        index += _placesPerDay;
      }

      // Limit to estimated days (based on distance)
      dailyPlans = dailyPlans.take(_estimatedDays).toList();

      List<Map<String, String>> fullTripPlan = [];

      for (int day = 0; day < dailyPlans.length; day++) {
        final dayPlaces = dailyPlans[day];
        final dayPlaceList = dayPlaces
            .map((p) => "${p.name} (${p.rating}⭐) - ${p.address}")
            .join("\n");

        final prompt =
            """
You are a travel planner AI.

Plan a ${_estimatedDays}-day trip by car from:
Start: ${widget.startAddress}
End: ${widget.endAddress}
Total Distance: ${widget.totalDistance.toStringAsFixed(1)} km.

This is **Day ${day + 1}** of the trip.

Here are ${dayPlaces.length} must-visit tourist spots for this day:
$dayPlaceList

Each day covers roughly 300 km and includes around 5 stops.
Create a friendly, realistic schedule for this day in this structured JSON format:

[
  {"time": "09:00 AM", "title": "Mysore Palace", "description": "Explore royal architecture."},
  {"time": "10:30 AM", "title": "Kukkarahalli Lake", "description": "Walk around the serene lake."}
]

Include realistic travel times, short fun descriptions (2 lines max), and a lunch suggestion.
Return **only JSON**, no extra text.
""";

        final url = Uri.parse(
          'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent?key=${widget.geminiApiKey}',
        );
        final res = await http.post(
          url,
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            "contents": [
              {
                "parts": [
                  {"text": prompt},
                ],
              },
            ],
          }),
        );

        if (res.statusCode != 200) {
          throw Exception('Gemini request failed: ${res.statusCode}');
        }

        final data = jsonDecode(res.body);
        final text =
            data['candidates']?[0]?['content']?['parts']?[0]?['text'] ?? '';

        final jsonStart = text.indexOf('[');
        final jsonEnd = text.lastIndexOf(']');
        if (jsonStart != -1 && jsonEnd != -1) {
          final jsonStr = text.substring(jsonStart, jsonEnd + 1);
          final List<Map<String, dynamic>> dayPlan =
              List<Map<String, dynamic>>.from(jsonDecode(jsonStr));

          for (var e in dayPlan) {
            fullTripPlan.add({
              "time": e["time"].toString(),
              "title": "Day ${day + 1}: ${e["title"]}",
              "description": e["description"].toString(),
            });
          }
        }
      }

      setState(() => _structuredPlan = fullTripPlan);
      _controller.forward(from: 0);

      if (_structuredPlan.isNotEmpty) await _savePlanToFirebase();
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error: $e")));
    } finally {
      setState(() => _loading = false);
    }
  }

  /// 💾 Save plan to Firebase
  /// 💾 Save trip plan to Firebase inside user's subcollection "tripplans"
  Future<void> _savePlanToFirebase() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("User not logged in")));
        return;
      }

      // Reference to "users" collection
      final usersRef = FirebaseFirestore.instance.collection("users");

      // 🔍 Fetch user doc by email
      final userQuery = await usersRef
          .where("email", isEqualTo: user.email)
          .get();

      if (userQuery.docs.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("User document not found in Firestore")),
        );
        return;
      }

      final userDocId = userQuery.docs.first.id;

      // ✅ Create trip plan data
      final planData = {
        "startAddress": widget.startAddress,
        "endAddress": widget.endAddress,
        "totalDistance": widget.totalDistance,
        "estimatedDays": _estimatedDays,
        "createdAt": FieldValue.serverTimestamp(),
        "plan": _structuredPlan,
      };

      // Save into subcollection `tripplans`
      await usersRef.doc(userDocId).collection("tripplans").add(planData);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("✅ Plan saved to your Trip Plans!")),
      );
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("❌ Error saving plan: $e")));
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeColor = const Color.fromARGB(255, 100, 67, 160);

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(
          "🚗 ${_estimatedDays}-Day Trip Plan",
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      floatingActionButton: _buildGlassButtons(themeColor),
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF2083ED), Color(0xFFF7F9F9)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
          _loading
              ? const Center(
                  child: CircularProgressIndicator(color: Colors.white),
                )
              : FadeTransition(
                  opacity: _fadeAnim,
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(16, 80, 16, 100),
                    child: Column(
                      children: [
                        _buildHeaderCard(themeColor),
                        const SizedBox(height: 20),
                        if (_structuredPlan.isEmpty)
                          const Text(
                            "Generating itinerary...",
                            style: TextStyle(color: Colors.white, fontSize: 18),
                          )
                        else
                          _buildPlanCards(),
                      ],
                    ),
                  ),
                ),
        ],
      ),
    );
  }

  /// 🌍 Header
  Widget _buildHeaderCard(Color color) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color, const Color.fromARGB(255, 254, 255, 255)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          const BoxShadow(
            color: Colors.black26,
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "🌍 Gemini AI Trip Plan",
            style: TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "From: ${widget.startAddress}",
            style: const TextStyle(color: Colors.white70, fontSize: 16),
          ),
          Text(
            "To: ${widget.endAddress}",
            style: const TextStyle(color: Colors.white70, fontSize: 16),
          ),
          const SizedBox(height: 8),
          Text(
            "Distance: ${widget.totalDistance.toStringAsFixed(1)} km • $_estimatedDays days",
            style: const TextStyle(color: Colors.white, fontSize: 15),
          ),
        ],
      ),
    );
  }

  /// 🧩 Itinerary cards
  Widget _buildPlanCards() {
    return Column(
      children: _structuredPlan.map((step) {
        final time = step["time"] ?? "";
        final title = step["title"] ?? "";
        final desc = step["description"] ?? "";

        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            boxShadow: const [
              BoxShadow(
                color: Colors.black12,
                blurRadius: 8,
                offset: Offset(0, 3),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  time,
                  style: const TextStyle(
                    color: Colors.grey,
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  desc,
                  style: TextStyle(
                    color: Colors.grey.shade800,
                    fontSize: 15,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 8),
                GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => PlaceMapScreen(
                          placeName: title,
                          googleApiKey: widget.geminiApiKey,
                        ),
                      ),
                    );
                  },
                  child: Row(
                    children: const [
                      Icon(
                        Icons.location_on_outlined,
                        size: 16,
                        color: Colors.teal,
                      ),
                      SizedBox(width: 4),
                      Text(
                        "Tap to view on map",
                        style: TextStyle(
                          color: Colors.teal,
                          fontSize: 13,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  /// 💎 Buttons
  Widget _buildGlassButtons(Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        GestureDetector(
          onTap: _generateAITripPlan,
          child: _glassButton(Icons.refresh, "Regenerate Plan", color),
        ),
        const SizedBox(width: 12),
        GestureDetector(
          onTap: _savePlanToFirebase,
          child: _glassButton(Icons.save, "Save Plan", Colors.blueAccent),
        ),
      ],
    );
  }

  Widget _glassButton(IconData icon, String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color.withOpacity(0.9), const Color(0xFF82C9C2)],
        ),
        borderRadius: BorderRadius.circular(30),
        boxShadow: const [
          BoxShadow(color: Colors.black26, blurRadius: 8, offset: Offset(0, 4)),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white),
          const SizedBox(width: 8),
          Text(
            text,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
