// The SDK's sealed reference types are faked only at the transaction test seam.
// ignore_for_file: subtype_of_sealed_class
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:naviigo_app/features/bookings/data/passport_repository.dart';
import 'package:naviigo_app/features/bookings/domain/models/passport_model.dart';

class _Firestore extends Fake implements FirebaseFirestore {
  final records = <String, Map<String, dynamic>>{};
  int committedWrites = 0;
  bool failBeforeCommit = false;
  bool failAfterCommit = false;
  void Function()? afterRead;

  @override
  CollectionReference<Map<String, dynamic>> collection(String path) =>
      _Collection(path);

  @override
  Future<T> runTransaction<T>(
    TransactionHandler<T> transactionHandler, {
    Duration timeout = const Duration(seconds: 30),
    int maxAttempts = 5,
  }) async {
    final transaction = _Transaction(this);
    final result = await transactionHandler(transaction);
    if (failBeforeCommit) throw StateError('storage unavailable');
    for (final entry in transaction.pending.entries) {
      records[entry.key] = {...?records[entry.key], ...entry.value};
      committedWrites++;
    }
    if (failAfterCommit) throw StateError('connection lost after commit');
    return result;
  }
}

class _Collection extends Fake
    implements CollectionReference<Map<String, dynamic>> {
  _Collection(this.path);
  @override
  final String path;
  @override
  DocumentReference<Map<String, dynamic>> doc([String? path]) =>
      _Document('${this.path}/$path');
}

class _Document extends Fake
    implements DocumentReference<Map<String, dynamic>> {
  _Document(this.path);
  @override
  final String path;
  @override
  CollectionReference<Map<String, dynamic>> collection(String path) =>
      _Collection('${this.path}/$path');
}

class _Snapshot<T extends Object?> extends Fake implements DocumentSnapshot<T> {
  _Snapshot(this.exists);
  @override
  final bool exists;
}

class _Transaction extends Fake implements Transaction {
  _Transaction(this.store);
  final _Firestore store;
  final pending = <String, Map<String, dynamic>>{};
  @override
  Future<DocumentSnapshot<T>> get<T extends Object?>(
    DocumentReference<T> reference,
  ) async {
    final snapshot = _Snapshot<T>(store.records.containsKey(reference.path));
    store.afterRead?.call();
    return snapshot;
  }

  @override
  Transaction set<T>(
    DocumentReference<T> reference,
    T data, [
    SetOptions? options,
  ]) {
    pending[reference.path] = Map<String, dynamic>.from(data as Map);
    return this;
  }
}

void main() {
  const stamp = PassportStampModel(
    id: 'award-trip-revision',
    awardKey: 'award-trip-revision',
    name: 'My travel memory',
    location: 'Jaipur',
    state: 'Rajasthan',
    xpEarned: 0,
    isVerified: false,
    verificationMethod: 'traveller_reported',
  );
  test(
    'a repeated owner award writes one entry and one stats mutation',
    () async {
      final store = _Firestore();
      final repository = PassportRepository(
        firestore: store,
        currentUserUid: () => 'alice',
      );
      expect(
        await repository.awardPassportStamp('alice', stamp),
        PassportAwardResult.awarded,
      );
      expect(
        await repository.awardPassportStamp('alice', stamp),
        PassportAwardResult.alreadyAwarded,
      );
      expect(store.committedWrites, 2);
      expect(store.records.length, 2);
      expect(
        store.records.keys.every((path) => path.startsWith('users/alice/')),
        isTrue,
      );
    },
  );
  test(
    'failed transaction leaves neither an award nor changed stats',
    () async {
      final store = _Firestore()..failBeforeCommit = true;
      final repository = PassportRepository(
        firestore: store,
        currentUserUid: () => 'alice',
      );
      await expectLater(
        repository.awardPassportStamp('alice', stamp),
        throwsStateError,
      );
      expect(store.records, isEmpty);
      expect(store.committedWrites, 0);
    },
  );
  test(
    'retry after an ambiguous committed result does not award twice',
    () async {
      final store = _Firestore()..failAfterCommit = true;
      final repository = PassportRepository(
        firestore: store,
        currentUserUid: () => 'alice',
      );
      await expectLater(
        repository.awardPassportStamp('alice', stamp),
        throwsStateError,
      );
      store.failAfterCommit = false;
      expect(
        await repository.awardPassportStamp('alice', stamp),
        PassportAwardResult.alreadyAwarded,
      );
      expect(store.committedWrites, 2);
    },
  );
  test(
    'an account change during the transaction rejects all pending writes',
    () async {
      final store = _Firestore();
      var uid = 'alice';
      store.afterRead = () => uid = 'bob';
      final repository = PassportRepository(
        firestore: store,
        currentUserUid: () => uid,
      );
      await expectLater(
        repository.awardPassportStamp('alice', stamp),
        throwsA(isA<PassportAwardException>()),
      );
      expect(store.records, isEmpty);
    },
  );
}
