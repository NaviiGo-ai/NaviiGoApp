import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/constants/master_destinations.dart';
import '../../../bookings/presentation/providers/saved_places_provider.dart';
import '../../../bookings/domain/models/saved_place_model.dart';
import '../../../../core/auth/auth_provider.dart';

ImageProvider _resolveDestImage(String img) {
  if (img.startsWith('http')) return NetworkImage(img);
  if (img.startsWith('assets/')) return AssetImage(img);
  return const AssetImage('assets/brand/varanasi-dawn-hero.jpg');
}

class DestinationDetailsPage extends ConsumerStatefulWidget {
  final String id;
  const DestinationDetailsPage({super.key, required this.id});

  @override
  ConsumerState<DestinationDetailsPage> createState() =>
      _DestinationDetailsPageState();
}

class _DestinationDetailsPageState
    extends ConsumerState<DestinationDetailsPage> {
  bool _isSaved = false;

  MasterDestination get _destination {
    return findDestinationById(widget.id) ?? kMasterDestinations.first;
  }

  List<String> _getIconicPlaces(String id) {
    switch (id.toLowerCase()) {
      case 'varanasi':
        return [
          'Dashashwamedh Ghat (Evening Aarti)',
          'Kashi Vishwanath Golden Temple',
          'Assi Ghat Sunrise Prayers',
          'Sarnath Deer Park & Stupa',
        ];
      case 'jaipur':
        return [
          'Amer Fort & Sunlit Ramparts',
          'Hawa Mahal Honeycomb Facade',
          'City Palace Courtyards',
          'Jantar Mantar Royal Observatory',
        ];
      case 'udaipur':
        return [
          'Lake Pichola Twilight Boat Ride',
          'City Palace Marble Complex',
          'Jag Mandir Island Pavilion',
          'Saheliyon-ki-Bari Royal Fountains',
        ];
      case 'rishikesh':
        return [
          'Triveni Ghat Evening Aarti',
          'Lakshman Jhula Suspension Bridge',
          'Beatles Ashram & Forest Ruins',
          'Neer Garh Natural Waterfall',
        ];
      default:
        return [
          'Historic Old Quarter & Bazaars',
          'Central Cultural Landmark',
          'Sunset River/Hill Lookout',
          'Artisan Heritage Workshops',
        ];
    }
  }

  @override
  Widget build(BuildContext context) {
    final dest = _destination;
    final screenHeight = MediaQuery.of(context).size.height;
    final heroHeight = (screenHeight * 0.50).clamp(360.0, 480.0);
    final places = _getIconicPlaces(dest.id);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              // 1. Photographic Opening (Occupies ~50% of Viewport)
              SliverAppBar(
                expandedHeight: heroHeight,
                pinned: true,
                elevation: 0,
                backgroundColor: AppColors.background,
                leading: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: CircleAvatar(
                    backgroundColor: Colors.black.withAlpha(90),
                    child: IconButton(
                      icon: const Icon(
                        Icons.arrow_back_ios_new_rounded,
                        color: Colors.white,
                        size: 18,
                      ),
                      onPressed: () {
                        if (context.canPop()) {
                          context.pop();
                        } else {
                          context.go('/home');
                        }
                      },
                    ),
                  ),
                ),
                actions: [
                  // Bookmark/Save
                  Padding(
                    padding: const EdgeInsets.only(right: 6.0),
                    child: CircleAvatar(
                      backgroundColor: Colors.black.withAlpha(90),
                      child: IconButton(
                        icon: Icon(
                          _isSaved
                              ? Icons.bookmark_rounded
                              : Icons.bookmark_border_rounded,
                          color: _isSaved ? AppColors.yellow : Colors.white,
                          size: 20,
                        ),
                        onPressed: () async {
                          setState(() => _isSaved = !_isSaved);
                          if (_isSaved) {
                            final uid =
                                ref.read(currentUserProvider)?.uid ?? 'guest';
                            final place = SavedPlaceModel(
                              id: dest.id,
                              name: dest.name,
                              type: dest.category,
                              image: dest.image,
                              location: dest.state,
                              createdAt: DateTime.now(),
                            );
                            await ref
                                .read(savedPlacesRepositoryProvider)
                                .toggleSavedPlace(uid, place);
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    'Saved ${dest.name} to Passport',
                                  ),
                                  duration: const Duration(seconds: 2),
                                  backgroundColor: AppColors.brown,
                                ),
                              );
                            }
                          }
                        },
                      ),
                    ),
                  ),
                  // Share
                  Padding(
                    padding: const EdgeInsets.only(right: 12.0),
                    child: CircleAvatar(
                      backgroundColor: Colors.black.withAlpha(90),
                      child: IconButton(
                        icon: const Icon(
                          Icons.share_outlined,
                          color: Colors.white,
                          size: 20,
                        ),
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                'Shared ${dest.name} with fellow nomads',
                              ),
                              duration: const Duration(seconds: 2),
                              backgroundColor: AppColors.brown,
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ],
                flexibleSpace: FlexibleSpaceBar(
                  background: Stack(
                    fit: StackFit.expand,
                    children: [
                      Hero(
                        tag: 'destination-${dest.id}',
                        child: Image(
                          image: _resolveDestImage(dest.image),
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Image.asset(
                            'assets/brand/varanasi-dawn-hero.jpg',
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                      // Atmospheric dark gradient
                      Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            stops: const [0.0, 0.45, 0.85, 1.0],
                            colors: [
                              Colors.black.withAlpha(80),
                              Colors.transparent,
                              Colors.black.withAlpha(80),
                              AppColors.background,
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // 2. Overlapping Content Sheet & Editorial Sections
              SliverToBoxAdapter(
                child: Container(
                  decoration: const BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(30),
                    ),
                  ),
                  transform: Matrix4.translationValues(0.0, -26.0, 0.0),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(22, 24, 22, 120),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Drag Indicator Accent
                        Center(
                          child: Container(
                            width: 36,
                            height: 4,
                            decoration: BoxDecoration(
                              color: AppColors.border,
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                        ),
                        const SizedBox(height: 18),

                        // Editorial Title: Region kicker + Large Destination Title
                        Text(
                          '${dest.state.toUpperCase()}, INDIA',
                          style: AppTypography.eyebrow(
                            color: AppColors.primary,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          dest.name,
                          style: AppTypography.epilogue.copyWith(
                            fontSize: 34,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -1.0,
                            height: 1.1,
                            color: AppColors.brown,
                          ),
                        ),
                        const SizedBox(height: 10),

                        // Concise Real Metadata (Typography + Small Dividers - No Generic Equal Cards)
                        Row(
                          children: [
                            Text(
                              dest.category,
                              style: AppTypography.caption(
                                color: AppColors.brown,
                              ).copyWith(fontWeight: FontWeight.w700),
                            ),
                            const Text(
                              '  ·  ',
                              style: TextStyle(color: AppColors.textTertiary),
                            ),
                            const Icon(
                              Icons.star_rounded,
                              size: 14,
                              color: AppColors.yellow,
                            ),
                            const SizedBox(width: 3),
                            Text(
                              dest.rating.toStringAsFixed(1),
                              style: AppTypography.caption(
                                color: AppColors.textPrimary,
                              ).copyWith(fontWeight: FontWeight.w700),
                            ),
                            const Text(
                              '  ·  ',
                              style: TextStyle(color: AppColors.textTertiary),
                            ),
                            Text(
                              'Best ${dest.bestTime}',
                              style: AppTypography.caption(
                                color: AppColors.textSecondary,
                              ),
                            ),
                            const Text(
                              '  ·  ',
                              style: TextStyle(color: AppColors.textTertiary),
                            ),
                            Text(
                              dest.iata,
                              style: AppTypography.caption(
                                color: AppColors.textTertiary,
                              ).copyWith(fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),

                        const SizedBox(height: 28),

                        // SECTION 1: ABOUT
                        Text(
                          'ABOUT',
                          style: AppTypography.eyebrow(
                            color: AppColors.primary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          dest.description.isNotEmpty
                              ? dest.description
                              : 'Ancient architecture, spiritual traditions, and vibrant cultural tapestries define this iconic Indian territory.',
                          style: AppTypography.bodyLarge(
                            color: AppColors.textPrimary,
                          ).copyWith(height: 1.6),
                        ),

                        const SizedBox(height: 32),

                        // SECTION 2: WHY GO (Visually Emphasized Feature Block)
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: AppColors.primary.withAlpha(60),
                              width: 1.2,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.primary.withAlpha(12),
                                blurRadius: 16,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Icon(
                                    Icons.auto_awesome_rounded,
                                    size: 18,
                                    color: AppColors.primary,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'WHY GO',
                                    style: AppTypography.eyebrow(
                                      color: AppColors.primary,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              Text(
                                'Experience a timeless atmosphere where ancient customs and sacred rituals remain deeply woven into daily morning life.',
                                style:
                                    AppTypography.bodyMedium(
                                      color: AppColors.textPrimary,
                                    ).copyWith(
                                      height: 1.5,
                                      fontWeight: FontWeight.w500,
                                    ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 32),

                        // SECTION 3: PLACES (Curated Highlights)
                        Text(
                          'ICONIC WAYPOINTS',
                          style: AppTypography.eyebrow(
                            color: AppColors.primary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Curated Stops',
                          style: AppTypography.epilogue.copyWith(
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                            color: AppColors.brown,
                          ),
                        ),
                        const SizedBox(height: 14),

                        ...List.generate(places.length, (index) {
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12.0),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  width: 24,
                                  height: 24,
                                  decoration: const BoxDecoration(
                                    color: AppColors.cream,
                                    shape: BoxShape.circle,
                                  ),
                                  alignment: Alignment.center,
                                  child: Text(
                                    '${index + 1}',
                                    style: AppTypography.micro(
                                      color: AppColors.brown,
                                    ).copyWith(fontWeight: FontWeight.w800),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    places[index],
                                    style: AppTypography.bodyMedium(
                                      color: AppColors.textPrimary,
                                    ).copyWith(fontWeight: FontWeight.w600),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }),

                        const SizedBox(height: 28),

                        // SECTION 4: GALLERY (Editorial Horizontal Photography Rail)
                        Text(
                          'EXPEDITION GALLERY',
                          style: AppTypography.eyebrow(
                            color: AppColors.primary,
                          ),
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          height: 140,
                          child: ListView(
                            scrollDirection: Axis.horizontal,
                            physics: const BouncingScrollPhysics(),
                            children: [
                              _buildGalleryThumbnail(
                                'assets/brand/varanasi-dawn-hero.jpg',
                                180,
                              ),
                              const SizedBox(width: 12),
                              _buildGalleryThumbnail(
                                'assets/brand/jaipur-heritage.jpg',
                                140,
                              ),
                              const SizedBox(width: 12),
                              _buildGalleryThumbnail(
                                'assets/brand/rishikesh-foothills.jpg',
                                140,
                              ),
                              const SizedBox(width: 12),
                              _buildGalleryThumbnail(
                                'assets/brand/kerala-backwaters.jpg',
                                180,
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 32),

                        // SECTION 5: GOOD TO KNOW
                        Text(
                          'GOOD TO KNOW',
                          style: AppTypography.eyebrow(
                            color: AppColors.primary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        _buildGoodToKnowItem(
                          Icons.flight_land_rounded,
                          'Transit & Arrival',
                          'Nearest airport is ${dest.iata}. Railway station is ${dest.station}. Coordinates: ${dest.lat.toStringAsFixed(2)}° N, ${dest.lng.toStringAsFixed(2)}° E.',
                        ),
                        const SizedBox(height: 12),
                        _buildGoodToKnowItem(
                          Icons.schedule_rounded,
                          'Recommended Pacing',
                          '3 to 4 days recommended to experience sunrise rituals and unhurried local walks.',
                        ),
                        const SizedBox(height: 12),
                        _buildGoodToKnowItem(
                          Icons.wb_sunny_outlined,
                          'Best Season',
                          'Ideal temperatures and clear skies occur from ${dest.bestTime}.',
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),

          // SECTION 6: PLAN THIS JOURNEY (Sticky Dominant Action Bar)
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
              decoration: BoxDecoration(
                color: AppColors.surface,
                border: const Border(
                  top: BorderSide(color: AppColors.border, width: 1),
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.brown.withAlpha(20),
                    blurRadius: 20,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              child: SafeArea(
                top: false,
                child: SizedBox(
                  height: 52,
                  child: ElevatedButton(
                    onPressed: () {
                      context.push(
                        '/trip-planner',
                        extra: {'destination': dest.name},
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 0,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.route_rounded,
                          size: 20,
                          color: Colors.white,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'PLAN A JOURNEY TO ${dest.name.toUpperCase()} →',
                          style: AppTypography.button(
                            color: Colors.white,
                          ).copyWith(letterSpacing: 0.6, fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGalleryThumbnail(String assetPath, double width) {
    return Container(
      width: width,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        image: DecorationImage(image: AssetImage(assetPath), fit: BoxFit.cover),
      ),
    );
  }

  Widget _buildGoodToKnowItem(IconData icon, String title, String body) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: AppColors.brown),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTypography.plusJakartaSans.copyWith(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  body,
                  style: AppTypography.bodySmall(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
