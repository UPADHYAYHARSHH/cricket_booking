import sys

def replace_function(content, func_name, new_code):
    start_idx = content.find(f"static Widget {func_name}(")
    if start_idx == -1:
        print(f"Function {func_name} not found")
        return content
    
    # find the opening brace {
    brace_idx = content.find('{', start_idx)
    if brace_idx == -1:
        return content
    
    # match braces to find the end
    brace_count = 1
    end_idx = brace_idx + 1
    while brace_count > 0 and end_idx < len(content):
        if content[end_idx] == '{':
            brace_count += 1
        elif content[end_idx] == '}':
            brace_count -= 1
        end_idx += 1
    
    return content[:start_idx] + new_code + content[end_idx:]

with open("lib/user_booking/presentation/widgets/slot_selection_widgets.dart", "r", encoding="utf-8") as f:
    content = f.read()

sport_code = """static Widget buildSportSelection(
      BuildContext context, SlotSelectionState state,
      {required Function(String) onSportChanged}) {
    if (state.availableSports.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const AppText(
            text: "SELECT SPORT",
            textStyle: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 16),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 1.5,
            ),
            itemCount: state.availableSports.length,
            itemBuilder: (context, index) {
              final sport = state.availableSports[index];
              final isSel = sport == state.selectedSport;

              return GestureDetector(
                onTap: () => onSportChanged(sport),
                child: Container(
                  decoration: BoxDecoration(
                    color: isSel ? AppColors.primaryDarkGreen.withOpacity(0.05) : Colors.white,
                    border: Border.all(
                      color: isSel ? AppColors.primaryDarkGreen : Theme.of(context).dividerColor.withOpacity(0.2),
                      width: 2,
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: isSel ? AppColors.primaryDarkGreen : Theme.of(context).colorScheme.surface,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          _getSportIcon(sport),
                          color: isSel ? Colors.white : AppColors.primaryDarkGreen,
                          size: 24,
                        ),
                      ),
                      const SizedBox(height: 8),
                      AppText(
                        text: sport,
                        textStyle: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }"""

ground_code = """static Widget buildGroundSelection(
      BuildContext context, SlotSelectionState state,
      {required Function(GroundModel) onTurfChanged}) {
    if (state.selectedSport == null || state.availableTurfs.isEmpty) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const AppText(
            text: "SELECT GROUND",
            textStyle: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 16),
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: state.availableTurfs.length,
            itemBuilder: (context, index) {
              final turf = state.availableTurfs[index];
              final isSelected = state.selectedTurf?.id == turf.id;
              final isAvailable = turf.isAvailable;

              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: GestureDetector(
                  onTap: isAvailable ? () => onTurfChanged(turf) : null,
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border.all(
                        color: isSelected ? AppColors.primaryDarkGreen : Theme.of(context).dividerColor.withOpacity(0.2),
                        width: isSelected ? 2 : 1,
                      ),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.stadium_outlined,
                          color: isSelected ? AppColors.primaryDarkGreen : Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                          size: 24,
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              AppText(
                                text: turf.name,
                                textStyle: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: isSelected ? AppColors.primaryDarkGreen : Theme.of(context).colorScheme.onSurface,
                                  decoration: isAvailable ? null : TextDecoration.lineThrough,
                                ),
                              ),
                              AppText(
                                text: turf.categories.isNotEmpty ? turf.categories.first : "Turf Pitch",
                                textStyle: TextStyle(
                                  fontSize: 12,
                                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (isSelected)
                          const Icon(Icons.check_circle, color: AppColors.primaryDarkGreen, size: 24)
                        else
                          Container(
                            width: 24,
                            height: 24,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Theme.of(context).dividerColor.withOpacity(0.3),
                                width: 2,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }"""

amenities_code = """static Widget buildAmenitiesSection(BuildContext context, List<String>? amenities) {
    if (amenities == null || amenities.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const AppText(
            text: "AMENITIES",
            textStyle: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 16),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 4,
              crossAxisSpacing: 8,
              mainAxisSpacing: 16,
              childAspectRatio: 0.8,
            ),
            itemCount: amenities.length,
            itemBuilder: (context, index) {
              final amenity = amenities[index];
              return Column(
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surface,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      getAmenityIcon(amenity),
                      color: AppColors.primaryDarkGreen,
                      size: 24,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Expanded(
                    child: AppText(
                      text: amenity.toUpperCase(),
                      align: TextAlign.center,
                      textStyle: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }"""

map_code = """static Widget buildMapSection(BuildContext context, {required double latitude, required double longitude, required String address}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const AppText(
            text: "LOCATION",
            textStyle: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 16),
          InkWell(
            onTap: () async {
              final url = "geo:$latitude,$longitude?q=$latitude,$longitude(${Uri.encodeComponent(address)})";
              if (await canLaunchUrlString(url)) {
                await launchUrlString(url);
              }
            },
            child: Container(
              height: 160,
              width: double.infinity,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Theme.of(context).dividerColor.withOpacity(0.2)),
                color: Colors.grey.withOpacity(0.1),
              ),
              child: Stack(
                children: [
                  Positioned.fill(
                    child: Opacity(
                      opacity: 0.5,
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          image: const DecorationImage(
                            image: NetworkImage("https://maps.googleapis.com/maps/api/staticmap?center=0,0&zoom=15&size=600x300"), // Fallback dummy visual
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                    ),
                  ),
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        color: AppColors.primaryDarkGreen.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  ),
                  Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.9),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 10,
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.location_on, color: Colors.red, size: 16),
                          const SizedBox(width: 8),
                          AppText(
                            text: address.length > 25 ? "${address.substring(0, 25)}..." : address,
                            textStyle: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }"""

review_code = """static Widget buildReviewSection(BuildContext context, List<ReviewModel> reviews, bool isLoading) {
    if (isLoading) {
      return const Padding(
        padding: EdgeInsets.all(16.0),
        child: Center(child: CircularProgressIndicator()),
      );
    }
    
    if (reviews.isEmpty) return const SizedBox.shrink();

    final averageRating = reviews.fold(0.0, (sum, review) => sum + review.rating) / reviews.length;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const AppText(
                text: "REVIEWS",
                textStyle: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.2,
                ),
              ),
              Row(
                children: [
                  const Icon(Icons.star, color: AppColors.goldenYellow, size: 16),
                  const SizedBox(width: 4),
                  AppText(
                    text: averageRating.toStringAsFixed(1),
                    textStyle: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(width: 4),
                  AppText(
                    text: "(${reviews.length})",
                    textStyle: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5)),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: reviews.take(3).length,
            separatorBuilder: (context, index) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final review = reviews[index];
              return Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Theme.of(context).dividerColor.withOpacity(0.1)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 32,
                              height: 32,
                              decoration: const BoxDecoration(
                                color: AppColors.primaryDarkGreen,
                                shape: BoxShape.circle,
                              ),
                              child: Center(
                                child: AppText(
                                  text: review.reviewerName.isNotEmpty ? review.reviewerName[0].toUpperCase() : "?",
                                  textStyle: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                AppText(
                                  text: review.reviewerName,
                                  textStyle: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                AppText(
                                  text: "Recent", // In a real app, calculate time ago
                                  textStyle: TextStyle(
                                    fontSize: 10,
                                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        Row(
                          children: List.generate(5, (starIndex) {
                            return Icon(
                              Icons.star,
                              size: 14,
                              color: starIndex < review.rating ? AppColors.goldenYellow : Theme.of(context).dividerColor.withOpacity(0.3),
                            );
                          }),
                        ),
                      ],
                    ),
                    if (review.comment.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      AppText(
                        text: review.comment,
                        textStyle: TextStyle(
                          fontSize: 14,
                          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                        ),
                      ),
                    ],
                  ],
                ),
              );
            },
          ),
          if (reviews.length > 3)
            Padding(
              padding: const EdgeInsets.only(top: 16),
              child: AppText(
                text: "View all ${reviews.length} reviews",
                textStyle: const TextStyle(
                  color: AppColors.primaryDarkGreen,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ),
        ],
      ),
    );
  }"""

content = replace_function(content, "buildSportSelection", sport_code)
content = replace_function(content, "buildGroundSelection", ground_code)
content = replace_function(content, "buildAmenitiesSection", amenities_code)
content = replace_function(content, "buildMapSection", map_code)
content = replace_function(content, "buildReviewSection", review_code)

with open("lib/user_booking/presentation/widgets/slot_selection_widgets.dart", "w", encoding="utf-8") as f:
    f.write(content)

print("Replacement script complete")
