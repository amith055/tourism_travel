import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geocoding/geocoding.dart';

class PlaceMapScreen extends StatefulWidget {
  final String placeName;
  final String googleApiKey;

  const PlaceMapScreen({
    super.key,
    required this.placeName,
    required this.googleApiKey,
  });

  @override
  State<PlaceMapScreen> createState() => _PlaceMapScreenState();
}

class _PlaceMapScreenState extends State<PlaceMapScreen> {
  LatLng? _placeLatLng;
  bool _loading = true;
  // ignore: unused_field
  GoogleMapController? _mapController;

  @override
  void initState() {
    super.initState();
    _fetchCoordinates();
  }

  Future<void> _fetchCoordinates() async {
    try {
      final locations = await locationFromAddress(widget.placeName);
      if (locations.isNotEmpty) {
        final loc = locations.first;
        setState(() {
          _placeLatLng = LatLng(loc.latitude, loc.longitude);
          _loading = false;
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("Error finding location: $e")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.placeName),
        backgroundColor: const Color.fromARGB(204, 187, 215, 245),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : GoogleMap(
              mapType: MapType.normal,
              initialCameraPosition: CameraPosition(
                target: _placeLatLng!,
                zoom: 15,
              ),
              markers: {
                Marker(
                  markerId: const MarkerId("place"),
                  position: _placeLatLng!,
                  infoWindow: InfoWindow(title: widget.placeName),
                ),
              },
              onMapCreated: (controller) => _mapController = controller,
              myLocationButtonEnabled: true,
              zoomControlsEnabled: true,
            ),
    );
  }
}
