import 'package:app/pages/ApiFunctions/functions.dart';
import 'package:app/pages/components/add_place_form.dart';
import 'package:app/pages/components/all_places.dart';
import 'package:app/pages/components/mapscreen.dart';
import 'package:flutter/material.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:app/pages/ApiFunctions/apis.dart';
import 'package:app/pages/components/destails.dart';
import 'package:shimmer/shimmer.dart';

class TourismHome extends StatefulWidget {
  final dynamic email;

  const TourismHome({super.key, required this.email});
  @override
  State<TourismHome> createState() => _BannerWithCarouselPageState();
}

List<Map<String, String>> bannerItems = [];
List<Map<String, String>> NatureItems = [];
List<Map<String, String>> HistoricalItems = [];
List<Map<String, String>> BeachItems = [];
List<Map<String, String>> WildLifeItems = [];
List<List<Map<String, String>>> listofall = [];
bool isDataLoaded = false;

class _BannerWithCarouselPageState extends State<TourismHome>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;
  List<String> types = ['Nature', 'Beach', 'Wildlife', 'Historical'];

  late List<bool> _showSeeMoreList;
  late List<ScrollController> _scrollControllers;

  bool _showSearchBar = false;
  TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (!isDataLoaded) {
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
    bannerItems = await gettouristplaces();
    NatureItems = await gettouristplacesspecific('Nature');
    HistoricalItems = await gettouristplacesspecific('Historical');
    BeachItems = await gettouristplacesspecific('Beach');
    WildLifeItems = await gettouristplacesspecific('Wildlife');

    setState(() {
      listofall = [NatureItems, BeachItems, WildLifeItems, HistoricalItems];
      isDataLoaded = true;
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
            bannerItems.isNotEmpty
                ? Stack(
                  children: [
                    CarouselSlider.builder(
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
                              // Filtering logic here
                            },
                          ),
                        ),
                      ),
                  ],
                )
                : Shimmer.fromColors(
                  baseColor: Colors.grey[800]!,
                  highlightColor: Colors.grey[700]!,
                  child: Container(
                    width: double.infinity,
                    height: 400,
                    color: Colors.grey[900],
                  ),
                ),

            ...List.generate(4, (i) {
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
                                          function: listofall[i],
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
                  SizedBox(
                    height: 180,
                    child:
                        listofall.isNotEmpty
                            ? ListView.builder(
                              controller: _scrollControllers[i],
                              scrollDirection: Axis.horizontal,
                              padding: EdgeInsets.symmetric(horizontal: 12),
                              itemCount: listofall[i].length,
                              itemBuilder: (context, index) {
                                final item = listofall[i][index];
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
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(8),
                                      child: Stack(
                                        children: [
                                          imageloader(item['image']),
                                          Container(
                                            decoration: BoxDecoration(
                                              gradient: LinearGradient(
                                                begin: Alignment.topCenter,
                                                end: Alignment.bottomCenter,
                                                colors: [
                                                  Colors.transparent,
                                                  Colors.black.withOpacity(0.7),
                                                ],
                                              ),
                                            ),
                                          ),
                                          Positioned(
                                            bottom: 28,
                                            left: 6,
                                            right: 6,
                                            child: Text(
                                              item['title'] ?? '',
                                              style: TextStyle(
                                                color: Colors.white,
                                                fontWeight: FontWeight.bold,
                                                fontSize: 14,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                          ),
                                          Positioned(
                                            bottom: 8,
                                            left: 6,
                                            child: Row(
                                              children: [
                                                Icon(
                                                  Icons.location_on,
                                                  color: Colors.white,
                                                  size: 12,
                                                ),
                                                SizedBox(width: 2),
                                                Text(
                                                  item['city'] ?? '',
                                                  style: TextStyle(
                                                    color: Colors.white,
                                                    fontSize: 12,
                                                    overflow:
                                                        TextOverflow.ellipsis,
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
                            )
                            : SizedBox(
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
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                        ),
                                      ),
                                    ),
                              ),
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
                    builder: (context) => MapScreen(name: "Tourism"),
                  ),
                );
              },
              backgroundColor: const Color.fromARGB(255, 36, 36, 36),
              child: Icon(Icons.location_on, color: Colors.white, size: 30),
            ),
          ],
        ),
      ),

      floatingActionButtonLocation: FloatingActionButtonLocation.endDocked,
    );
  }
}
