import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/constants/master_destinations.dart';
import '../../../../core/network/firebase_client.dart';
import '../../../../core/widgets/journey_line.dart';
import '../../../trips/presentation/providers/trip_provider.dart';
import '../../../trips/domain/models/trip_itinerary_model.dart';

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
  MasterDestination _selectedDestination =
      kMasterDestinations[1]; // Default: Jaipur
  int _days = 3;
  DateTime _startDate = DateTime.now().add(const Duration(days: 7));
  String _groupType = 'solo';
  String _purpose = 'cultural';
  String _pace = 'balanced';
  double _budget = 25000;
  bool _isGenerating = false;

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
      'id': 'relaxed',
      'label': 'Relaxed Pacing',
      'desc': '1–2 stops per day with ample slow contemplation',
    },
    {
      'id': 'balanced',
      'label': 'Balanced Rhythm',
      'desc': 'Curated mix of landmark highlights and local pauses',
    },
    {
      'id': 'fast',
      'label': 'Intensive Expedition',
      'desc': 'Full-day movement covering maximum territory',
    },
  ];

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 320),
    );
    _animController.forward();

    // Check for prefilled destination extra
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final extra = GoRouterState.of(context).extra;
      if (extra is Map && extra.containsKey('destination')) {
        final destName = extra['destination'].toString();
        final found = findDestinationById(destName);
        if (found != null) {
          setState(() => _selectedDestination = found);
        }
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
    if (_currentStep < _totalSteps - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 320),
        curve: Curves.easeOutCubic,
      );
      setState(() => _currentStep++);
      _animController.reset();
      _animController.forward();
    } else {
      _onGeneratePressed();
    }
  }

  void _prevStep() {
    if (_currentStep > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 320),
        curve: Curves.easeOutCubic,
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

  void _onGeneratePressed() async {
    final user = FirebaseClient.auth.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please sign in to generate and save your journey.'),
          backgroundColor: AppColors.teal,
        ),
      );
      context.push('/login');
      return;
    }

    setState(() => _isGenerating = true);

    try {
      final repo = ref.read(tripRepositoryProvider);
      final generatedTrip = await repo.generateItineraryFromBackend(
        destName: _selectedDestination.name,
        destination: _selectedDestination.id,
        days: _days,
        purpose: _purpose,
        group: _groupType,
        budget: _budget.toInt(),
        startDate: _startDate.toIso8601String().split('T')[0],
        travelerType: _pace == 'fast' ? 'backpacker' : 'comfort',
      );

      if (mounted) {
        setState(() => _isGenerating = false);
        context.push('/itinerary', extra: generatedTrip);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isGenerating = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Generation failed. The NaviiGo Intelligence Engine may be unavailable or returned an error.',
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
                  Text(
                    'STEP 0${_currentStep + 1} OF 0$_totalSteps',
                    style: AppTypography.eyebrow(
                      color: AppColors.primary,
                    ).copyWith(letterSpacing: 1.6),
                  ),
                  InkWell(
                    onTap: () {
                      if (context.canPop()) {
                        context.pop();
                      } else {
                        context.go('/home');
                      }
                    },
                    child: Text(
                      'Cancel',
                      style: AppTypography.caption(
                        color: AppColors.textTertiary,
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
                      onPressed: _prevStep,
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
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  _currentStep == _totalSteps - 1
                                      ? 'GENERATE YOUR JOURNEY →'
                                      : 'CONTINUE →',
                                  style: AppTypography.button(
                                    color: Colors.white,
                                  ).copyWith(letterSpacing: 0.8, fontSize: 13),
                                ),
                              ],
                            ),
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

  // ─────────────────────────────────────────────────────────
  // SCENE 01: WHERE?
  // ─────────────────────────────────────────────────────────
  Widget _buildWhereScene() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 22.0),
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
                final isSelected = d.id == _selectedDestination.id;
                return Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: InkWell(
                    onTap: () => setState(() => _selectedDestination = d),
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: isSelected ? AppColors.brown : AppColors.surface,
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
                );
              },
            ),
          ),

          const SizedBox(height: 20),

          // Large Visual Destination Card
          Expanded(
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(22),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.brown.withAlpha(20),
                    blurRadius: 18,
                    offset: const Offset(0, 6),
                  ),
                ],
                image: DecorationImage(
                  image: _selectedDestination.image.startsWith('assets/')
                      ? AssetImage(_selectedDestination.image)
                      : (const AssetImage('assets/brand/jaipur-heritage.jpg')
                            as ImageProvider),
                  fit: BoxFit.cover,
                ),
              ),
              clipBehavior: Clip.antiAlias,
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(22),
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
                        '${_selectedDestination.state.toUpperCase()} · ${_selectedDestination.category.toUpperCase()}',
                        style: AppTypography.micro(
                          color: AppColors.brown,
                        ).copyWith(fontWeight: FontWeight.w800),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      _selectedDestination.name,
                      style: AppTypography.epilogue.copyWith(
                        fontSize: 26,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _selectedDestination.description,
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
            ),
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────
  // SCENE 02: WHEN?
  // ─────────────────────────────────────────────────────────
  Widget _buildWhenScene() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 22.0),
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
            'Choose your departure date and duration for ${_selectedDestination.name}',
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
                Column(
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
                      style: AppTypography.caption(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
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
    );
  }

  // ─────────────────────────────────────────────────────────
  // SCENE 03: WHO'S GOING?
  // ─────────────────────────────────────────────────────────
  Widget _buildWhoScene() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 22.0),
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
            'Party dynamics help us calibrate stay recommendations and pace',
            style: AppTypography.bodySmall(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 20),

          Expanded(
            child: ListView.builder(
              itemCount: _groupOptions.length,
              physics: const BouncingScrollPhysics(),
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
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────
  // SCENE 04: WHAT KIND OF JOURNEY?
  // ─────────────────────────────────────────────────────────
  Widget _buildVibeScene() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 22.0),
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

          Expanded(
            child: ListView.builder(
              itemCount: _purposeOptions.length,
              physics: const BouncingScrollPhysics(),
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
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────
  // SCENE 05: PACE
  // ─────────────────────────────────────────────────────────
  Widget _buildPaceScene() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 22.0),
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
            'Balance the density of activities per day',
            style: AppTypography.bodySmall(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 20),

          Expanded(
            child: ListView.builder(
              itemCount: _paceOptions.length,
              physics: const BouncingScrollPhysics(),
              itemBuilder: (context, index) {
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
                              Text(
                                opt['label']!,
                                style: AppTypography.plusJakartaSans.copyWith(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.brown,
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
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────
  // SCENE 06: BUDGET
  // ─────────────────────────────────────────────────────────
  Widget _buildBudgetScene() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 22.0),
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
                  style: AppTypography.caption(color: AppColors.textSecondary),
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
