import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../../di/get_it/get_it.dart';
import '../../blocs/profile/profile_cubit.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _nameController = TextEditingController(text: 'Rahul Sharma');

  String _selectedGender = 'Male';
  DateTime? _selectedDate = DateTime(1995, 8, 15);

  static const _primaryGreen = Color(0xFF2D6A4F);
  static const _bgColor = Color(0xFFF5F5F5);
  static const _borderColor = Color(0xFFE0E0E0);

  final List<String> _genders = ['Male', 'Female', 'Other'];

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime(1995, 8, 15),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );

    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<ProfileCubit>(),
      child: BlocListener<ProfileCubit, ProfileState>(
        listener: (context, state) {
          if (state.isSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Profile updated successfully!')),
            );
          }

          if (state.error != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.error!)),
            );
          }
        },
        child: Scaffold(
          backgroundColor: _bgColor,
          appBar: AppBar(
            backgroundColor: _bgColor,
            elevation: 0,
            title: const Text(
              'Edit Profile',
              style: TextStyle(
                color: _primaryGreen,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                TextField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    hintText: 'Enter name',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 20),
                _genderSelector(),
                const SizedBox(height: 20),
                _datePicker(),
                const SizedBox(height: 30),
                BlocBuilder<ProfileCubit, ProfileState>(
                  builder: (context, state) {
                    return ElevatedButton(
                      onPressed: state.isLoading ? null : _saveChanges,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _primaryGreen,
                      ),
                      child: state.isLoading ? const CircularProgressIndicator(color: Colors.white) : const Text("Save"),
                    );
                  },
                )
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _genderSelector() {
    return Wrap(
      spacing: 10,
      children: _genders.map((gender) {
        final isSelected = _selectedGender == gender;

        return GestureDetector(
          onTap: () => setState(() => _selectedGender = gender),
          child: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: isSelected ? _primaryGreen : Colors.transparent,
              border: Border.all(color: _borderColor),
            ),
            child: Text(
              gender,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.black,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _datePicker() {
    final formatted = _selectedDate != null ? DateFormat('dd/MM/yyyy').format(_selectedDate!) : 'Select date';

    return GestureDetector(
      onTap: _pickDate,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          border: Border.all(color: _borderColor),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(formatted),
            const Icon(Icons.calendar_today),
          ],
        ),
      ),
    );
  }

  void _saveChanges() {
    context.read<ProfileCubit>().saveProfile(
          name: _nameController.text.trim(),
          gender: _selectedGender,
          dob: _selectedDate,
        );
  }
}
