import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/features/vietnam_local/views/gym_goals_screen.dart';

void main() {
  test('reviewed and legacy applied route approvals are terminal', () {
    expect(gymRouteApprovalPhase('Reviewed'), GymRouteApprovalPhase.completed);
    expect(gymRouteApprovalPhase('Applied'), GymRouteApprovalPhase.completed);
  });

  test('only pending route approval stays in waiting phase', () {
    expect(gymRouteApprovalPhase('Pending'), GymRouteApprovalPhase.pending);
    expect(gymRouteApprovalPhase('Rejected'), GymRouteApprovalPhase.none);
    expect(gymRouteApprovalPhase(null), GymRouteApprovalPhase.none);
  });

  test('PT must accept the connection before route initialization', () {
    expect(
      gymPtConnectionPhase([
        {'connectionStatus': 'Pending'},
      ]),
      GymPtConnectionPhase.pending,
    );
    expect(
      gymPtConnectionPhase([
        {'ConnectionStatus': 'Pending'},
        {'connectionStatus': 'Connected'},
      ]),
      GymPtConnectionPhase.connected,
    );
    expect(gymPtConnectionPhase(const []), GymPtConnectionPhase.none);
  });
}
