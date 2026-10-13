import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/network/api_exceptions.dart';
import '../../data/trip_repository.dart';
import '../../domain/models/trip_itinerary_model.dart';
import '../../domain/models/trip_operation_models.dart';
import 'trip_provider.dart';

/// The only replan reason currently supported by the shared Phase 6 contract.
///
/// Keep this enum deliberately small. Adding another reason here without an
/// agreed server contract would make the mobile client send a request the
/// server cannot safely interpret.
enum ReplanReason {
  iAmTired;

  String get wireName => 'I_AM_TIRED';
}

/// The identity tuple that scopes a replan operation.
///
/// A revision is required. In particular, it is not safe to manufacture one
/// from activity titles, places, day numbers, list positions, timestamps, or
/// the itinerary ID. Older mobile itinerary documents without an explicit
/// revision stay unavailable until the owner stream supplies one.
class ReplanScope {
  final String ownerUid;
  final String itineraryId;
  final String baseRevisionId;

  const ReplanScope({
    required this.ownerUid,
    required this.itineraryId,
    required this.baseRevisionId,
  });

  /// Returns a scope only when the trip is safe to hand to the replan seam.
  /// The server receipt remains the authority for ownership; this check keeps
  /// an obviously foreign, ephemeral, or unrevisioned model out of the flow.
  static ReplanScope? fromTrip({
    required String? ownerUid,
    required TripItineraryModel trip,
  }) {
    final uid = ownerUid?.trim();
    final revision = trip.revisionId?.trim();
    if (uid == null || uid.isEmpty || trip.userId != uid) return null;
    if (trip.id.trim().isEmpty ||
        trip.isEphemeral ||
        revision == null ||
        !trip.canReplan) {
      return null;
    }
    if (trip.tripStatus != TripStatus.active) return null;
    return ReplanScope(
      ownerUid: uid,
      itineraryId: trip.id,
      baseRevisionId: revision,
    );
  }

  @override
  bool operator ==(Object other) {
    return other is ReplanScope &&
        other.ownerUid == ownerUid &&
        other.itineraryId == itineraryId &&
        other.baseRevisionId == baseRevisionId;
  }

  @override
  int get hashCode => Object.hash(ownerUid, itineraryId, baseRevisionId);
}

/// Narrow seam for the repository/backend contract.
///
/// Production uses [TripRepositoryReplanAdapter] for the aligned owner-path
/// contract. Tests may override this seam without changing the state machine.
abstract interface class ReplanRepository {
  /// Whether this adapter is connected to the aligned Phase 6 contract.
  bool get isAvailable;

  Future<ReplanProposal> requestProposal({
    required String ownerUid,
    required ReplanRequest request,
  });

  Future<ReplanAcceptanceResult> acceptProposal({
    required String ownerUid,
    required String itineraryId,
    required String operationId,
    required String baseRevisionId,
    required ReplanProposal proposal,
  });
}

/// Explicit fail-closed adapter for environments without the aligned contract.
class UnavailableReplanRepository implements ReplanRepository {
  const UnavailableReplanRepository();

  @override
  bool get isAvailable => false;

  @override
  Future<ReplanProposal> requestProposal({
    required String ownerUid,
    required ReplanRequest request,
  }) async {
    throw const ReplanUnavailableException();
  }

  @override
  Future<ReplanAcceptanceResult> acceptProposal({
    required String ownerUid,
    required String itineraryId,
    required String operationId,
    required String baseRevisionId,
    required ReplanProposal proposal,
  }) async {
    throw const ReplanUnavailableException();
  }
}

/// Adapter from the provider seam to the repository's verified owner-path
/// implementation. Keeping this adapter here prevents the UI from inventing a
/// second network contract while still making the production flow reachable.
class TripRepositoryReplanAdapter implements ReplanRepository {
  TripRepositoryReplanAdapter(this._repository);

  final TripRepository _repository;

  @override
  bool get isAvailable => true;

  @override
  Future<ReplanProposal> requestProposal({
    required String ownerUid,
    required ReplanRequest request,
  }) => _repository.requestReplanForRequest(uid: ownerUid, request: request);

  @override
  Future<ReplanAcceptanceResult> acceptProposal({
    required String ownerUid,
    required String itineraryId,
    required String operationId,
    required String baseRevisionId,
    required ReplanProposal proposal,
  }) => _repository.acceptReplan(
    uid: ownerUid,
    itineraryId: itineraryId,
    proposalId: proposal.proposalId,
    operationId: operationId,
    baseRevisionId: baseRevisionId,
  );
}

final replanRepositoryProvider = Provider<ReplanRepository>(
  (ref) => TripRepositoryReplanAdapter(ref.read(tripRepositoryProvider)),
);

typedef ReplanOperationIdFactory = String Function();

String _newReplanOperationId() {
  return const Uuid().v4();
}

final replanOperationIdFactoryProvider = Provider<ReplanOperationIdFactory>(
  (ref) => _newReplanOperationId,
);

class ReplanUnavailableException implements Exception {
  final String message;

  const ReplanUnavailableException([
    this.message =
        'Contextual replanning is unavailable for this saved itinerary.',
  ]);

  @override
  String toString() => message;
}

class ReplanStaleException implements Exception {
  final String message;

  const ReplanStaleException([
    this.message = 'This itinerary changed before the replan could be applied.',
  ]);

  @override
  String toString() => message;
}

class ReplanAmbiguousException implements Exception {
  final String message;

  const ReplanAmbiguousException([
    this.message =
        'The replan result could not be confirmed. Retry the same operation to reconcile it.',
  ]);

  @override
  String toString() => message;
}

class ReplanContractException implements Exception {
  final String message;

  const ReplanContractException(this.message);

  @override
  String toString() => message;
}

enum ReplanStatus {
  unavailable,
  idle,
  requesting,
  review,
  accepting,
  accepted,
  stale,
  ambiguous,
  failed,
}

enum ReplanAction { request, accept }

class ReplanState {
  final String ownerUid;
  final String itineraryId;
  final String baseRevisionId;
  final ReplanStatus status;
  final String? operationId;
  final ReplanRequest? request;
  final ReplanProposal? proposal;
  final TripOperationReceipt? receipt;
  final TripItineraryModel? authoritativeItinerary;
  final String? message;
  final ReplanAction? lastAction;

  const ReplanState({
    required this.ownerUid,
    required this.itineraryId,
    required this.baseRevisionId,
    this.status = ReplanStatus.idle,
    this.operationId,
    this.request,
    this.proposal,
    this.receipt,
    this.authoritativeItinerary,
    this.message,
    this.lastAction,
  });

  bool get isBusy =>
      status == ReplanStatus.requesting || status == ReplanStatus.accepting;

  bool get hasUnconfirmedResult => status == ReplanStatus.ambiguous;

  ReplanState copyWith({
    ReplanStatus? status,
    String? operationId,
    ReplanRequest? request,
    ReplanProposal? proposal,
    TripOperationReceipt? receipt,
    TripItineraryModel? authoritativeItinerary,
    String? message,
    ReplanAction? lastAction,
    bool clearProposal = false,
    bool clearReceipt = false,
    bool clearAuthoritativeItinerary = false,
    bool clearMessage = false,
    bool clearOperationId = false,
    bool clearRequest = false,
  }) {
    return ReplanState(
      ownerUid: ownerUid,
      itineraryId: itineraryId,
      baseRevisionId: baseRevisionId,
      status: status ?? this.status,
      operationId: clearOperationId ? null : (operationId ?? this.operationId),
      request: clearRequest ? null : (request ?? this.request),
      proposal: clearProposal ? null : (proposal ?? this.proposal),
      receipt: clearReceipt ? null : (receipt ?? this.receipt),
      authoritativeItinerary: clearAuthoritativeItinerary
          ? null
          : (authoritativeItinerary ?? this.authoritativeItinerary),
      message: clearMessage ? null : (message ?? this.message),
      lastAction: lastAction ?? this.lastAction,
    );
  }
}

class ReplanController extends StateNotifier<ReplanState> {
  ReplanController(
    this._ref,
    this.scope,
    this._repository,
    this._operationIdFactory,
  ) : super(
        ReplanState(
          ownerUid: scope.ownerUid,
          itineraryId: scope.itineraryId,
          baseRevisionId: scope.baseRevisionId,
          status: _repository.isAvailable
              ? ReplanStatus.idle
              : ReplanStatus.unavailable,
          message: _repository.isAvailable
              ? null
              : 'Contextual replanning is unavailable for this saved itinerary. '
                    'Your current plan remains unchanged.',
        ),
      );

  final Ref _ref;
  final ReplanScope scope;
  final ReplanRepository _repository;
  final ReplanOperationIdFactory _operationIdFactory;
  int _generation = 0;

  bool _isCurrent(int generation) {
    return mounted &&
        generation == _generation &&
        _ref.read(currentUserIdProvider) == scope.ownerUid;
  }

  bool _hasVerifiedOwner() {
    if (_ref.read(currentUserIdProvider) == scope.ownerUid) return true;
    state = state.copyWith(
      status: ReplanStatus.unavailable,
      message: 'Sign in again to verify ownership before replanning.',
      clearProposal: true,
      clearReceipt: true,
      clearAuthoritativeItinerary: true,
    );
    return false;
  }

  String _operationId() {
    final existing = state.operationId;
    if (existing != null && existing.isNotEmpty) return existing;
    final created = _operationIdFactory().trim();
    if (created.isEmpty) {
      throw const ReplanContractException(
        'A replan operation could not be identified safely.',
      );
    }
    return created;
  }

  /// Request a proposal. The request does not change the visible itinerary.
  ///
  /// Request context is supplied by Live Journey so the server receives the
  /// actual display day and stable check-in identities. No day is converted to
  /// an array position here.
  Future<void> requestProposal({
    required int? currentDayNumber,
    String? currentTime,
    List<String> completedActivityIds = const [],
    List<String> skippedActivityIds = const [],
    ReplanLocation? location,
    String destinationTimezone = 'UTC',
  }) async {
    if (state.isBusy ||
        state.status == ReplanStatus.review ||
        state.status == ReplanStatus.accepted ||
        state.status == ReplanStatus.stale ||
        state.status == ReplanStatus.unavailable) {
      return;
    }
    if (!_hasVerifiedOwner()) return;

    if (currentDayNumber == null || currentDayNumber < 1) {
      state = state.copyWith(
        status: ReplanStatus.failed,
        message:
            'The current day is unavailable, so a safe replan request cannot be sent.',
      );
      return;
    }

    late final String operationId;
    late final ReplanRequest request;
    try {
      operationId = _operationId();
      request = ReplanRequest(
        itineraryId: scope.itineraryId,
        operationId: operationId,
        baseRevisionId: scope.baseRevisionId,
        currentDayNumber: currentDayNumber,
        currentTime: currentTime ?? DateTime.now().toIso8601String(),
        reason: ReplanReason.iAmTired.wireName,
        completedActivityIds: List<String>.unmodifiable(completedActivityIds),
        skippedActivityIds: List<String>.unmodifiable(skippedActivityIds),
        location: location,
        destinationTimezone: destinationTimezone,
      );
    } catch (error) {
      _applyFailure(error, ReplanAction.request);
      return;
    }
    final generation = ++_generation;
    state = state.copyWith(
      status: ReplanStatus.requesting,
      operationId: operationId,
      request: request,
      lastAction: ReplanAction.request,
      clearMessage: true,
      clearProposal: true,
      clearReceipt: true,
      clearAuthoritativeItinerary: true,
    );

    try {
      final proposal = await _repository.requestProposal(
        ownerUid: scope.ownerUid,
        request: request,
      );
      if (!_isCurrent(generation)) return;
      _validateProposal(proposal, operationId);
      state = state.copyWith(
        status: ReplanStatus.review,
        proposal: proposal,
        clearMessage: true,
      );
    } catch (error) {
      if (!_isCurrent(generation)) return;
      _applyFailure(error, ReplanAction.request);
    }
  }

  /// Accept only the exact proposal currently bound to this scope. The
  /// repository must return both an authoritative itinerary and receipt before
  /// this provider reports success.
  Future<void> acceptProposal() async {
    final proposal = state.proposal;
    if (proposal == null ||
        state.status != ReplanStatus.review ||
        state.isBusy ||
        !_hasVerifiedOwner()) {
      return;
    }

    final operationId = state.operationId;
    if (operationId == null || operationId != proposal.operationId) {
      _applyFailure(
        const ReplanContractException(
          'The replan proposal is no longer bound to this operation.',
        ),
        ReplanAction.accept,
      );
      return;
    }
    final generation = ++_generation;
    state = state.copyWith(
      status: ReplanStatus.accepting,
      lastAction: ReplanAction.accept,
      clearMessage: true,
    );

    try {
      final result = await _repository.acceptProposal(
        ownerUid: scope.ownerUid,
        itineraryId: scope.itineraryId,
        operationId: operationId,
        baseRevisionId: scope.baseRevisionId,
        proposal: proposal,
      );
      if (!_isCurrent(generation)) return;
      final authoritative = result.itinerary;
      if (authoritative is! TripItineraryModel) {
        throw const ReplanContractException(
          'The authoritative replan itinerary could not be verified.',
        );
      }
      _validateAcceptance(result, authoritative, operationId);
      state = state.copyWith(
        status: ReplanStatus.accepted,
        receipt: result.receipt,
        authoritativeItinerary: authoritative,
        clearMessage: true,
      );

      // Ask the existing owner stream to reconcile. The stream remains
      // authoritative; this provider never rewrites activeTripProvider or
      // applies a local/optimistic itinerary mutation.
      _ref.invalidate(userTripsStreamProvider);
    } catch (error) {
      if (!_isCurrent(generation)) return;
      _applyFailure(error, ReplanAction.accept);
    }
  }

  /// Retry only the same operation after an explicitly ambiguous result. A
  /// caller cannot silently create a second operation and claim reconciliation.
  Future<void> retryAmbiguous() async {
    if (state.status != ReplanStatus.ambiguous || state.isBusy) return;
    if (state.lastAction == ReplanAction.accept && state.proposal != null) {
      state = state.copyWith(status: ReplanStatus.review, clearMessage: true);
      await acceptProposal();
      return;
    }
    final request = state.request;
    if (request == null) return;
    state = state.copyWith(status: ReplanStatus.failed, clearMessage: true);
    await requestProposal(
      currentDayNumber: request.currentDayNumber,
      currentTime: request.currentTime,
      completedActivityIds: request.completedActivityIds,
      skippedActivityIds: request.skippedActivityIds,
      location: request.location,
      destinationTimezone: request.destinationTimezone,
    );
  }

  /// Dismiss a proposal without touching the current itinerary. A new request
  /// receives a new operation ID and therefore cannot accidentally accept the
  /// dismissed proposal.
  void keepCurrentPlan() {
    if (state.isBusy) return;
    state = state.copyWith(
      status: _repository.isAvailable
          ? ReplanStatus.idle
          : ReplanStatus.unavailable,
      clearOperationId: true,
      clearRequest: true,
      clearProposal: true,
      clearReceipt: true,
      clearAuthoritativeItinerary: true,
      clearMessage: true,
    );
    _generation++;
  }

  void invalidateSession() => _generation++;

  void _validateProposal(ReplanProposal proposal, String operationId) {
    if (proposal.itineraryId != scope.itineraryId ||
        proposal.operationId != operationId ||
        proposal.baseRevisionId != scope.baseRevisionId ||
        proposal.reason != ReplanReason.iAmTired.wireName) {
      throw const ReplanContractException(
        'The proposal could not be bound to this owner, itinerary, and revision.',
      );
    }
  }

  void _validateAcceptance(
    ReplanAcceptanceResult result,
    TripItineraryModel itinerary,
    String operationId,
  ) {
    final receipt = result.receipt;
    if (receipt.ownerUid != scope.ownerUid ||
        receipt.itineraryId != scope.itineraryId ||
        receipt.operationId != operationId ||
        receipt.status != 'accepted' ||
        receipt.revisionId.trim().isEmpty ||
        itinerary.id != scope.itineraryId ||
        itinerary.userId != scope.ownerUid ||
        (!result.idempotent && itinerary.revisionId != receipt.revisionId) ||
        itinerary.isEphemeral) {
      throw const ReplanContractException(
        'The authoritative replan result or receipt could not be verified.',
      );
    }
  }

  void _applyFailure(Object error, ReplanAction action) {
    final isStaleConflict =
        error is ConflictException &&
        error.conflictCode?.toUpperCase() == 'STALE_PROPOSAL';
    if (error is ReplanStaleException || isStaleConflict) {
      state = state.copyWith(
        status: ReplanStatus.stale,
        message:
            'This itinerary changed before the proposal could be applied. '
            'Refresh the live journey before trying again.',
      );
      return;
    }
    if (error is ReplanUnavailableException) {
      state = state.copyWith(
        status: ReplanStatus.unavailable,
        message: error.message,
      );
      return;
    }
    if (error is ReplanAmbiguousException ||
        action == ReplanAction.accept &&
            error is! ReplanUnavailableException &&
            error is! ReplanStaleException &&
            !isStaleConflict) {
      state = state.copyWith(
        status: ReplanStatus.ambiguous,
        message:
            'We could not confirm this replan operation. It remains unconfirmed; '
            'retry the same operation to reconcile its result.',
      );
      return;
    }
    final message = error is ReplanContractException
        ? error.message
        : 'Could not request a replan right now. Your current plan remains unchanged.';
    state = state.copyWith(status: ReplanStatus.failed, message: message);
  }
}

final replanControllerProvider =
    StateNotifierProvider.family<ReplanController, ReplanState, ReplanScope>((
      ref,
      scope,
    ) {
      final controller = ReplanController(
        ref,
        scope,
        ref.watch(replanRepositoryProvider),
        ref.watch(replanOperationIdFactoryProvider),
      );
      ref.onDispose(controller.invalidateSession);
      return controller;
    });

/// Short alias for widgets and future callers that do not need the controller
/// suffix. Both names point at the same family contract.
final replanProvider = replanControllerProvider;
