import 'package:lokvista_app/pages/components/details.dart';
import 'package:flutter/material.dart';
import 'ApiFunctions/apis.dart';
import 'components/details.dart'; // Make sure you import the details page

class ExplorePage extends StatefulWidget {
  const ExplorePage({super.key});

  @override
  State<ExplorePage> createState() => _ExplorePageState();
}

class _ExplorePageState extends State<ExplorePage> {
  final TextEditingController _searchController = TextEditingController();
  bool _isSearching = false;
  bool _isLoading = false;
  String _searchQuery = '';
  bool istourism = true;
  String title = "Tourism Places";

  late List<Map<String, String>> episodes = [];

  @override
  void initState() {
    super.initState();
    getdata();
  }

  void getdata() async {
    setState(() {
      _isLoading = true;
    });

    if (istourism) {
      episodes = await getalltouristplaces();
    } else {
      episodes = await getallculturalplaces();
    }

    setState(() {
      _isLoading = false;
    });
  }

  List<Map<String, String>> get _filteredEpisodes {
    if (_searchQuery.isEmpty) return episodes;
    return episodes
        .where(
          (ep) =>
              ep['title']!.toLowerCase().contains(_searchQuery.toLowerCase()),
        )
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          CustomScrollView(
            slivers: [
              SliverAppBar(
                floating: true,
                snap: true,
                backgroundColor: Colors.black,
                toolbarHeight: 50,
                title: _isSearching
                    ? TextField(
                        controller: _searchController,
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          hintText: 'Search $title',
                          hintStyle: TextStyle(color: Colors.grey),
                          border: InputBorder.none,
                        ),
                        onChanged: (value) {
                          setState(() {
                            _searchQuery = value;
                          });
                        },
                      )
                    : Text(
                        'Explore Latest $title',
                        style: TextStyle(color: Colors.white),
                      ),
                actions: [
                  IconButton(
                    icon: Icon(_isSearching ? Icons.close : Icons.search),
                    onPressed: () {
                      setState(() {
                        if (_isSearching) {
                          _searchController.clear();
                          _searchQuery = '';
                        }
                        _isSearching = !_isSearching;
                      });
                    },
                  ),
                ],
              ),
              SliverPadding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 12,
                ),
                sliver: SliverGrid(
                  delegate: SliverChildBuilderDelegate((context, index) {
                    final episode = _filteredEpisodes[index];
                    return GestureDetector(
                      onTap: () {
                        // Navigate to the DetailsPage when tapped
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => DetailPage(
                              title: episode['title']!,
                              imagePath: episode['image']!,
                            ),
                          ),
                        );
                      },
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Stack(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(6),
                                child: Image.network(
                                  episode['image']!,
                                  width: double.infinity,
                                  height: 100,
                                  fit: BoxFit.cover,
                                ),
                              ),
                              Positioned(
                                bottom: 6,
                                right: 6,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 2,
                                  ),
                                  color: Colors.black54,
                                  child: Text(
                                    episode['city']!,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            episode['title']!,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            episode['city']!,
                            style: const TextStyle(
                              color: Colors.grey,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    );
                  }, childCount: _filteredEpisodes.length),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 8,
                    childAspectRatio: 1.2,
                  ),
                ),
              ),
            ],
          ),
          // Floating bar
          Positioned(
            left: 16,
            right: 16,
            bottom: 40,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(30),
                gradient: const LinearGradient(
                  colors: [Color(0xFF1E1E1E), Color(0xFF2D2D2D)],
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  InkWell(
                    onTap: () async {
                      setState(() {
                        title = "Tourism Places";
                        istourism = true;
                      });
                      getdata();
                    },
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.transparent,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Text(
                        'Tourism',
                        style: TextStyle(color: Colors.white, fontSize: 14),
                      ),
                    ),
                  ),
                  InkWell(
                    onTap: () async {
                      setState(() {
                        title = "Cultural Places";
                        istourism = false;
                      });
                      getdata();
                    },
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.transparent,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Text(
                        'Culture',
                        style: TextStyle(color: Colors.white, fontSize: 14),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
