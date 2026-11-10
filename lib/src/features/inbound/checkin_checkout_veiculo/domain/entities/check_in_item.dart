import 'package:equatable/equatable.dart';

class CheckInItem extends Equatable {
  final String checkin;
  final String accesskey;
  final String? status;
  final String? chave;

  const CheckInItem({
    required this.checkin,
    required this.accesskey,
    this.status,
    this.chave,
  });

  factory CheckInItem.fromJson(Map<String, dynamic> json) => CheckInItem(
        checkin: json['Checkin'] as String,
        accesskey: json['Accesskey'] as String,
        status: json['Status'] as String?,
        chave: json['Chave'] as String?,
      );

  @override
  List<Object?> get props => [
        checkin,
        accesskey,
        status,
        chave,
      ];
}
