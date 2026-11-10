import 'package:equatable/equatable.dart';
import 'package:xml/xml.dart';

/// Veículo de frota (diretoria/flutuante/terceiro) retornado pelo COMMAV.
/// Esses veículos não têm QR Code — a portaria os localiza pela placa.
class FrotaVeiculo extends Equatable {
  final String frota;
  final String placa;

  const FrotaVeiculo({required this.frota, required this.placa});

  factory FrotaVeiculo.fromXml(XmlElement xml) => FrotaVeiculo(
        frota: xml.getElement('FRT_STR_Frota')?.innerText ?? '',
        placa: xml.getElement('FRT_STR_Placa')?.innerText ?? '',
      );

  @override
  List<Object?> get props => [frota, placa];
}
