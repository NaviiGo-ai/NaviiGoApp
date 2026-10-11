import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/constants/master_destinations.dart';
import '../../../../core/auth/auth_provider.dart';
import '../../../../core/network/api_exceptions.dart';
import '../../../../core/motion/nav_motion.dart';
import '../../../../core/widgets/journey_line.dart';
import '../../../trips/data/trip_repository.dart';
import '../../../trips/presentation/providers/trip_provider.dart';
import '../../../trips/presentation/widgets/itinerary_overview_widgets.dart';

MasterDestination? resolveTripPlannerDestination(Object? extra) {
  final requestedDestination = extra is Map ? extra['destination'] : extra;
  if (requestedDestination is MasterDestination) {
    return findDestinationById(requestedDestination.id) ??
        findDestinationById(requestedDestination.name);
  }
  if (requestedDestination is String) {
    return findDestinationById(requestedDestination);
  }
  return null;
}

String? validateTripPlannerInputs({
  required MasterDestination? destination,
  required int days,
  required double budget,
  required DateTime startDate,
  DateTime? today,
}) {
  if (destination == null) {
    return 'Choose a supported destination before generating your journey.';
  }
  if (days < 1 || days > 14) {
    return 'Journey duration must be between 1 and 14 days.';
  }
  if (!budget.isFinite || budget <= 0) {
    return 'Enter a positive journey budget.';
  }

  final referenceDate = today ?? DateTime.now();
  final todayOnly = DateTime(
    referenceDate.year,
    referenceDate.month,
    referenceDate.day,
  );
  final startOnly = DateTime(startDate.year, startDate.month, startDate.day);
  if (startOnly.isBefore(todayOnly)) {
    return 'Choose a departure date that is today or later.';
  }

  return null;
}

String friendlyTripGenerationError(Object error) {
  if (error is AuthRequiredException) {
    return 'Your sign-in changed. Sign in again before generating a journey.';
  }
  if (error is NetworkException) {
    final message = error.message.toLowerCase();
    if (message.contains('timed out')) {
      return 'The request timed out. The server may still finish or save it; retrying can create another trip.';
    }
    return 'The request outcome is unknown. The server may still finish or save it; retrying can create another trip. Check your connection before retrying.';
  }
  if (error is ValidationException) {
    return 'The itinerary request was rejected. Check the destination, dates, and journey details.';
  }
  if (error is ItineraryGenerationResponseException) {
    return 'The itinerary response was incomplete. The server may still finish or save it; retrying can create another trip.';
  }
  if (error is ServerException || error is AppException) {
    return 'The request outcome is unknown. The server may still finish or save it; retrying can create another trip.';
  }
  return 'The request outcome is unknown. The server may still finish or save it; retrying can create another trip.';
}

class TripPlannerPage extends ConsumerStatefulWidget {
  const TripPlannerPage({super.key});

  @override
  ConsumerState<TripPlannerPage> createState() => _TripPlannerPageState();
}

class _TripPlannerPageState extends ConsumerState<TripPlannerPage>
    with SingleTickerProviderStateMixin {
  late final PageController _pageController;
  late final AnimationController _animController;

  int _currentStep = 0;
  static const int _totalSteps = 6;

  // Selected State
  MasterDestination? _selectedDestination;
  int _days = 3;
  DateTime _startDate = DateTime.now().add(const Duration(days: 7));
  String _groupType = 'solo';
  String _purpose = 'cultural';
  String _pace = 'comfort';
  double _budget = 25000;
  bool _isGenerating = false;
  String? _validationError;
  String? _generationError;
  String? _draftOwnerUid;
  bool _hasObservedOwner = false;
  bool _accountObservationScheduled = false;
  int _requestGeneration = 0;
  final List<String> _selectedInterests = [];
  String? _dietaryPreference;

  final List<Map<String, String>> _groupOptions = [
    {
      'id': 'solo',
      'label': 'Solo Wanderer',
      'subtitle': 'Unfiltered personal discovery',
      'icon': '🎒',
    },
    {
      'id': 'couple',
      'label': 'Couple / Duo',
      'subtitle': 'Intimate sunsets & quiet stays',
      'icon': '✨',
    },
    {
      'id': 'friends',
      'label': 'Nomad Crew',
      'subtitle': 'Shared trails & vibrant stories',
      'icon': '👥',
    },
    {
      'id': 'family',
      'label': 'Family Journey',
      'subtitle': 'Unhurried comfort & safety',
      'icon': '🏡',
    },
  ];

  final List<Map<String, String>> _purposeOptions = [
    {
      'id': 'cultural',
      'label': 'Heritage & History',
      'desc': 'Palaces, forts, ancient architecture',
      'icon': '🏛️',
    },
    {
      'id': 'spiritual',
      'label': 'Spiritual & Sacred',
      'desc': 'Ghats, dawn aarti, temple bells',
      'icon': '🪔',
    },
    {
      'id': 'adventure',
      'label': 'Nature & Expedition',
      'desc': 'Rivers, mountains, pine forests',
      'icon': '⛰️',
    },
    {
      'id': 'leisure',
      'label': 'Slow Coastal & Cafes',
      'desc': 'Quiet backwaters & sea breezes',
      'icon': '🌴',
    },
  ];

  final List<Map<String, String>> _paceOptions = [
    {
      'id': 'slow',
      'label': 'Slow backend preset',
      'desc': 'A lower-density itinerary generated by the backend preset',
    },
    {
      'id': 'comfort',
      'label': 'Comfort backend preset',
      'desc': 'A comfort-oriented itinerary generated by the backend preset',
    },
    {
      'id': 'flash',
      'label': 'Flash backend preset',
      'desc': 'A compact itinerary generated by the backend preset',
    },
  ];

  final List<String> _interestOptions = const ['Heritage', 'Nature', 'Food'];
  final List<Map<String, String>> _dietaryOptions = const [
    {'id': 'vegetarian', 'label': 'Vegetarian'},
    {'id': 'jain', 'label': 'Jain'},
    {'id': 'halal', 'label': 'Halal'},
  ];

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _animController = AnimationController(
      vsync: this,
      duration: NavMotion.standard,
    );
    _animController.forward();

    // Check for prefilled destination extra
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      final extra = GoRouterState.of(context).extra;
      final requestedDestination = extra is Map ? extra['destination'] : extra;
      final found = resolveTripPlannerDestination(extra);

      if (found != null) {
        setState(() {
          _selectedDestination = found;
          _validationError = null;
        });
      } else if (requestedDestination != null) {
        setState(() {
          _selectedDestination = null;
          _validationError =
              'That destination is not supported yet. Choose a destination from the registry.';
        });
      }
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    _animController.dispose();
    super.dispose();
  }

  void _nextStep() {
    if (_currentStep == 0 && _selectedDestination == null) {
      _showValidationError('Choose a supported destination before continuing.');
      return;
    }

    if (_currentStep < _totalSteps - 1) {
      _pageController.nextPage(
        duration: NavMotion.standard,
        curve: NavMotion.movement,
      );
      setState(() => _currentStep++);
      _animController.reset();
      _animController.forward();
    } else {
      _onGeneratePressed();
    }
  }

  void _prevStep() {
    if (_isGenerating) {
      _onCancelPressed();
      return;
    }
    if (_currentStep > 0) {
      _pageController.previousPage(
        duration: NavMotion.standard,
        curve: NavMotion.movement,
      );
      setState(() => _currentStep--);
      _animController.reset();
      _animController.forward();
    } else {
      if (context.canPop()) {
        context.pop();
      } else {
        context.go('/home');
      }
    }
  }

  String? _validateInputs() {
    return validateTripPlannerInputs(
      destination: _selectedDestination,
      days: _days,
      budget: _budget,
      startDate: _startDate,
    );
  }

  void _observeAccount(String? uid) {
    if (!_hasObservedOwner) {
      _draftOwnerUid = uid;
      _hasObservedOwner = true;
      return;
    }
    if (_draftOwnerUid == uid) return;

    _draftOwnerUid = uid;
    _requestGeneration++;
    if (!mounted) return;
    setState(() {
      // A supported destination can come from the navigation entry point, so
      // preserve it while clearing account-owned planner choices.
      _days = 3;
      _startDate = DateTime.now().add(const Duration(days: 7));
      _groupType = 'solo';
      _purpose = 'cultural';
      _pace = 'comfort';
      _budget = 25000;
      _selectedInterests.clear();
      _dietaryPreference = null;
      _validationError = null;
      _generationError = _isGenerating
          ? 'Your account changed. The previous request may still finish or save on the server.'
          : null;
    });
  }

  void _syncAccountFromBuild(String? uid) {
    if (!_hasObservedOwner) {
      _draftOwnerUid = uid;
      _hasObservedOwner = true;
      return;
    }
    if (_draftOwnerUid == uid || _accountObservationScheduled) return;
    _accountObservationScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _accountObservationScheduled = false;
      if (mounted) _observeAccount(uid);
    });
  }

  Future<void> _onCancelPressed() async {
    if (!_isGenerating) {
      _leavePlanner();
      return;
    }

    final shouldStop = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Stop waiting?'),
        content: const Text(
          'There is no cancellation endpoint. The server may continue and save this request. If it times out, retrying can create another trip.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Keep waiting'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Stop waiting'),
          ),
        ],
      ),
    );
    if (!mounted || shouldStop != true) return;
    _requestGeneration++;
    _leavePlanner();
  }

  void _leavePlanner() {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go('/home');
    }
  }

  Map<String, dynamic>? _generationPreferences() {
    final preferences = <String, dynamic>{
      if (_selectedInterests.isNotEmpty)
        'interests': List<String>.from(_selectedInterests),
      if (_dietaryPreference != null) 'dietary': _dietaryPreference,
    };
    return preferences.isEmpty ? null : preferences;
  }

  void _showValidationError(String message) {
    if (!mounted) return;
    setState(() {
      _validationError = message;
      _generationError = null;
    });
  }

  Future<void> _onGeneratePressed() async {
    if (_isGenerating) return;

    final validationError = _validateInputs();
    if (validationError != null) {
      _showValidationError(validationError);
      return;
    }

    final user = ref.read(currentUserProvider);
    if (user == null) {
      _showValidationError('Please sign in to generate your journey.');
      context.push('/login');
      return;
    }

    final initiatingUid = user.uid;
    final requestGeneration = ++_requestGeneration;
    FocusManager.instance.primaryFocus?.unfocus();
    setState(() {
      _isGenerating = true;
      _validationError = null;
      _generationError = null;
    });

    try {
      final repo = ref.read(tripRepositoryProvider);
      final generatedTrip = await repo.generateItineraryFromBackend(
        destName: _selectedDestination!.name,
        destination: _selectedDestination!.id,
        days: _days,
        purpose: _purpose,
        group: _groupType,
        budget: _budget.toInt(),
        startDate: _startDate.toIso8601String().split('T')[0],
        travelerType: _pace,
        preferences: _generationPreferences(),
        expectedAuthUid: initiatingUid,
      );

      if (!mounted) return;
      if (requestGeneration != _requestGeneration ||
          ref.read(currentUserProvider)?.uid != initiatingUid) {
        setState(() {
          _isGenerating = false;
          _generationError =
              'The request finished after your account changed. No result was opened; the server may still have finished or saved it.';
        });
        return;
      }

      setState(() => _isGenerating = false);
      context.push('/itinerary', extra: generatedTrip);
    } catch (e) {
      if (!mounted) return;
      if (requestGeneration != _requestGeneration ||
          ref.read(currentUserProvider)?.uid != initiatingUid) {
        setState(() {
          _isGenerating = false;
          _generationError =
              'The request ended after your account changed. No result was opened; the server may still have finished or saved it.';
        });
        return;
      }
      setState(() {
        _isGenerating = false;
        _generationError = friendlyTripGenerationError(e);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUid = ref.watch(currentUserProvider)?.uid;
    _syncAccountFromBuild(currentUid);

    return PopScope<void>(
      canPop: !_isGenerating,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop && _isGenerating) {
          unawaited(_onCancelPressed());
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: SafeArea(
          child: Column(
            children: [
              // Top Bar: Back button, Wizard Title, Step Number
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 20, 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      icon: const Icon(
                        Icons.arrow_back_ios_new_rounded,
                        color: AppColors.brown,
                        size: 20,
                      ),
                      onPressed: _prevStep,
                    ),
                    Expanded(
                      child: Text(
                        'STEP 0${_currentStep + 1} OF 0$_totalSteps',
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.eyebrow(
                          color: AppColors.primary,
                        ).copyWith(letterSpacing: 1.6),
                      ),
                    ),
                    SizedBox(
                      width: 76,
                      child: InkWell(
                        onTap: _onCancelPressed,
                        child: Text(
                          _isGenerating ? 'Stop waiting' : 'Cancel',
                          maxLines: 2,
                          textAlign: TextAlign.center,
                          overflow: TextOverflow.ellipsis,
                          style: AppTypography.caption(
                            color: AppColors.textTertiary,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // The Journey Line — Signature brand motion device
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: JourneyLine(
                  totalSteps: _totalSteps,
                  currentStep: _currentStep.toDouble(),
                  mode: JourneyLineMode.plan,
                ),
              ),

              if (_validationError != null || _generationError != null)
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
                  child: Semantics(
                    liveRegion: true,
                    container: true,
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceWarm,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppColors.borderStrong),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            _generationError == null
                                ? Icons.info_outline_rounded
                                : Icons.error_outline_rounded,
                            color: _generationError == null
                                ? AppColors.primary
                                : Colors.red.shade700,
                            size: 20,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              _generationError ?? _validationError!,
                              style: AppTypography.bodySmall(
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ),
                          if (_generationError != null)
                            TextButton(
                              onPressed: _isGenerating
                                  ? null
                                  : _onGeneratePressed,
                              child: const Text('Retry'),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),

              const SizedBox(height: 12),

              // Wizard Scenes: One Decision Per Scene
              Expanded(
                child: PageView(
                  controller: _pageController,
                  physics: const NeverScrollableScrollPhysics(),
                  children: [
                    _buildWhereScene(),
                    _buildWhenScene(),
                    _buildWhoScene(),
                    _buildVibeScene(),
                    _buildPaceScene(),
                    _buildBudgetScene(),
                  ],
                ),
              ),

              // Persistent Tactile Navigation Bottom Bar
              Container(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
                decoration: const BoxDecoration(
                  color: AppColors.surface,
                  border: Border(
                    top: BorderSide(color: AppColors.border, width: 1),
                  ),
                ),
                child: Row(
                  children: [
                    if (_currentStep > 0) ...[
                      OutlinedButton(
                        onPressed: _isGenerating ? null : _prevStep,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.brown,
                          side: const BorderSide(color: AppColors.border),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 14,
                          ),
                        ),
                        child: const Text('Back'),
                      ),
                      const SizedBox(width: 12),
                    ],
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _isGenerating ? null : _nextStep,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          elevation: 0,
                        ),
                        child: _isGenerating
                            ? Semantics(
                                label: 'Generating itinerary',
                                liveRegion: true,
                                child: SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                ),
                              )
                            : Center(
                                child: Text(
                                  _currentStep == _totalSteps - 1
                                      ? 'GENERATE YOUR JOURNEY →'
                                      : 'CONTINUE →',
                                  maxLines: 2,
                                  textAlign: TextAlign.center,
                                  overflow: TextOverflow.ellipsis,
                                  style: AppTypography.button(
                                    color: Colors.white,
                                  ).copyWith(letterSpacing: 0.8, fontSize: 13),
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────
  // SCENE 01: WHERE?
  // ─────────────────────────────────────────────────────────
  Widget _buildWhereScene() {
    final destinationCardHeight =
        MediaQuery.of(context).textScaler.scale(1) > 1.5 ? 620.0 : 360.0;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 22.0),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'WHERE WILL\nYOUR CURIOSITY LEAD?',
              style: AppTypography.epilogue.copyWith(
                fontSize: 28,
                fontWeight: FontWeight.w800,
                color: AppColors.brown,
                height: 1.12,
                letterSpacing: -0.8,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Select your expedition territory from our curated subcontinent registry',
              style: AppTypography.bodySmall(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 20),

            // Horizontal Destination Pills
            SizedBox(
              height: 42,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                itemCount: kMasterDestinations.length,
                itemBuilder: (context, index) {
                  final d = kMasterDestinations[index];
                  final isSelected = d.id == _selectedDestination?.id;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: Semantics(
                      button: true,
                      selected: isSelected,
                      label: 'Destination ${d.name}',
                      child: InkWell(
                        onTap: () => setState(() {
                          _selectedDestination = d;
                          _validationError = null;
                        }),
                        borderRadius: BorderRadius.circular(20),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? AppColors.brown
                                : AppColors.surface,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: isSelected
                                  ? AppColors.brown
                                  : AppColors.border,
                            ),
                          ),
                          child: Text(
                            d.name,
                            style: AppTypography.plusJakartaSans.copyWith(
                              fontSize: 13,
                              fontWeight: isSelected
                                  ? FontWeight.w700
                                  : FontWeight.w500,
                              color: isSelected
                                  ? Colors.white
                                  : AppColors.textPrimary,
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: 20),

            // Large Visual Destination Card
            SizedBox(
              height: destinationCardHeight,
              child: _selectedDestination == null
                  ? Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(22),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Semantics(
                        container: true,
                        label: 'No destination selected',
                        child: const Center(
                          child: Padding(
                            padding: EdgeInsets.all(24),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.explore_outlined,
                                  color: AppColors.primary,
                                  size: 42,
                                ),
                                SizedBox(height: 12),
                                Text('Choose a supported destination'),
                              ],
                            ),
                          ),
                        ),
                      ),
                    )
                  : ClipRRect(
                      borderRadius: BorderRadius.circular(22),
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          SafeExpeditionImage(
                            imagePath: _selectedDestination!.image,
                            fit: BoxFit.cover,
                          ),
                          Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                stops: const [0.0, 0.45, 1.0],
                                colors: [
                                  Colors.transparent,
                                  Colors.black.withAlpha(60),
                                  AppColors.brown.withAlpha(220),
                                ],
                              ),
                            ),
                            padding: const EdgeInsets.all(22),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.cream,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    '${_selectedDestination!.state.toUpperCase()} · ${_selectedDestination!.category.toUpperCase()}',
                                    style: AppTypography.micro(
                                      color: AppColors.brown,
                                    ).copyWith(fontWeight: FontWeight.w800),
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  _selectedDestination!.name,
                                  style: AppTypography.epilogue.copyWith(
                                    fontSize: 26,
                                    fontWeight: FontWeight.w800,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  _selectedDestination!.description,
                                  style: AppTypography.plusJakartaSans.copyWith(
                                    fontSize: 12,
                                    color: AppColors.cream,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────
  // SCENE 02: WHEN?
  // ─────────────────────────────────────────────────────────
  Widget _buildWhenScene() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 22.0),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'WHEN DO YOU\nINTEND TO TRAVEL?',
              style: AppTypography.epilogue.copyWith(
                fontSize: 28,
                fontWeight: FontWeight.w800,
                color: AppColors.brown,
                height: 1.12,
                letterSpacing: -0.8,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Choose your departure date and duration for ${_selectedDestination?.name ?? 'your destination'}',
              style: AppTypography.bodySmall(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 24),

            // Date Trigger Card
            InkWell(
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: _startDate,
                  firstDate: DateTime.now(),
                  lastDate: DateTime.now().add(const Duration(days: 365)),
                );
                if (picked != null) {
                  setState(() => _startDate = picked);
                }
              },
              borderRadius: BorderRadius.circular(18),
              child: Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: AppColors.border),
                  boxShadow: AppColors.cardShadow,
                ),
                child: Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: AppColors.surfaceWarm,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.calendar_month_rounded,
                        color: AppColors.primary,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'DEPARTURE DATE',
                            style: AppTypography.micro(
                              color: AppColors.primary,
                            ).copyWith(fontWeight: FontWeight.w800),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            '${_startDate.day} / ${_startDate.month} / ${_startDate.year}',
                            style: AppTypography.epilogue.copyWith(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: AppColors.brown,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(
                      Icons.edit_calendar_outlined,
                      color: AppColors.textTertiary,
                      size: 20,
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 28),

            // Duration Selector: Days Counter
            Text(
              'EXPEDITION DURATION',
              style: AppTypography.eyebrow(color: AppColors.primary),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: AppColors.border),
                boxShadow: AppColors.cardShadow,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '$_days Days & ${_days - 1} Nights',
                          style: AppTypography.epilogue.copyWith(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: AppColors.brown,
                          ),
                        ),
                        Text(
                          'Optimal pacing for curated waypoints',
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: AppTypography.caption(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(
                          Icons.remove_circle_outline_rounded,
                          color: AppColors.brown,
                        ),
                        onPressed: _days > 2
                            ? () => setState(() => _days--)
                            : null,
                      ),
                      Text(
                        '$_days',
                        style: AppTypography.epilogue.copyWith(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: AppColors.primary,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(
                          Icons.add_circle_outline_rounded,
                          color: AppColors.brown,
                        ),
                        onPressed: _days < 10
                            ? () => setState(() => _days++)
                            : null,
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

  // ─────────────────────────────────────────────────────────
  // SCENE 03: WHO'S GOING?
  // ─────────────────────────────────────────────────────────
  Widget _buildWhoScene() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 22.0),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'WHO IS\nACCOMPANYING YOU?',
              style: AppTypography.epilogue.copyWith(
                fontSize: 28,
                fontWeight: FontWeight.w800,
                color: AppColors.brown,
                height: 1.12,
                letterSpacing: -0.8,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Choose a supported group. Saved account settings may override this choice when the backend generates your itinerary.',
              style: AppTypography.bodySmall(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 20),

            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _groupOptions.length,
              itemBuilder: (context, index) {
                final opt = _groupOptions[index];
                final isSelected = opt['id'] == _groupType;

                return Padding(
                  padding: const EdgeInsets.only(bottom: 12.0),
                  child: InkWell(
                    onTap: () => setState(() => _groupType = opt['id']!),
                    borderRadius: BorderRadius.circular(18),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppColors.surfaceWarm
                            : AppColors.surface,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                          color: isSelected
                              ? AppColors.primary
                              : AppColors.border,
                          width: isSelected ? 1.5 : 1.0,
                        ),
                        boxShadow: isSelected ? AppColors.cardShadow : null,
                      ),
                      child: Row(
                        children: [
                          Text(
                            opt['icon']!,
                            style: const TextStyle(fontSize: 28),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  opt['label']!,
                                  style: AppTypography.plusJakartaSans.copyWith(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.brown,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  opt['subtitle']!,
                                  style: AppTypography.bodySmall(
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Icon(
                            isSelected
                                ? Icons.check_circle_rounded
                                : Icons.radio_button_unchecked_rounded,
                            color: isSelected
                                ? AppColors.primary
                                : AppColors.border,
                            size: 22,
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
      ),
    );
  }

  // ─────────────────────────────────────────────────────────
  // SCENE 04: WHAT KIND OF JOURNEY?
  // ─────────────────────────────────────────────────────────
  Widget _buildVibeScene() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 22.0),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'WHAT VIBE\nDEFINES THIS EXPEDITION?',
              style: AppTypography.epilogue.copyWith(
                fontSize: 28,
                fontWeight: FontWeight.w800,
                color: AppColors.brown,
                height: 1.12,
                letterSpacing: -0.8,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Select the thematic focus for your daily chapters',
              style: AppTypography.bodySmall(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 20),

            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _purposeOptions.length,
              itemBuilder: (context, index) {
                final opt = _purposeOptions[index];
                final isSelected = opt['id'] == _purpose;

                return Padding(
                  padding: const EdgeInsets.only(bottom: 12.0),
                  child: InkWell(
                    onTap: () => setState(() => _purpose = opt['id']!),
                    borderRadius: BorderRadius.circular(18),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppColors.surfaceWarm
                            : AppColors.surface,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                          color: isSelected
                              ? AppColors.primary
                              : AppColors.border,
                          width: isSelected ? 1.5 : 1.0,
                        ),
                        boxShadow: isSelected ? AppColors.cardShadow : null,
                      ),
                      child: Row(
                        children: [
                          Text(
                            opt['icon']!,
                            style: const TextStyle(fontSize: 28),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  opt['label']!,
                                  style: AppTypography.plusJakartaSans.copyWith(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.brown,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  opt['desc']!,
                                  style: AppTypography.bodySmall(
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Icon(
                            isSelected
                                ? Icons.check_circle_rounded
                                : Icons.radio_button_unchecked_rounded,
                            color: isSelected
                                ? AppColors.primary
                                : AppColors.border,
                            size: 22,
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
      ),
    );
  }

  // ─────────────────────────────────────────────────────────
  // SCENE 05: PACE
  // ─────────────────────────────────────────────────────────
  Widget _buildPaceScene() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 22.0),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'WHAT PACING\nFITS YOUR RHYTHM?',
              style: AppTypography.epilogue.copyWith(
                fontSize: 28,
                fontWeight: FontWeight.w800,
                color: AppColors.brown,
                height: 1.12,
                letterSpacing: -0.8,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Choose the backend traveler preset. Saved account settings may override this preset; no stop-count promise is made.',
              style: AppTypography.bodySmall(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 20),

            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _paceOptions.length + 1,
              itemBuilder: (context, index) {
                if (index == _paceOptions.length) {
                  return _buildPreferenceOptions();
                }
                final opt = _paceOptions[index];
                final isSelected = opt['id'] == _pace;

                return Padding(
                  padding: const EdgeInsets.only(bottom: 14.0),
                  child: InkWell(
                    onTap: () => setState(() => _pace = opt['id']!),
                    borderRadius: BorderRadius.circular(18),
                    child: Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppColors.surfaceWarm
                            : AppColors.surface,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                          color: isSelected
                              ? AppColors.primary
                              : AppColors.border,
                          width: isSelected ? 1.5 : 1.0,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  opt['label']!,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: AppTypography.plusJakartaSans.copyWith(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.brown,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Icon(
                                isSelected
                                    ? Icons.check_circle_rounded
                                    : Icons.radio_button_unchecked_rounded,
                                color: isSelected
                                    ? AppColors.primary
                                    : AppColors.border,
                                size: 22,
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            opt['desc']!,
                            style: AppTypography.bodySmall(
                              color: AppColors.textSecondary,
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
      ),
    );
  }

  Widget _buildPreferenceOptions() {
    return Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 20),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surfaceWarm,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'OPTIONAL GENERATION PREFERENCES',
              style: AppTypography.eyebrow(color: AppColors.primary),
            ),
            const SizedBox(height: 6),
            Text(
              'Interests use backend-supported tag names. Dietary choice affects restaurant ranking only and is not a safety guarantee.',
              style: AppTypography.caption(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 12),
            Text(
              'INTERESTS',
              style: AppTypography.micro(color: AppColors.textTertiary),
            ),
            const SizedBox(height: 6),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _interestOptions.map((interest) {
                final selected = _selectedInterests.contains(interest);
                return FilterChip(
                  label: Text(interest),
                  selected: selected,
                  onSelected: (value) {
                    setState(() {
                      if (value) {
                        _selectedInterests.add(interest);
                      } else {
                        _selectedInterests.remove(interest);
                      }
                    });
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 14),
            Text(
              'DIETARY',
              style: AppTypography.micro(color: AppColors.textTertiary),
            ),
            const SizedBox(height: 6),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ChoiceChip(
                  label: const Text('No preference'),
                  selected: _dietaryPreference == null,
                  onSelected: (_) => setState(() => _dietaryPreference = null),
                ),
                ..._dietaryOptions.map((option) {
                  final id = option['id']!;
                  return ChoiceChip(
                    label: Text(option['label']!),
                    selected: _dietaryPreference == id,
                    onSelected: (_) => setState(() => _dietaryPreference = id),
                  );
                }),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────
  // SCENE 06: BUDGET
  // ─────────────────────────────────────────────────────────
  Widget _buildBudgetScene() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 22.0),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'ESTIMATED\nJOURNEY BUDGET',
              style: AppTypography.epilogue.copyWith(
                fontSize: 28,
                fontWeight: FontWeight.w800,
                color: AppColors.brown,
                height: 1.12,
                letterSpacing: -0.8,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Total anticipated allocation in INR for stay, transit & experiences',
              style: AppTypography.bodySmall(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 32),

            // Large Budget Display
            Center(
              child: Column(
                children: [
                  Text(
                    '₹${_budget.toInt().toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')}',
                    style: AppTypography.epilogue.copyWith(
                      fontSize: 40,
                      fontWeight: FontWeight.w800,
                      color: AppColors.primary,
                      letterSpacing: -1.0,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '₹${(_budget / _days).toInt()} per day estimated',
                    style: AppTypography.caption(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Slider
            SliderTheme(
              data: SliderTheme.of(context).copyWith(
                activeTrackColor: AppColors.primary,
                inactiveTrackColor: AppColors.border,
                thumbColor: AppColors.primary,
                overlayColor: AppColors.primary.withAlpha(30),
              ),
              child: Slider(
                value: _budget,
                min: 8000,
                max: 80000,
                divisions: 36,
                onChanged: (val) => setState(() => _budget = val),
              ),
            ),

            const SizedBox(height: 20),

            // Quick Tier Buttons
            Row(
              children: [
                _buildTierButton('Backpacker', 12000),
                const SizedBox(width: 8),
                _buildTierButton('Comfort', 25000),
                const SizedBox(width: 8),
                _buildTierButton('Heritage', 55000),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTierButton(String label, double amount) {
    final isSelected = _budget == amount;
    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _budget = amount),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.brown : AppColors.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? AppColors.brown : AppColors.border,
            ),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: AppTypography.plusJakartaSans.copyWith(
              fontSize: 12,
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              color: isSelected ? Colors.white : AppColors.textPrimary,
            ),
          ),
        ),
      ),
    );
  }
}
