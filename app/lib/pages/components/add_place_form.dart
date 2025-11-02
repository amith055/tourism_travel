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
  int _currentStep = 0;

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
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              _buildProgressBar(),
              const SizedBox(height: 12),
              _buildStepIndicator(),
              const SizedBox(height: 12),
              Expanded(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 400),
                  child: _buildCurrentStep(),
                ),
              ),
              const SizedBox(height: 20),
              _buildNavigationButtons(),
            ],
          ),
        ),
      ),
    );
  }

  // 🌊 Progress Bar
  Widget _buildProgressBar() {
    final double progress = (_currentStep + 1) / 3;
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: Container(
        height: 6,
        width: double.infinity,
        color: Colors.white12,
        child: Stack(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 400),
              width: MediaQuery.of(context).size.width * progress,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.cyanAccent, Colors.blueAccent],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 🧩 Step 1 – Basic Info
  Widget _buildStep1() {
    return ListView(
      key: const ValueKey(0),
      children: [
        _buildDropdown(
          label: "Type",
          value: selectedType,
          items: types,
          onChanged: (val) => setState(() => selectedType = val),
        ),
        const SizedBox(height: 16),
        _buildTextField("Tourism Place Name", placeNameController),
        _buildTextField("Time Needed to Visit", timeNeededController),
        _buildTextField(
          "Description of the Place",
          descriptionController,
          maxLines: 3,
        ),
      ],
    );
  }

  // 📍 Step 2 – Location
  Widget _buildStep2() {
    return ListView(
      key: const ValueKey(1),
      children: [
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.cyanAccent.withOpacity(0.1),
            foregroundColor: Colors.cyanAccent,
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
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
                ? 'Location Selected: (${selectedCoordinates!.latitude.toStringAsFixed(2)}, ${selectedCoordinates!.longitude.toStringAsFixed(2)})'
                : 'Select Location on Map',
          ),
        ),
        const SizedBox(height: 16),
        _buildTextField("Town", townController),
        _buildTextField("City", cityController),
        _buildTextField("District", districtController),
        _buildTextField("State", stateController),
      ],
    );
  }

  // 🏷 Step 3 – Categorization
  Widget _buildStep3() {
    return ListView(
      key: const ValueKey(2),
      children: [
        _buildDropdown(
          label: "Zone",
          value: selectedZone,
          items: zones,
          onChanged: (val) => setState(() => selectedZone = val),
        ),
        const SizedBox(height: 16),
        _buildDropdown(
          label: "Tourism Type",
          value: selectedTourismType,
          items: tourismTypes,
          onChanged: (val) => setState(() => selectedTourismType = val),
        ),
        const SizedBox(height: 16),
        _buildDropdown(
          label: "Best Season",
          value: selectedBestSeason,
          items: bestSeasons,
          onChanged: (val) => setState(() => selectedBestSeason = val),
        ),
      ],
    );
  }

  Widget _buildCurrentStep() {
    switch (_currentStep) {
      case 0:
        return _buildStep1();
      case 1:
        return _buildStep2();
      case 2:
        return _buildStep3();
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildStepIndicator() {
    final steps = ["Basic Info", "Location", "Category"];
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: List.generate(3, (index) {
        final isActive = _currentStep == index;
        return Column(
          children: [
            CircleAvatar(
              radius: 14,
              backgroundColor: isActive ? Colors.cyanAccent : Colors.white24,
              child: Text(
                "${index + 1}",
                style: TextStyle(
                  color: isActive ? Colors.black : Colors.white70,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              steps[index],
              style: TextStyle(
                color: isActive ? Colors.cyanAccent : Colors.white60,
                fontSize: 12,
              ),
            ),
          ],
        );
      }),
    );
  }

  Widget _buildNavigationButtons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        if (_currentStep > 0)
          OutlinedButton(
            onPressed: () => setState(() => _currentStep--),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: Colors.cyanAccent),
              foregroundColor: Colors.cyanAccent,
            ),
            child: const Text("Back"),
          ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.cyanAccent,
            foregroundColor: Colors.black,
          ),
          onPressed: () async {
            if (_currentStep < 2) {
              if (_formKey.currentState!.validate()) {
                setState(() => _currentStep++);
              }
            } else {
              if (_formKey.currentState!.validate()) {
                await _submitTourismPlace();
              }
            }
          },
          child: Text(_currentStep < 2 ? "Next" : "Submit"),
        ),
      ],
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
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          enabledBorder: OutlineInputBorder(
            borderSide: const BorderSide(color: Colors.white24),
            borderRadius: BorderRadius.circular(12),
          ),
          focusedBorder: OutlineInputBorder(
            borderSide: const BorderSide(color: Colors.cyanAccent),
            borderRadius: BorderRadius.circular(12),
          ),
          filled: true,
          fillColor: Colors.white10,
        ),
        validator:
            (value) =>
                (value == null || value.isEmpty) ? 'Please enter $label' : null,
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
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        enabledBorder: OutlineInputBorder(
          borderSide: const BorderSide(color: Colors.white24),
          borderRadius: BorderRadius.circular(12),
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: const BorderSide(color: Colors.cyanAccent),
          borderRadius: BorderRadius.circular(12),
        ),
        filled: true,
        fillColor: Colors.white10,
      ),
      items:
          items
              .map((item) => DropdownMenuItem(value: item, child: Text(item)))
              .toList(),
      onChanged: onChanged,
      validator:
          (val) => val == null || val.isEmpty ? 'Please select $label' : null,
    );
  }

  Future<void> _getAddressFromCoordinates(LatLng position) async {
    try {
      final placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );
      if (placemarks.isNotEmpty) {
        final place = placemarks.first;
        setState(() {
          townController.text = place.subLocality ?? '';
          cityController.text = place.locality ?? '';
          districtController.text =
              place.subAdministrativeArea?.replaceAll('Division', '').trim() ??
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
      final data = {
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
          .add(data);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Tourism place submitted for verification!'),
        ),
      );

      _formKey.currentState!.reset();
      _clearControllers();
      setState(() {
        _currentStep = 0;
        selectedZone = null;
        selectedTourismType = null;
        selectedBestSeason = null;
        selectedCoordinates = null;
      });
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
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
