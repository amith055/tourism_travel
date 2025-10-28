import 'package:app/pages/components/add_culture.dart';
import 'package:app/pages/components/all_places.dart';
import 'package:app/pages/components/mapscreen.dart';
import 'package:flutter/material.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:app/pages/ApiFunctions/functions.dart';
import 'package:app/pages/ApiFunctions/apis.dart';
import 'package:app/pages/components/destails.dart';
import 'package:shimmer/shimmer.dart';

class CultureHome extends StatefulWidget {
  const CultureHome({super.key});
  @override
  State<CultureHome> createState() => _CultureHomeState();
}

List<Map<String, String>> bannerItems = [];
List<Map<String, String>> UpcomingFest = [];
List<Map<String, String>> FestivalsPlaces = [];
List<Map<String, String>> CulturalEvents = [];
List<Map<String, String>> ReligiousFestivals = [];
List<Map<String, String>> ReligiousSites = [];
List<List<Map<String, String>>> Listofall = [];
bool isDataloaded = false;

class _CultureHomeState extends State<CultureHome>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;
  List<String> types = [
    'Upcoming Festivals in ${getCurrentMonth()}',
    'Festivals',
    'Cultural Events',
    'Religious Festivals',
    'Religious Sites',
  ];

  late List<bool> _showSeeMoreList;
  late List<ScrollController> _scrollControllers;

  bool _showSearchBar = false;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (!isDataloaded) {
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
    bannerItems = await getcultureplaces();
    UpcomingFest = await getupcomingcultureplaces();
    FestivalsPlaces = await getculturalplacesspecific("Festival");
    ReligiousFestivals = await getculturalplacesspecific("Religious Festival");
    CulturalEvents = await getculturalplacesspecific("Cultural Event");
    ReligiousSites = await getculturalplacesspecific("Religious Site");
    setState(() {
      Listofall = [
        UpcomingFest,
        FestivalsPlaces,
        CulturalEvents,
        ReligiousFestivals,
        ReligiousSites,
      ];
      isDataloaded = true;
    });
  }

  @override
  void dispose() {
    for (final controller in _scrollControllers) {
      controller.dispose();
    }
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Scaffold(
      backgroundColor: Colors.black,
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Banner Section with Search Bar on top
            Stack(
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
                                builder:
                                    (_) => DetailPage(
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
                              Container(
                                height: 400,
                                decoration: BoxDecoration(
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
                                bottom: 34,
                                left: 16,
                                child: Text(
                                  banner['title']!,
                                  style: TextStyle(
                                    fontSize: 28,
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              Positioned(
                                bottom: 15,
                                left: 16,
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.location_on,
                                      color: Colors.white,
                                      size: 16,
                                    ),
                                    SizedBox(width: 4),
                                    Text(
                                      banner['city']!,
                                      style: TextStyle(
                                        fontSize: 16,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ],
                                ),
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
                        autoPlayAnimationDuration: Duration(milliseconds: 1000),
                        autoPlayCurve: Curves.easeInOut,
                      ),
                    ),
                // Search icon
                Positioned(
                  top: 40,
                  right: 16,
                  child: IconButton(
                    icon: Icon(
                      _showSearchBar ? Icons.close : Icons.search,
                      color: Colors.white,
                      size: 28,
                    ),
                    onPressed: () {
                      setState(() {
                        _showSearchBar = !_showSearchBar;
                      });
                    },
                  ),
                ),
                // Search bar
                if (_showSearchBar)
                  Positioned(
                    top: 40,
                    left: 16,
                    right: 64,
                    child: Container(
                      padding: EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: TextField(
                        controller: _searchController,
                        style: TextStyle(color: Colors.black),
                        decoration: InputDecoration(
                          hintText: 'Search places...',
                          border: InputBorder.none,
                          icon: Icon(Icons.search, color: Colors.black),
                        ),
                        onChanged: (value) {
                          // Optional: Add your search filtering logic here
                        },
                      ),
                    ),
                  ),
              ],
            ),
            // Repeated Horizontal Lists
            ...List.generate(5, (i) {
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
                          types[i],
                          style: TextStyle(
                            fontSize: 20,
                            color: Colors.white,
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
                                    builder:
                                        (_) => AllPlaces(
                                          function: Listofall[i],
                                          title: types[i],
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
                  // Horizontal Carousel
                  Listofall.isEmpty
                      ? SizedBox(
                        height: 180,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: 5,
                          padding: EdgeInsets.symmetric(horizontal: 12),
                          itemBuilder:
                              (context, index) => Shimmer.fromColors(
                                baseColor: Colors.grey[800]!,
                                highlightColor: Colors.grey[700]!,
                                child: Container(
                                  width: 120,
                                  height: 180,
                                  margin: EdgeInsets.only(right: 12),
                                  decoration: BoxDecoration(
                                    color: Colors.grey[900],
                                    borderRadius: BorderRadius.circular(8),
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
                          itemCount: Listofall[i].length,
                          itemBuilder: (context, index) {
                            final item = Listofall[i][index];
                            return GestureDetector(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder:
                                        (_) => DetailPage(
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
                                        borderRadius: BorderRadius.circular(8),
                                        gradient: LinearGradient(
                                          begin: Alignment.topCenter,
                                          end: Alignment.bottomCenter,
                                          colors: [
                                            Colors.transparent,
                                            Colors.black.withValues(),
                                          ],
                                        ),
                                      ),
                                    ),
                                    Positioned(
                                      top: 8,
                                      left: 8,
                                      child: Container(
                                        padding: EdgeInsets.symmetric(
                                          horizontal: 6,
                                          vertical: 2,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.black.withOpacity(0.7),
                                          borderRadius: BorderRadius.circular(
                                            4,
                                          ),
                                        ),
                                        child: Text(
                                          item['date'] ?? 'N/A',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                          ),
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
                                            overflow: TextOverflow.ellipsis,
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
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 15, right: 8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            SizedBox(width: 60),
            FloatingActionButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => MapScreen(name: "Culture"),
                  ),
                );
              },
              backgroundColor: const Color.fromARGB(255, 51, 51, 51),
              child: Icon(Icons.location_on, color: Colors.white, size: 30),
            ),
          ],
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endDocked,
    );
  }
}
