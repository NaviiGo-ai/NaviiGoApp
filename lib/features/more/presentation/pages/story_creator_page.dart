import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/constants/master_destinations.dart';
import '../../../trips/presentation/providers/trip_provider.dart';
import '../../../trips/domain/models/trip_itinerary_model.dart';

class StoryCreatorPage extends ConsumerStatefulWidget {
  const StoryCreatorPage({super.key});

  @override
  ConsumerState<StoryCreatorPage> createState() => _StoryCreatorPageState();
}

class _StoryCreatorPageState extends ConsumerState<StoryCreatorPage> {
  int _step = 0; // 0: Select Journey, 1: Select Format, 2: 9:16 Preview
  TripItineraryModel? _selectedTrip;
  String _selectedFormat = 'JOURNEY RECAP';
  String _caption =
      'Walking the quiet sunrise corridors and ancient red-sandstone walls.';

  final List<Map<String, String>> _storyFormats = [
    {
      'title': 'JOURNEY RECAP',
      'subtitle': 'Full multi-day chapter retrospective',
      'icon': '🗺️',
    },
    {
      'title': 'THE ROUTE',
      'subtitle': 'Consecutive checkpoints & transit paths',
      'icon': '📍',
    },
    {
      'title': '48 HOURS IN...',
      'subtitle': 'Fast-paced weekend immersion',
      'icon': '⚡',
    },
    {
      'title': 'DAY RECAP',
      'subtitle': 'Single day highlights and dawn chants',
      'icon': '🌅',
    },
    {
      'title': 'FOOD TRAIL',
      'subtitle': 'Signature spices, thalis, and street stalls',
      'icon': '☕',
    },
  ];

  @override
  Widget build(BuildContext context) {
    final allTrips = ref.watch(userTripsStreamProvider).valueOrNull ?? [];

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: AppColors.textPrimary,
            size: 18,
          ),
          onPressed: () {
            if (_step > 0) {
              setState(() => _step--);
            } else {
              if (context.canPop()) {
                context.pop();
              } else {
                context.go('/home');
              }
            }
          },
        ),
        title: Text(
          'Story Creator Beta',
          style: AppTypography.editorialTitle(
            color: AppColors.brown,
          ).copyWith(fontSize: 19),
        ),
        centerTitle: true,
      ),
      body: _step == 2
          ? _buildStory916Preview(context)
          : SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (_step == 0) _buildStep0ChooseJourney(allTrips),
                  if (_step == 1) _buildStep1ChooseFormat(),
                ],
              ),
            ),
      bottomNavigationBar: _step < 2 ? _buildBottomBar() : null,
    );
  }

  // STEP 0: CHOOSE JOURNEY
  Widget _buildStep0ChooseJourney(List<TripItineraryModel> userTrips) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: const BoxDecoration(
                color: AppColors.primary,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              'STEP 01 · NAVIIGO ALREADY KNOWS YOUR JOURNEY',
              style: AppTypography.eyebrow(color: AppColors.primary),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          'Select a Journey',
          style: AppTypography.editorialTitle(color: AppColors.brown),
        ),
        const SizedBox(height: 6),
        Text(
          'Choose from your logged trips or create a story for any destination in the Naviigo atlas.',
          style: AppTypography.bodyMedium(),
        ),
        const SizedBox(height: 20),

        if (userTrips.isNotEmpty) ...[
          Text(
            'YOUR TRIPS',
            style: AppTypography.eyebrow(color: AppColors.textTertiary),
          ),
          const SizedBox(height: 10),
          ...userTrips.map((t) {
            final isSelected = _selectedTrip?.id == t.id;
            return GestureDetector(
              onTap: () => setState(() => _selectedTrip = t),
              child: Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppColors.cream.withAlpha(90)
                      : AppColors.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isSelected ? AppColors.primary : AppColors.border,
                    width: isSelected ? 1.5 : 1,
                  ),
                ),
                child: Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Image.network(
                        t.heroImage,
                        width: 56,
                        height: 56,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          width: 56,
                          height: 56,
                          color: AppColors.surfaceWarm,
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(t.destName, style: AppTypography.tripTitle()),
                          Text(
                            '${t.totalDays} Days · ${t.dayPlans.length} chapters',
                            style: AppTypography.micro(),
                          ),
                        ],
                      ),
                    ),
                    if (isSelected)
                      const Icon(
                        Icons.check_circle_rounded,
                        color: AppColors.primary,
                        size: 20,
                      ),
                  ],
                ),
              ),
            );
          }),
          const SizedBox(height: 20),
        ],

        Text(
          'ATLAS DESTINATIONS',
          style: AppTypography.eyebrow(color: AppColors.textTertiary),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: kMasterDestinations.take(6).map((d) {
            final isSelected = _selectedTrip?.destName == d.name;
            return ChoiceChip(
              label: Text(d.name),
              selected: isSelected,
              selectedColor: AppColors.primary,
              labelStyle: AppTypography.caption(
                color: isSelected ? Colors.white : AppColors.textPrimary,
              ),
              backgroundColor: AppColors.surface,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(
                  color: isSelected ? AppColors.primary : AppColors.border,
                ),
              ),
              onSelected: (_) {
                setState(() {
                  _selectedTrip = TripItineraryModel(
                    id: 'temp_${d.id}',
                    uuid: 'temp_${d.id}',
                    destId: d.id,
                    destName: d.name,
                    form: {'heroImage': d.image, 'days': 3},
                  );
                });
              },
            );
          }).toList(),
        ),
      ],
    );
  }

  // STEP 1: CHOOSE FORMAT & CAPTION
  Widget _buildStep1ChooseFormat() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('STEP 02', style: AppTypography.eyebrow(color: AppColors.primary)),
        const SizedBox(height: 6),
        Text(
          'Select Story Format',
          style: AppTypography.editorialTitle(color: AppColors.brown),
        ),
        const SizedBox(height: 6),
        Text(
          'NaviiGo structures layout, waypoints, and typography automatically.',
          style: AppTypography.bodyMedium(),
        ),
        const SizedBox(height: 20),
        ..._storyFormats.map((f) {
          final isSelected = _selectedFormat == f['title'];
          return GestureDetector(
            onTap: () => setState(() => _selectedFormat = f['title']!),
            child: Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.cream.withAlpha(90)
                    : AppColors.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isSelected ? AppColors.primary : AppColors.border,
                  width: isSelected ? 1.5 : 1,
                ),
              ),
              child: Row(
                children: [
                  Text(f['icon']!, style: const TextStyle(fontSize: 24)),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          f['title']!,
                          style: AppTypography.caption(
                            color: AppColors.textPrimary,
                          ).copyWith(fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          f['subtitle']!,
                          style: AppTypography.micro(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    isSelected
                        ? Icons.radio_button_checked
                        : Icons.radio_button_unchecked,
                    color: isSelected
                        ? AppColors.primary
                        : AppColors.textTertiary,
                    size: 20,
                  ),
                ],
              ),
            ),
          );
        }),
        const SizedBox(height: 16),
        Text(
          'JOURNEY CAPTION',
          style: AppTypography.eyebrow(color: AppColors.textTertiary),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: TextEditingController(text: _caption),
          onChanged: (val) => _caption = val,
          maxLines: 2,
          style: AppTypography.bodyMedium(),
          decoration: InputDecoration(
            hintText: 'Add an editorial note or personal memory...',
            filled: true,
            fillColor: AppColors.surface,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: AppColors.border),
            ),
          ),
        ),
      ],
    );
  }

  // STEP 2: 9:16 EXPENSIVE STORY CANVAS PREVIEW (PART 37)
  Widget _buildStory916Preview(BuildContext context) {
    final dest = _selectedTrip?.destName ?? 'Rajasthan';
    final image = _selectedTrip?.heroImage ?? kMasterDestinations[1].image;
    final days = _selectedTrip?.totalDays ?? 4;

    return Column(
      children: [
        Expanded(
          child: Center(
            child: AspectRatio(
              aspectRatio: 9 / 16,
              child: Container(
                margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: AppColors.floatingShadow,
                  image: DecorationImage(
                    image: NetworkImage(image),
                    fit: BoxFit.cover,
                  ),
                ),
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(24),
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black.withAlpha((0.55 * 255).round()),
                        Colors.transparent,
                        Colors.transparent,
                        Colors.black.withAlpha((0.92 * 255).round()),
                      ],
                      stops: const [0.0, 0.25, 0.6, 1.0],
                    ),
                  ),
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header: Small Naviigo Branding & Format
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Image.asset(
                                'assets/brand/naviigo-mark-knockout.png',
                                width: 20,
                                height: 20,
                                errorBuilder: (_, __, ___) => const Icon(
                                  Icons.navigation,
                                  color: Colors.white,
                                  size: 16,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'NAVIIGO STORIES',
                                style: AppTypography.micro(color: Colors.white)
                                    .copyWith(
                                      letterSpacing: 2.0,
                                      fontWeight: FontWeight.w800,
                                    ),
                              ),
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white24,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              _selectedFormat,
                              style: AppTypography.micro(
                                color: Colors.white,
                              ).copyWith(fontSize: 8),
                            ),
                          ),
                        ],
                      ),
                      const Spacer(),

                      // Destination & Editorial Title
                      Text(
                        dest.toUpperCase(),
                        style: AppTypography.displayHero(
                          color: Colors.white,
                        ).copyWith(fontSize: 34, letterSpacing: 1.0),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        _caption,
                        style: AppTypography.bodyMedium(
                          color: AppColors.cream,
                        ).copyWith(fontSize: 13, height: 1.3),
                      ),
                      const SizedBox(height: 18),

                      // Route Graphic / Waypoint Line
                      Row(
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              color: AppColors.primary,
                              shape: BoxShape.circle,
                            ),
                          ),
                          Expanded(
                            child: Container(
                              height: 1.5,
                              color: AppColors.cream,
                              margin: const EdgeInsets.symmetric(horizontal: 6),
                            ),
                          ),
                          Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              color: AppColors.yellow,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // Story Metadata Footer (PART 37)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '$days DAYS · 8 PLACES',
                            style: AppTypography.micro(color: AppColors.cream)
                                .copyWith(
                                  letterSpacing: 1.2,
                                  fontWeight: FontWeight.w700,
                                ),
                          ),
                          Text(
                            'Travelled with NaviiGo',
                            style: AppTypography.micro(color: Colors.white70),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
        // Share / Export Bar
        Container(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
          decoration: const BoxDecoration(
            color: AppColors.surface,
            border: Border(top: BorderSide(color: AppColors.border)),
          ),
          child: SafeArea(
            top: false,
            child: Row(
              children: [
                OutlinedButton.icon(
                  onPressed: () => setState(() => _step = 1),
                  icon: const Icon(Icons.edit_outlined, size: 16),
                  label: const Text('EDIT'),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'Exported 9:16 Story for $dest to System Share Sheet!',
                          ),
                          backgroundColor: AppColors.brown,
                        ),
                      );
                    },
                    icon: const Icon(
                      Icons.share_outlined,
                      size: 18,
                      color: Colors.white,
                    ),
                    label: const Text('SHARE STORY'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBottomBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.border, width: 1)),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 50,
          child: ElevatedButton(
            onPressed: () {
              if (_selectedTrip == null) {
                // Default to first destination if none selected
                setState(() {
                  final d = kMasterDestinations[1];
                  _selectedTrip = TripItineraryModel(
                    id: 'temp_${d.id}',
                    uuid: 'temp_${d.id}',
                    destId: d.id,
                    destName: d.name,
                    form: {'heroImage': d.image, 'days': 4},
                  );
                });
              }
              setState(() => _step++);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  _step == 0
                      ? 'CONTINUE TO TEMPLATES'
                      : 'GENERATE 9:16 PREVIEW',
                  style: AppTypography.button(
                    color: Colors.white,
                  ).copyWith(letterSpacing: 0.8),
                ),
                const SizedBox(width: 6),
                const Icon(
                  Icons.arrow_forward_rounded,
                  size: 16,
                  color: Colors.white,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
