import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:naviigo_app/features/profile/data/user_repository.dart';
import 'package:naviigo_app/features/profile/domain/models/user_preferences_model.dart';

// Minimal Firestore boundary double: exercises the real repository's document
// path, merge semantics, acknowledgement wait, and snapshot metadata filter.
class _Firestore extends Fake implements FirebaseFirestore {
  Map<String, dynamic> stored = {
    'recentSearches': ['kept'],
  };
  Map<String, dynamic>? update;
  String? writtenPath;
  bool? merge;
  bool? metadataChanges;
  final ack = Completer<void>();
  final snapshots =
      StreamController<DocumentSnapshot<Map<String, dynamic>>>.broadcast();
  @override
  CollectionReference<Map<String, dynamic>> collection(String path) =>
      _Collection(this, path);
}

// SDK interfaces are implemented only by recording test doubles here.
// ignore: subtype_of_sealed_class
class _Collection extends Fake
    implements CollectionReference<Map<String, dynamic>> {
  final _Firestore db;
  @override
  final String path;
  _Collection(this.db, this.path);
  @override
  DocumentReference<Map<String, dynamic>> doc([String? path]) =>
      _Document(db, '${this.path}/$path');
}

// ignore: subtype_of_sealed_class
class _Document extends Fake
    implements DocumentReference<Map<String, dynamic>> {
  final _Firestore db;
  @override
  final String path;
  _Document(this.db, this.path);
  @override
  CollectionReference<Map<String, dynamic>> collection(String path) =>
      _Collection(db, '${this.path}/$path');
  @override
  Future<void> set(Map<String, dynamic> data, [SetOptions? options]) async {
    db.writtenPath = path;
    db.update = data;
    db.merge = options?.merge;
    await db.ack.future;
    db.stored.addAll(data);
  }

  @override
  Stream<DocumentSnapshot<Map<String, dynamic>>> snapshots({
    bool includeMetadataChanges = false,
    ListenSource source = ListenSource.defaultSource,
  }) {
    db.metadataChanges = includeMetadataChanges;
    return db.snapshots.stream;
  }
}

class _Metadata extends Fake implements SnapshotMetadata {
  @override
  final bool hasPendingWrites;
  @override
  final bool isFromCache;
  _Metadata(this.hasPendingWrites, {this.isFromCache = false});
}

// ignore: subtype_of_sealed_class
class _Snapshot extends Fake implements DocumentSnapshot<Map<String, dynamic>> {
  final Map<String, dynamic>? value;
  @override
  final SnapshotMetadata metadata;
  _Snapshot(this.value, this.metadata);
  @override
  bool get exists => value != null;
  @override
  Map<String, dynamic>? data() => value;
}

void main() {
  test(
    'explicit completion persists all fields in the existing contract after ack',
    () async {
      final db = _Firestore();
      addTearDown(db.snapshots.close);
      final repository = UserRepository(firestore: db);
      const selections = UserPreferencesModel(
        travelStyle: 'mid-range',
        preferredGroup: 'solo',
        interests: ['culture', 'food'],
        dietaryPreferences: ['vegetarian'],
        accessibilityNeeds: ['step-free'],
        homeCity: 'Jaipur',
        adaptiveAppearanceEnabled: false,
      );
      var confirmed = false;
      final save = repository
          .completeOnboarding('traveller', selections)
          .then((_) => confirmed = true);
      await Future<void>.delayed(Duration.zero);
      expect(confirmed, isFalse);
      expect(db.stored['onboardingCompleted'], isNull);
      expect(db.writtenPath, 'users/traveller/preferences/main');
      expect(db.merge, isTrue);
      expect(db.update, containsPair('onboardingCompleted', true));
      expect(db.update, containsPair('adaptiveAppearanceEnabled', false));
      expect(
        selections.copyWith(sourceUserId: 'traveller').toMap(),
        isNot(contains('sourceUserId')),
      );
      db.ack.complete();
      await save;
      expect(confirmed, isTrue);
      final loaded = UserPreferencesModel.fromMap(db.stored);
      expect(loaded.onboardingCompleted, isTrue);
      expect(loaded.travelStyle, selections.travelStyle);
      expect(loaded.preferredGroup, selections.preferredGroup);
      expect(loaded.interests, selections.interests);
      expect(loaded.dietaryPreferences, selections.dietaryPreferences);
      expect(loaded.accessibilityNeeds, selections.accessibilityNeeds);
      expect(loaded.homeCity, selections.homeCity);
      expect(db.stored['recentSearches'], ['kept']);
    },
  );

  test(
    'completion serializes cleared lists rather than preserving removed choices',
    () async {
      final db = _Firestore()..stored['interests'] = ['adventure'];
      db.ack.complete();
      addTearDown(db.snapshots.close);
      await UserRepository(
        firestore: db,
      ).completeOnboarding('u', const UserPreferencesModel());
      expect(db.stored['interests'], isEmpty);
      expect(db.stored['dietaryPreferences'], isEmpty);
      expect(db.stored['accessibilityNeeds'], isEmpty);
      expect(db.stored['onboardingCompleted'], isTrue);
    },
  );

  test(
    'ordinary updates preserve existing completion and persist appearance both ways',
    () async {
      final db = _Firestore()..stored['onboardingCompleted'] = true;
      db.ack.complete();
      addTearDown(db.snapshots.close);
      final repo = UserRepository(firestore: db);
      for (final enabled in [false, true]) {
        await repo.updateUserPreferences(
          'u',
          UserPreferencesModel(adaptiveAppearanceEnabled: enabled),
        );
        expect(db.update!['adaptiveAppearanceEnabled'], enabled);
        expect(
          UserPreferencesModel.fromMap(db.stored).adaptiveAppearanceEnabled,
          enabled,
        );
        expect(db.stored['onboardingCompleted'], isTrue);
      }
    },
  );

  test(
    'legacy and missing documents are incomplete, not empty-field heuristics',
    () {
      for (final value in [
        null,
        <String, dynamic>{},
        {
          'travelStyle': 'luxury',
          'interests': ['culture'],
        },
        {'onboardingCompleted': 'true'},
      ]) {
        final prefs = UserPreferencesModel.fromFirestore(
          _Snapshot(value, _Metadata(false)),
        );
        expect(prefs.onboardingCompleted, isFalse);
        expect(prefs.adaptiveAppearanceEnabled, isTrue);
      }
    },
  );

  test(
    'pending completion cannot unlock entry; confirmed cached state can',
    () async {
      final db = _Firestore();
      addTearDown(db.snapshots.close);
      final received = <UserPreferencesModel>[];
      final subscription = UserRepository(
        firestore: db,
      ).getUserPreferencesStream('u').listen(received.add);
      addTearDown(subscription.cancel);
      expect(db.metadataChanges, isTrue);
      db.snapshots.add(_Snapshot({}, _Metadata(false)));
      db.snapshots.add(
        _Snapshot({'onboardingCompleted': true}, _Metadata(true)),
      );
      await Future<void>.delayed(Duration.zero);
      expect(received.map((p) => p.onboardingCompleted), [false]);
      db.snapshots.add(
        _Snapshot({
          'onboardingCompleted': true,
        }, _Metadata(false, isFromCache: true)),
      );
      await Future<void>.delayed(Duration.zero);
      expect(received.map((p) => p.onboardingCompleted), [false, true]);
    },
  );
}
