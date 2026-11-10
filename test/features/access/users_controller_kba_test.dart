import 'package:flutter_test/flutter_test.dart';
import 'package:result_dart/result_dart.dart';

import 'package:gjamobile/src/features/access/data/repositories/access_admin_repository.dart';
import 'package:gjamobile/src/features/access/domain/entities/portal_user.dart';
import 'package:gjamobile/src/features/access/presentation/controllers/users_controller.dart';
import 'package:gjamobile/src/features/kba/domain/entities/employee_link.dart';
import 'package:gjamobile/src/utils/utils.dart';

/// Fake do repositório admin cobrindo só as operações de KBA; o restante da
/// interface cai no noSuchMethod (não usado nestes testes).
class _FakeAdminRepository implements AccessAdminRepository {
  AppResult<Unit> unlockResult = const Success(unit);
  AppResult<Unit> linkResult = const Success(unit);
  int? linkedCodigoEmpresa;
  int? linkedMatricula;

  @override
  AsyncAppResult<Unit> unlockKba(String userId) async => unlockResult;

  @override
  AsyncAppResult<Unit> linkKba(
    String userId, {
    required int codigoEmpresa,
    required int matricula,
  }) async {
    linkedCodigoEmpresa = codigoEmpresa;
    linkedMatricula = matricula;
    return linkResult;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('${invocation.memberName}');
}

void main() {
  late _FakeAdminRepository repository;
  late UsersController controller;

  const blockedUser = PortalUser(
    id: 'u1',
    email: 'a@b.com',
    name: 'Fulano',
    kbaBloqueado: true,
  );

  setUp(() {
    repository = _FakeAdminRepository();
    controller = UsersController(repository: repository);
    controller.seedUsers(const [blockedUser]);
  });

  tearDown(() => controller.dispose());

  test('unlockKba com sucesso limpa o bloqueio na lista local', () async {
    final error = await controller.unlockKba('u1');

    expect(error, isNull);
    expect(controller.usersSignal.value.single.kbaBloqueado, isFalse);
  });

  test('unlockKba com falha retorna a mensagem e mantem o bloqueio', () async {
    repository.unlockResult = const Failure(ServerFailure('sem permissao'));

    final error = await controller.unlockKba('u1');

    expect(error, 'sem permissao');
    expect(controller.usersSignal.value.single.kbaBloqueado, isTrue);
  });

  test('linkKba com sucesso vincula, desbloqueia e grava a matricula', () async {
    final error = await controller.linkKba(
      'u1',
      codigoEmpresa: 1,
      matricula: 2002,
    );

    expect(error, isNull);
    expect(repository.linkedCodigoEmpresa, 1);
    expect(repository.linkedMatricula, 2002);
    final updated = controller.usersSignal.value.single;
    expect(updated.employeeLinkStatus, EmployeeLinkStatus.linked);
    expect(updated.isLinked, isTrue);
    expect(updated.kbaBloqueado, isFalse);
    expect(updated.matricula, 2002);
  });

  test('linkKba com falha nao altera a lista local', () async {
    repository.linkResult = const Failure(
        ApiFailure('matricula nao existe', status: 404));

    final error = await controller.linkKba(
      'u1',
      codigoEmpresa: 1,
      matricula: 9999,
    );

    expect(error, 'matricula nao existe');
    final unchanged = controller.usersSignal.value.single;
    expect(unchanged.isLinked, isFalse);
    expect(unchanged.matricula, isNull);
  });
}
