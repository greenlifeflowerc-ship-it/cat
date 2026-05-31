import '../core/constants.dart';

/// Mutable per-frame input intent for the locally controlled cat. Touch
/// controls and the keyboard both write into this; the player component reads
/// it during update().
class InputState {
  bool up = false;
  bool down = false;
  bool left = false;
  bool right = false;

  /// Edge-triggered: set true on press, consumed by the game each frame.
  bool placeBomb = false;
  bool remoteDetonate = false;

  Direction? get heldDirection {
    if (up) return Direction.up;
    if (down) return Direction.down;
    if (left) return Direction.left;
    if (right) return Direction.right;
    return null;
  }

  void clearMovement() {
    up = down = left = right = false;
  }
}
