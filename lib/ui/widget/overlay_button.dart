import 'package:alice/alice.dart';
import 'package:alice/utils/alice_constants.dart';
import 'package:flutter/material.dart';

class AliceOverlayButton extends StatefulWidget {
  final Widget child;
  final Alice alice;
  final bool isShow;

  const AliceOverlayButton({
    Key? key,
    required this.child,
    required this.alice,
    required this.isShow,
  }) : super(key: key);

  @override
  State<AliceOverlayButton> createState() => _AliceOverlayButtonState();
}

class _AliceOverlayButtonState extends State<AliceOverlayButton> {
  double? left, top;

  @override
  void initState() {
    WidgetsBinding.instance?.addPostFrameCallback((_) => _setupHeight());
    super.initState();
  }

  void _setupHeight() {
    final size = MediaQuery.of(context).size;

    setState(() {
      top = size.height / 2;
      left = size.width - 100;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.isShow) return widget.child;
    return Stack(
      children: [
        widget.child,
        if (top != null && left != null)
          Positioned(
            left: left,
            top: top,
            child: Draggable(
              feedback: _FloatingActionButton(
                alice: widget.alice,
              ),
              onDragEnd: (value) {
                setState(() {
                  left = value.offset.dx;
                  top = value.offset.dy;
                });
              },
              childWhenDragging: const SizedBox(),
              child: _FloatingActionButton(
                alice: widget.alice,
              ),
            ),
          ),
      ],
    );
  }
}

class _FloatingActionButton extends StatelessWidget {
  final Alice alice;

  const _FloatingActionButton({
    Key? key,
    required this.alice,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: alice.showInspector,
      child: Container(
        height: 55,
        width: 55,
        decoration: BoxDecoration(
          color: AliceConstants.lightRed,
          shape: BoxShape.circle,
        ),
        child: Icon(
          Icons.network_wifi,
          color: Colors.white,
        ),
      ),
    );
  }
}
