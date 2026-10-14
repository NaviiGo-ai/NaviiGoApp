import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/journey_recording_provider.dart';

class RecordedRouteCard extends ConsumerWidget {
  final RecordingKey record;
  const RecordedRouteCard({super.key, required this.record});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final provider = journeyRecordingProvider(record);
    final state = ref.watch(provider);
    final recorder = ref.read(provider.notifier);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Your actual route',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Opt in to record GPS while NaviiGo is in the foreground. '
              'The route stays private on this device and can be added to your story. '
              'Background recording is not supported; keep NaviiGo open for a complete path.',
            ),
            if (state.points.length > 1) ...[
              const SizedBox(height: 12),
              RouteTraceDiagram(points: state.points),
              Text(
                '${routeDistanceKm(state.points).toStringAsFixed(2)} km recorded · ${state.points.length} GPS points',
              ),
            ],
            if (state.error != null) Text(state.error!),
            Wrap(
              spacing: 8,
              children: [
                FilledButton.icon(
                  onPressed: state.recording ? recorder.stop : recorder.start,
                  icon: Icon(
                    state.recording
                        ? Icons.stop_circle_outlined
                        : Icons.fiber_manual_record,
                  ),
                  label: Text(
                    state.recording ? 'Stop recording' : 'Record my route',
                  ),
                ),
                if (state.points.isNotEmpty)
                  TextButton(
                    onPressed: () async {
                      final remove = await showDialog<bool>(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text('Delete this recorded route?'),
                          content: const Text(
                            'This removes the GPS points saved on this device.',
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context, false),
                              child: const Text('Keep'),
                            ),
                            TextButton(
                              onPressed: () => Navigator.pop(context, true),
                              child: const Text('Delete'),
                            ),
                          ],
                        ),
                      );
                      if (remove == true) await recorder.clear();
                    },
                    child: const Text('Delete route'),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// A coordinate diagram, not a street map or a reconstructed navigation route.
class RouteTraceDiagram extends StatelessWidget {
  final List<RouteSample> points;
  final Color color;
  const RouteTraceDiagram({
    super.key,
    required this.points,
    this.color = const Color(0xFFE66E35),
  });
  @override
  Widget build(BuildContext context) => Semantics(
    label: 'Recorded GPS route diagram',
    child: SizedBox(
      height: 160,
      width: double.infinity,
      child: CustomPaint(painter: _RoutePainter(points, color)),
    ),
  );
}

class _RoutePainter extends CustomPainter {
  final List<RouteSample> points;
  final Color color;
  _RoutePainter(this.points, this.color);
  @override
  void paint(Canvas canvas, Size size) {
    if (points.length < 2) return;
    final centerLat =
        points.map((p) => p.lat).reduce((a, b) => a + b) / points.length;
    final longitudeScale = math.cos(centerLat * math.pi / 180);
    final minX = points.map((p) => p.lng * longitudeScale).reduce(math.min);
    final maxX = points.map((p) => p.lng * longitudeScale).reduce(math.max);
    final minY = points.map((p) => p.lat).reduce(math.min);
    final maxY = points.map((p) => p.lat).reduce(math.max);
    final scale = math.min(
      (size.width - 24) / math.max(maxX - minX, 0.00001),
      (size.height - 24) / math.max(maxY - minY, 0.00001),
    );
    Offset point(RouteSample p) => Offset(
      size.width / 2 + (p.lng * longitudeScale - (maxX + minX) / 2) * scale,
      size.height / 2 - (p.lat - (maxY + minY) / 2) * scale,
    );
    final path = Path()..moveTo(point(points.first).dx, point(points.first).dy);
    for (var i = 1; i < points.length; i++) {
      final p = points[i];
      if (p.at.difference(points[i - 1].at).inSeconds > 120) {
        path.moveTo(point(p).dx, point(p).dy);
      } else {
        path.lineTo(point(p).dx, point(p).dy);
      }
    }
    canvas.drawPath(
      path,
      Paint()
        ..color = color
        ..strokeWidth = 3
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round,
    );
    canvas.drawCircle(point(points.first), 5, Paint()..color = Colors.green);
    canvas.drawCircle(point(points.last), 5, Paint()..color = color);
  }

  @override
  bool shouldRepaint(covariant _RoutePainter oldDelegate) =>
      oldDelegate.points != points || oldDelegate.color != color;
}
