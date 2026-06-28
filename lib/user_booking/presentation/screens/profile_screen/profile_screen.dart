import 'package:turfpro/common/constants/colors.dart';
import 'package:turfpro/user_booking/presentation/blocs/auth/auth_cubit.dart';
import 'package:turfpro/user_booking/presentation/blocs/auth/auth_state.dart';
import 'package:turfpro/user_booking/presentation/blocs/theme/theme_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hugeicons/hugeicons.dart';

import '../../../constants/route_constants.dart';
import 'package:turfpro/common/config/feature_config.dart';

import 'package:turfpro/user_booking/presentation/blocs/profile/profile_cubit.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:turfpro/user_booking/di/get_it/get_it.dart';
import 'package:shimmer/shimmer.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => getIt<ProfileCubit>()..loadProfile(),
        child: MultiBlocListener(
          listeners: [
            BlocListener<AuthCubit, AuthState>(
              listener: (context, state) {
                if (state is AuthInitial) {
                  Navigator.pushNamedAndRemoveUntil(
                    context,
                    AppRoutes.login,
                    (route) => false,
                  );
                }
              },
            ),
            BlocListener<ProfileCubit, ProfileState>(
              listenWhen: (prev, curr) => prev.isDeleted != curr.isDeleted || prev.error != curr.error,
              listener: (context, state) {
                if (state.isDeleted) {
                  Navigator.pushNamedAndRemoveUntil(
                    context,
                    AppRoutes.login,
                    (route) => false,
                  );
                  return;
                }
                
                if (state.error != null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(state.error!),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
            ),
          ],
          child: Scaffold(
            backgroundColor: Theme.of(context).scaffoldBackgroundColor,
            body: SafeArea(
              child: BlocBuilder<ProfileCubit, ProfileState>(
                builder: (context, profileState) {
                  debugPrint("[PROFILE_SCREEN] State: isLoading=${profileState.isLoading}, name=${profileState.name}, error=${profileState.error}");
                  
                  if (profileState.isLoading && profileState.name == null) {
                    return const _ProfileSkeleton();
                  }

                  return SingleChildScrollView(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                    child: Column(
                      children: [
                        _buildAvatar(context, profileState),
                        const SizedBox(height: 14),
                        _buildNameSection(context, profileState),
                        if (FeatureConfig.isWalletEnabled) ...[
                          const SizedBox(height: 24),
                          _buildWalletCard(context, profileState),
                        ],
                        const SizedBox(height: 28),
                        _buildMenuList(context),
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
                color: Colors.black.withValues(
                    alpha: Theme.of(context).brightness == Brightness.dark
                        ? 0.3
                        : 0.08),
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
      if (kIsWeb) {
        context.read<ProfileCubit>().uploadImage(XFile(image.path));
        return;
      }

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
          WebUiSettings(
            context: context,
            presentStyle: WebPresentStyle.page,
          ),
        ],
      );

      if (croppedFile != null && context.mounted) {
        context.read<ProfileCubit>().uploadImage(XFile(croppedFile.path));
      }
    }
  }

  Widget _buildWalletCard(BuildContext context, ProfileState state) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? [const Color(0xFF1E3A8A), const Color(0xFF1E40AF)]
              : [const Color(0xFF3B82F6), const Color(0xFF2563EB)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: (isDark ? Colors.black : Colors.blue).withValues(alpha: 0.2),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.account_balance_wallet_rounded,
                color: Colors.white, size: 28),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "My Wallet",
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  "₹${state.walletBalance.toStringAsFixed(2)}",
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Text(
              "Active",
              style: TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
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
        iconColor:
            isDark ? AppColors.primaryLightGreen : AppColors.primaryDarkGreen,
        isLogout: false,
        onTap: () async {
          await Navigator.pushNamed(context, AppRoutes.editProfileScreen);
          if (context.mounted) {
            context.read<ProfileCubit>().loadProfile();
          }
        },
      ),
      if (FeatureConfig.isLoyaltyEnabled)
        _MenuItem(
          icon: HugeIcons.strokeRoundedStar,
          label: "My Rewards",
          iconBg: Colors.amber.withOpacity(isDark ? 0.2 : 0.1),
          iconColor: isDark ? Colors.amberAccent : Colors.amber.shade700,
          isLogout: false,
          onTap: () {
            // Placeholder for rewards screen
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("Rewards screen coming soon!")),
            );
          },
        ),
      if (FeatureConfig.isSplitEnabled)
        _MenuItem(
          icon: HugeIcons.strokeRoundedCreditCard,
          label: "Split History",
          iconBg: Colors.blue.withOpacity(isDark ? 0.2 : 0.1),
          iconColor: isDark ? Colors.blueAccent : Colors.blue.shade700,
          isLogout: false,
          onTap: () => Navigator.pushNamed(context, AppRoutes.splitHistory),
        ),
      _MenuItem(
        icon:
            isDark ? HugeIcons.strokeRoundedMoon : HugeIcons.strokeRoundedSun01,
        label: "Dark Mode",
        iconBg: isDark
            ? Colors.blueGrey.withOpacity(0.2)
            : Colors.amber.withOpacity(0.1),
        iconColor: isDark ? Colors.lightBlueAccent : AppColors.accentOrange,
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
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text("Logout"),
              content: const Text("Are you sure you want to logout?"),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("Cancel"),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                    context.read<AuthCubit>().logout();
                  },
                  child: const Text(
                    "Logout",
                    style: TextStyle(color: Colors.red),
                  ),
                ),
              ],
            ),
          );
        },
      ),
      _MenuItem(
        icon: Icons.delete_outline_rounded,
        label: "Delete Account",
        iconBg: Colors.red.withOpacity(isDark ? 0.2 : 0.1),
        iconColor: isDark ? Colors.redAccent : const Color(0xFFD32F2F),
        isLogout: true,
        onTap: () {
          showDialog(
            context: context,
            builder: (ctx) => AlertDialog(
              title: const Text("Delete Account"),
              content: const Text(
                  "Are you sure you want to permanently delete your account and all associated data? This action cannot be undone."),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text("Cancel", style: TextStyle(color: Colors.grey)),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.pop(ctx);
                    context.read<ProfileCubit>().deleteAccount();
                  },
                  child: const Text("Delete", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          );
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
}

// ─── Stat Card ────────────────────────────────────────────────────────────────

// ─── Menu Tile ────────────────────────────────────────────────────────────────

class _MenuTile extends StatelessWidget {
  final _MenuItem item;

  const _MenuTile({required this.item});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
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
                color: Theme.of(context)
                    .colorScheme
                    .onSurface
                    .withValues(alpha: 0.2),
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

// ─── Skeleton Loader ──────────────────────────────────────────────────────────

class _ProfileSkeleton extends StatelessWidget {
  const _ProfileSkeleton();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final baseColor = isDark ? Colors.grey[800]! : Colors.grey[300]!;
    final highlightColor = isDark ? Colors.grey[700]! : Colors.grey[100]!;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Shimmer.fromColors(
        baseColor: baseColor,
        highlightColor: highlightColor,
        child: Column(
          children: [
            // Avatar Skeleton
            Container(
              width: 88,
              height: 88,
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(height: 14),
            
            // Name Skeleton
            Container(
              width: 150,
              height: 24,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            const SizedBox(height: 8),
            
            // Username Skeleton
            Container(
              width: 100,
              height: 16,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            const SizedBox(height: 28),

            // Wallet Card Skeleton (Optional, but good to have)
            if (FeatureConfig.isWalletEnabled) ...[
              Container(
                width: double.infinity,
                height: 100,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                ),
              ),
              const SizedBox(height: 28),
            ],

            // Menu List Skeleton
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: List.generate(6, (index) => _buildMenuTileSkeleton()),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuTileSkeleton() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          // Icon Skeleton
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          const SizedBox(width: 14),
          // Label Skeleton
          Expanded(
            child: Container(
              height: 16,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
          const SizedBox(width: 14),
          // Trailing Icon Skeleton
          Container(
            width: 20,
            height: 20,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        ],
      ),
    );
  }
}

