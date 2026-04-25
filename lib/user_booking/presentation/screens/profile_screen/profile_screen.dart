import 'package:turfpro/common/constants/colors.dart';
import 'package:turfpro/user_booking/presentation/blocs/auth/auth_cubit.dart';
import 'package:turfpro/user_booking/presentation/blocs/auth/auth_state.dart';
import 'package:turfpro/user_booking/presentation/blocs/theme/theme_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hugeicons/hugeicons.dart';

import '../../../constants/route_constants.dart';

import 'package:turfpro/user_booking/presentation/blocs/profile/profile_cubit.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:turfpro/user_booking/di/get_it/get_it.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

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
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                  child: Column(
                    children: [
                      _buildAvatar(context, profileState),
                      const SizedBox(height: 14),
                      _buildNameSection(context, profileState),
                      const SizedBox(height: 28),
                      _buildMenuList(context),
                      const SizedBox(height: 24),
                      _buildProBanner(context),
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
                color: Colors.black.withValues(alpha: Theme.of(context).brightness == Brightness.dark ? 0.3 : 0.08),
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
                      child: const Icon(Icons.person, size: 44, color: Colors.grey),
                    ),
                  )
                : Container(
                    color: Colors.grey.shade200,
                    child: const Icon(Icons.person, size: 44, color: Colors.grey),
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
      final croppedFile = await ImageCropper().cropImage(
        sourcePath: image.path,
        aspectRatio: const CropAspectRatio(ratioX: 1, ratioY: 1),
        uiSettings: [
          AndroidUiSettings(
            toolbarTitle: 'Crop Profile Picture',
            toolbarColor: AppColors.primaryDarkGreen,
            toolbarWidgetColor: Colors.white,
            lockAspectRatio: true,
          ),
          IOSUiSettings(
            title: 'Crop Profile Picture',
            aspectRatioLockEnabled: true,
            resetAspectRatioEnabled: false,
          ),
        ],
      );

      if (croppedFile != null && context.mounted) {
        context.read<ProfileCubit>().uploadImage(XFile(croppedFile.path));
      }
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
          state.username != null ? "@${state.username}" : "User",
          style: const TextStyle(
            fontSize: 14,
            color: AppColors.primaryDarkGreen,
            fontWeight: FontWeight.w600,
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
        iconBg: AppColors.primaryDarkGreen.withOpacity(isDark ? 0.2 : 0.1),
        iconColor: isDark ? AppColors.primaryLightGreen : AppColors.primaryDarkGreen,
        isLogout: false,
        onTap: () async {
          await Navigator.pushNamed(context, AppRoutes.editProfileScreen);
          if (context.mounted) {
            context.read<ProfileCubit>().loadProfile();
          }
        },
      ),
      _MenuItem(
        icon: isDark ? HugeIcons.strokeRoundedMoon : HugeIcons.strokeRoundedSun01,
        label: "Dark Mode",
        iconBg: isDark ? Colors.blueGrey.withOpacity(0.2) : Colors.amber.withOpacity(0.1),
        iconColor: isDark ? Colors.lightBlueAccent : AppColors.accentOrange,
        isLogout: false,
        trailing: Switch(
          value: isDark,
          onChanged: (_) => themeCubit.toggleTheme(),
          activeThumbColor: AppColors.accentOrange,
        ),
      ),
      // _MenuItem(
      //   icon: Icons.receipt_long_outlined,
      //   label: "Split Bill History",
      //   iconBg: const Color(0xFFFFF3E0).withValues(alpha: isDark ? 0.1 : 1),
      //   iconColor: Colors.orange.shade800,
      //   isLogout: false,
      //   onTap: () => Navigator.pushNamed(context, AppRoutes.splitHistory),
      // ),
      _MenuItem(
        icon: Icons.help_outline_rounded,
        label: "Help & Support",
        iconBg: Colors.purple.withOpacity(isDark ? 0.2 : 0.1),
        iconColor: isDark ? Colors.purpleAccent : const Color(0xFF7B1FA2),
        isLogout: false,
      ),
      _MenuItem(
        icon: Icons.logout_rounded,
        label: "Logout",
        iconBg: Colors.red.withOpacity(isDark ? 0.2 : 0.1),
        iconColor: isDark ? Colors.redAccent : const Color(0xFFD32F2F),
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
            color: Colors.black.withValues(alpha: 0.05),
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
          color: Theme.of(context).dividerColor.withValues(alpha: 0.5),
        ),
        itemBuilder: (context, index) {
          final item = menuItems[index];
          return _MenuTile(item: item);
        },
      ),
    );
  }

  Widget _buildProBanner(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark 
            ? [AppColors.surfaceDark, AppColors.bgDark] 
            : [AppColors.primaryDarkGreen, AppColors.primaryLightGreen],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.3 : 0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
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
              color: Colors.white.withValues(alpha: 0.6),
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
                backgroundColor: isDark ? AppColors.accentOrange : Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                "Go Pro Membership",
                style: TextStyle(
                  color: isDark ? Colors.white : AppColors.primaryDarkGreen,
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
              child: item.icon is IconData ? Icon(item.icon, size: 18, color: item.iconColor) : HugeIcon(icon: item.icon, size: 18, color: item.iconColor),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                item.label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: item.isLogout ? const Color(0xFFD32F2F) : Theme.of(context).colorScheme.onSurface,
                ),
              ),
            ),
            if (item.trailing != null)
              item.trailing!
            else
              Icon(
                Icons.chevron_right_rounded,
                size: 20,
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.2),
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
