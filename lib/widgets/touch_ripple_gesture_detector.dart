import "package:flutter/gestures.dart";
import "package:flutter/material.dart";
import "package:flutter_touch_ripple/flutter_touch_ripple.dart";

/// Signature for the builder function that creates an instance of [GestureRecognizer].
typedef GestureRecognizerBuilder<T extends GestureRecognizer> = T Function();

/// This widget detects user gestures, notifies the relevant controller that
/// manages touch ripple effects, and delegates the handling to it.
class TouchRippleGestureDetector extends StatefulWidget {
  const TouchRippleGestureDetector({
    super.key,
    this.onTap,
    this.onDoubleTap,
    this.onLongTap,
    this.behavior = HitTestBehavior.translucent,
    required this.controller,
    required this.child,
  });

  /// The callback function is called when the user taps or clicks.
  final VoidCallback? onTap;

  /// The callback function is called when the user double taps or double clicks.
  final TouchRippleContinuableCallback? onDoubleTap;

  /// The callback function is called when the user long presses or long clicks.
  final TouchRippleContinuableCallback? onLongTap;

  /// The defines the behavior of hit testing for the child widget.
  final HitTestBehavior behavior;

  /// The controller that manages ripple effects triggered by user gestures.
  final TouchRippleController controller;

  /// The widget is the target for detecting gestures related to touch ripple effects.
  final Widget child;

  @override
  State<TouchRippleGestureDetector> createState() => _TouchRippleGestureDetectorState();
}

class _TouchRippleGestureDetectorState extends State<TouchRippleGestureDetector> {
  /// The list defines instances of a builder function that creates GestureRecognizer objects.
  /// Instances of [GestureRecognizer] should be added and removed according to the lifecycle
  /// of the gesture detector.
  ///
  /// This keeps the context about the factory and lifecycle management clear and concise.
  final List<GestureRecognizerBuilder> _builders = [];

  /// The list defines the instances of currently active [GestureRecognizer].
  final List<GestureRecognizer> _recognizers = <GestureRecognizer>[];

  /// Returns an instance of a given [TouchRippleController] as this widget reference.
  TouchRippleController get controller => widget.controller;

  // Initializes gesture recognizer builders.
  initBuilders() {
    _builders.clear();

    if (widget.onTap != null) {
      _builders.add(() {
        late TouchRippleSpreadingEffect activeEffect;
        return TouchRippleTapGestureRecognizer(
          context: context,
          rejectBehavior: controller.context.rejectBehavior,
          previewMinDuration: controller.context.previewDuration,
          acceptableDuration: controller.context.tappableDuration,
          onTap: (offset) {
            activeEffect = TouchRippleSpreadingEffect(
              vsync: controller.context.vsync,
              callback: widget.onTap!,
              isRejectable: false,
              baseOffset: offset,
              behavior: controller.context.tapBehavior
            );

            controller.attach(activeEffect..start());
          },
          onTapRejectable: (offset) {
            activeEffect = TouchRippleSpreadingEffect(
              vsync: controller.context.vsync,
              callback: widget.onTap!,
              isRejectable: true,
              baseOffset: offset,
              behavior: controller.context.tapBehavior
            );

            controller.attach(activeEffect..start());
          },
          onTapReject: () => activeEffect.onRejected(),
          onTapAccept: () => activeEffect.onAccepted(),
        )
        // Called when this gesture recognizer disposed.
        ..onDispose = _recognizers.remove;
      });
    }
  }

  _handlePointerDown(PointerDownEvent event) {
    // Recreates the necessary gesture recognizer to forward to
    // a new lifecycle when no gesture recognizer has been assigned.
    if (_recognizers.length <= 1) {
      _recognizers.clear();
      _recognizers.addAll([HoldingGestureRecognizer()]);
      _recognizers.addAll(_builders.map((builder) => builder.call()));
    }

    for (var r in _recognizers) {
      r.addPointer(event);
    }
  }

  @override
  void initState() {
    super.initState();

    // Initializes initial gesture recognizer builders.
    initBuilders();
  }

  @override
  void didUpdateWidget(covariant TouchRippleGestureDetector oldWidget) {
    super.didUpdateWidget(oldWidget);

    // The gesture recognizer builders needs to be rebuilt
    // when a given callback function is different or null.
    if (widget.onTap != oldWidget.onTap ||
        widget.onDoubleTap != oldWidget.onDoubleTap ||
        widget.onLongTap != oldWidget.onLongTap) {
      initBuilders();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      behavior: widget.behavior,
      onPointerDown: _handlePointerDown,
      child: widget.child,
    );
  }
}
