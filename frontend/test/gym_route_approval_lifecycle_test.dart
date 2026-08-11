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

  test('locks the exact future plan date returned by PT requests', () {
    final request = gymRouteRequestForDate([
      {
        'weekStartDate': '2026-08-13',
        'status': 'Pending',
        'requestType': 'RouteApproval',
        'createdAt': '2026-08-12T12:49:00Z',
      },
    ], DateTime(2026, 8, 13));

    expect(request, isNotNull);
    expect(
      gymRouteRequestForDate([
        {
          'WeekStartDate': '2026-08-13',
          'Status': 'Reviewed',
          'RequestType': 'RouteApproval',
        },
      ], DateTime(2026, 8, 13)),
      isNotNull,
    );
    expect(
      gymRouteRequestForDate([
        {
          'weekStartDate': '2026-08-13',
          'status': 'Pending',
          'requestType': 'RouteApproval',
        },
      ], DateTime(2026, 8, 12)),
      isNull,
    );
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

  test('pending or accepted PT program occupies every covered date', () {
    final program = <String, dynamic>{
      'status': 'Pending',
      'startDate': '2026-08-12',
      'endDate': '2026-08-18',
    };

    expect(gymPtProgramCoversDate(program, DateTime(2026, 8, 12)), isTrue);
    expect(gymPtProgramCoversDate(program, DateTime(2026, 8, 18)), isTrue);
    expect(gymPtProgramCoversDate(program, DateTime(2026, 8, 19)), isFalse);

    program['status'] = 'Accepted';
    expect(gymPtProgramCoversDate(program, DateTime(2026, 8, 15)), isTrue);
  });

  test('rejected PT program no longer blocks self creation', () {
    expect(
      gymPtProgramCoversDate({
        'Status': 'Rejected',
        'WeekStartDate': '2026-08-12',
      }, DateTime(2026, 8, 12)),
      isFalse,
    );
  });
}
