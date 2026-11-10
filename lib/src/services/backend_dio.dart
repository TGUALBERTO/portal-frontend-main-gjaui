import 'package:dio/dio.dart';

/// Wrappers marcadores para o DI.
///
/// O `auto_injector` resolve dependências de construtor por TIPO, então dois
/// [Dio] crus seriam ambíguos. Cada wrapper carrega o [Dio] de um backend, de
/// modo que um repositório declare exatamente de qual backend depende.
class CoreDio {
  const CoreDio(this.dio);
  final Dio dio;
}

class TeamsbotDio {
  const TeamsbotDio(this.dio);
  final Dio dio;
}

class PortariaDio {
  const PortariaDio(this.dio);
  final Dio dio;
}

class RhprocessoDio {
  const RhprocessoDio(this.dio);
  final Dio dio;
}

/// SAP Gateways. Diferente dos demais, estes [Dio] **não** carregam o
/// interceptor de auth Microsoft — a autenticação vai por request, com o cookie
/// de sessão SAP emitido pelo backend `core` (ver `SapSessionRepository`).
class SapBandeirantesDio {
  const SapBandeirantesDio(this.dio);
  final Dio dio;
}

class SapNelDio {
  const SapNelDio(this.dio);
  final Dio dio;
}

class SapVitamedicDio {
  const SapVitamedicDio(this.dio);
  final Dio dio;
}
