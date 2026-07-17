import 'package:flutter/material.dart';

class PaymentHistoryPage extends StatelessWidget {
  const PaymentHistoryPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAF9F6),
      appBar: AppBar(
        title: const Text('Payment History', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: ListView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(16),
        children: [
          const Text('August 2024', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF2D3142))),
          const SizedBox(height: 16),
          _buildReceiptCard('Grand Resort Santorini', 'Hotel Booking', 'Aug 14, 2024', '\$1,250.00', Icons.hotel_rounded, Colors.blue),
          const SizedBox(height: 16),
          _buildReceiptCard('Emirates Airlines', 'Flight EK412', 'Aug 02, 2024', '\$840.00', Icons.flight_rounded, Colors.orange),
          const SizedBox(height: 32),
          
          const Text('July 2024', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF2D3142))),
          const SizedBox(height: 16),
          _buildReceiptCard('Ocean View Cafe', 'Dining', 'Jul 28, 2024', '\$45.50', Icons.restaurant_rounded, Colors.green),
          const SizedBox(height: 16),
          _buildReceiptCard('Uber', 'Transport', 'Jul 27, 2024', '\$24.00', Icons.local_taxi_rounded, Colors.black),
        ],
      ),
    );
  }

  Widget _buildReceiptCard(String title, String subtitle, String date, String amount, IconData icon, Color iconColor) {
    return Theme(
      data: ThemeData().copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        collapsedBackgroundColor: Colors.white,
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: Colors.black.withValues(alpha: 0.05)),
        ),
        collapsedShape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: Colors.black.withValues(alpha: 0.05)),
        ),
        leading: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: iconColor.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: iconColor),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF2D3142))),
        subtitle: Text('$subtitle • $date', style: TextStyle(color: Colors.grey[500], fontSize: 12)),
        trailing: Text(amount, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: Color(0xFF2D3142))),
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 20, right: 20, bottom: 20),
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFFFAF9F6),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.withValues(alpha: 0.2), style: BorderStyle.solid), // Changed to solid for standard Container
              ),
              child: Column(
                children: [
                  const Text('DIGITAL RECEIPT', style: TextStyle(letterSpacing: 2, fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey)),
                  const SizedBox(height: 16),
                  _buildReceiptRow('Transaction ID', '#TRX-993821'),
                  const SizedBox(height: 8),
                  _buildReceiptRow('Payment Method', 'Visa ending in 4242'),
                  const SizedBox(height: 8),
                  _buildReceiptRow('Status', 'Completed', isSuccess: true),
                  const SizedBox(height: 16),
                  Container(height: 1, color: Colors.grey[300]),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Total', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      Text(amount, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // Mock barcode
                  Container(
                    height: 40,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      image: const DecorationImage(
                        image: NetworkImage('https://upload.wikimedia.org/wikipedia/commons/thumb/e/e9/UPC-A-036000291452.svg/1200px-UPC-A-036000291452.svg.png'),
                        fit: BoxFit.cover,
                      ),
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReceiptRow(String label, String value, {bool isSuccess = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(color: Colors.grey[600], fontSize: 14)),
        Text(value, style: TextStyle(
          color: isSuccess ? Colors.green : const Color(0xFF2D3142),
          fontWeight: isSuccess ? FontWeight.bold : FontWeight.w500,
          fontSize: 14,
        )),
      ],
    );
  }
}
