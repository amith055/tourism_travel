import 'package:lokvista_app/pages/allhotels.dart';
import 'package:lokvista_app/pages/apifunctions/functions.dart';
import 'package:lokvista_app/pages/components/all_places.dart';
import 'package:lokvista_app/pages/foodpage.dart';
import 'package:lokvista_app/pages/screens/map_screen.dart';
import 'package:lokvista_app/pages/culturehome.dart';
import 'package:lokvista_app/pages/loginsignup.dart';
import 'package:lokvista_app/pages/tourismhome.dart';
import 'package:lokvista_app/pages/userdetails.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:lokvista_app/pages/apifunctions/apis.dart';
import 'package:iconsax/iconsax.dart';
import 'components/details.dart';
import 'explorehome.dart';
import 'package:shimmer/shimmer.dart';

class MainPage extends StatefulWidget {
  final dynamic login;

  final dynamic email;

  const MainPage({super.key, required this.login, this.email});

  @override
  State<MainPage> createState() => _MainPageState();
}

int _selectedIndex = 0;
bool isLoggedIn = false;

class _MainPageState extends State<MainPage> {
  @override
  void initState() {
    super.initState();
    isLoggedIn = widget.login;
  }

  void handleLoginSuccess() {
    setState(() {
      isLoggedIn = true;
      _selectedIndex = 4;
    });
  }

  void handleLogout() async {
    await FirebaseAuth.instance.signOut();
    setState(() {
      isLoggedIn = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> _pages = [
      HomePage(button: false),
      TourismHome(email: widget.email),
      ExplorePage(),
      CultureHome(),
      // Show MySpacePage if logged in, otherwise LoginScreen
      isLoggedIn
          ? ProfileScreen(onLogout: handleLogout, email: widget.email)
          : LoginScreen(onLoginSuccess: handleLoginSuccess),
    ];

    return Scaffold(
      backgroundColor: Colors.black,
      body: _pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: Colors.black,
        selectedItemColor: Colors.white,
        unselectedItemColor: Colors.grey,
        currentIndex: _selectedIndex,
        type: BottomNavigationBarType.fixed,
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        items: [
          const BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          const BottomNavigationBarItem(
            icon: Icon(Icons.travel_explore),
            label: 'Tourism',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.bolt),
            label: 'Explore',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.festival_outlined),
            label: 'Culture',
          ),
          isLoggedIn
              ? BottomNavigationBarItem(
                  icon: const Icon(Icons.person),
                  label: 'My Space',
                )
              : BottomNavigationBarItem(
                  icon: const Icon(Icons.person),
                  label: 'Login',
                ),
        ],
      ),
    );
  }
}

class HomePage extends StatefulWidget {
  final bool button;

  const HomePage({super.key, required this.button});
  @override
  State<HomePage> createState() => _BannerWithCarouselPageState();
}

List<Map<String, String>> bannerItems = [];
List<Map<String, String>> placesbyseason = [];
List<Map<String, String>> upcomingfest = [];
List<Map<String, String>> highratedplaces = [];
List<List<Map<String, String>>> allinone = [];
late List<bool> _showSeeMoreList;
late List<ScrollController> _scrollControllers;
bool _isDataLoaded = false;

class _BannerWithCarouselPageState extends State<HomePage>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  List<String> title = [
    'Best to Visit in ${getCurrentSeason()}',
    'Upcoming Festivals in ${getCurrentMonth()}',
    "High Rated Places",
  ];
  bool _showSearchBar = false;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (!_isDataLoaded) {
      fetchData();
    }
    int numberOfSliders = 5;
    _showSeeMoreList = List.generate(numberOfSliders, (_) => false);
    _scrollControllers = List.generate(numberOfSliders, (index) {
      final controller = ScrollController();
      controller.addListener(() {
        if (controller.offset > 150 && !_showSeeMoreList[index]) {
          setState(() {
            _showSeeMoreList[index] = true;
          });
        } else if (controller.offset <= 150 && _showSeeMoreList[index]) {
          setState(() {
            _showSeeMoreList[index] = false;
          });
        }
      });
      return controller;
    });
  }

  Future<void> fetchData() async {
    bannerItems = await getbanneritems();
    placesbyseason = await gettouristplacesbyseason(getCurrentSeason());
    upcomingfest = await getupcomingcultureplaces();
    highratedplaces = await gethighratedtouristplaces();
    allinone = [placesbyseason, upcomingfest, highratedplaces];
    setState(() {
      _isDataLoaded = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 255, 255, 255),
      body: Stack(
        children: [
          SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Banner Carousel with Search Icon
                Stack(
                  children: [
                    SizedBox(
                      height: 300,
                      child: Stack(
                        children: [
                          bannerItems.isEmpty
                              ? Shimmer.fromColors(
                                  baseColor: Colors.grey[800]!,
                                  highlightColor: Colors.grey[700]!,
                                  child: Container(
                                    width: double.infinity,
                                    height: 400,
                                    color: Colors.grey[900],
                                  ),
                                )
                              : CarouselSlider.builder(
                                  itemCount: bannerItems.length,
                                  itemBuilder: (context, index, realIndex) {
                                    final banner = bannerItems[index];
                                    return GestureDetector(
                                      onTap: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (_) => DetailPage(
                                              title: banner['title']!,
                                              imagePath: banner['image']!,
                                            ),
                                          ),
                                        );
                                      },
                                      child: Stack(
                                        children: [
                                          Image.network(
                                            banner['image']!,
                                            width: double.infinity,
                                            height: 400,
                                            fit: BoxFit.cover,
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                                  options: CarouselOptions(
                                    height: 400,
                                    viewportFraction: 1.0,
                                    autoPlay: true,
                                    autoPlayInterval: Duration(seconds: 4),
                                    autoPlayAnimationDuration: Duration(
                                      milliseconds: 1000,
                                    ),
                                    autoPlayCurve: Curves.easeInOut,
                                  ),
                                ),
                        ],
                      ),
                    ),
                    Positioned(
                      bottom: 0,
                      left: 0,
                      right: 0,
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 16),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(30),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Iconsax.search_normal_1,
                              color: Colors.grey,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: TextField(
                                decoration: const InputDecoration(
                                  hintText: "Search destinations, hotels...",
                                  hintStyle: TextStyle(color: Colors.grey),
                                  border: InputBorder.none,
                                ),
                              ),
                            ),
                            const Icon(
                              Iconsax.microphone_2,
                              color: Colors.grey,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 30),

                // --- CATEGORY BUTTON SECTION ---
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Wrap(
                    spacing: 16,
                    runSpacing: 16,
                    children: [
                      buildCategoryButton(
                        context,
                        Iconsax.building,
                        "Hotels",
                        Colors.blue,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => HotelsPage(),
                            ),
                          );
                        },
                      ),
                      buildCategoryButton(
                        context,
                        Iconsax.cup,
                        "Foods",
                        Colors.orange,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => FamousFoodsPage(),
                            ),
                          );
                        },
                      ),
                      buildCategoryButton(
                        context,
                        Iconsax.airplane,
                        "Trip Planner",
                        Colors.purple,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => MapScreen(),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),

                // Horizontal carousels
                ...List.generate(3, (i) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              title[i],
                              style: TextStyle(
                                fontSize: 20,
                                color: const Color.fromARGB(255, 0, 0, 0),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            AnimatedOpacity(
                              opacity: _showSeeMoreList[i] ? 1.0 : 0.0,
                              duration: Duration(milliseconds: 300),
                              child: IconButton(
                                icon: Icon(
                                  Icons.arrow_forward_ios,
                                  color: Colors.white,
                                  size: 18,
                                ),
                                onPressed: () {
                                  if (_showSeeMoreList[i]) {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => AllPlaces(
                                          function: allinone[i],
                                          title: title[i],
                                        ),
                                      ),
                                    );
                                  }
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                      allinone.isEmpty
                          ? SizedBox(
                              height: 180,
                              child: ListView.builder(
                                scrollDirection: Axis.horizontal,
                                itemCount: 5,
                                padding: EdgeInsets.symmetric(horizontal: 12),
                                itemBuilder: (context, index) =>
                                    Shimmer.fromColors(
                                      baseColor: Colors.grey[800]!,
                                      highlightColor: Colors.grey[700]!,
                                      child: Container(
                                        width: 120,
                                        height: 180,
                                        margin: EdgeInsets.only(right: 12),
                                        decoration: BoxDecoration(
                                          color: Colors.grey[900],
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                        ),
                                      ),
                                    ),
                              ),
                            )
                          : SizedBox(
                              height: 180,
                              child: ListView.builder(
                                controller: _scrollControllers[i],
                                scrollDirection: Axis.horizontal,
                                padding: EdgeInsets.symmetric(horizontal: 12),
                                itemCount: allinone[i].length,
                                itemBuilder: (context, index) {
                                  final item = allinone[i][index];
                                  return GestureDetector(
                                    onTap: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) => DetailPage(
                                            title: item['title']!,
                                            imagePath: item['image']!,
                                          ),
                                        ),
                                      );
                                    },
                                    child: Container(
                                      margin: EdgeInsets.only(right: 12),
                                      width: 120,
                                      child: Stack(
                                        children: [
                                          imageloader(item['image']),
                                          Container(
                                            width: 120,
                                            height: 180,
                                            decoration: BoxDecoration(
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                              gradient: LinearGradient(
                                                begin: Alignment.topCenter,
                                                end: Alignment.bottomCenter,
                                                colors: [
                                                  Colors.transparent,
                                                  Colors.black.withOpacity(0.8),
                                                ],
                                              ),
                                            ),
                                          ),
                                          Positioned(
                                            bottom: 28,
                                            left: 8,
                                            right: 8,
                                            child: Text(
                                              item['title'] ?? '',
                                              style: TextStyle(
                                                color: Colors.white,
                                                fontWeight: FontWeight.bold,
                                                fontSize: 14,
                                              ),
                                              maxLines: 2,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                          Positioned(
                                            bottom: 10,
                                            left: 8,
                                            child: Row(
                                              children: [
                                                Icon(
                                                  Icons.location_on,
                                                  color: Colors.white,
                                                  size: 14,
                                                ),
                                                SizedBox(width: 4),
                                                Text(
                                                  item['city'] ?? '',
                                                  style: TextStyle(
                                                    color: Colors.white,
                                                    fontSize: 12,
                                                  ),
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                    ],
                  );
                }),
              ],
            ),
          ),

          // Search Bar Overlay
          if (_showSearchBar)
            Positioned(
              top: 40,
              left: 16,
              right: 60,
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: Colors.grey[900],
                  borderRadius: BorderRadius.circular(10),
                ),
                child: TextField(
                  controller: _searchController,
                  style: TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: 'Search...',
                    hintStyle: TextStyle(color: Colors.grey),
                    border: InputBorder.none,
                  ),
                  onChanged: (query) {
                    // Live search logic here
                  },
                ),
              ),
            ),
        ],
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endDocked,
    );
  }
}

class LatestReleasesPage extends StatelessWidget {
  const LatestReleasesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: Text('All Releases', style: TextStyle(color: Colors.white)),
        iconTheme: IconThemeData(color: Colors.white),
      ),
      body: Center(
        child: Text(
          'This is the new page for all latest releases.',
          style: TextStyle(color: Colors.white, fontSize: 16),
        ),
      ),
    );
  }
}

class MySpacePage extends StatelessWidget {
  const MySpacePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text("Search Page", style: TextStyle(color: Colors.white)),
    );
  }
}

Widget buildCategoryButton(
  BuildContext context,
  IconData icon,
  String label,
  Color color, {
  VoidCallback? onTap,
}) {
  return InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(16),
    child: Container(
      width: 100,
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 30),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 14,
              color: color,
            ),
          ),
        ],
      ),
    ),
  );
}
