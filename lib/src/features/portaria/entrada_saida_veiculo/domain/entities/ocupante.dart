import 'package:equatable/equatable.dart';

/// Ocupante (funcionário) dentro do veículo no momento do registro de
/// entrada/saída. Só carrega a matrícula — não há endpoint de lookup de
/// funcionário por matrícula no projeto hoje (mesmo padrão simples usado em
/// `KbaLinkSheet`: matrícula validada só localmente, sem nome).
class Ocupante extends Equatable {
  const Ocupante({required this.matricula});

  final int matricula;

  Map<String, dynamic> toRequest() => {'matricula': matricula};

  @override
  List<Object?> get props => [matricula];
}
