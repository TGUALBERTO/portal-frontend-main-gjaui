import 'package:equatable/equatable.dart';

import 'package:gjamobile/src/features/access/domain/entities/module.dart';

class Feature extends Equatable {
  final String id;
  final String code;
  final String label;
  final String? iconName;
  final Module module;

  const Feature({
    required this.id,
    required this.code,
    required this.label,
    required this.module,
    this.iconName,
  });

  factory Feature.fromJson(Map<String, dynamic> json) => Feature(
        id: json['id'] as String,
        code: json['code'] as String,
        label: json['label'] as String,
        iconName: json['iconName'] as String?,
        module: Module.fromJson(json['module'] as Map<String, dynamic>),
      );

  @override
  List<Object?> get props => [id, code, label, iconName, module];
}
