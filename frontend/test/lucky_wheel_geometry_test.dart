import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/features/vietnam_local/utils/lucky_wheel_geometry.dart';

void main() {
  test('every selected segment stops under the top pointer', () {
    for (var segmentCount = 2; segmentCount <= 10; segmentCount++) {
      for (
        var selectedIndex = 0;
        selectedIndex < segmentCount;
        selectedIndex++
      ) {
        final rotation = luckyWheelTargetRotation(
          selectedIndex: selectedIndex,
          segmentCount: segmentCount,
        );

        expect(
          luckyWheelIndexAtPointer(
            rotation: rotation,
            segmentCount: segmentCount,
          ),
          selectedIndex,
        );
      }
    }
  });
}
