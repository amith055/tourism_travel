import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cached_network_image/cached_network_image.dart';

class HotelsPage extends StatefulWidget {
  const HotelsPage({Key? key}) : super(key: key);

  @override
  State<HotelsPage> createState() => _HotelsPageState();
}

class _HotelsPageState extends State<HotelsPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text(
          "Hotels",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: StreamBuilder<QuerySnapshot>(
        // ✅ Fetch only verified hotels
        stream: _firestore
            .collection('hotels')
            .where('status', isEqualTo: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: Colors.white),
            );
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Text(
                "No verified hotels available.",
                style: TextStyle(color: Colors.white70, fontSize: 16),
              ),
            );
          }

          final hotels = snapshot.data!.docs;

          return ListView.builder(
            itemCount: hotels.length,
            padding: const EdgeInsets.all(12.0),
            itemBuilder: (context, index) {
              final hotel = hotels[index].data() as Map<String, dynamic>;

              final basicInfo = hotel['basicInfo'] ?? {};
              final photos = hotel['photos'] ?? {};
              final exterior = (photos['exterior'] as List?) ?? [];

              final imageUrl = exterior.isNotEmpty
                  ? exterior[0]
                  : 'https://via.placeholder.com/400x250.png?text=No+Image';

              return Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => HotelDetailPage(hotelData: hotel),
                      ),
                    );
                  },
                  child: Card(
                    color: Colors.grey[900],
                    margin: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 8,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Image section
                        ClipRRect(
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(16),
                          ),
                          child: CachedNetworkImage(
                            imageUrl: imageUrl,
                            height: 200,
                            width: double.infinity,
                            fit: BoxFit.cover,
                            placeholder: (context, url) => Container(
                              color: Colors.grey[800],
                              child: const Center(
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                ),
                              ),
                            ),
                            errorWidget: (context, url, error) => Container(
                              height: 200,
                              color: Colors.grey[850],
                              child: const Center(
                                child: Icon(
                                  Icons.broken_image,
                                  color: Colors.white70,
                                  size: 40,
                                ),
                              ),
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(14.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      basicInfo['name'] ?? 'Unnamed Hotel',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  const Icon(
                                    Icons.verified,
                                    color: Colors.blueAccent,
                                    size: 22,
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Row(
                                children: [
                                  const Icon(
                                    Icons.location_on,
                                    color: Colors.white70,
                                    size: 18,
                                  ),
                                  const SizedBox(width: 4),
                                  Expanded(
                                    child: Text(
                                      "${basicInfo['address'] ?? 'No address'}, ${basicInfo['city'] ?? ''}",
                                      style: const TextStyle(
                                        color: Colors.white70,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Row(
                                children: [
                                  const Icon(
                                    Icons.phone,
                                    color: Colors.white70,
                                    size: 18,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    hotel['ownerInfo']?['contact'] ??
                                        'No contact info',
                                    style: const TextStyle(
                                      color: Colors.white70,
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 6,
                                  horizontal: 12,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.green[800],
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Text(
                                  "VERIFIED",
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    letterSpacing: 1,
                                  ),
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
            },
          );
        },
      ),
    );
  }
}

class HotelDetailPage extends StatelessWidget {
  final Map<String, dynamic> hotelData;

  const HotelDetailPage({Key? key, required this.hotelData}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final basicInfo = hotelData['basicInfo'] ?? {};
    final ownerInfo = hotelData['ownerInfo'] ?? {};
    final photos = hotelData['photos'] ?? {};
    final exterior = (photos['exterior'] as List?) ?? [];
    final dining = (photos['dining'] as List?) ?? [];
    final rooms = (photos['rooms'] as List?) ?? [];

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Row(
          children: [
            Expanded(
              child: Text(
                basicInfo['name'] ?? 'Hotel Details',
                style: const TextStyle(color: Colors.white),
              ),
            ),
            const Icon(Icons.verified, color: Colors.blueAccent, size: 20),
          ],
        ),
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (exterior.isNotEmpty)
              CachedNetworkImage(
                imageUrl: exterior[0],
                height: 220,
                width: double.infinity,
                fit: BoxFit.cover,
              ),
            const SizedBox(height: 16),
            Text(
              basicInfo['name'] ?? '',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "${basicInfo['address'] ?? ''}, ${basicInfo['city'] ?? ''}",
              style: const TextStyle(color: Colors.white70, fontSize: 16),
            ),
            const SizedBox(height: 16),
            const Text(
              "Owner Details",
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              "${ownerInfo['name'] ?? ''} • ${ownerInfo['contact'] ?? ''}",
              style: const TextStyle(color: Colors.white70),
            ),
            const SizedBox(height: 16),
            const Text(
              "Gallery",
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            if (rooms.isNotEmpty) _buildImageList(rooms, "Rooms"),
            if (dining.isNotEmpty) _buildImageList(dining, "Dining"),
          ],
        ),
      ),
    );
  }

  Widget _buildImageList(List<dynamic> urls, String title) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(color: Colors.white70, fontSize: 14),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 120,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: urls.length,
            itemBuilder: (context, index) {
              return Padding(
                padding: const EdgeInsets.only(right: 8.0),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: CachedNetworkImage(
                    imageUrl: urls[index],
                    width: 150,
                    height: 120,
                    fit: BoxFit.cover,
                    placeholder: (context, url) =>
                        Container(color: Colors.grey[800]),
                    errorWidget: (context, url, error) =>
                        const Icon(Icons.broken_image, color: Colors.white70),
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }
}
