import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'auth_repository.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository();
});

final authStateProvider = StreamProvider<User?>((ref) {
  final repo = ref.watch(authRepositoryProvider);
  return repo.authStateChanges;
});

final currentUserProvider = Provider<User?>((ref) {
  final authState = ref.watch(authStateProvider);
  if (authState.hasValue) return authState.value;
  return ref.watch(authRepositoryProvider).currentUser;
});

enum AuthStatus { initial, loading, authenticated, unauthenticated, error }

class AuthState {
  final AuthStatus status;
  final String? errorMessage;

  const AuthState({this.status = AuthStatus.initial, this.errorMessage});

  AuthState copyWith({AuthStatus? status, String? errorMessage}) {
    return AuthState(status: status ?? this.status, errorMessage: errorMessage);
  }
}

class AuthController extends StateNotifier<AuthState> {
  final AuthRepository _repo;

  AuthController(this._repo) : super(const AuthState());

  Future<bool> signIn(String email, String password) async {
    state = state.copyWith(status: AuthStatus.loading, errorMessage: null);
    try {
      await _repo.signInWithEmailAndPassword(email: email, password: password);
      state = state.copyWith(status: AuthStatus.authenticated);
      return true;
    } on FirebaseAuthException catch (e) {
      state = state.copyWith(
        status: AuthStatus.error,
        errorMessage: _formatAuthError(e),
      );
      return false;
    } catch (_) {
      state = state.copyWith(
        status: AuthStatus.error,
        errorMessage: 'Could not sign in. Please try again.',
      );
      return false;
    }
  }

  Future<bool> register(
    String email,
    String password,
    String displayName,
  ) async {
    state = state.copyWith(status: AuthStatus.loading, errorMessage: null);
    try {
      await _repo.registerWithEmailAndPassword(
        email: email,
        password: password,
        displayName: displayName,
      );
      state = state.copyWith(status: AuthStatus.authenticated);
      return true;
    } on FirebaseAuthException catch (e) {
      state = state.copyWith(
        status: AuthStatus.error,
        errorMessage: _formatAuthError(e),
      );
      return false;
    } catch (_) {
      state = state.copyWith(
        status: AuthStatus.error,
        errorMessage: 'Could not create your account. Please try again.',
      );
      return false;
    }
  }

  Future<bool> signOut() async {
    state = state.copyWith(status: AuthStatus.loading);
    try {
      await _repo.signOut();
      state = state.copyWith(status: AuthStatus.unauthenticated);
      return true;
    } catch (_) {
      state = state.copyWith(
        status: AuthStatus.error,
        errorMessage: 'Could not sign out. Please try again.',
      );
      return false;
    }
  }

  void clearError() => state = const AuthState();

  String _formatAuthError(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return 'No user found with this email address.';
      case 'wrong-password':
      case 'invalid-credential':
        return 'Invalid credentials. Please verify your email and password.';
      case 'email-already-in-use':
        return 'An account already exists for this email.';
      case 'invalid-email':
        return 'The email address is invalid.';
      case 'weak-password':
        return 'Choose a stronger password with at least 6 characters.';
      case 'network-request-failed':
        return 'Check your connection and try again.';
      case 'too-many-requests':
        return 'Too many attempts. Please wait a little and try again.';
      case 'user-disabled':
        return 'This account is unavailable. Please contact support.';
      default:
        return 'Unable to sign in right now. Please try again.';
    }
  }
}

final authControllerProvider = StateNotifierProvider<AuthController, AuthState>(
  (ref) {
    final repo = ref.watch(authRepositoryProvider);
    return AuthController(repo);
  },
);
