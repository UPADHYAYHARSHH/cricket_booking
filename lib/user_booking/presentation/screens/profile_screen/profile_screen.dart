import 'package:bloc_structure/common/constants/colors.dart';
import 'package:bloc_structure/user_booking/presentation/blocs/auth/auth_cubit.dart';
import 'package:bloc_structure/user_booking/presentation/blocs/auth/auth_state.dart';
import 'package:bloc_structure/user_booking/presentation/blocs/theme/theme_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hugeicons/hugeicons.dart';

import '../../../constants/route_constants.dart';

import 'dart:io';
import 'package:bloc_structure/user_booking/presentation/blocs/profile/profile_cubit.dart';
import 'package:image_picker/image_picker.dart';
import 'package:bloc_structure/user_booking/di/get_it/get_it.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  static const Color _primaryGreen = Color(0xFF2D6A2D);
  static const Color _orange = Color(0xFFFF6B1A);
  static const Color _darkCard = Color(0xFF1A1F2E);

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => getIt<ProfileCubit>()..loadProfile(),
      child: BlocListener<AuthCubit, AuthState>(
        listener: (context, state) {
          if (state is AuthInitial) {
            Navigator.pushNamedAndRemoveUntil(
              context,
              AppRoutes.login,
              (route) => false,
            );
          }
        },
        child: Scaffold(
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          body: SafeArea(
            child: BlocBuilder<ProfileCubit, ProfileState>(
              builder: (context, profileState) {
                if (profileState.isLoading && profileState.name == null) {
                  return const Center(child: CircularProgressIndicator());
                }

                return SingleChildScrollView(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                  child: Column(
                    children: [
                      _buildAvatar(context, profileState),
                      const SizedBox(height: 14),
                      _buildNameSection(context, profileState),
                      const SizedBox(height: 28),
                      _buildMenuList(context),
                      const SizedBox(height: 24),
                      _buildProBanner(),
                      const SizedBox(height: 16),
                    ],
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAvatar(BuildContext context, ProfileState state) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          width: 88,
          height: 88,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 3),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.12),
                blurRadius: 14,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ClipOval(
            child: state.photoUrl != null
                ? Image.network(
                    state.photoUrl!,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      color: Colors.grey.shade200,
                      child: const Icon(Icons.person,
                          size: 44, color: Colors.grey),
                    ),
                  )
                : Container(
                    color: Colors.grey.shade200,
                    child:
                        const Icon(Icons.person, size: 44, color: Colors.grey),
                  ),
          ),
        ),
        Positioned(
          bottom: 0,
          right: 0,
          child: GestureDetector(
            onTap: () => _pickImage(context),
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: AppColors.primaryDarkGreen,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
              ),
              child: const Icon(
                Icons.edit,
                size: 14,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _pickImage(BuildContext context) async {
    final picker = ImagePicker();
    final image = await picker.pickImage(source: ImageSource.gallery);
    if (image != null && context.mounted) {
      context.read<ProfileCubit>().uploadImage(File(image.path));
    }
  }

  Widget _buildNameSection(BuildContext context, ProfileState state) {
    return Column(
      children: [
        Text(
          state.name ?? "Player",
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          state.gender ?? "User",
          style: TextStyle(
            fontSize: 13,
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildStatsRow(BuildContext context) {
    return const Row(
      children: [
        Expanded(
          child: _StatCard(
            value: "42",
            label: "MATCHES\nPLAYED",
          ),
        ),
        SizedBox(width: 14),
        Expanded(
          child: _StatCard(
            value: "12",
            label: "MVPS\nWON",
          ),
        ),
      ],
    );
  }

  Widget _buildMenuList(BuildContext context) {
    final themeCubit = context.watch<ThemeCubit>();
    final isDark = themeCubit.state.themeMode == ThemeMode.dark;

    final menuItems = [
      _MenuItem(
        icon: Icons.person_outline_rounded,
        label: "Edit Profile",
        iconBg: const Color(0xFFE8F5E9).withOpacity(isDark ? 0.1 : 1),
        iconColor: isDark ? AppColors.primaryLightGreen : _primaryGreen,
        isLogout: false,
        onTap: () async {
          await Navigator.pushNamed(context, AppRoutes.editProfileScreen);
          if (context.mounted) {
            context.read<ProfileCubit>().loadProfile();
          }
        },
      ),
      _MenuItem(
        icon:
            isDark ? HugeIcons.strokeRoundedMoon : HugeIcons.strokeRoundedSun01,
        label: "Dark Mode",
        iconBg: isDark ? const Color(0xFF37474F) : const Color(0xFFFFF9C4),
        iconColor: isDark
            ? const Color.fromARGB(255, 0, 0, 0)
            : AppColors.accentOrange,
        isLogout: false,
        trailing: Switch(
          value: isDark,
          onChanged: (_) => themeCubit.toggleTheme(),
          activeThumbColor: AppColors.accentOrange,
        ),
      ),
      _MenuItem(
        icon: Icons.help_outline_rounded,
        label: "Help & Support",
        iconBg: const Color(0xFFF3E5F5).withOpacity(isDark ? 0.1 : 1),
        iconColor: const Color(0xFF7B1FA2),
        isLogout: false,
      ),
      _MenuItem(
        icon: Icons.logout_rounded,
        label: "Logout",
        iconBg: const Color(0xFFFFEBEE).withOpacity(isDark ? 0.1 : 1),
        iconColor: const Color(0xFFD32F2F),
        isLogout: true,
        onTap: () {
          context.read<AuthCubit>().logout();
        },
      ),
    ];

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ListView.separated(
        physics: const NeverScrollableScrollPhysics(),
        shrinkWrap: true,
        itemCount: menuItems.length,
        separatorBuilder: (_, __) => Divider(
          height: 1,
          indent: 58,
          color: Theme.of(context).dividerColor.withOpacity(0.5),
        ),
        itemBuilder: (context, index) {
          final item = menuItems[index];
          return _MenuTile(item: item);
        },
      ),
    );
  }

  Widget _buildProBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      decoration: BoxDecoration(
        color: _darkCard,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Elevate Your Game",
            style: TextStyle(
              color: Colors.white,
              fontSize: 17,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            "Unlock priority bookings, exclusive\ntournaments, and 15% discount on all turfs.",
            style: TextStyle(
              color: Colors.white.withOpacity(0.6),
              fontSize: 12,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 46,
            child: ElevatedButton(
              onPressed: () {},
              style: ElevatedButton.styleFrom(
                backgroundColor: _orange,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                "Go Pro Membership",
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Stat Card ────────────────────────────────────────────────────────────────

class _StatCard extends StatelessWidget {
  final String value;
  final String label;

  const _StatCard({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 18),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.4),
              letterSpacing: 0.8,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Menu Tile ────────────────────────────────────────────────────────────────

class _MenuTile extends StatelessWidget {
  final _MenuItem item;

  const _MenuTile({required this.item});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: item.onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: item.iconBg,
                borderRadius: BorderRadius.circular(10),
              ),
              child: item.icon is IconData
                  ? Icon(item.icon, size: 18, color: item.iconColor)
                  : HugeIcon(icon: item.icon, size: 18, color: item.iconColor),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                item.label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: item.isLogout
                      ? const Color(0xFFD32F2F)
                      : Theme.of(context).colorScheme.onSurface,
                ),
              ),
            ),
            if (item.trailing != null)
              item.trailing!
            else
              Icon(
                Icons.chevron_right_rounded,
                size: 20,
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.2),
              ),
          ],
        ),
      ),
    );
  }
}

// ─── Models ───────────────────────────────────────────────────────────────────

class _MenuItem {
  final dynamic icon;
  final String label;
  final Color iconBg;
  final Color iconColor;
  final bool isLogout;
  final Widget? trailing;
  final void Function()? onTap;

  const _MenuItem({
    required this.icon,
    required this.label,
    required this.iconBg,
    required this.iconColor,
    required this.isLogout,
    this.trailing,
    this.onTap,
  });
}
