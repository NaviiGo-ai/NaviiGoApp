import 'package:flutter/material.dart';

class SwipeToUnlock extends StatefulWidget {
  final VoidCallback onUnlock;
  final String text;

  const SwipeToUnlock({
    super.key,
    required this.onUnlock,
    this.text = 'Swipe to start your journey',
  });

  @override
  State<SwipeToUnlock> createState() => _SwipeToUnlockState();
}

class _SwipeToUnlockState extends State<SwipeToUnlock> {
  double _dragPosition = 0.0;
  bool _isUnlocked = false;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final double maxWidth = constraints.maxWidth;
        final double thumbSize = 56.0;
        final double maxDrag = maxWidth - thumbSize - 8.0;

        // Calculate opacity based on drag position
        double textOpacity = 1.0 - (_dragPosition / maxDrag);
        if (textOpacity < 0) textOpacity = 0;
        if (textOpacity > 1) textOpacity = 1;
        if (_isUnlocked) textOpacity = 0.0;

        return Container(
          height: 64,
          padding: const EdgeInsets.all(4.0),
          decoration: BoxDecoration(
            color: Colors.orange.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(32),
            border: Border.all(color: Colors.orange.withValues(alpha: 0.3), width: 1),
          ),
          child: Stack(
            children: [
              Center(
                child: Text(
                  widget.text,
                  style: TextStyle(
                    color: Colors.orange.withValues(alpha: textOpacity),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Positioned(
                left: _dragPosition,
                child: GestureDetector(
                  onHorizontalDragUpdate: (details) {
                    if (_isUnlocked) return;
                    setState(() {
                      _dragPosition += details.delta.dx;
                      if (_dragPosition < 0) _dragPosition = 0;
                      if (_dragPosition > maxDrag) _dragPosition = maxDrag;
                    });
                  },
                  onHorizontalDragEnd: (details) {
                    if (_isUnlocked) return;
                    if (_dragPosition > maxDrag * 0.8) {
                      setState(() {
                        _dragPosition = maxDrag;
                        _isUnlocked = true;
                      });
                      widget.onUnlock();
                    } else {
                      setState(() {
                        _dragPosition = 0.0;
                      });
                    }
                  },
                  child: Container(
                    width: thumbSize,
                    height: thumbSize,
                    decoration: const BoxDecoration(
                      color: Colors.orange,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.arrow_forward_rounded, color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
