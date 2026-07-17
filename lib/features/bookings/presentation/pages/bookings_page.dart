import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class BookingsPage extends StatelessWidget {
  const BookingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.black),
          onPressed: () => context.go('/home'),
        ),
        title: const Text('Bookings', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 18)),
        centerTitle: true,
        actions: [
          IconButton(icon: const Icon(Icons.filter_list_rounded, color: Colors.black), onPressed: () {}),
        ],
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Summary Stats
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFFF6B00), Color(0xFFFF8F3F)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  Column(
                    children: [
                      Text('5', style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
                      SizedBox(height: 4),
                      Text('Active', style: TextStyle(color: Colors.white70, fontSize: 11)),
                    ],
                  ),
                  Column(
                    children: [
                      Text('₹24,500', style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
                      SizedBox(height: 4),
                      Text('This Month', style: TextStyle(color: Colors.white70, fontSize: 11)),
                    ],
                  ),
                  Column(
                    children: [
                      Text('18', style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
                      SizedBox(height: 4),
                      Text('Total', style: TextStyle(color: Colors.white70, fontSize: 11)),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Quick Access Cards
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => context.push('/saved-places'),
                    child: Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.04),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFF3E0),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: const Icon(Icons.bookmark_rounded, color: Color(0xFFFF6B00), size: 24),
                          ),
                          const SizedBox(height: 12),
                          const Text('Saved Places', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                          const SizedBox(height: 4),
                          Text('12 places', style: TextStyle(color: Colors.grey[500], fontSize: 11)),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: GestureDetector(
                    onTap: () => context.push('/payment-history'),
                    child: Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.04),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: const Color(0xFFE8F5E9),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: const Icon(Icons.receipt_long_rounded, color: Color(0xFF059669), size: 24),
                          ),
                          const SizedBox(height: 12),
                          const Text('Payment History', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                          const SizedBox(height: 4),
                          Text('18 transactions', style: TextStyle(color: Colors.grey[500], fontSize: 11)),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 28),

            // Active Bookings
            const Text('Active Bookings', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),

            _buildBookingCard(
              icon: Icons.hotel_rounded,
              title: 'Grand Hyatt Resort',
              subtitle: 'Dubai, UAE • Jul 20 - Jul 23',
              amount: '₹12,500',
              status: 'Confirmed',
              statusColor: const Color(0xFF059669),
              iconBgColor: const Color(0xFF2563EB),
            ),
            const SizedBox(height: 12),

            _buildBookingCard(
              icon: Icons.flight_rounded,
              title: 'Emirates EK524',
              subtitle: 'DEL → DXB • Jul 20, 08:30 AM',
              amount: '₹8,200',
              status: 'Confirmed',
              statusColor: const Color(0xFF059669),
              iconBgColor: const Color(0xFFFF6B00),
            ),
            const SizedBox(height: 12),

            _buildBookingCard(
              icon: Icons.directions_car_rounded,
              title: 'Airport Transfer',
              subtitle: 'DXB Airport → Hotel • Jul 20',
              amount: '₹1,800',
              status: 'Pending',
              statusColor: const Color(0xFFD97706),
              iconBgColor: const Color(0xFF8B5CF6),
            ),
            const SizedBox(height: 12),

            _buildBookingCard(
              icon: Icons.local_activity_rounded,
              title: 'Desert Safari',
              subtitle: 'Dubai Desert • Jul 22, 04:00 PM',
              amount: '₹3,500',
              status: 'Confirmed',
              statusColor: const Color(0xFF059669),
              iconBgColor: const Color(0xFFDC2626),
            ),
            const SizedBox(height: 28),

            // Recent Bookings
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Recent Bookings', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                Text('View all', style: TextStyle(color: Colors.grey[500], fontSize: 13)),
              ],
            ),
            const SizedBox(height: 16),

            _buildRecentBookingItem('Taj Palace Hotel', 'Jaipur • Mar 10-18', '₹9,800', Icons.hotel_rounded),
            _buildRecentBookingItem('Shinkansen Ticket', 'Kyoto → Tokyo • Apr 6', '₹4,200', Icons.train_rounded),
            _buildRecentBookingItem('Gondola Ride', 'Venice • Jan 19', '₹2,100', Icons.sailing_rounded),

            const SizedBox(height: 100),
          ],
        ),
      ),
    );
  }

  Widget _buildBookingCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required String amount,
    required String status,
    required Color statusColor,
    required Color iconBgColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: iconBgColor,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: Colors.white, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                const SizedBox(height: 4),
                Text(subtitle, style: TextStyle(color: Colors.grey[500], fontSize: 11)),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(amount, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(status, style: TextStyle(color: statusColor, fontSize: 10, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRecentBookingItem(String title, String subtitle, String amount, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.grey[100],
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: Colors.grey[600], size: 18),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                const SizedBox(height: 2),
                Text(subtitle, style: TextStyle(color: Colors.grey[500], fontSize: 11)),
              ],
            ),
          ),
          Text(amount, style: TextStyle(color: Colors.grey[700], fontSize: 13, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
