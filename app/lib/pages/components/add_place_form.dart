import 'dart:io';
import 'package:video_player/video_player.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'selectmapscreen.dart';

class AddPlaceForm extends StatefulWidget {
  final dynamic email;
  final dynamic area;
  const AddPlaceForm({super.key, required this.email, required this.area});
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
  final TextEditingController startdateController = TextEditingController();
  final TextEditingController enddateController = TextEditingController();
  final TextEditingController entrancefeesController = TextEditingController();
  bool _wantsToBeGuide = false;

  String? selectedZone;
  String? category;
  String? selectedBestSeason;
  LatLng? selectedCoordinates;
  late String _videoUrl;

  final List<String> zones = ['Northern', 'Southern', 'Western', 'Eastern'];
  final List<String> tourismTypes = [
    'Nature',
    'Historical',
    'Beach',
    'Wildlife',
    'Other',
  ];
  final List<String> cultureTypes = [
    'Cultural Event',
    'Religious Festival',
    'Festival',
    'Food Festival',
    'Music Festival',
    'Tribal Festival',
  ];
  final List<String> types = ['Cultural Event', 'Tourist Places'];
  final List<String> bestSeasons = ['Summer', 'Winter', 'Monsoon', 'Spring'];

  List<File> _selectedImages = [];
  List<String> _uploadedImageUrls = [];
  bool _isUploading = false;

  File? _videoFile;
  VideoPlayerController? _videoController;
  bool _isUploadingVideo = false;
  Future<void> _recordVideo() async {
    final picker = ImagePicker();
    final pickedVideo = await picker.pickVideo(source: ImageSource.camera);

    if (pickedVideo != null) {
      setState(() {
        _videoFile = File(pickedVideo.path);
      });
      _videoController = VideoPlayerController.file(_videoFile!)
        ..initialize().then((_) {
          setState(() {});
        });

      // Upload to Firebase Storage
      final fileName = DateTime.now().millisecondsSinceEpoch.toString();
      final ref = FirebaseStorage.instance
          .ref()
          .child('place_videos')
          .child('$fileName.mp4');

      final uploadTask = await ref.putFile(_videoFile!);
      final videoUrl = await ref.getDownloadURL();

      setState(() {
        _videoUrl = videoUrl; // Store this in your form data for Firestore
      });
    }
  }

  Future<void> _pickImages() async {
    final picker = ImagePicker();
    final pickedFiles = await picker.pickMultiImage();

    if (pickedFiles != null && pickedFiles.isNotEmpty) {
      setState(() {
        _selectedImages = pickedFiles
            .map((file) => File(file.path))
            .take(5)
            .toList();
      });
    }
  }

  @override
  void dispose() {
    _videoController?.dispose();
    placeNameController.dispose();
    townController.dispose();
    cityController.dispose();
    districtController.dispose();
    stateController.dispose();
    timeNeededController.dispose();
    descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: widget.area == "cultural"
            ? const Text("Add Cultural Event or Festival")
            : const Text("Add Tourist Place"),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
      ),
      body: Stack(
        children: [
          Padding(
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

          // 🌀 Loading overlay
          if (_isUploading)
            Container(
              color: Colors.black.withOpacity(0.7),
              child: const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(color: Colors.cyanAccent),
                    SizedBox(height: 16),
                    Text(
                      "Uploading, please wait...",
                      style: TextStyle(color: Colors.white70, fontSize: 16),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  // 🌊 Progress Bar
  Widget _buildProgressBar() {
    final double progress = (_currentStep + 1) / 4;
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
        const SizedBox(height: 16),
        widget.area == "cultural"
            ? _buildTextField("Event or Festival Name", placeNameController)
            : _buildTextField("Place Name", placeNameController),
        widget.area == "cultural"
            ? Column(
                children: [
                  _buildDatePicker("Start Date", startdateController),
                  _buildDatePicker("End Date", enddateController),
                ],
              )
            : _buildTextField("Time Needed to Visit", timeNeededController),
        _buildTextField("Entrance Fees (if any)", entrancefeesController),
        _buildTextField(
          "Description of the Place",
          descriptionController,
          maxLines: 3,
        ),
        _buildCheckButton(),
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
          label: "Category",
          value: category,
          items: widget.area == "cultural" ? cultureTypes : tourismTypes,
          onChanged: (val) => setState(() => category = val),
        ),
        const SizedBox(height: 16),
        widget.area == 'cultural'
            ? const SizedBox(height: 0)
            : _buildDropdown(
                label: "Best Season",
                value: selectedBestSeason,
                items: bestSeasons,
                onChanged: (val) => setState(() => selectedBestSeason = val),
              ),
      ],
    );
  }

  Widget _buildStep4() {
    return SingleChildScrollView(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF121212),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Upload Images",
              style: TextStyle(
                color: Colors.cyanAccent,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _selectedImages.isEmpty
                ? Center(
                    child: Text(
                      "No images selected yet",
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.6),
                        fontSize: 14,
                      ),
                    ),
                  )
                : SizedBox(
                    height: 120,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: _selectedImages.length,
                      itemBuilder: (context, index) {
                        return Padding(
                          padding: const EdgeInsets.only(right: 10),
                          child: Stack(
                            alignment: Alignment.topRight,
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(15),
                                child: Image.file(
                                  _selectedImages[index],
                                  width: 120,
                                  height: 120,
                                  fit: BoxFit.cover,
                                ),
                              ),
                              Positioned(
                                top: 5,
                                right: 5,
                                child: GestureDetector(
                                  onTap: () {
                                    setState(() {
                                      _selectedImages.removeAt(index);
                                    });
                                  },
                                  child: Container(
                                    decoration: const BoxDecoration(
                                      color: Colors.black54,
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.close,
                                      color: Colors.redAccent,
                                      size: 20,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
            const SizedBox(height: 20),

            Center(
              child: ElevatedButton.icon(
                onPressed: _pickImages,
                icon: const Icon(Icons.add_photo_alternate_outlined, size: 24),
                label: const Text(
                  "Select Images",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.cyanAccent,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(
                    vertical: 14,
                    horizontal: 20,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),
            Center(
              child: Text(
                "You can upload up to 5 images",
                style: TextStyle(
                  color: Colors.white.withOpacity(0.5),
                  fontSize: 13,
                ),
              ),
            ),

            const SizedBox(height: 40),

            // -------------------- VIDEO UPLOAD --------------------
            const Text(
              "Upload Live Preview Video",
              style: TextStyle(
                color: Colors.cyanAccent,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),

            _videoFile == null
                ? Center(
                    child: Text(
                      "No video recorded yet",
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.6),
                        fontSize: 14,
                      ),
                    ),
                  )
                : Column(
                    children: [
                      AspectRatio(
                        aspectRatio:
                            _videoController?.value.aspectRatio ?? 16 / 9,
                        child:
                            _videoController != null &&
                                _videoController!.value.isInitialized
                            ? VideoPlayer(_videoController!)
                            : const Center(child: CircularProgressIndicator()),
                      ),
                      const SizedBox(height: 10),
                      ElevatedButton.icon(
                        onPressed: () {
                          if (_videoController!.value.isPlaying) {
                            _videoController!.pause();
                          } else {
                            _videoController!.play();
                          }
                          setState(() {});
                        },
                        icon: Icon(
                          _videoController!.value.isPlaying
                              ? Icons.pause
                              : Icons.play_arrow,
                        ),
                        label: Text(
                          _videoController!.value.isPlaying
                              ? "Pause"
                              : "Play Video",
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.cyanAccent,
                          foregroundColor: Colors.black,
                        ),
                      ),
                    ],
                  ),
            const SizedBox(height: 20),

            Center(
              child: ElevatedButton.icon(
                onPressed: _recordVideo,
                icon: const Icon(Icons.videocam_outlined, size: 24),
                label: const Text(
                  "Record Live Preview",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.cyanAccent,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(
                    vertical: 14,
                    horizontal: 20,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
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
      case 3:
        return _buildStep4();
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildStepIndicator() {
    final steps = ["Basic Info", "Location", "Category", "Others"];
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: List.generate(4, (index) {
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

  Widget _buildCheckButton() {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF121212),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _wantsToBeGuide ? Colors.cyanAccent : Colors.white24,
          width: 1.5,
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Become a Local Guide?",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  "Choose this if you’d like to guide visitors for this place or event.",
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.6),
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: () {
              setState(() {
                _wantsToBeGuide = !_wantsToBeGuide;
              });
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              height: 28,
              width: 60,
              decoration: BoxDecoration(
                color: _wantsToBeGuide ? Colors.cyanAccent : Colors.white10,
                borderRadius: BorderRadius.circular(30),
                border: Border.all(color: Colors.white24),
              ),
              alignment: _wantsToBeGuide
                  ? Alignment.centerRight
                  : Alignment.centerLeft,
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Container(
                height: 22,
                width: 22,
                decoration: BoxDecoration(
                  color: _wantsToBeGuide ? Colors.black : Colors.white70,
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ),
        ],
      ),
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
            if (_currentStep < 3) {
              if (_formKey.currentState!.validate()) {
                setState(() => _currentStep++);
              }
            } else {
              if (_formKey.currentState!.validate()) {
                await _submitTourismPlace();
              }
            }
          },
          child: Text(_currentStep < 3 ? "Next" : "Submit"),
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
        validator: (value) =>
            (value == null || value.isEmpty) ? 'Please enter $label' : null,
      ),
    );
  }

  // 📅 Custom Date Picker Field
  Widget _buildDatePicker(String label, TextEditingController controller) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: controller,
        readOnly: true,
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
          suffixIcon: const Icon(
            Icons.calendar_today,
            color: Colors.cyanAccent,
          ),
        ),
        validator: (value) =>
            (value == null || value.isEmpty) ? 'Please select $label' : null,
        onTap: () async {
          FocusScope.of(context).requestFocus(FocusNode()); // prevent keyboard

          final DateTime now = DateTime.now();
          final DateTime? pickedDate = await showDatePicker(
            context: context,
            initialDate: now,
            firstDate: DateTime(1900),
            lastDate: DateTime(2100),
            builder: (context, child) {
              return Theme(
                data: Theme.of(context).copyWith(
                  colorScheme: const ColorScheme.dark(
                    primary: Colors.cyanAccent,
                    onPrimary: Colors.black,
                    surface: Color(0xFF1E1E1E),
                    onSurface: Colors.white,
                  ),
                  dialogBackgroundColor: const Color(0xFF121212),
                ),
                child: child!,
              );
            },
          );

          if (pickedDate != null) {
            setState(() {
              controller.text =
                  "${pickedDate.day.toString().padLeft(2, '0')}-${pickedDate.month.toString().padLeft(2, '0')}-${pickedDate.year}";
            });
          }
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
      items: items
          .map((item) => DropdownMenuItem(value: item, child: Text(item)))
          .toList(),
      onChanged: onChanged,
      validator: (val) =>
          val == null || val.isEmpty ? 'Please select $label' : null,
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
          // Fallback logic to handle missing fields
          townController.text = place.subLocality?.isNotEmpty == true
              ? place.subLocality!
              : (place.name ?? '');

          cityController.text = place.locality?.isNotEmpty == true
              ? place.locality!
              : (place.subAdministrativeArea ?? '');

          districtController.text =
              place.subAdministrativeArea?.isNotEmpty == true
              ? place.subAdministrativeArea!
              : (place.locality ?? '');

          stateController.text = place.administrativeArea?.isNotEmpty == true
              ? place.administrativeArea!
              : (place.isoCountryCode ?? '');
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No address found for the selected location.'),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error fetching address: $e')));
    }
  }

  Future<void> _submitTourismPlace() async {
    if (selectedZone == null ||
        category == null ||
        selectedCoordinates == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please complete all fields and select a location.'),
        ),
      );
      return;
    }

    setState(() => _isUploading = true);
    _uploadedImageUrls = [];
    for (final imageFile in _selectedImages) {
      final fileName = DateTime.now().millisecondsSinceEpoch.toString();
      final ref = FirebaseStorage.instance
          .ref()
          .child('places')
          .child(fileName);

      await ref.putFile(imageFile);
      final imageUrl = await ref.getDownloadURL();
      _uploadedImageUrls.add(imageUrl);
    }

    try {
      final data = widget.area == "cultural"
          ? {
              "name": placeNameController.text.trim(),
              "town": townController.text.trim(),
              "city": cityController.text.trim(),
              "district": districtController.text.trim(),
              "state": stateController.text.trim(),
              "start_date": startdateController.text.trim(),
              "end_date": enddateController.text.trim(),
              "entrance_fees": entrancefeesController.text.trim(),
              "description": descriptionController.text.trim(),
              "zone": selectedZone,
              "category": category,
              "latitude": selectedCoordinates!.latitude,
              "longitude": selectedCoordinates!.longitude,
              "isguide": _wantsToBeGuide,
              "verified": false,
              "useremail": widget.email,
              "created_at": FieldValue.serverTimestamp(),
              "review_rating": 0,
              "no_of_reviews": 0,
              "area": widget.area,
            }
          : {
              "name": placeNameController.text.trim(),
              "town": townController.text.trim(),
              "city": cityController.text.trim(),
              "district": districtController.text.trim(),
              "state": stateController.text.trim(),
              "time_needed_to_visit": timeNeededController.text.trim(),
              "entrance_fees": entrancefeesController.text.trim(),
              "description": descriptionController.text.trim(),
              "zone": selectedZone,
              "category": category,
              "best_season": selectedBestSeason,
              "latitude": selectedCoordinates!.latitude,
              "longitude": selectedCoordinates!.longitude,
              "verified": false,
              "isguide": _wantsToBeGuide,
              "useremail": widget.email,
              "videourl": _videoUrl,
              "created_at": FieldValue.serverTimestamp(),
              "review_rating": 0,
              "no_of_reviews": 0,
              "area": widget.area,
            };

      final placeRef = await FirebaseFirestore.instance
          .collection('usersubmittedplaces')
          .add(data);
      await FirebaseFirestore.instance
          .collection('users')
          .where('email', isEqualTo: widget.email)
          .limit(1)
          .get()
          .then((snapshot) {
            if (snapshot.docs.isNotEmpty) {
              final docId = snapshot.docs.first.id;
              FirebaseFirestore.instance.collection('users').doc(docId).update({
                'count': FieldValue.increment(1),
              });
            }
          });

      final imagesRef = placeRef.collection('images');
      for (final imageUrl in _uploadedImageUrls) {
        await imagesRef.add({
          "url": imageUrl,
          "submittedAt": FieldValue.serverTimestamp(),
        });
      }

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
        category = null;
        selectedBestSeason = null;
        selectedCoordinates = null;
      });
      Navigator.pop(context, true);
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      setState(() => _isUploading = false);
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
