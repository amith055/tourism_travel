import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:lokvista_app/pages/services/trip_plan_screen.dart';
import '../services/places_service.dart';
import '../models/place.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  _MapScreenState createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  GoogleMapController? _controller;
  LatLng? _start;
  LatLng? _end;

  final TextEditingController _startController = TextEditingController();
  final TextEditingController _endController = TextEditingController();
  final PlacesService _placesService = PlacesService();

  List<PlaceModel> _nearby = [];
  List<PlaceModel> _geminiTop10 = [];
  bool _loading = false;
  double _totalDistanceKm = 0.0;
  Set<Marker> _markers = {};
  Set<Polyline> _polylines = {};

  final Set<String> _selectedCategories = {'tourism'};
  static const double _avgKmPerDay = 300.0;
  int _days = 1;
  bool _useAutoDays = false;

  Offset _fabPosition = const Offset(20, 520);

  @override
  void initState() {
    super.initState();
    _determinePosition();
  }

  // ------------------ CORE LOGIC ------------------ //
  Future<void> _determinePosition() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      _showMessage('Please enable location services.');
      return;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return;
    }

    if (permission == LocationPermission.deniedForever) {
      _showMessage('Location permission permanently denied.');
      return;
    }

    final pos = await Geolocator.getCurrentPosition();
    setState(() {
      _start = LatLng(pos.latitude, pos.longitude);
      _startController.text = '📍 Current location';
      _updateMarkers();
    });
  }

  void _showMessage(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  Future<LatLng?> _geocodeAddress(String address) async {
    if (address.trim().isEmpty) return null;
    try {
      return await _placesService.geocodeAddress(address);
    } catch (_) {
      return null;
    }
  }

  Future<void> _computeRouteAndDistance() async {
    if (_start == null || _end == null) {
      _showMessage('Please enter both start and destination.');
      return;
    }
    setState(() => _loading = true);

    try {
      final dir = await _placesService.getDirections(
        _start!.latitude,
        _start!.longitude,
        _end!.latitude,
        _end!.longitude,
      );

      final distanceKm = (dir['distanceKm'] ?? 0.0) as double;
      final points = List<LatLng>.from(dir['polyline'] ?? []);
      setState(() {
        _totalDistanceKm = distanceKm;
        _polylines = {
          Polyline(
            polylineId: const PolylineId('route'),
            points: points,
            color: const Color(0xFF1565C0),
            width: 5,
          ),
        };
      });

      if (_useAutoDays) {
        _days = (distanceKm / _avgKmPerDay).ceil().clamp(1, 2);
      }

      if (points.isNotEmpty && _controller != null) {
        final mid = points[points.length ~/ 2];
        _controller!.animateCamera(CameraUpdate.newLatLngZoom(mid, 8));
      }

      await _searchNearby();
    } catch (e) {
      _showMessage('Route fetch failed: $e');
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _searchNearby() async {
    if (_start == null || _end == null) {
      _showMessage('Please enter both start and destination.');
      return;
    }

    setState(() => _loading = true);
    try {
      final combinedCategories = _selectedCategories.join(',');

      final result = await _placesService.nearbyWithAI(
        _start!.latitude,
        _start!.longitude,
        _end!.latitude,
        _end!.longitude,
        category: combinedCategories,
      );

      setState(() {
        _nearby = result['allNearby'] ?? [];
        _geminiTop10 = result['geminiTop10'] ?? [];
      });
      _updateMarkers();
    } catch (e) {
      _showMessage('Failed to fetch nearby places: $e');
    } finally {
      setState(() => _loading = false);
    }
  }

  void _updateMarkers() async {
    final markers = <Marker>{};

    if (_start != null) {
      markers.add(
        Marker(
          markerId: const MarkerId('start'),
          position: _start!,
          infoWindow: const InfoWindow(title: 'Start'),
          icon: BitmapDescriptor.defaultMarkerWithHue(
            BitmapDescriptor.hueAzure,
          ),
        ),
      );
    }

    if (_end != null) {
      markers.add(
        Marker(
          markerId: const MarkerId('end'),
          position: _end!,
          infoWindow: const InfoWindow(title: 'Destination'),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
        ),
      );
    }

    for (final p in _geminiTop10) {
      markers.add(
        Marker(
          markerId: MarkerId('gemini_${p.placeId}'),
          position: LatLng(p.lat, p.lng),
          infoWindow: InfoWindow(title: '🏛️ ${p.name}', snippet: p.address),
          icon: BitmapDescriptor.defaultMarkerWithHue(
            BitmapDescriptor.hueYellow,
          ),
        ),
      );
    }

    setState(() => _markers = markers);

    if (_controller != null && markers.isNotEmpty) {
      final bounds = _createBoundsFromMarkers(markers);
      await _controller!.animateCamera(
        CameraUpdate.newLatLngBounds(bounds, 70),
      );
    }
  }

  LatLngBounds _createBoundsFromMarkers(Set<Marker> markers) {
    final latitudes = markers.map((m) => m.position.latitude).toList();
    final longitudes = markers.map((m) => m.position.longitude).toList();
    final southWest = LatLng(
      latitudes.reduce((a, b) => a < b ? a : b),
      longitudes.reduce((a, b) => a < b ? a : b),
    );
    final northEast = LatLng(
      latitudes.reduce((a, b) => a > b ? a : b),
      longitudes.reduce((a, b) => a > b ? a : b),
    );
    return LatLngBounds(southwest: southWest, northeast: northEast);
  }

  Future<void> _onAddressesSubmitted() async {
    setState(() => _loading = true);
    try {
      final s = await _geocodeAddress(_startController.text);
      final e = await _geocodeAddress(_endController.text);
      if (s != null) _start = s;
      if (e != null) _end = e;
      _updateMarkers();
      if (_start != null && _end != null) await _computeRouteAndDistance();
    } finally {
      setState(() => _loading = false);
    }
  }

  // ------------------ UI SECTION ------------------ //
  Widget _buildInputSection() {
    return Container(
      margin: const EdgeInsets.all(14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 8)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildAddressField(
            _startController,
            'Starting Destination',
            Icons.my_location,
            isStart: true,
          ),
          const SizedBox(height: 10),
          _buildAddressField(_endController, 'Final Destination', Icons.flag),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Distance: ${_totalDistanceKm.toStringAsFixed(1)} km',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              Text(
                'Days: $_days',
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  color: Colors.blueGrey,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          const Divider(height: 20, color: Colors.black26),
          const Text(
            'Choose Categories',
            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 10,
            children: [
              _buildCategoryChip('Tourism', 'tourism'),
              _buildCategoryChip('Temples', 'temples'),
              _buildCategoryChip('Historical', 'historical'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAddressField(
    TextEditingController controller,
    String label,
    IconData icon, {
    bool isStart = false,
  }) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        prefixIcon: Icon(icon, color: const Color(0xFF1565C0)),
        labelText: label,
        filled: true,
        fillColor: Colors.blueGrey.shade50,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        suffixIcon: IconButton(
          icon: Icon(
            isStart ? Icons.gps_fixed : Icons.search,
            color: Colors.amber.shade700,
          ),
          onPressed: isStart ? _determinePosition : _onAddressesSubmitted,
        ),
      ),
    );
  }

  Widget _buildCategoryChip(String label, String value) {
    final selected = _selectedCategories.contains(value);
    return FilterChip(
      label: Text(label),
      selected: selected,
      selectedColor: const Color(0xFF1565C0),
      backgroundColor: Colors.blueGrey.shade100,
      labelStyle: TextStyle(
        color: selected ? Colors.white : Colors.blueGrey.shade800,
      ),
      onSelected: (bool val) async {
        setState(() {
          if (val) {
            _selectedCategories.add(value);
          } else {
            _selectedCategories.remove(value);
          }
        });
        await _searchNearby();
      },
    );
  }

  Widget _buildPlaceLists() {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Card(
        elevation: 3,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: DefaultTabController(
          length: 2,
          child: Column(
            children: [
              Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF1565C0), Color(0xFF42A5F5)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
                ),
                child: const TabBar(
                  labelColor: Colors.white,
                  unselectedLabelColor: Colors.white70,
                  indicatorColor: Colors.amberAccent,
                  tabs: [
                    Tab(
                      icon: Icon(Icons.auto_awesome),
                      text: 'Gemini AI Top 20',
                    ),
                    Tab(
                      icon: Icon(Icons.place_outlined),
                      text: 'Nearby Places',
                    ),
                  ],
                ),
              ),
              SizedBox(
                height: 380,
                child: TabBarView(
                  children: [_buildGeminiAIList(), _buildNearbyPlacesList()],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGeminiAIList() {
    if (_loading) return const LinearProgressIndicator();
    if (_geminiTop10.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(12),
          child: Text(
            'No AI recommendations yet.\nTap “Get Route & Nearby” to generate.',
            textAlign: TextAlign.center,
          ),
        ),
      );
    }
    return ListView.builder(
      itemCount: _geminiTop10.length,
      itemBuilder: (context, i) {
        final p = _geminiTop10[i];
        return Card(
          margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 10),
          elevation: 2,
          child: ListTile(
            leading: const Icon(Icons.star, color: Colors.amber),
            title: Text(
              p.name,
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
            ),
            subtitle: Text('⭐ ${p.rating} • ${p.address}'),
            trailing: IconButton(
              icon: const Icon(Icons.delete, color: Colors.redAccent),
              onPressed: () {
                setState(() {
                  _geminiTop10.remove(p);
                  _updateMarkers();
                });
              },
            ),
            onTap: () async {
              if (_controller != null) {
                await _controller!.animateCamera(
                  CameraUpdate.newLatLngZoom(LatLng(p.lat, p.lng), 15),
                );
              }
            },
          ),
        );
      },
    );
  }

  Widget _buildNearbyPlacesList() {
    if (_loading) return const LinearProgressIndicator();
    if (_nearby.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(12),
          child: Text(
            'No nearby places found.\nTry adjusting your route or category.',
          ),
        ),
      );
    }

    final filteredNearby = _nearby
        .where((p) => !_geminiTop10.any((ai) => ai.placeId == p.placeId))
        .toList();

    return ListView.builder(
      itemCount: filteredNearby.length,
      itemBuilder: (context, i) {
        final p = filteredNearby[i];
        return Card(
          margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 10),
          child: ListTile(
            leading: const Icon(Icons.place, color: Colors.deepOrange),
            title: Text(
              p.name,
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
            ),
            subtitle: Text('⭐ ${p.rating} • ${p.address}'),
            trailing: IconButton(
              icon: const Icon(Icons.add_circle_outline, color: Colors.green),
              onPressed: () {
                if (!_geminiTop10.any((ai) => ai.placeId == p.placeId)) {
                  setState(() {
                    _geminiTop10.add(p);
                    _updateMarkers();
                  });
                } else {
                  _showMessage('Already in Gemini top list');
                }
              },
            ),
            onTap: () async {
              if (_controller != null) {
                await _controller!.animateCamera(
                  CameraUpdate.newLatLngZoom(LatLng(p.lat, p.lng), 15),
                );
              }
            },
          ),
        );
      },
    );
  }

  // ------------------ UI BUILD ------------------ //
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Smart Trip Planner',
          style: TextStyle(
            color: Color(0xFF1565C0),
            fontWeight: FontWeight.bold,
            fontSize: 20,
            letterSpacing: 0.5,
          ),
        ),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            child: Column(
              children: [
                _buildInputSection(),
                Container(
                  height: 360,
                  margin: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: const [
                      BoxShadow(
                        color: Colors.black12,
                        blurRadius: 8,
                        offset: Offset(0, 3),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: _start == null
                        ? const Center(child: CircularProgressIndicator())
                        : GoogleMap(
                            initialCameraPosition: CameraPosition(
                              target: _start!,
                              zoom: 8,
                            ),
                            onMapCreated: (c) => _controller = c,
                            markers: _markers,
                            polylines: _polylines,
                            myLocationEnabled: true,
                          ),
                  ),
                ),
                _buildPlaceLists(),
              ],
            ),
          ),

          // 🌟 Floating Gradient Button (Draggable)
          Positioned(
            left: _fabPosition.dx,
            top: _fabPosition.dy,
            child: GestureDetector(
              onPanUpdate: (details) {
                setState(() {
                  _fabPosition = Offset(
                    _fabPosition.dx + details.delta.dx,
                    _fabPosition.dy + details.delta.dy,
                  );
                });
              },
              child: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF1565C0), Color(0xFF42A5F5)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.all(Radius.circular(30)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black26,
                      blurRadius: 8,
                      offset: Offset(0, 3),
                    ),
                  ],
                ),
                child: FloatingActionButton.extended(
                  backgroundColor: Colors.transparent,
                  elevation: 0,
                  icon: const Icon(Icons.alt_route, color: Colors.white),
                  label: const Text(
                    'Plan a Trip',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  onPressed: () async {
                    if (_geminiTop10.isEmpty) {
                      _showMessage('Please fetch Gemini AI top places first.');
                      return;
                    }

                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => TripPlanScreen(
                          topPlaces: _geminiTop10,
                          totalDistance: _totalDistanceKm,
                          geminiApiKey: _placesService.geminiApiKey,
                          startAddress: _startController.text,
                          endAddress: _endController.text,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
