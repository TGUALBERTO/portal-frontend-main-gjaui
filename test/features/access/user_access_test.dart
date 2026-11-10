import 'package:flutter_test/flutter_test.dart';

import 'package:gjamobile/src/features/access/domain/entities/user_access.dart';
import 'package:gjamobile/src/features/kba/domain/entities/employee_link.dart';

UserAccess _parse({Map<String, dynamic>? employeeLink}) {
  final json = <String, dynamic>{
    'user': <String, dynamic>{'id': 'u1', 'email': 'a@b.com', 'name': 'Fulano'},
    'groups': <dynamic>[],
  };
  if (employeeLink != null) json['employeeLink'] = employeeLink;
  return UserAccess.fromJson(json);
}

void main() {
  test('fromJson sem employeeLink (backend antigo) fica nulo', () {
    expect(_parse().employeeLink, isNull);
  });

  test('fromJson com employeeLink popula o vinculo', () {
    final access = _parse(employeeLink: <String, dynamic>{
      'status': 'LINKED',
      'bloqueado': false,
      'kbaAvailable': true,
      'attemptsRemaining': 2,
      'matricula': 2002,
      'codigoEmpresa': 1,
      'cpfMasked': '***.***.*89-01',
    });

    final link = access.employeeLink!;
    expect(link.status, EmployeeLinkStatus.linked);
    expect(link.isLinked, isTrue);
    expect(link.needsLink, isFalse);
    expect(link.matricula, 2002);
    expect(link.cpfMasked, '***.***.*89-01');
  });

  test('needsLink: desvinculado com KBA disponivel precisa do fluxo', () {
    final access = _parse(employeeLink: <String, dynamic>{
      'status': 'UNLINKED',
      'bloqueado': false,
      'kbaAvailable': true,
      'attemptsRemaining': 2,
    });
    expect(access.employeeLink!.needsLink, isTrue);
  });

  test('needsLink: KBA indisponivel (dev/helpdesk off) nao exige o fluxo', () {
    final access = _parse(employeeLink: <String, dynamic>{
      'status': 'UNLINKED',
      'bloqueado': false,
      'kbaAvailable': false,
      'attemptsRemaining': 2,
    });
    expect(access.employeeLink!.needsLink, isFalse);
  });

  test('needsLink: bloqueado continua preso no fluxo (tela de bloqueio)', () {
    final access = _parse(employeeLink: <String, dynamic>{
      'status': 'UNLINKED',
      'bloqueado': true,
      'kbaAvailable': true,
      'attemptsRemaining': 0,
    });
    final link = access.employeeLink!;
    expect(link.bloqueado, isTrue);
    expect(link.needsLink, isTrue);
  });
}
