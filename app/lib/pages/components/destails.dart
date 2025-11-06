import 'package:app/pages/ApiFunctions/apis.dart'; 
import 'package:app/pages/loginsignup.dart'; // <- fixed import
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';

class DetailPage extends StatefulWidget {
  final String title;
  final String imagePath;

  const DetailPage({super.key, required this.title, required this.imagePath});

  @override
  State<DetailPage> createState() => _DetailPageState();
}

class _DetailPageState extends State<DetailPage> {
  String selectedSection = 'Details';
  LatLng latLng = const LatLng(0, 0);

  Map<String, String> placeDetails = {};
  List<Map<String, dynamic>> reviews = [];
  List<String> images = [];

  bool _hasReviewed = false;
  double averageRating = 0.0;
  int reviewCount = 0;

  @override
  void initState() {
    super.initState();
    getdetails();
    _getCurrentLocation();
    _loadReviews();
  }

  Future<void> _getCurrentLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return;
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.deniedForever) return;
    Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high);
    setState(() {
      // not used directly in this file, but kept as in original
      latLng = LatLng(position.latitude, position.longitude);
    });
  }

  Future<void> getdetails() async {
    placeDetails = await getplacedetails(widget.title);
    latLng = await getlatlong(widget.title);
    images = await getimages(widget.title);
    setState(() {});
  }

  Future<void> _loadReviews() async {
    final snapshot = await FirebaseFirestore.instance
        .collection('reviews')
        .where('placeName', isEqualTo: widget.title)
        .get();

    final data = snapshot.docs.map((d) => d.data()).toList();

    final user = FirebaseAuth.instance.currentUser;
    final casted = <Map<String, dynamic>>[];
    for (var e in data) {
      if (e is Map<String, dynamic>) {
        casted.add(e);
      } else {
        // defensive fallback: try to convert
        casted.add(Map<String, dynamic>.from(e as Map));
      }
    }

    setState(() {
      reviews = casted;
      reviewCount = reviews.length;
      if (reviews.isNotEmpty) {
        double total = 0;
        for (var r in reviews) {
          final ratingObj = r['rating'];
          if (ratingObj is int) total += ratingObj.toDouble();
          else if (ratingObj is double) total += ratingObj;
          else if (ratingObj is num) total += ratingObj.toDouble();
        }
        averageRating = total / reviews.length;
      } else {
        averageRating = 0.0;
      }
      _hasReviewed =
          user != null && reviews.any((r) => (r['email'] as String?) == user.email);
    });
  }

  Future<void> _addReview(BuildContext context) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          backgroundColor: Colors.black87,
          title: const Text("Login Required", style: TextStyle(color: Colors.white)),
          content:
              const Text("Please login to add a review.", style: TextStyle(color: Colors.white70)),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                // direct push to your LoginScreen, with required callback param
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => LoginScreen(onLoginSuccess: () {}),
                  ),
                );
              },
              child: const Text("Login", style: TextStyle(color: Colors.blue)),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel", style: TextStyle(color: Colors.white70)),
            ),
          ],
        ),
      );
      return;
    }

    double rating = 0.0;
    final commentController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.black87,
        title: const Text("Add Review", style: TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text("Rate this place:", style: TextStyle(color: Colors.white70)),
            const SizedBox(height: 8),
            StatefulBuilder(
              builder: (context, setStarState) => Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(5, (i) {
                  return IconButton(
                    icon: Icon(i < rating ? Icons.star : Icons.star_border, color: Colors.amber),
                    onPressed: () {
                      setStarState(() {
                        rating = i + 1.0;
                      });
                    },
                  );
                }),
              ),
            ),
            TextField(
              controller: commentController,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                hintText: "Write your comment...",
                hintStyle: TextStyle(color: Colors.white54),
                enabledBorder:
                    UnderlineInputBorder(borderSide: BorderSide(color: Colors.white38)),
                focusedBorder:
                    UnderlineInputBorder(borderSide: BorderSide(color: Colors.blueAccent)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () async {
              if (rating == 0.0 || commentController.text.trim().isEmpty) return;
              await FirebaseFirestore.instance.collection('reviews').add({
                'placeName': widget.title,
                'email': user.email,
                'comment': commentController.text.trim(),
                'rating': rating,
                'timestamp': Timestamp.now(),
              });
              Navigator.pop(ctx);
              setState(() => _hasReviewed = true);
              await _loadReviews();
            },
            child: const Text("Submit", style: TextStyle(color: Colors.blue)),
          ),
        ],
      ),
    );
  }

  Widget _buildReviews() {
    // Use the locally loaded `reviews` for display (keeps UI consistent).
    // You can also use StreamBuilder for real-time updates (I can swap this if you prefer).
    if (reviews.isEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          Text('User Reviews:', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
          SizedBox(height: 10),
          Text('No reviews yet.', style: TextStyle(color: Colors.white70)),
          SizedBox(height: 80),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.star, color: Colors.amber, size: 24),
            const SizedBox(width: 6),
            Text(
              '${averageRating.toStringAsFixed(1)} / 5.0 ($reviewCount Reviews)',
              style: const TextStyle(color: Colors.white, fontSize: 16),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ...reviews.map((review) {
          final email = (review['email'] as String?) ?? 'Anonymous';
          final comment = (review['comment'] as String?) ?? '';
          final ratingNum = review['rating'];
          final rating = ratingNum is int ? ratingNum.toDouble() : (ratingNum is double ? ratingNum : 0.0);
          final timestamp = review['timestamp'];
          String dateText = '';
          if (timestamp is Timestamp) {
            final dt = timestamp.toDate();
            dateText = '${dt.day.toString().padLeft(2, '0')}-${dt.month.toString().padLeft(2, '0')}-${dt.year}';
          }

          return Container(
            margin: const EdgeInsets.symmetric(vertical: 6.0),
            padding: const EdgeInsets.all(12.0),
            decoration: BoxDecoration(color: Colors.white10, borderRadius: BorderRadius.circular(12)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  const Icon(Icons.person, color: Colors.white70),
                  const SizedBox(width: 8),
                  Text(email, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ]),
                const SizedBox(height: 6),
                Row(children: List.generate(5, (i) {
                  return Icon(i < rating ? Icons.star : Icons.star_border, color: Colors.amber, size: 16);
                })),
                const SizedBox(height: 6),
                Text(comment, style: const TextStyle(color: Colors.white70)),
                if (dateText.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(dateText, style: const TextStyle(color: Colors.grey, fontSize: 11)),
                ]
              ],
            ),
          );
        }).toList(),
        const SizedBox(height: 80),
      ],
    );
  }

  Widget _buildDetails() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: placeDetails.entries.map((entry) {
        final String key = entry.key[0].toUpperCase() + entry.key.substring(1);
        final String value = entry.value.toString();

        return Card(
          color: Colors.white10,
          margin: const EdgeInsets.symmetric(vertical: 6.0, horizontal: 4.0),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.label_outline, color: Colors.tealAccent, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: RichText(
                    text: TextSpan(
                      children: [
                        TextSpan(
                          text: '$key: ',
                          style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 16),
                        ),
                        TextSpan(
                          text: value,
                          style: const TextStyle(color: Colors.white70, fontSize: 16),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget showMaps() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 3),
      child: Card(
        color: Colors.white10,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        elevation: 4,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: SizedBox(
            height: 300,
            child: GoogleMap(
              initialCameraPosition: CameraPosition(target: latLng, zoom: 7),
              markers: {
                Marker(markerId: const MarkerId('location'), position: latLng, infoWindow: InfoWindow(title: widget.title)),
              },
              zoomControlsEnabled: false,
              myLocationButtonEnabled: false,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHotels() {
    final hotels = [
      {'name': 'Hotel Paradise', 'rating': 4.2},
      {'name': 'Nature Stay Inn', 'rating': 3.9},
      {'name': 'Budget Lodge', 'rating': 3.5},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: hotels.map((hotel) {
        final name = hotel['name']?.toString() ?? '';
        final rating = hotel['rating']?.toString() ?? '';
        return Card(
          color: Colors.white10,
          margin: const EdgeInsets.symmetric(vertical: 6.0, horizontal: 4.0),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: ListTile(
            leading: const Icon(Icons.hotel, color: Colors.tealAccent),
            title: Text(name, style: const TextStyle(color: Colors.white)),
            subtitle: Text('Rating: $rating', style: const TextStyle(color: Colors.white70)),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildImages() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: images.map((url) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: ClipRRect(borderRadius: BorderRadius.circular(16), child: Image.network(url, fit: BoxFit.cover)),
        );
      }).toList(),
    );
  }

  Widget _getSectionContent() {
    switch (selectedSection) {
      case 'Details':
        return _buildDetails();
      case 'Reviews':
        return _buildReviews();
      case 'Map':
        return showMaps();
      case 'Hotels':
        return _buildHotels();
      case 'Images':
        return _buildImages();
      default:
        return const Text("No content available.", style: TextStyle(color: Colors.white));
    }
  }

  Widget _functionLabel(String text) {
    final bool isSelected = selectedSection == text;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 6),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: isSelected ? Colors.white : const Color.fromARGB(255, 30, 30, 30),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white),
      ),
      child: TextButton(
        style: TextButton.styleFrom(
          backgroundColor: Colors.transparent,
          padding: EdgeInsets.zero,
          minimumSize: Size(54, 23),
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
        onPressed: () => setState(() => selectedSection = text),
        child: Text(text, style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: isSelected ? Colors.black : Colors.white)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      floatingActionButton: selectedSection == 'Reviews' && !_hasReviewed
          ? FloatingActionButton.extended(
              onPressed: () => _addReview(context),
              backgroundColor: Colors.amber,
              label: const Text('Add Comment', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
              icon: const Icon(Icons.add_comment, color: Colors.black),
            )
          : null,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Stack(
            children: [
              Container(
                height: 300,
                width: double.infinity,
                decoration: BoxDecoration(image: DecorationImage(image: NetworkImage(widget.imagePath), fit: BoxFit.cover)),
              ),
              Container(
                height: 300,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.transparent, Colors.black.withOpacity(0.8)],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
              ),
              Positioned(
                top: 40,
                left: 16,
                child: IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.white, size: 30),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
              Positioned(
                top: 40,
                right: 16,
                child: IconButton(
                  icon: const Icon(
                    Icons.favorite_border,
                    color: Colors.white,
                    size: 30,
                  ),
                  onPressed: () {},
                ),
              ),
              Positioned(
                bottom: 20,
                left: 16,
                right: 100,
                child: Text(
                  widget.title,
                  style: const TextStyle(
                    fontSize: 30,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    shadows: [Shadow(color: Colors.black, blurRadius: 6)],
                  ),
                ),
              ),
            ],
          ),
          Container(
            padding: EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: Colors.black,
              boxShadow: [
                BoxShadow(
                  color: Colors.black54,
                  blurRadius: 4,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Row(
                  children: [
                    _functionLabel("Details"),
                    _functionLabel("Reviews"),
                    _functionLabel("Map"),
                    _functionLabel("Hotels"),
                    _functionLabel("Images"), // <- Added Images section
                  ],
                ),
              ),
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.all(16),
              child: _getSectionContent(),
            ),
          ),
        ],

      ),
    );
  }
} 