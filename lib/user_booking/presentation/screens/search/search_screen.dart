import 'package:bloc_structure/user_booking/constants/widgets/app_sizedBox.dart';
import 'package:bloc_structure/user_booking/presentation/blocs/ground/ground_cubit.dart';
import 'package:bloc_structure/user_booking/presentation/blocs/ground/ground_state.dart';
import 'package:bloc_structure/user_booking/presentation/widgets/ground_card.dart';
import 'package:bloc_structure/user_booking/presentation/screens/ground_list/widgets/ground_skeleton.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:bloc_structure/user_booking/presentation/blocs/user_search/user_search_cubit.dart';
import 'package:bloc_structure/user_booking/presentation/widgets/user_card.dart';
import 'package:bloc_structure/user_booking/di/get_it/get_it.dart';

import '../../../constants/widgets/app_text.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => getIt<UserSearchCubit>(),
      child: DefaultTabController(
        length: 2,
        child: Builder(builder: (context) {
          return Scaffold(
            backgroundColor: Theme.of(context).scaffoldBackgroundColor,
            appBar: AppBar(
              backgroundColor: Theme.of(context).cardColor,
              elevation: 0,
              leading: IconButton(
                icon: Icon(Icons.arrow_back_ios_new,
                    size: 20, color: Theme.of(context).colorScheme.onSurface),
                onPressed: () => Navigator.pop(context),
              ),
              titleSpacing: 0,
              title: Padding(
                padding: const EdgeInsets.only(right: 16),
                child: Hero(
                  tag: 'search_bar',
                  child: Material(
                    color: Colors.transparent,
                    child: TextField(
                      controller: _searchController,
                      focusNode: _focusNode,
                      onChanged: (value) {
                        context.read<GroundCubit>().searchGrounds(value);
                        context.read<UserSearchCubit>().searchUsers(value);
                      },
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                      decoration: InputDecoration(
                        hintText: "Search turfs or usernames...",
                        hintStyle: TextStyle(
                          color: Theme.of(context)
                              .colorScheme
                              .onSurface
                              .withValues(alpha: 0.4),
                        ),
                        prefixIcon: Padding(
                          padding: const EdgeInsets.all(12),
                          child: HugeIcon(
                            icon: HugeIcons.strokeRoundedSearch01,
                            size: 18,
                            color: Theme.of(context)
                                .colorScheme
                                .onSurface
                                .withValues(alpha: 0.4),
                          ),
                        ),
                        prefixIconConstraints: const BoxConstraints(
                          minWidth: 40,
                        ),
                        filled: true,
                        fillColor: Theme.of(context).scaffoldBackgroundColor,
                        contentPadding:
                            const EdgeInsets.symmetric(vertical: 12),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(30),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              bottom: const TabBar(
                indicatorColor: Colors.green,
                labelColor: Colors.green,
                unselectedLabelColor: Colors.grey,
                indicatorWeight: 3,
                tabs: [
                  Tab(text: "Grounds"),
                  Tab(text: "Players"),
                ],
              ),
            ),
            body: TabBarView(
              children: [
                _buildGroundSearch(context),
                _buildUserSearch(context),
              ],
            ),
          );
        }),
      ),
    );
  }

  Widget _buildGroundSearch(BuildContext context) {
    return BlocBuilder<GroundCubit, GroundState>(
      builder: (context, state) {
        if (state is GroundLoading) {
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: 5,
            itemBuilder: (context, index) => const GroundSkeleton(),
          );
        }

        if (state is GroundLoaded) {
          if (_searchController.text.isEmpty) {
            return _buildEmptyState(context, "Search for your favorite turfs");
          }

          if (state.grounds.isEmpty) {
            return _buildNoResultsState(context, "No grounds found");
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: state.grounds.length,
            itemBuilder: (context, index) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: GroundCard(ground: state.grounds[index]),
              );
            },
          );
        }

        if (state is GroundError) {
          return Center(child: AppText(text: state.message));
        }

        return const SizedBox();
      },
    );
  }

  Widget _buildUserSearch(BuildContext context) {
    return BlocBuilder<UserSearchCubit, UserSearchState>(
      builder: (context, state) {
        if (state is UserSearchLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (state is UserSearchLoaded) {
          if (_searchController.text.isEmpty) {
            return _buildEmptyState(context, "Find other players by username");
          }

          if (state.users.isEmpty) {
            return _buildNoResultsState(context, "No players found");
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: state.users.length,
            itemBuilder: (context, index) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: UserCard(
                  user: state.users[index],
                  onTap: () {
                    // Navigate to user profile if needed
                  },
                ),
              );
            },
          );
        }

        if (state is UserSearchError) {
          return Center(child: AppText(text: state.message));
        }

        return _buildEmptyState(context, "Find other players by username");
      },
    );
  }

  Widget _buildEmptyState(BuildContext context, String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          HugeIcon(
            icon: HugeIcons.strokeRoundedSearch01,
            size: 64,
            color:
                Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.1),
          ),
          const AppSizedBox(height: 16),
          AppText(
            text: message,
            textStyle: TextStyle(
              color: Theme.of(context)
                  .colorScheme
                  .onSurface
                  .withValues(alpha: 0.4),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoResultsState(BuildContext context, String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          HugeIcon(
            icon: HugeIcons.strokeRoundedSearch01,
            size: 64,
            color:
                Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.1),
          ),
          const AppSizedBox(height: 16),
          AppText(text: message),
        ],
      ),
    );
  }
}
