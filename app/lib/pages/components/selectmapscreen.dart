import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  LatLng? selectedLocation;

  void _onTap(LatLng position) {
    setState(() {
      selectedLocation = position;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text("Select Location"),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
      ),
      body: GoogleMap(
        initialCameraPosition: const CameraPosition(
          target: LatLng(20.5937, 78.9629),
          zoom: 5,
        ),
        onTap: _onTap,
        markers:
            selectedLocation != null
                ? {
                  Marker(
                    markerId: const MarkerId("selected"),
                    position: selectedLocation!,
                  ),
                }
                : {},
      ),
      floatingActionButton:
          selectedLocation != null
              ? FloatingActionButton.extended(
                backgroundColor: Colors.teal,
                onPressed: () => Navigator.pop(context, selectedLocation),
                label: const Text("Select Location"),
                icon: const Icon(Icons.check),
              )
              : null,
    );
  }
}
