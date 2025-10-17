import 'package:app/pages/ApiFunctions/apis.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';

class MapScreen extends StatefulWidget {
  final dynamic name;
  const MapScreen({super.key, required this.name});

  @override
  _MapScreenState createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  late GoogleMapController _mapController;
  LatLng? _currentPosition;
  bool _isLoading = true;
  List<Map<String, dynamic>> mapdata = [];

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
    getlocdata();
  }

  void getlocdata() async {
    if (widget.name == "Tourism") {
      mapdata = await getlocationoftourismdetails();
    } else if (widget.name == "Cultural") {
      mapdata = await getlocationofculturaldetails();
    }
    setState(() {});
  }

  Future<void> _getCurrentLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    // Check if location services are enabled
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return Future.error('Location services are disabled.');
    }

    // Check permission status
    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return Future.error('Location permission denied.');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return Future.error('Location permissions are permanently denied.');
    }

    // Get the current position
    Position position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );
    print(position);

    setState(() {
      _currentPosition = LatLng(position.latitude, position.longitude);
      _isLoading = false;
    });
  }

  void _showBottomSheet(Map<String, dynamic> loc) {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                loc['title'] ?? "Null", // Place name
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 10),
              Text(
                'Location: ${loc['latitude'] ?? "Null"}, ${loc['longitude'] ?? "Null"}',
                style: TextStyle(fontSize: 18),
              ),
              SizedBox(height: 10),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Map for ${widget.name}"),
        foregroundColor: Colors.white,
        backgroundColor: Colors.black,
      ),
      body:
          _isLoading
              ? Center(child: CircularProgressIndicator())
              : GoogleMap(
                mapType: MapType.normal,
                buildingsEnabled: true,
                initialCameraPosition: CameraPosition(
                  target: LatLng(20.5937, 78.9629),
                  zoom: 5,
                ),
                onMapCreated: (controller) {
                  _mapController = controller;
                },
                myLocationEnabled: true,
                myLocationButtonEnabled: true,
                markers:
                    mapdata.map((loc) {
                      return Marker(
                        markerId: MarkerId(loc['title']),
                        position: LatLng(
                          double.parse(loc['latitude']),
                          double.parse(loc['longitude']),
                        ),
                        infoWindow: InfoWindow(title: loc['name']),
                        icon: BitmapDescriptor.defaultMarkerWithHue(
                          BitmapDescriptor.hueRed,
                        ),
                        onTap: () {
                          _showBottomSheet(
                            loc,
                          ); // Show the bottom sheet when the marker is tapped
                        },
                      );
                    }).toSet(),
              ),
    );
  }
}
