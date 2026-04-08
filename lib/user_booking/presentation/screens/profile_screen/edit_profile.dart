import 'dart:io';
import 'package:bloc_structure/common/constants/colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';

import '../../../di/get_it/get_it.dart';
import '../../blocs/profile/profile_cubit.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  late TextEditingController _nameController;
  String _selectedGender = 'Male';
  DateTime? _selectedDate;
  String? _photoUrl;

  final List<String> _genders = ['Male', 'Female', 'Other'];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

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
      create: (_) => getIt<ProfileCubit>()..loadProfile(),
      child: BlocConsumer<ProfileCubit, ProfileState>(
        listenWhen: (prev, curr) =>
            prev.isSuccess != curr.isSuccess || curr.error != null,
        listener: (context, state) {
          if (state.isSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Profile updated successfully!')),
            );
            Navigator.pop(context);
          }

          if (state.error != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.error!)),
            );
          }
        },
        builder: (context, state) {
          final theme = Theme.of(context);
          final colorScheme = theme.colorScheme;
          final isDark = theme.brightness == Brightness.dark;

          if (state.isLoading && state.name == null) {
            return const Scaffold(
                body: Center(child: CircularProgressIndicator()));
          }

          // Initialize values from state if they are null
          if (_nameController.text.isEmpty && state.name != null) {
            _nameController.text = state.name!;
            _selectedGender = state.gender ?? 'Male';
            _selectedDate = state.dob;
            _photoUrl = state.photoUrl;
          }

          return Scaffold(
            backgroundColor: theme.scaffoldBackgroundColor,
            appBar: AppBar(
              backgroundColor: theme.scaffoldBackgroundColor,
              elevation: 0,
              centerTitle: true,
              leading: IconButton(
                icon: Icon(Icons.arrow_back, color: colorScheme.onSurface),
                onPressed: () => Navigator.pop(context),
              ),
              title: Text(
                'Edit Profile',
                style: TextStyle(
                  color: colorScheme.onSurface,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            body: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              child: Column(
                children: [
                  _buildAvatar(context, state),
                  const SizedBox(height: 32),
                  TextField(
                    controller: _nameController,
                    style: TextStyle(color: colorScheme.onSurface),
                    decoration: InputDecoration(
                      labelText: 'Full Name',
                      labelStyle: TextStyle(
                          color: colorScheme.onSurface.withOpacity(0.6)),
                      hintText: 'Enter your name',
                      filled: true,
                      fillColor: theme.cardColor,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide.none,
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: const BorderSide(
                            color: AppColors.primaryDarkGreen, width: 2),
                      ),
                      prefixIcon: Icon(Icons.person_outline,
                          color: colorScheme.primary),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      "Gender",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: colorScheme.onSurface.withOpacity(0.7),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildGenderSelector(theme),
                  const SizedBox(height: 24),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      "Date of Birth",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: colorScheme.onSurface.withOpacity(0.7),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildDatePicker(theme),
                  const SizedBox(height: 48),
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed:
                          state.isLoading ? null : () => _saveChanges(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryDarkGreen,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: state.isLoading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text(
                              "Save Changes",
                              style: TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                    ),
                  )
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildAvatar(BuildContext context, ProfileState state) {
    return Center(
      child: Stack(
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 4),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: ClipOval(
              child: state.photoUrl != null
                  ? Image.network(
                      state.photoUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _defaultAvatar(),
                    )
                  : _defaultAvatar(),
            ),
          ),
          Positioned(
            bottom: 5,
            right: 5,
            child: GestureDetector(
              onTap: () => _pickImage(context),
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: const BoxDecoration(
                  color: AppColors.primaryDarkGreen,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.camera_alt,
                  size: 20,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _defaultAvatar() {
    return Container(
      color: Colors.grey.shade200,
      child: const Icon(Icons.person, size: 60, color: Colors.grey),
    );
  }

  Future<void> _pickImage(BuildContext context) async {
    final picker = ImagePicker();
    final image = await picker.pickImage(source: ImageSource.gallery);
    if (image != null && context.mounted) {
      context.read<ProfileCubit>().uploadImage(File(image.path));
    }
  }

  Widget _buildGenderSelector(ThemeData theme) {
    return Wrap(
      spacing: 12,
      children: _genders.map((gender) {
        final isSelected = _selectedGender == gender;

        return GestureDetector(
          onTap: () => setState(() => _selectedGender = gender),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: BoxDecoration(
              color: isSelected ? AppColors.primaryDarkGreen : theme.cardColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected
                    ? AppColors.primaryDarkGreen
                    : theme.dividerColor,
                width: 1.5,
              ),
            ),
            child: Text(
              gender,
              style: TextStyle(
                color: isSelected ? Colors.white : theme.colorScheme.onSurface,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildDatePicker(ThemeData theme) {
    final formatted = _selectedDate != null
        ? DateFormat('dd MMM, yyyy').format(_selectedDate!)
        : 'Select date';

    return GestureDetector(
      onTap: _pickDate,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: theme.dividerColor, width: 1.5),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              formatted,
              style: TextStyle(
                color: _selectedDate != null
                    ? theme.colorScheme.onSurface
                    : theme.colorScheme.onSurface.withOpacity(0.5),
                fontSize: 15,
              ),
            ),
            Icon(Icons.calendar_today_outlined,
                size: 20, color: theme.colorScheme.primary),
          ],
        ),
      ),
    );
  }

  void _saveChanges(BuildContext context) {
    context.read<ProfileCubit>().saveProfile(
          name: _nameController.text.trim(),
          gender: _selectedGender,
          dob: _selectedDate,
        );
  }
}
