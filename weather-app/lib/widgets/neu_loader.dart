import 'package:flutter/material.dart';
import 'neu_container.dart';

class NeuLoader extends StatefulWidget {
  const NeuLoader({super.key});

  @override
  _NeuLoaderState createState() => _NeuLoaderState();
}

class _NeuLoaderState extends State<NeuLoader>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        NeuContainer(
          width: 80,
          height: 80,
          shape: BoxShape.circle,
          isInner: true, // Sunken track
          child: Center(
            child: RotationTransition(
              turns: _controller,
              child: NeuContainer(
                width: 40,
                height: 40,
                shape: BoxShape.circle,
                child: Center(
                  child: Icon(
                    Icons.sync_rounded,
                    size: 20,
                    color: Theme.of(context).iconTheme.color,
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
