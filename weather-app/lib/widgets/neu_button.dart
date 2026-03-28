import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'neu_container.dart';
import '../providers/app_provider.dart';

class NeuButton extends StatefulWidget {
  final Widget child;
  final VoidCallback onTap;
  final double radius;
  final double? width;
  final double height;
  final BoxShape shape;

  const NeuButton({
    super.key,
    required this.child,
    required this.onTap,
    this.radius = 32.0,
    this.width,
    this.height = 64.0,
    this.shape = BoxShape.rectangle,
  });

  @override
  _NeuButtonState createState() => _NeuButtonState();
}

class _NeuButtonState extends State<NeuButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) {
        setState(() => _isPressed = false);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _isPressed = false),
      child: NeuContainer(
        width: widget.shape == BoxShape.circle ? widget.height : widget.width,
        height: widget.height,
        radius: widget.radius,
        shape: widget.shape,
        isInner: false,
        intensity: _isPressed 
            ? (Provider.of<AppProvider>(context, listen: false).shadowIntensity * 0.3)
            : null,
        child: widget.child,
      ),
    );
  }
}
