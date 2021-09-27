import 'package:flutter/material.dart';
import 'dart:async';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const OverlayDemo(),
    );
  }
}

class OverlayDemo extends StatefulWidget {
  const OverlayDemo({Key? key}) : super(key: key);

  @override
  State<OverlayDemo> createState() => _OverlayDemoState();
}

class _OverlayDemoState extends State<OverlayDemo> {
  OverlayEntry? entry;
  int counter = 0;

  @override
  void initState() {
    print('');
    super.initState();
    WidgetsBinding.instance?.addPostFrameCallback((_) => showOverlay());
  }

  void showOverlay() {
    entry = OverlayEntry(
      builder: (context) => RedditCommentJumper(
        rebuild: entry?.markNeedsBuild,
        onTap: incrementCounter,
      ),
    );
    final overlay = Overlay.of(context)!;
    overlay.insert(entry!);
  }

  void incrementCounter() {
    setState(() {
      ++counter;
    });
  }

  @override
  void dispose() {
    hideOverlay();
    super.dispose();
  }

  void hideOverlay() {
    entry?.remove();
    entry = null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: Text(counter.toString()),
        leading: GestureDetector(
          onTap: () {
            entry == null ? showOverlay() : hideOverlay();
          },
          child: const Icon(Icons.favorite),
        ),
      ),
      body: ListView.builder(
        itemCount: 10,
        itemBuilder: (context, index) => Padding(
          padding: const EdgeInsets.all(8.0),
          child: Container(
            height: 100,
            color: Colors.blue,
          ),
        ),
      ),
    );
  }
}

class RedditCommentJumper extends StatelessWidget {
  final VoidCallback? rebuild;
  final VoidCallback onTap;
  const RedditCommentJumper({
    Key? key,
    this.rebuild,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ScalingOverlayButton(
      rebuild: rebuild,
      onTap: onTap,
      position: const Offset(150, 150),
      color: Colors.black54,
      icon: const Icon(FontAwesomeIcons.angleDoubleDown, color: Colors.white),
      padding: const EdgeInsets.all(2.0),
      longPressDuration: const Duration(milliseconds: 350),
      animationDuration: const Duration(milliseconds: 500),
      reverseDuration: const Duration(milliseconds: 200),
      curve: Curves.elasticOut,
      reverseCurve: Curves.easeOut,
      scaleEnd: 4,
    );
  }
}

class ScalingOverlayButton extends StatefulWidget {
  final VoidCallback? rebuild;
  final VoidCallback onTap;
  final Offset position;
  final Color color;
  final EdgeInsets padding;
  final Widget icon;
  final Duration longPressDuration;
  final double scaleStart;
  final double scaleEnd;
  final Duration animationDuration;
  final Duration reverseDuration;
  final Curve curve;
  final Curve reverseCurve;
  const ScalingOverlayButton({
    Key? key,
    this.rebuild,
    required this.onTap,
    required this.position,
    required this.color,
    required this.padding,
    required this.icon,
    required this.longPressDuration,
    this.scaleStart = 1.0,
    required this.scaleEnd,
    required this.animationDuration,
    required this.reverseDuration,
    required this.curve,
    required this.reverseCurve,
  }) : super(key: key);

  @override
  ScalingOverlayButtonState createState() => ScalingOverlayButtonState();
}

class ScalingOverlayButtonState extends State<ScalingOverlayButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController controller;
  late final Animation<double> scaleAnimation;
  bool movable = false;
  Timer? _timer;
  late Offset offset;

  @override
  void initState() {
    offset = widget.position;
    controller = AnimationController(
      vsync: this,
      duration: widget.animationDuration,
      reverseDuration: widget.reverseDuration,
    );

    final curvedAnimation = CurvedAnimation(
      parent: controller,
      curve: widget.curve,
      reverseCurve: widget.reverseCurve,
    );
    scaleAnimation =
        Tween<double>(begin: widget.scaleStart, end: widget.scaleEnd)
            .animate(curvedAnimation);
    controller.addStatusListener(animationControllerStatusListener);
    super.initState();
  }

  void animationControllerStatusListener(AnimationStatus status) {
    if (status == AnimationStatus.completed ||
        status == AnimationStatus.forward) {
      movable = true;
    } else if (status == AnimationStatus.dismissed ||
        status == AnimationStatus.reverse) {
      movable = false;
    }
  }

  @override
  void dispose() {
    super.dispose();
    controller.removeStatusListener(animationControllerStatusListener);
    controller.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: offset.dx,
      top: offset.dy,
      child: GestureDetector(
        onTap: () {},
        onPanDown: _onPanDown,
        onPanCancel: _onPanCancel,
        onPanUpdate: _onPanUpdate,
        onPanEnd: _onPanEnd,
        child: AnimatedBuilder(
          builder: (context, child) => ScaleTransition(
            scale: scaleAnimation,
            child: child,
          ),
          animation: controller,
          child: _buildButton(),
        ),
      ),
    );
  }

  void _onPanCancel() {
    if (!movable) {
      widget.onTap();
    }
    _timer?.cancel();
    controller.reset();
  }

  void _onPanEnd(DragEndDetails details) {
    _timer?.cancel();

    if (controller.status == AnimationStatus.completed ||
        controller.status == AnimationStatus.forward) {
      controller.reverse();
    }
  }

  void _onPanUpdate(DragUpdateDetails details) {
    if (movable) {
      offset += details.delta;
      widget.rebuild?.call();
    }
  }

  void _onPanDown(DragDownDetails details) {
    _timer = Timer(
      widget.longPressDuration,
      () => controller.forward(),
    );
  }

  Widget _buildButton() {
    return Card(
      color: widget.color,
      shape: const StadiumBorder(),
      child: Padding(padding: widget.padding, child: widget.icon),
    );
  }
}
