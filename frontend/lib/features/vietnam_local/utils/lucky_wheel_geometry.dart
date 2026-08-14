import 'dart:math' as math;

/// The pointer is drawn at the top of the wheel.
const double luckyWheelPointerAngle = -math.pi / 2;

double normalizeLuckyWheelAngle(double angle) {
  final normalized = angle % (2 * math.pi);
  return normalized < 0 ? normalized + 2 * math.pi : normalized;
}

/// Returns the wheel rotation that places [selectedIndex] under the pointer.
double luckyWheelTargetRotation({
  required int selectedIndex,
  required int segmentCount,
}) {
  if (segmentCount <= 0) {
    throw ArgumentError.value(segmentCount, 'segmentCount', 'must be positive');
  }
  if (selectedIndex < 0 || selectedIndex >= segmentCount) {
    throw RangeError.range(selectedIndex, 0, segmentCount - 1, 'selectedIndex');
  }

  final segmentAngle = (2 * math.pi) / segmentCount;
  final selectedCenter = (selectedIndex + 0.5) * segmentAngle;
  return normalizeLuckyWheelAngle(luckyWheelPointerAngle - selectedCenter);
}

/// Returns the segment currently located under the top pointer.
int luckyWheelIndexAtPointer({
  required double rotation,
  required int segmentCount,
}) {
  if (segmentCount <= 0) {
    throw ArgumentError.value(segmentCount, 'segmentCount', 'must be positive');
  }

  final segmentAngle = (2 * math.pi) / segmentCount;
  final angleOnWheel = normalizeLuckyWheelAngle(
    luckyWheelPointerAngle - rotation,
  );
  return (angleOnWheel / segmentAngle).floor() % segmentCount;
}
