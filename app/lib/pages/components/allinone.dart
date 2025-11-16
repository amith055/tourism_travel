import 'package:flutter/material.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:lokvista_app/pages/apifunctions/apis.dart';
import 'package:lokvista_app/pages/components/details.dart';

class AllinOne extends StatefulWidget {
  final bool button;
  final dynamic type;

  const AllinOne({super.key, required this.button, required this.type});
  @override
  State<AllinOne> createState() => _BannerWithCarouselPageState();
}

class _BannerWithCarouselPageState extends State<AllinOne> {
  List<Map<String, String>> bannerItems = [];
  List<Map<String, String>> latestReleases = [];
  List<Map<String, String>> releasesForSlider2 = [];

  late List<bool> _showSeeMoreList;
  late List<ScrollController> _scrollControllers;

  @override
  void initState() {
    super.initState();
    fetchData();
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
    if (widget.type == "tourism") {
      bannerItems = await gettouristplaces();
      latestReleases = await gettouristplaces();
    } else if (widget.type == "culture") {
      bannerItems = await getcultureplaces();
      latestReleases = await getcultureplaces();
    }
    setState(() {});
  }

  @override
  void dispose() {
    for (final controller in _scrollControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // BANNER CAROUSEL
            CarouselSlider.builder(
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
            // Repeated Horizontal Carousels
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
                          'Latest Releases ${i + 1}',
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
                                    builder: (_) => const LatestReleasesPage(),
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
                  SizedBox(
                    height: 180,
                    child: ListView.builder(
                      controller: _scrollControllers[i],
                      scrollDirection: Axis.horizontal,
                      padding: EdgeInsets.symmetric(horizontal: 12),
                      itemCount: latestReleases.length,
                      itemBuilder: (context, index) {
                        final item = latestReleases[index];
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
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(8),
                              image: DecorationImage(
                                image: NetworkImage(item['image']!),
                                fit: BoxFit.cover,
                              ),
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
        padding: const EdgeInsets.only(bottom: 16, right: 16),
        child: FloatingActionButton(
          onPressed: () {
            // Add your map logic here
          },
          backgroundColor: const Color.fromARGB(255, 0, 0, 0),
          child: Icon(Icons.location_on, color: Colors.white, size: 30),
        ),
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
