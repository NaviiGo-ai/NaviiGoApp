import 'package:flutter/material.dart';

class TransportationPage extends StatefulWidget {
  const TransportationPage({super.key});

  @override
  State<TransportationPage> createState() => _TransportationPageState();
}

class _TransportationPageState extends State<TransportationPage> {
  int _selectedTabIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAF9F6),
      appBar: AppBar(
        title: const Text('Transit', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: Column(
        children: [
          // Custom Tab Bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Container(
              height: 50,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(25),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  _buildTab(0, 'Flights', Icons.flight_takeoff_rounded),
                  _buildTab(1, 'Trains', Icons.train_rounded),
                  _buildTab(2, 'Cabs', Icons.local_taxi_rounded),
                ],
              ),
            ),
          ),

          // Content
          Expanded(
            child: _selectedTabIndex == 0
                ? _buildFlightsContent()
                : _selectedTabIndex == 1
                    ? _buildTrainsContent()
                    : _buildCabsContent(),
          ),
        ],
      ),
    );
  }

  Widget _buildTab(int index, String text, IconData icon) {
    final isSelected = _selectedTabIndex == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedTabIndex = index),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          decoration: BoxDecoration(
            color: isSelected ? Theme.of(context).primaryColor : Colors.transparent,
            borderRadius: BorderRadius.circular(25),
          ),
          child: Center(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 16, color: isSelected ? Colors.white : Colors.grey[600]),
                const SizedBox(width: 6),
                Text(
                  text,
                  style: TextStyle(
                    color: isSelected ? Colors.white : Colors.grey[600],
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFlightsContent() {
    return ListView(
      padding: const EdgeInsets.all(16),
      physics: const BouncingScrollPhysics(),
      children: [
        const Text('Upcoming Flights', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF2D3142))),
        const SizedBox(height: 16),
        _buildBoardingPass(
          airline: 'Emirates',
          flightNum: 'EK 412',
          from: 'JFK',
          to: 'DXB',
          timeFrom: '10:45 PM',
          timeTo: '08:20 PM',
          date: '14 Aug',
          status: 'ON TIME',
          statusColor: const Color(0xFF059669),
        ),
        const SizedBox(height: 24),
        const Text('Past Flights', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF2D3142))),
        const SizedBox(height: 16),
        _buildBoardingPass(
          airline: 'Delta',
          flightNum: 'DL 901',
          from: 'LHR',
          to: 'JFK',
          timeFrom: '08:00 AM',
          timeTo: '11:30 AM',
          date: '02 Aug',
          status: 'COMPLETED',
          statusColor: Colors.grey,
        ),
      ],
    );
  }

  Widget _buildTrainsContent() {
    return const Center(child: Text('No upcoming train tickets.'));
  }

  Widget _buildCabsContent() {
    return const Center(child: Text('No upcoming cab rides.'));
  }

  Widget _buildBoardingPass({
    required String airline,
    required String flightNum,
    required String from,
    required String to,
    required String timeFrom,
    required String timeTo,
    required String date,
    required String status,
    required Color statusColor,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Top section
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(airline, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        status,
                        style: TextStyle(color: statusColor, fontWeight: FontWeight.bold, fontSize: 10, letterSpacing: 0.5),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(from, style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w800, color: Color(0xFF2D3142))),
                        const SizedBox(height: 4),
                        Text(timeFrom, style: TextStyle(color: Colors.grey[600], fontWeight: FontWeight.w500)),
                      ],
                    ),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        child: Row(
                          children: [
                            const CircleAvatar(radius: 4, backgroundColor: Colors.grey),
                            Expanded(
                              child: Container(
                                height: 1,
                                color: Colors.grey[300],
                              ),
                            ),
                            Icon(Icons.flight_takeoff_rounded, color: Theme.of(context).primaryColor),
                            Expanded(
                              child: Container(
                                height: 1,
                                color: Colors.grey[300],
                              ),
                            ),
                            const CircleAvatar(radius: 4, backgroundColor: Colors.grey),
                          ],
                        ),
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(to, style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w800, color: Color(0xFF2D3142))),
                        const SizedBox(height: 4),
                        Text(timeTo, style: TextStyle(color: Colors.grey[600], fontWeight: FontWeight.w500)),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          // Divider with notches
          Row(
            children: [
              Container(
                width: 10,
                height: 20,
                decoration: const BoxDecoration(
                  color: Color(0xFFFAF9F6),
                  borderRadius: BorderRadius.horizontal(right: Radius.circular(10)),
                ),
              ),
              Expanded(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    return Flex(
                      direction: Axis.horizontal,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      mainAxisSize: MainAxisSize.max,
                      children: List.generate(
                        (constraints.constrainWidth() / 10).floor(),
                        (index) => SizedBox(
                          width: 5,
                          height: 1,
                          child: DecoratedBox(decoration: BoxDecoration(color: Colors.grey[300])),
                        ),
                      ),
                    );
                  },
                ),
              ),
              Container(
                width: 10,
                height: 20,
                decoration: const BoxDecoration(
                  color: Color(0xFFFAF9F6),
                  borderRadius: BorderRadius.horizontal(left: Radius.circular(10)),
                ),
              ),
            ],
          ),

          // Bottom section
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildPassDetail('Date', date),
                _buildPassDetail('Flight', flightNum),
                _buildPassDetail('Gate', 'C24'),
                _buildPassDetail('Seat', '12A'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPassDetail(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(color: Colors.grey[500], fontSize: 12)),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF2D3142))),
      ],
    );
  }
}
