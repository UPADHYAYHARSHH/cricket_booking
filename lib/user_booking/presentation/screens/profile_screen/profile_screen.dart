import 'package:firebase_auth/firebase_auth.dart';
import 'package:turfpro/common/constants/colors.dart';
import 'package:turfpro/user_booking/presentation/blocs/auth/auth_cubit.dart';
import 'package:turfpro/user_booking/presentation/blocs/auth/auth_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hugeicons/hugeicons.dart';

import '../../../constants/route_constants.dart';
import 'package:turfpro/common/config/feature_config.dart';

import 'package:turfpro/user_booking/presentation/blocs/profile/profile_cubit.dart';
import 'package:turfpro/user_booking/di/get_it/get_it.dart';
import 'package:shimmer/shimmer.dart';
import 'package:turfpro/user_booking/constants/widgets/app_text.dart';
import '../support/help_support_screen.dart';

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
            listenWhen: (prev, curr) =>
                prev.isDeleted != curr.isDeleted || prev.error != curr.error,
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
          body: BlocBuilder<ProfileCubit, ProfileState>(
            builder: (context, profileState) {
              debugPrint(
                  "[PROFILE_SCREEN] State: isLoading=${profileState.isLoading}, name=${profileState.name}, error=${profileState.error}");

              if (profileState.isLoading && profileState.name == null) {
                return const _ProfileSkeleton();
              }

              return Column(
                children: [
                  _buildProfileHeader(context, profileState),
                  Expanded(
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
                      child: Column(
                        children: [
                          if (FeatureConfig.isWalletEnabled) ...[
                            _buildWalletCard(context, profileState),
                            const SizedBox(height: 16),
                          ],
                          _buildAccountSection(context),
                          const SizedBox(height: 14),
                          _buildSupportSection(context),
                          const SizedBox(height: 14),
                          _buildDangerSection(context),
                          const SizedBox(height: 24),
                          _buildAppVersion(context),
                          const SizedBox(height: 16),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  // ─── COMPACT MODERN PROFILE HEADER ────────────────────────────
  Widget _buildProfileHeader(BuildContext context, ProfileState state) {
    final topPadding = MediaQuery.of(context).padding.top;
    final displayName = state.name?.isNotEmpty == true ? state.name! : "Player";
    final displayEmail = state.email?.isNotEmpty == true
        ? state.email!
        : (FirebaseAuth.instance.currentUser?.email ?? "");

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0B8457), Color(0xFF065B3C)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryDarkGreen.withValues(alpha: 0.25),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(24)),
        child: Stack(
          children: [
            // Decorative background glow circles
            Positioned(
              top: -30,
              right: -20,
              child: Container(
                width: 110,
                height: 110,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.07),
                ),
              ),
            ),
            Positioned(
              bottom: -20,
              left: -20,
              child: Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.04),
                ),
              ),
            ),

            Padding(
              padding: EdgeInsets.fromLTRB(18, topPadding + 8, 18, 18),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // App Bar Title Row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const AppText(
                        text: "Profile",
                        size: 20,
                        weight: FontWeight.w700,
                        color: AppColors.white,
                      ),
                      // Quick Edit Pill Button
                      GestureDetector(
                        onTap: () async {
                          HapticFeedback.lightImpact();
                          await Navigator.pushNamed(
                              context, AppRoutes.editProfileScreen);
                          if (context.mounted) {
                            context.read<ProfileCubit>().loadProfile();
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.25),
                              width: 1,
                            ),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.edit_outlined,
                                  size: 14, color: Colors.white),
                              SizedBox(width: 5),
                              Text(
                                "Edit",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Compact Profile Card Row
                  Row(
                    children: [
                      // Avatar
                      _buildAvatar(context, state),
                      const SizedBox(width: 14),

                      // Name & Username info
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            AppText(
                              text: displayName,
                              size: 18,
                              weight: FontWeight.w700,
                              color: AppColors.white,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            if (displayEmail.isNotEmpty)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.14),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  displayEmail,
                                  style: TextStyle(
                                    color: Colors.white.withValues(alpha: 0.9),
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── AVATAR WIDGET ────────────────────────────────────────────
  Widget _buildAvatar(BuildContext context, ProfileState state) {
    const double avatarSize = 62.0;

    return Container(
      width: avatarSize,
      height: avatarSize,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.5),
          width: 2.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: ClipOval(
        child: state.photoUrl != null && state.photoUrl!.isNotEmpty
            ? Image.network(
                state.photoUrl!,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  color: Colors.white.withValues(alpha: 0.2),
                  child: const Icon(Icons.person,
                      size: 34, color: AppColors.white),
                ),
              )
            : Container(
                color: Colors.white.withValues(alpha: 0.2),
                child:
                    const Icon(Icons.person, size: 34, color: AppColors.white),
              ),
      ),
    );
  }

  // ─── WALLET CARD ──────────────────────────────────────────────
  Widget _buildWalletCard(BuildContext context, ProfileState state) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? [const Color(0xFF1E3A8A), const Color(0xFF1E40AF)]
              : [const Color(0xFF2563EB), const Color(0xFF1D4ED8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: (isDark ? Colors.black : Colors.blue).withValues(alpha: 0.2),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.account_balance_wallet_rounded,
              color: Colors.white,
              size: 24,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Wallet Balance",
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  "₹${state.walletBalance.toStringAsFixed(2)}",
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Text(
              "Active",
              style: TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── ACCOUNT SECTION ──────────────────────────────────────────
  Widget _buildAccountSection(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return _buildSectionCard(
      context,
      title: "Account",
      items: [
        _MenuItem(
          icon: HugeIcons.strokeRoundedUser,
          label: "Edit Profile",
          iconBg:
              AppColors.primaryDarkGreen.withValues(alpha: isDark ? 0.2 : 0.1),
          iconColor:
              isDark ? AppColors.primaryLightGreen : AppColors.primaryDarkGreen,
          isLogout: false,
          onTap: () async {
            HapticFeedback.lightImpact();
            await Navigator.pushNamed(context, AppRoutes.editProfileScreen);
            if (context.mounted) {
              context.read<ProfileCubit>().loadProfile();
            }
          },
        ),
        _MenuItem(
          icon: HugeIcons.strokeRoundedNotification01,
          label: "Notification Settings",
          subtitle: "Push alerts & game reminders",
          iconBg: Colors.teal.withValues(alpha: isDark ? 0.2 : 0.1),
          iconColor:
              isDark ? Colors.tealAccent : const Color(0xFF00796B),
          isLogout: false,
          onTap: () async {
            HapticFeedback.lightImpact();
            await Navigator.pushNamed(
                context, AppRoutes.notificationSettings);
            if (context.mounted) {
              context.read<ProfileCubit>().loadProfile();
            }
          },
        ),
        _MenuItem(
          icon: HugeIcons.strokeRoundedCricketBat,
          label: "Generate 3D Avatar",
          subtitle: "Batsman, Bowler & All-Rounder",
          iconBg: Colors.indigo.withValues(alpha: isDark ? 0.2 : 0.1),
          iconColor:
              isDark ? Colors.indigoAccent : Colors.indigo.shade700,
          isLogout: false,
          onTap: () async {
            HapticFeedback.lightImpact();
            await Navigator.pushNamed(context, AppRoutes.avatarGenerator);
            if (context.mounted) {
              context.read<ProfileCubit>().loadProfile();
            }
          },
        ),
        if (FeatureConfig.isLoyaltyEnabled)
          _MenuItem(
            icon: HugeIcons.strokeRoundedStar,
            label: "My Rewards",
            iconBg: Colors.amber.withValues(alpha: isDark ? 0.2 : 0.1),
            iconColor: isDark ? Colors.amberAccent : Colors.amber.shade700,
            isLogout: false,
            onTap: () {
              HapticFeedback.lightImpact();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Rewards screen coming soon!")),
              );
            },
          ),
        if (FeatureConfig.isSplitEnabled)
          _MenuItem(
            icon: HugeIcons.strokeRoundedCreditCard,
            label: "Split History",
            iconBg: Colors.blue.withValues(alpha: isDark ? 0.2 : 0.1),
            iconColor: isDark ? Colors.blueAccent : Colors.blue.shade700,
            isLogout: false,
            onTap: () {
              HapticFeedback.lightImpact();
              Navigator.pushNamed(context, AppRoutes.splitHistory);
            },
          ),
      ],
    );
  }

  // ─── SUPPORT SECTION ──────────────────────────────────────────
  Widget _buildSupportSection(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return _buildSectionCard(
      context,
      title: "Support",
      items: [
        _MenuItem(
          icon: HugeIcons.strokeRoundedHelpCircle,
          label: "Help & Support",
          iconBg: Colors.purple.withValues(alpha: isDark ? 0.2 : 0.1),
          iconColor: isDark ? Colors.purpleAccent : const Color(0xFF7B1FA2),
          isLogout: false,
          onTap: () {
            HapticFeedback.lightImpact();
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const HelpSupportScreen()),
            );
          },
        ),
      ],
    );
  }

  // ─── DANGER ZONE SECTION ──────────────────────────────────────
  Widget _buildDangerSection(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return _buildSectionCard(
      context,
      title: "Account Actions",
      items: [
        _MenuItem(
          icon: HugeIcons.strokeRoundedLogout01,
          label: "Logout",
          iconBg: Colors.orange.withValues(alpha: isDark ? 0.15 : 0.1),
          iconColor: isDark ? Colors.orangeAccent : const Color(0xFFE65100),
          isLogout: true,
          onTap: () => _showLogoutDialog(context),
        ),
        _MenuItem(
          icon: HugeIcons.strokeRoundedDelete02,
          label: "Delete Account",
          iconBg: Colors.red.withValues(alpha: isDark ? 0.15 : 0.1),
          iconColor: isDark ? Colors.redAccent : const Color(0xFFD32F2F),
          isLogout: true,
          onTap: () => _showDeleteDialog(context),
        ),
      ],
    );
  }

  // ─── SECTION CARD BUILDER ─────────────────────────────────────
  Widget _buildSectionCard(
    BuildContext context, {
    required String title,
    required List<_MenuItem> items,
  }) {
    if (items.isEmpty) return const SizedBox.shrink();
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 6),
          child: Text(
            title,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
              letterSpacing: 0.5,
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: theme.cardColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.06)
                  : AppColors.borderLight,
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: ListView.separated(
            padding: EdgeInsets.zero,
            physics: const NeverScrollableScrollPhysics(),
            shrinkWrap: true,
            itemCount: items.length,
            separatorBuilder: (_, __) => Divider(
              height: 1,
              indent: 56,
              color: theme.dividerColor.withValues(alpha: 0.4),
            ),
            itemBuilder: (context, index) {
              return _MenuTile(item: items[index]);
            },
          ),
        ),
      ],
    );
  }

  // ─── APP VERSION ──────────────────────────────────────────────
  Widget _buildAppVersion(BuildContext context) {
    return Center(
      child: Text(
        "TurfPro • Version 1.0.0",
        style: TextStyle(
          fontSize: 12,
          color: Theme.of(context)
              .colorScheme
              .onSurface
              .withValues(alpha: 0.35),
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  // ─── DIALOGS ──────────────────────────────────────────────────
  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
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
              style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  void _showDeleteDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Delete Account"),
        content: const Text(
            "Are you sure you want to permanently delete your account and all associated data? This action cannot be undone."),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
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
            child: const Text(
              "Delete",
              style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── MENU TILE WIDGET ───────────────────────────────────────────

class _MenuTile extends StatelessWidget {
  final _MenuItem item;

  const _MenuTile({required this.item});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: item.onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: item.iconBg,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Center(
                  child: item.icon is IconData
                      ? Icon(item.icon, size: 18, color: item.iconColor)
                      : HugeIcon(
                          icon: item.icon, size: 18, color: item.iconColor),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      item.label,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: item.isLogout
                            ? (item.label == "Delete Account"
                                ? const Color(0xFFD32F2F)
                                : Theme.of(context).colorScheme.onSurface)
                            : Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                    if (item.subtitle != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        item.subtitle!,
                        style: TextStyle(
                          fontSize: 12,
                          color: Theme.of(context)
                              .colorScheme
                              .onSurface
                              .withValues(alpha: 0.5),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                size: 20,
                color: Theme.of(context)
                    .colorScheme
                    .onSurface
                    .withValues(alpha: 0.25),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── MODELS ─────────────────────────────────────────────────────

class _MenuItem {
  final dynamic icon;
  final String label;
  final String? subtitle;
  final Color iconBg;
  final Color iconColor;
  final bool isLogout;
  final void Function()? onTap;

  const _MenuItem({
    required this.icon,
    required this.label,
    this.subtitle,
    required this.iconBg,
    required this.iconColor,
    required this.isLogout,
    this.onTap,
  });
}

// ─── SKELETON LOADER ────────────────────────────────────────────

class _ProfileSkeleton extends StatelessWidget {
  const _ProfileSkeleton();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final baseColor = isDark ? Colors.grey[800]! : Colors.grey[300]!;
    final highlightColor = isDark ? Colors.grey[700]! : Colors.grey[100]!;
    final topPadding = MediaQuery.of(context).padding.top;

    return SingleChildScrollView(
      physics: const NeverScrollableScrollPhysics(),
      child: Shimmer.fromColors(
        baseColor: baseColor,
        highlightColor: highlightColor,
        child: Column(
          children: [
            // Compact Header Skeleton
            Container(
              width: double.infinity,
              padding: EdgeInsets.fromLTRB(18, topPadding + 8, 18, 18),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius:
                    BorderRadius.vertical(bottom: Radius.circular(24)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        width: 80,
                        height: 22,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                      Container(
                        width: 60,
                        height: 28,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Container(
                        width: 62,
                        height: 62,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 140,
                            height: 18,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(6),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Container(
                            width: 90,
                            height: 14,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Body Skeletons
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: [
                  if (FeatureConfig.isWalletEnabled) ...[
                    Container(
                      width: double.infinity,
                      height: 72,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(18),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      children: List.generate(
                          4, (index) => _buildMenuTileSkeleton()),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuTileSkeleton() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Container(
              height: 14,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(6),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Container(
            width: 16,
            height: 16,
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
