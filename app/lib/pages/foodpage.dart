import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';

class FamousFoodsPage extends StatefulWidget {
  const FamousFoodsPage({super.key});

  @override
  State<FamousFoodsPage> createState() => _FamousFoodsPageState();
}

class _FamousFoodsPageState extends State<FamousFoodsPage> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  final List<Map<String, String>> allFoods = [
    {
      'location': 'Delhi, India',
      'food': 'Chole Bhature',
      'image': 'assets/images/chole bhature.jpg',
    },
    {
      'location': 'Hyderabad, Telangana',
      'food': 'Hyderabadi Biryani',
      'image': 'assets/images/hyderabadi-biryani-recipe-chicken.jpg',
    },
    {
      'location': 'Mumbai, India',
      'food': 'Vada Pav',
      'image': 'assets/images/vada pav.jpg',
    },
    {
      'location': 'Kolkata, West Bengal',
      'food': 'Kathi Roll',
      'image': 'assets/images/cheeseburger-and-french-fries.jpg',
    },
    {
      'location': 'Vijayapura, Karnataka',
      'food': 'Jolada Rotti Oota',
      'image': 'assets/images/Bijapur-travel-guide_vacaywork-97.jpg',
    },
    {
      'location': 'Goa, India',
      'food': 'Goan Fish Curry',
      'image': 'assets/images/padthai.jpg',
    },
  ];

  @override
  Widget build(BuildContext context) {
    // Filter list based on search
    final filteredFoods = allFoods.where((item) {
      final query = _searchQuery.toLowerCase();
      return item['food']!.toLowerCase().contains(query) ||
          item['location']!.toLowerCase().contains(query);
    }).toList();

    return Scaffold(
      backgroundColor: const Color(0xfff3f6fb),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        centerTitle: true,
        title: const Text(
          'Famous Foods',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black),
        ),
      ),
      body: Column(
        children: [
          // --- SEARCH BAR ---
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(30),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  const Icon(Iconsax.search_normal_1, color: Colors.grey),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      onChanged: (value) {
                        setState(() => _searchQuery = value);
                      },
                      decoration: const InputDecoration(
                        hintText: "Search food or location...",
                        hintStyle: TextStyle(color: Colors.grey),
                        border: InputBorder.none,
                      ),
                    ),
                  ),
                  if (_searchQuery.isNotEmpty)
                    GestureDetector(
                      onTap: () {
                        _searchController.clear();
                        setState(() => _searchQuery = '');
                      },
                      child: const Icon(Icons.close, color: Colors.grey),
                    ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 8),

          // --- GRID OF FOODS ---
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: 0.8,
                ),
                itemCount: filteredFoods.length,
                itemBuilder: (context, index) {
                  final item = filteredFoods[index];
                  return MouseRegion(
                    cursor: SystemMouseCursors.click,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(16),
                      onTap: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              "${item['food']} from ${item['location']}",
                            ),
                          ),
                        );
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.grey.withOpacity(0.15),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Image Section
                            ClipRRect(
                              borderRadius: const BorderRadius.vertical(
                                top: Radius.circular(16),
                              ),
                              child: Image.asset(
                                item['image']!,
                                width: double.infinity,
                                height: 120,
                                fit: BoxFit.cover,
                              ),
                            ),

                            // Text Section
                            Padding(
                              padding: const EdgeInsets.all(12.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item['food']!,
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    item['location']!,
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: Colors.grey.shade600,
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
              ),
            ),
          ),
        ],
      ),
    );
  }
}
