import 'package:flutter/material.dart';

import '../../game/input/input_state.dart';

/// On-screen controls for mobile landscape play: a large D-pad on the
/// bottom-left and action buttons on the bottom-right (section 22). Buttons are
/// big, spaced for thumbs, multi-touch friendly (each is its own pointer
/// target) and give visual press feedback.
class TouchControls extends StatelessWidget {
  final InputState input;
  const TouchControls({super.key, required this.input});

  @override
  Widget build(BuildContext context) {
    // Fill the stack and pin the controls to the bottom of the screen.
    return Positioned.fill(
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 0, 18, 16),
          child: Align(
            alignment: Alignment.bottomCenter,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                DPad(input: input),
                const Spacer(),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                Padding(
                  padding: const EdgeInsets.only(bottom: 6, right: 14),
                  child: _ActionButton(
                    asset: 'assets/game/ui/connection_icon.png',
                    color: const Color(0xFF9b5cff),
                    size: 62,
                    label: 'BOOM',
                    onPress: () => input.remoteDetonate = true,
                  ),
                ),
                    _ActionButton(
                      asset: 'assets/game/ui/bomb_ui_icon.png',
                      color: const Color(0xFFff5a4d),
                      size: 92,
                      onPress: () => input.placeBomb = true,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// A plus-shaped 4-direction pad. Each arrow is an independent press target so
/// holding a direction while tapping bomb works (multi-touch).
class DPad extends StatelessWidget {
  final InputState input;
  const DPad({super.key, required this.input});

  static const double _btn = 66;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: _btn * 3,
      height: _btn * 3,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Faint backing plate so the pad reads as one control.
          Container(
            width: _btn * 3,
            height: _btn * 3,
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.18),
              shape: BoxShape.circle,
            ),
          ),
          Align(
            alignment: Alignment.topCenter,
            child: _DirButton(
              asset: 'assets/game/ui/small_arrow_up.png',
              size: _btn,
              onChanged: (v) => input.up = v,
            ),
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: _DirButton(
              asset: 'assets/game/ui/small_arrow_down.png',
              size: _btn,
              onChanged: (v) => input.down = v,
            ),
          ),
          Align(
            alignment: Alignment.centerLeft,
            child: _DirButton(
              asset: 'assets/game/ui/small_arrow_left.png',
              size: _btn,
              onChanged: (v) => input.left = v,
            ),
          ),
          Align(
            alignment: Alignment.centerRight,
            child: _DirButton(
              asset: 'assets/game/ui/small_arrow_right.png',
              size: _btn,
              onChanged: (v) => input.right = v,
            ),
          ),
        ],
      ),
    );
  }
}

class _DirButton extends StatefulWidget {
  final String asset;
  final double size;
  final void Function(bool) onChanged;
  const _DirButton({
    required this.asset,
    required this.size,
    required this.onChanged,
  });

  @override
  State<_DirButton> createState() => _DirButtonState();
}

class _DirButtonState extends State<_DirButton> {
  bool _down = false;

  void _set(bool v) {
    if (_down != v) setState(() => _down = v);
    widget.onChanged(v);
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      behavior: HitTestBehavior.opaque,
      onPointerDown: (_) => _set(true),
      onPointerUp: (_) => _set(false),
      onPointerCancel: (_) => _set(false),
      child: AnimatedScale(
        scale: _down ? 0.88 : 1.0,
        duration: const Duration(milliseconds: 70),
        child: Container(
          width: widget.size,
          height: widget.size,
          decoration: BoxDecoration(
            color: _down ? const Color(0xFFffd34d) : Colors.black54,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white24, width: 2),
            boxShadow: const [
              BoxShadow(color: Colors.black54, offset: Offset(0, 3)),
            ],
          ),
          child: Padding(
            padding: EdgeInsets.all(widget.size * 0.22),
            child: Image.asset(widget.asset, filterQuality: FilterQuality.none),
          ),
        ),
      ),
    );
  }
}

class _ActionButton extends StatefulWidget {
  final String asset;
  final Color color;
  final double size;
  final String? label;
  final VoidCallback onPress;
  const _ActionButton({
    required this.asset,
    required this.color,
    required this.size,
    required this.onPress,
    this.label,
  });

  @override
  State<_ActionButton> createState() => _ActionButtonState();
}

class _ActionButtonState extends State<_ActionButton> {
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    return Listener(
      behavior: HitTestBehavior.opaque,
      onPointerDown: (_) {
        setState(() => _down = true);
        widget.onPress();
      },
      onPointerUp: (_) => setState(() => _down = false),
      onPointerCancel: (_) => setState(() => _down = false),
      child: AnimatedScale(
        scale: _down ? 0.9 : 1.0,
        duration: const Duration(milliseconds: 70),
        child: Container(
          width: widget.size,
          height: widget.size,
          decoration: BoxDecoration(
            color: widget.color,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.black, width: 4),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.5),
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              Padding(
                padding: EdgeInsets.all(widget.size * 0.24),
                child:
                    Image.asset(widget.asset, filterQuality: FilterQuality.none),
              ),
              if (widget.label != null)
                Positioned(
                  bottom: 4,
                  child: Text(
                    widget.label!,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
