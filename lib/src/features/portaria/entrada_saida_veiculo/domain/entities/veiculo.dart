import 'package:equatable/equatable.dart';

class Veiculo extends Equatable {
  final String codigo;
  final String placa;
  final String status;
  

  const Veiculo(
      {required this.codigo, required this.placa, required this.status});

  factory Veiculo.fromJson(Map<String, dynamic> json) => Veiculo(
        codigo: json['Veiculo'] as String,
        placa: json['Placa'] as String,
        status: json['Status'] as String,
      );

  @override
  List<Object?> get props => [
        codigo,
        placa,
        status,
      ];
}
