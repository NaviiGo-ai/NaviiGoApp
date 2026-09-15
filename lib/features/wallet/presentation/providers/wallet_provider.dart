import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/auth/auth_provider.dart';
import '../../../../core/network/api_provider.dart';
import '../../data/wallet_repository.dart';
import '../../domain/models/wallet_account_model.dart';
import '../../domain/models/wallet_transaction_model.dart';

final walletRepositoryProvider = Provider<WalletRepository>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return WalletRepository(apiClient: apiClient);
});

final walletAccountStreamProvider = StreamProvider<WalletAccountModel>((ref) {
  final user = ref.watch(currentUserProvider);
  if (user == null) {
    return Stream.value(const WalletAccountModel(rewardPoints: 150));
  }
  final repo = ref.watch(walletRepositoryProvider);
  return repo.getWalletAccountStream(user.uid);
});

final walletTransactionsStreamProvider =
    StreamProvider<List<WalletTransactionModel>>((ref) {
      final user = ref.watch(currentUserProvider);
      if (user == null) {
        return Stream.value([]);
      }
      final repo = ref.watch(walletRepositoryProvider);
      return repo.getTransactionsStream(user.uid);
    });

final walletFilterProvider = StateProvider<String>((ref) => 'All');
