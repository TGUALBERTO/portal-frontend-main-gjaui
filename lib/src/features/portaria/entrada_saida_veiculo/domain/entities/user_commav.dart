import 'package:equatable/equatable.dart';
import 'package:xml/xml.dart';

class UserCommav extends Equatable {
  final String nome;
  final String matricula;
  final String unidade;

  const UserCommav({
    required this.nome,
    required this.matricula,
    required this.unidade,
  });

  factory UserCommav.fromXml(XmlElement xml) {
    final funcionario = xml.getElement('CLA_Funcionario_Acesso');

    return UserCommav(
      nome: funcionario?.getElement('FAC_STR_Nome_Usuario_Acesso')?.innerText ?? '',
      matricula: funcionario?.getElement('FAC_STR_Matricula_Usuario_Acesso')?.innerText ?? '',
      unidade: funcionario?.getElement('FAC_INT_Unidade_Usuario_Acesso')?.innerText ?? '',
    );
  }

  @override
  List<Object?> get props => [
        nome,
        matricula,
        unidade,
      ];
}
