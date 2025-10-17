import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class CultureFormPage extends StatefulWidget {
  const CultureFormPage({super.key});

  @override
  State<CultureFormPage> createState() => _CultureFormPageState();
}

class _CultureFormPageState extends State<CultureFormPage> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _townController = TextEditingController();
  final TextEditingController _cityController = TextEditingController();
  final TextEditingController _districtController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();

  DateTime? _selectedDate;
  String? _selectedZone;
  String? _selectedCultureType;

  final List<String> zones = ['Northern', 'Southern', 'Western', 'Eastern'];
  final List<String> cultureTypes = [
    'Cultural Event',
    'Religious Festival',
    'Festival',
    'Food Festival',
    'Music Festival',
    'Tribal Festival',
  ];

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime(2100),
      builder: (context, child) {
        return Theme(data: ThemeData.dark(), child: child!);
      },
    );

    if (picked != null) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  void _submitForm() async {
    if (_formKey.currentState!.validate()) {
      final data = {
        'name': _nameController.text.trim(),
        'town': _townController.text.trim(),
        'city': _cityController.text.trim(),
        'district': _districtController.text.trim(),
        'starting_date': _selectedDate?.toIso8601String() ?? '',
        'description': _descriptionController.text.trim(),
        'zone': _selectedZone,
        'culture_type': _selectedCultureType,
        'created_at': Timestamp.now(),
      };

      try {
        await FirebaseFirestore.instance
            .collection('cultural_verify')
            .add(data);

        showDialog(
          // ignore: use_build_context_synchronously
          context: context,
          builder:
              (_) => AlertDialog(
                backgroundColor: Colors.grey[900],
                title: const Text(
                  'Success',
                  style: TextStyle(color: Colors.white),
                ),
                content: const Text(
                  'Your cultural event has been added.',
                  style: TextStyle(color: Colors.white70),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text(
                      'OK',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ],
              ),
        );

        _formKey.currentState!.reset();
        _nameController.clear();
        _townController.clear();
        _cityController.clear();
        _districtController.clear();
        _descriptionController.clear();
        setState(() {
          _selectedDate = null;
          _selectedZone = null;
          _selectedCultureType = null;
        });
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Colors.red,
            content: Text('Failed to submit: $e'),
          ),
        );
      }
    }
  }

  InputDecoration _inputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: Colors.black54),
      border: const OutlineInputBorder(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Cultural Details'),
        backgroundColor: Colors.black,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _nameController,
                decoration: _inputDecoration('Culture Name'),
                style: const TextStyle(color: Colors.black),
                validator:
                    (value) => value!.isEmpty ? 'Enter culture name' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _townController,
                decoration: _inputDecoration('Town'),
                style: const TextStyle(color: Colors.black),
                validator: (value) => value!.isEmpty ? 'Enter town' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _cityController,
                decoration: _inputDecoration('City'),
                style: const TextStyle(color: Colors.black),
                validator: (value) => value!.isEmpty ? 'Enter city' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _districtController,
                decoration: _inputDecoration('District'),
                style: const TextStyle(color: Colors.black),
                validator: (value) => value!.isEmpty ? 'Enter district' : null,
              ),
              const SizedBox(height: 12),
              InkWell(
                onTap: _pickDate,
                child: InputDecorator(
                  decoration: _inputDecoration('Starting Date'),
                  child: Text(
                    _selectedDate != null
                        ? '${_selectedDate!.day}-${_selectedDate!.month}-${_selectedDate!.year}'
                        : 'Select a date',
                    style: const TextStyle(color: Colors.black),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _descriptionController,
                maxLines: 4,
                decoration: _inputDecoration('Description'),
                style: const TextStyle(color: Colors.black),
                validator:
                    (value) => value!.isEmpty ? 'Enter description' : null,
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: _selectedZone,
                items:
                    zones
                        .map(
                          (zone) =>
                              DropdownMenuItem(value: zone, child: Text(zone)),
                        )
                        .toList(),
                decoration: _inputDecoration('Zone'),
                dropdownColor: Colors.white,
                style: const TextStyle(color: Colors.black),
                onChanged: (value) => setState(() => _selectedZone = value),
                validator: (value) => value == null ? 'Select a zone' : null,
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: _selectedCultureType,
                items:
                    cultureTypes
                        .map(
                          (type) =>
                              DropdownMenuItem(value: type, child: Text(type)),
                        )
                        .toList(),
                decoration: _inputDecoration('Culture Type'),
                dropdownColor: Colors.white,
                style: const TextStyle(color: Colors.black),
                onChanged:
                    (value) => setState(() => _selectedCultureType = value),
                validator:
                    (value) => value == null ? 'Select culture type' : null,
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _submitForm,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepPurple,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text('Submit', style: TextStyle(fontSize: 16)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
