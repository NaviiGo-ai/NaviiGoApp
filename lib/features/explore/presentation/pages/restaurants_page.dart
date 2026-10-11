import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../places/domain/models/place_model.dart';
import '../../../places/presentation/providers/places_provider.dart';
import '../../../../core/constants/master_destinations.dart';
import '../../../navigation/presentation/nav_hub_page.dart';

class RestaurantsPage extends ConsumerStatefulWidget {
  final MasterDestination? destination;
  const RestaurantsPage({super.key, this.destination});

  @override
  ConsumerState<RestaurantsPage> createState() => _RestaurantsPageState();
}

class _RestaurantsPageState extends ConsumerState<RestaurantsPage> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  List<PlaceModel>? _restaurants;
  bool _isLoading = false;
  String? _errorMessage;
  int _requestGeneration = 0;

  @override
  void initState() {
    super.initState();
    _fetchRestaurants();
  }

  Future<void> _fetchRestaurants([String query = '']) async {
    final requestGeneration = ++_requestGeneration;
    if (mounted) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
        _restaurants = null;
      });
    }
    final destination = widget.destination;
    if (destination == null) {
      if (mounted && requestGeneration == _requestGeneration) {
        setState(() {
          _restaurants = [];
          _isLoading = false;
        });
      }
      return;
    }
    final repo = ref.read(placesRepositoryProvider);

    try {
      final results = await repo.getPlaceDetails(
        lat: destination.lat,
        lng: destination.lng,
        type: 'restaurant',
        query: query.isNotEmpty ? query : 'authentic dining restaurant',
      );

      if (mounted && requestGeneration == _requestGeneration) {
        setState(() {
          _restaurants = results;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted && requestGeneration == _requestGeneration) {
        setState(() {
          _restaurants = [];
          _isLoading = false;
          _errorMessage = 'Dining spots are unavailable right now.';
        });
      }
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: const NavHubLeading(),
        title: Text(
          'CUISINE & DINING',
          style: AppTypography.eyebrow(color: AppColors.brown),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // Search Input
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border),
              ),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Search restaurants, cafes, local dishes...',
                  hintStyle: AppTypography.bodyMedium(
                    color: AppColors.textSecondary,
                  ),
                  prefixIcon: const Icon(
                    Icons.search,
                    color: AppColors.textSecondary,
                    size: 20,
                  ),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear, size: 18),
                          onPressed: () {
                            _searchController.clear();
                            setState(() => _searchQuery = '');
                            _fetchRestaurants('');
                          },
                        )
                      : null,
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 14),
                ),
                onSubmitted: (val) {
                  setState(() => _searchQuery = val.trim());
                  _fetchRestaurants(_searchQuery);
                },
              ),
            ),
          ),

          // Restaurant List
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: AppColors.primary),
                  )
                : _errorMessage != null
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.cloud_off_outlined,
                          size: 48,
                          color: AppColors.border,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          _errorMessage!,
                          style: AppTypography.sectionTitle(
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextButton(
                          onPressed: () => _fetchRestaurants(_searchQuery),
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  )
                : (_restaurants == null || _restaurants!.isEmpty)
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.restaurant_outlined,
                          size: 48,
                          color: AppColors.border,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          widget.destination == null
                              ? 'Choose a destination first'
                              : 'No dining spots found',
                          style: AppTypography.sectionTitle(
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          widget.destination == null
                              ? 'Open food discovery from a destination'
                              : 'Try searching for another cuisine or dish',
                          style: AppTypography.caption(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
                    itemCount: _restaurants!.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 16),
                    itemBuilder: (context, index) {
                      final rest = _restaurants![index];
                      return GestureDetector(
                        onTap: () =>
                            context.push('/place-details', extra: rest),
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: AppColors.border),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Photo
                              ClipRRect(
                                borderRadius: const BorderRadius.vertical(
                                  top: Radius.circular(16),
                                ),
                                child:
                                    rest.photoUrl != null &&
                                        rest.photoUrl!.isNotEmpty
                                    ? Hero(
                                        tag: 'place-${rest.id}',
                                        child: Image.network(
                                          rest.photoUrl!,
                                          height: 160,
                                          width: double.infinity,
                                          fit: BoxFit.cover,
                                          errorBuilder: (_, __, ___) =>
                                              Container(
                                                height: 160,
                                                color: AppColors.surfaceWarm,
                                                child: const Center(
                                                  child: Icon(
                                                    Icons.restaurant_rounded,
                                                    color: AppColors.primary,
                                                    size: 40,
                                                  ),
                                                ),
                                              ),
                                        ),
                                      )
                                    : Container(
                                        height: 160,
                                        width: double.infinity,
                                        color: AppColors.surfaceWarm,
                                        child: const Center(
                                          child: Icon(
                                            Icons.restaurant_rounded,
                                            color: AppColors.primary,
                                            size: 40,
                                          ),
                                        ),
                                      ),
                              ),
                              Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            rest.name,
                                            style: AppTypography.tripTitle(
                                              color: AppColors.textPrimary,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        if (rest.rating > 0) ...[
                                          const Icon(
                                            Icons.star_rounded,
                                            color: AppColors.yellow,
                                            size: 18,
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            rest.rating.toStringAsFixed(1),
                                            style:
                                                AppTypography.bodyMedium(
                                                  color: AppColors.textPrimary,
                                                ).copyWith(
                                                  fontWeight: FontWeight.bold,
                                                ),
                                          ),
                                        ],
                                      ],
                                    ),
                                    const SizedBox(height: 6),
                                    if (rest.vicinity.isNotEmpty)
                                      Text(
                                        rest.vicinity,
                                        style: AppTypography.caption(
                                          color: AppColors.textSecondary,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    const SizedBox(height: 12),
                                    Row(
                                      children: [
                                        if (rest.isOpen != null)
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 8,
                                              vertical: 3,
                                            ),
                                            decoration: BoxDecoration(
                                              color: rest.isOpen!
                                                  ? AppColors.teal.withAlpha(20)
                                                  : Colors.red.withAlpha(20),
                                              borderRadius:
                                                  BorderRadius.circular(4),
                                            ),
                                            child: Text(
                                              rest.isOpen! ? 'OPEN' : 'CLOSED',
                                              style: AppTypography.micro(
                                                color: rest.isOpen!
                                                    ? AppColors.teal
                                                    : Colors.red,
                                              ),
                                            ),
                                          ),
                                        const Spacer(),
                                        Text(
                                          'VIEW DETAILS →',
                                          style: AppTypography.eyebrow(
                                            color: AppColors.primary,
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
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
