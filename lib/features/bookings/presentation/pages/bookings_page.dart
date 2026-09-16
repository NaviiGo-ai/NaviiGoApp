import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../providers/bookings_provider.dart';
import '../../domain/models/booking_model.dart';
import '../../../navigation/presentation/nav_hub_page.dart';

class BookingsPage extends ConsumerWidget {
  const BookingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bookingsAsync = ref.watch(bookingsStreamProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: const NavHubLeading(),
        title: Text(
          'BOOKINGS & VOUCHERS',
          style: AppTypography.eyebrow(color: AppColors.brown),
        ),
        centerTitle: true,
      ),
      body: bookingsAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
        error: (err, _) => Center(
          child: Text(
            'Error loading bookings: $err',
            style: AppTypography.bodyMedium(),
          ),
        ),
        data: (bookings) {
          if (bookings.isEmpty) {
            return _buildEmptyBookingsState(context);
          }

          return ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            itemCount: bookings.length,
            separatorBuilder: (_, __) => const SizedBox(height: 16),
            itemBuilder: (context, index) {
              final booking = bookings[index];
              return _buildBookingCard(context, booking);
            },
          );
        },
      ),
    );
  }

  Widget _buildEmptyBookingsState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(22),
              decoration: const BoxDecoration(
                color: AppColors.cream,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.confirmation_number_outlined,
                size: 48,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 18),
            Text(
              'No Active Bookings',
              style: AppTypography.sectionTitle(color: AppColors.textPrimary),
            ),
            const SizedBox(height: 8),
            Text(
              'Tickets, rail confirmations, and hotel vouchers for your journeys will appear here.',
              textAlign: TextAlign.center,
              style: AppTypography.caption(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => context.go('/transportation'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 14,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                'SEARCH TRANSIT & STAYS',
                style: AppTypography.button(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBookingCard(BuildContext context, BookingModel booking) {
    return GestureDetector(
      onTap: () => _showBookingDetails(context, booking),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.cream,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    _getIconForType(booking.type),
                    color: AppColors.primary,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        booking.providerName,
                        style: AppTypography.tripTitle(
                          color: AppColors.textPrimary,
                        ),
                      ),
                      if (booking.providerCode != null)
                        Text(
                          booking.providerCode!,
                          style: AppTypography.caption(
                            color: AppColors.textSecondary,
                          ),
                        ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.teal.withAlpha(20),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    booking.status.toUpperCase(),
                    style: AppTypography.micro(color: AppColors.teal),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            const Divider(color: AppColors.border, height: 1),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'ROUTE',
                      style: AppTypography.micro(color: AppColors.textTertiary),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${booking.from} → ${booking.to}',
                      style: AppTypography.bodyMedium(
                        color: AppColors.textPrimary,
                      ).copyWith(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                if (booking.pnr != null && booking.pnr!.isNotEmpty)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        'PNR / REFERENCE',
                        style: AppTypography.micro(
                          color: AppColors.textTertiary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        booking.pnr!,
                        style: AppTypography.bodyMedium(
                          color: AppColors.primary,
                        ).copyWith(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Date: ${booking.date}',
                  style: AppTypography.caption(color: AppColors.textSecondary),
                ),
                Text(
                  '${booking.travelers} Traveler${booking.travelers > 1 ? 's' : ''}',
                  style: AppTypography.caption(color: AppColors.textSecondary),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showBookingDetails(BuildContext context, BookingModel booking) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: const EdgeInsets.all(24),
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
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'BOOKING VOUCHER',
                    style: AppTypography.eyebrow(color: AppColors.primary),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, size: 20),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                booking.providerName,
                style: AppTypography.editorialTitle(
                  color: AppColors.textPrimary,
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
                    _buildDetailRow('Status', booking.status.toUpperCase()),
                    const Divider(color: AppColors.border, height: 16),
                    _buildDetailRow('Leg', '${booking.from} to ${booking.to}'),
                    const Divider(color: AppColors.border, height: 16),
                    _buildDetailRow('Travel Date', booking.date),
                    if (booking.pnr != null) ...[
                      const Divider(color: AppColors.border, height: 16),
                      _buildDetailRow('PNR / Ref', booking.pnr!),
                    ],
                    if (booking.totalPrice > 0) ...[
                      const Divider(color: AppColors.border, height: 16),
                      _buildDetailRow(
                        'Total Paid',
                        '₹${booking.totalPrice.toStringAsFixed(0)}',
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () async {
                    Navigator.pop(context);
                    final text =
                        'NaviiGo Voucher: ${booking.providerName}\nLeg: ${booking.from} to ${booking.to}\nDate: ${booking.date}\nPNR: ${booking.pnr ?? "Confirmed"}\nAmount: ₹${booking.totalPrice.toStringAsFixed(0)}';
                    await Clipboard.setData(ClipboardData(text: text));
                    HapticFeedback.lightImpact();
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'Voucher copied to clipboard for ${booking.providerName}',
                          ),
                          backgroundColor: AppColors.teal,
                        ),
                      );
                    }
                  },
                  icon: const Icon(Icons.share, size: 18, color: Colors.white),
                  label: Text(
                    'SHARE / OFFLINE VOUCHER',
                    style: AppTypography.button(),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 10),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDetailRow(String label, String value) {
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

  IconData _getIconForType(String type) {
    switch (type.toLowerCase()) {
      case 'flight':
        return Icons.flight_takeoff_rounded;
      case 'train':
      case 'rail':
        return Icons.train_rounded;
      case 'hotel':
      case 'stay':
        return Icons.hotel_rounded;
      case 'taxi':
      case 'cab':
        return Icons.local_taxi_rounded;
      default:
        return Icons.confirmation_number_outlined;
    }
  }
}
