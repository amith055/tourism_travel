import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'selectmapscreen.dart';

class AddPlaceForm extends StatefulWidget {
  final dynamic email;

  const AddPlaceForm({super.key, required this.email});

  @override
  State<AddPlaceForm> createState() => _AddPlaceFormState();
}

class _AddPlaceFormState extends State<AddPlaceForm> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController placeNameController = TextEditingController();
  final TextEditingController townController = TextEditingController();
  final TextEditingController cityController = TextEditingController();
  final TextEditingController districtController = TextEditingController();
  final TextEditingController stateController = TextEditingController();
  final TextEditingController timeNeededController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();

  String? selectedZone;
  String? selectedType;
  String? selectedTourismType;
  String? selectedCultureType;
  String? selectedBestSeason;
  LatLng? selectedCoordinates;

  final List<String> zones = ['Northern', 'Southern', 'Western', 'Eastern'];
  final List<String> tourismTypes = [
    'Nature',
    'Historical',
    'Beach',
    'Wildlife',
    'Other',
  ];

  final List<String> types = ['Cultural Event', 'Tourist Places'];

  final List<String> cultureTypes = [
    'Cultural Event',
    'Religious Festival',
    'Festival',
    'Food Festival',
    'Music Festival',
    'Tribal Festival',
  ];
  final List<String> bestSeasons = ['Summer', 'Winter', 'Monsoon', 'Spring'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text("Add a Place or Event"),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              _buildDropdown(
                label: "Type",
                value: selectedType,
                items: types,
                onChanged: (value) => setState(() => selectedType = value),
              ),
              _buildTextField("Tourism Place Name", placeNameController),
              _buildTextField("Town", townController),
              _buildTextField("City", cityController),
              _buildTextField("District", districtController),
              _buildTextField("State", stateController),
              _buildTextField("Time Needed to Visit", timeNeededController),
              _buildTextField(
                "Description of the Place",
                descriptionController,
                maxLines: 4,
              ),
              const SizedBox(height: 16),
              _buildDropdown(
                label: "Zone",
                value: selectedZone,
                items: zones,
                onChanged: (value) => setState(() => selectedZone = value),
              ),
              const SizedBox(height: 16),
              _buildDropdown(
                label: "Tourism Type",
                value: selectedTourismType,
                items: tourismTypes,
                onChanged:
                    (value) => setState(() => selectedTourismType = value),
              ),
              const SizedBox(height: 16),
              _buildDropdown(
                label: "Best Season",
                value: selectedBestSeason,
                items: bestSeasons,
                onChanged:
                    (value) => setState(() => selectedBestSeason = value),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () async {
                  final result = await Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const MapScreen()),
                  );

                  if (result != null && result is LatLng) {
                    setState(() => selectedCoordinates = result);
                    await _getAddressFromCoordinates(result);
                  }
                },
                child: Text(
                  selectedCoordinates != null
                      ? 'Location Selected: (${selectedCoordinates!.latitude}, ${selectedCoordinates!.longitude})'
                      : 'Select Location on Map',
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () async {
                  if (_formKey.currentState!.validate()) {
                    await _submitTourismPlace();
                  }
                },
                child: const Text("Submit"),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(
    String label,
    TextEditingController controller, {
    int maxLines = 1,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: controller,
        maxLines: maxLines,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: Colors.white70),
          border: const OutlineInputBorder(),
          enabledBorder: const OutlineInputBorder(
            borderSide: BorderSide(color: Colors.white38),
          ),
          focusedBorder: const OutlineInputBorder(
            borderSide: BorderSide(color: Colors.white),
          ),
        ),
        validator: (value) {
          if (value == null || value.isEmpty) {
            return 'Please enter $label';
          }
          return null;
        },
      ),
    );
  }

  Widget _buildDropdown({
    required String label,
    required String? value,
    required List<String> items,
    required void Function(String?) onChanged,
  }) {
    return DropdownButtonFormField<String>(
      value: value,
      dropdownColor: Colors.black,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white70),
        enabledBorder: const OutlineInputBorder(
          borderSide: BorderSide(color: Colors.white38),
        ),
        border: const OutlineInputBorder(),
      ),
      items:
          items
              .map((item) => DropdownMenuItem(value: item, child: Text(item)))
              .toList(),
      onChanged: onChanged,
      validator:
          (value) =>
              value == null || value.isEmpty ? 'Please select $label' : null,
    );
  }

  Future<void> _getAddressFromCoordinates(LatLng position) async {
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );
      if (placemarks.isNotEmpty) {
        final place = placemarks.first;
        setState(() {
          townController.text = place.subLocality ?? '';
          cityController.text = place.locality ?? '';
          districtController.text =
              place.subAdministrativeArea!.replaceAll('Division', '').trim() ??
              '';
          stateController.text = place.administrativeArea ?? '';
        });
      }
    } catch (e) {
      debugPrint("Error getting address: $e");
    }
  }

  Future<void> _submitTourismPlace() async {
    if (selectedZone == null ||
        selectedTourismType == null ||
        selectedBestSeason == null ||
        selectedCoordinates == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please complete all fields and select a location.'),
        ),
      );
      return;
    }

    try {
      final tourismData = {
        "name": placeNameController.text.trim(),
        "town": townController.text.trim(),
        "city": cityController.text.trim(),
        "district": districtController.text.trim(),
        "state": stateController.text.trim(),
        "time_needed_to_visit": timeNeededController.text.trim(),
        "description": descriptionController.text.trim(),
        "zone": selectedZone,
        "tourism_type": selectedTourismType,
        "best_season": selectedBestSeason,
        "latitude": selectedCoordinates!.latitude,
        "longitude": selectedCoordinates!.longitude,
        "verified": false,
        "useremail": widget.email,
        "created_at": FieldValue.serverTimestamp(),
      };

      await FirebaseFirestore.instance
          .collection('touristplacesverify')
          .add(tourismData);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Tourism place submitted for verification!'),
        ),
      );

      _formKey.currentState!.reset();
      _clearControllers();
      setState(() {
        selectedZone = null;
        selectedTourismType = null;
        selectedBestSeason = null;
        selectedCoordinates = null;
      });
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: ${e.toString()}')));
    }
  }

  void _clearControllers() {
    placeNameController.clear();
    townController.clear();
    cityController.clear();
    districtController.clear();
    stateController.clear();
    timeNeededController.clear();
    descriptionController.clear();
  }
}
