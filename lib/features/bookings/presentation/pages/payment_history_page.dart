import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../wallet/domain/models/wallet_transaction_model.dart';
import '../../../wallet/presentation/providers/wallet_provider.dart';
import '../../../navigation/presentation/nav_hub_page.dart';

class PaymentHistoryPage extends ConsumerWidget {
  const PaymentHistoryPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final accountAsync = ref.watch(walletAccountStreamProvider);
    final transactionsAsync = ref.watch(walletTransactionsStreamProvider);
    final selectedFilter = ref.watch(walletFilterProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: const NavHubLeading(),
        title: Text(
          'TRAVEL WALLET & LEDGER',
          style: AppTypography.eyebrow(color: AppColors.brown),
        ),
        centerTitle: true,
      ),
      body: CustomScrollView(
        slivers: [
          // Wallet Balance Header Card
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Container(
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [AppColors.brown, Color(0xFF3E170B)],
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.brown.withAlpha(50),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      alignment: WrapAlignment.spaceBetween,
                      spacing: 12,
                      runSpacing: 8,
                      children: [
                        Text(
                          'NAVIIGO CREDIT',
                          style: AppTypography.micro(color: AppColors.cream),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withAlpha(30),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.stars_rounded,
                                color: AppColors.yellow,
                                size: 14,
                              ),
                              const SizedBox(width: 4),
                              accountAsync.when(
                                data: (acc) => Text(
                                  '${acc.rewardPoints} Points',
                                  style: AppTypography.micro(
                                    color: Colors.white,
                                  ),
                                ),
                                loading: () => const Text(
                                  '...',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                  ),
                                ),
                                error: (_, __) => const Text(
                                  'Points unavailable',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    accountAsync.when(
                      data: (acc) => Text(
                        acc.formattedBalance,
                        style: AppTypography.displayHero(color: Colors.white),
                      ),
                      loading: () => const Text(
                        '₹ --.--',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      error: (_, __) => const Text(
                        'Unavailable',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Your NaviiGo credit and payment history',
                      style: AppTypography.micro(
                        color: AppColors.cream.withAlpha(180),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Filter chips
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Wrap(
                runSpacing: 8,
                children: ['All', 'Trip', 'Refund', 'Reward'].map((filter) {
                  final isSelected = selectedFilter == filter;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(
                        filter.toUpperCase(),
                        style: AppTypography.micro(
                          color: isSelected
                              ? Colors.white
                              : AppColors.textSecondary,
                        ),
                      ),
                      selected: isSelected,
                      selectedColor: AppColors.primary,
                      backgroundColor: Colors.white,
                      side: BorderSide(
                        color: isSelected
                            ? AppColors.primary
                            : AppColors.border,
                      ),
                      onSelected: (_) {
                        ref.read(walletFilterProvider.notifier).state = filter;
                      },
                    ),
                  );
                }).toList(),
              ),
            ),
          ),

          // Transactions List
          transactionsAsync.when(
            loading: () => const SliverFillRemaining(
              child: Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              ),
            ),
            error: (err, _) => SliverFillRemaining(
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('Payment history is unavailable. Try again.'),
                    TextButton(
                      onPressed: () {
                        ref.invalidate(walletAccountStreamProvider);
                        ref.invalidate(walletTransactionsStreamProvider);
                      },
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            ),
            data: (allTransactions) {
              final filtered = allTransactions.where((tx) {
                if (selectedFilter == 'Trip') {
                  return tx.type.contains('BOOKING');
                }
                if (selectedFilter == 'Refund') {
                  return tx.type.contains('REFUND');
                }
                if (selectedFilter == 'Reward') {
                  return tx.type.contains('REWARD');
                }
                return true;
              }).toList();

              if (filtered.isEmpty) {
                return SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.receipt_long_outlined,
                            size: 48,
                            color: AppColors.border,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'No Transactions Found',
                            style: AppTypography.sectionTitle(
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Your completed booking debits and refunds will appear here.',
                            textAlign: TextAlign.center,
                            style: AppTypography.caption(
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }

              return SliverPadding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 10,
                ),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate((context, index) {
                    final tx = filtered[index];
                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        leading: Container(
                          width: 42,
                          height: 42,
                          decoration: BoxDecoration(
                            color: tx.direction == TransactionDirection.credit
                                ? AppColors.teal.withAlpha(20)
                                : AppColors.cream,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(
                            tx.direction == TransactionDirection.credit
                                ? Icons.arrow_downward_rounded
                                : Icons.arrow_upward_rounded,
                            color: tx.direction == TransactionDirection.credit
                                ? AppColors.teal
                                : AppColors.primary,
                            size: 20,
                          ),
                        ),
                        title: Text(
                          tx.description,
                          style: AppTypography.tripTitle(
                            color: AppColors.textPrimary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        subtitle: Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            tx.createdAt != null
                                ? '${tx.createdAt!.day}/${tx.createdAt!.month}/${tx.createdAt!.year}'
                                : 'Completed',
                            style: AppTypography.caption(
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ),
                        trailing: Text(
                          tx.formattedAmount,
                          style: AppTypography.tripTitle(
                            color: tx.direction == TransactionDirection.credit
                                ? AppColors.teal
                                : AppColors.textPrimary,
                          ),
                        ),
                        onTap: () => _showTransactionDetail(context, tx),
                      ),
                    );
                  }, childCount: filtered.length),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  void _showTransactionDetail(BuildContext context, WalletTransactionModel tx) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: const EdgeInsets.all(24),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.border,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'TRANSACTION DETAILS',
                  style: AppTypography.eyebrow(color: AppColors.primary),
                ),
                const SizedBox(height: 8),
                Text(
                  tx.formattedAmount,
                  style: AppTypography.displayHero(
                    color: tx.direction == TransactionDirection.credit
                        ? AppColors.teal
                        : AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceWarm,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Column(
                    children: [
                      _buildRow('Status', tx.status),
                      const Divider(color: AppColors.border, height: 16),
                      _buildRow('Type', tx.type.replaceAll('_', ' ')),
                      const Divider(color: AppColors.border, height: 16),
                      _buildRow('Source', tx.source),
                      if (tx.referenceId != null) ...[
                        const Divider(color: AppColors.border, height: 16),
                        _buildRow('Reference ID', tx.referenceId!),
                      ],
                      if (tx.createdAt != null) ...[
                        const Divider(color: AppColors.border, height: 16),
                        _buildRow('Timestamp', tx.createdAt!.toIso8601String()),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: AppTypography.caption(color: AppColors.textSecondary),
        ),
        Text(
          value,
          style: AppTypography.bodyMedium(
            color: AppColors.textPrimary,
          ).copyWith(fontWeight: FontWeight.bold),
        ),
      ],
    );
  }
}
