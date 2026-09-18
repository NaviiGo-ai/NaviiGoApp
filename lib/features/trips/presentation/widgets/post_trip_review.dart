import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/auth/auth_provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../domain/models/trip_itinerary_model.dart';
import '../../../analytics/data/analytics_repository.dart';
import '../providers/trip_provider.dart';

class PostTripReviewModal extends ConsumerStatefulWidget {
  final TripItineraryModel trip;

  const PostTripReviewModal({super.key, required this.trip});

  static Future<void> show(BuildContext context, TripItineraryModel trip) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => PostTripReviewModal(trip: trip),
    );
  }

  @override
  ConsumerState<PostTripReviewModal> createState() =>
      _PostTripReviewModalState();
}

class _PostTripReviewModalState extends ConsumerState<PostTripReviewModal> {
  final Map<String, String> _responses = {};
  List<TripActivityModel> _ambiguousActivities = [];
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    // Gather places with a placeId that we aren't sure about.
    // In a real app we'd filter out ones already marked completed or skipped.
    final acts = <TripActivityModel>[];
    for (final day in widget.trip.dayPlans) {
      for (final act in day.activities) {
        if (act.placeId != null && !act.isCompleted && acts.length < 3) {
          acts.add(act);
        }
      }
    }
    _ambiguousActivities = acts;
  }

  Future<void> _submitReview() async {
    setState(() => _isSubmitting = true);
    final analytics = ref.read(analyticsRepositoryProvider);

    for (final act in _ambiguousActivities) {
      final response = _responses[act.title];
      if (response == 'YES') {
        await analytics.logEvent(
          eventType: 'POST_TRIP_PLACE_CONFIRMED_VISITED',
          placeId: act.placeId,
          destinationId: widget.trip.destName,
          metadata: {'confirmationSource': 'post_trip'},
        );
      } else if (response == 'NO') {
        await analytics.logEvent(
          eventType: 'POST_TRIP_PLACE_MARKED_NOT_VISITED',
          placeId: act.placeId,
          destinationId: widget.trip.destName,
          metadata: {'skipReason': 'NOT_INTERESTED'},
        );
      }
    }

    // Mark trip as reviewed via repository using the authenticated user's uid.
    // TripItineraryModel does NOT carry userId — uid comes from currentUserProvider.
    final uid = ref.read(currentUserProvider)?.uid;
    if (uid != null) {
      final tripRepo = ref.read(tripRepositoryProvider);
      // saveTrip writes isReviewed=true by merging the existing document;
      // we pass a model constructed with isReviewed=true directly.
      await tripRepo.markTripReviewed(uid, widget.trip.id);
    }

    if (mounted) {
      context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_ambiguousActivities.isEmpty) {
      // Nothing to review — silently complete.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _submitReview();
      });
      return const SizedBox.shrink();
    }

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 24,
        bottom: MediaQuery.of(context).padding.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            "We're not sure about ${_ambiguousActivities.length} stops",
            // FIX 6: AppTypography.h3 does not exist → use editorialTitle()
            style: AppTypography.editorialTitle(color: AppColors.textPrimary),
          ),
          const SizedBox(height: 8),
          Text(
            "Did you make it to these places during your trip to ${widget.trip.destName}?",
            // FIX 6: AppTypography.body1 does not exist → use bodyMedium()
            style: AppTypography.bodyMedium(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 24),
          ..._ambiguousActivities.map((act) => _buildReviewRow(act)),
          const SizedBox(height: 32),
          ElevatedButton(
            onPressed: _isSubmitting ? null : _submitReview,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.black,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: _isSubmitting
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.black,
                    ),
                  )
                : Text(
                    'Confirm',
                    // FIX 6: AppTypography.h4 does not exist → use tripTitle()
                    style: AppTypography.tripTitle(color: Colors.black),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildReviewRow(TripActivityModel act) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            act.title,
            // FIX 6: AppTypography.h4 does not exist → use tripTitle()
            style: AppTypography.tripTitle(color: AppColors.textPrimary),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _buildChoiceChip(act.title, 'YES'),
              const SizedBox(width: 8),
              _buildChoiceChip(act.title, 'NO'),
              const SizedBox(width: 8),
              _buildChoiceChip(act.title, 'NOT SURE'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildChoiceChip(String actTitle, String choice) {
    final isSelected = _responses[actTitle] == choice;
    return GestureDetector(
      onTap: () => setState(() => _responses[actTitle] = choice),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary.withValues(alpha: 0.2) : Colors.transparent,
          border: Border.all(
            // FIX 8: AppColors.divider does not exist → use AppColors.border
            color: isSelected ? AppColors.primary : AppColors.border,
            width: 1,
          ),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          choice,
          // FIX 7: AppTypography.button is TextStyle Function({Color color}),
          // NOT a TextStyle property → call it as a function.
          style: AppTypography.button(
            color: isSelected ? AppColors.primary : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }
}
