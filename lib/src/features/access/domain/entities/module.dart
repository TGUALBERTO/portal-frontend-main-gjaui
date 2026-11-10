import 'package:equatable/equatable.dart';

class Module extends Equatable {
  final String id;
  final String code;
  final String label;

  const Module({
    required this.id,
    required this.code,
    required this.label,
  });

  factory Module.fromJson(Map<String, dynamic> json) => Module(
        id: json['id'] as String,
        code: json['code'] as String,
        label: json['label'] as String,
      );

  @override
  List<Object?> get props => [id, code, label];
}
