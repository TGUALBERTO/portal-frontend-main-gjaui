import 'package:equatable/equatable.dart';
import 'package:gjamobile/src/features/inbound/checkin_checkout_veiculo/domain/entities/check_in_item.dart';

class CheckIn extends Equatable {
  final String checkin;
  final String status;
  final String? credat;
  final String? cretim;
  final String? crenam;
  final String? chadat;
  final String? chatim;
  final String? chanam;
  final List<CheckInItem> items;

  const CheckIn({
    required this.checkin,
    required this.status,
    this.credat,
    this.cretim,
    this.crenam,
    this.chadat,
    this.chatim,
    this.chanam,
    this.items = const [],
  });

  factory CheckIn.fromJson(Map<String, dynamic> json) => CheckIn(
        checkin: json['Checkin'] as String,
        status: json['Status'] as String,
        credat: json['Credat'] as String?,
        cretim: json['Cretim'] as String?,
        crenam: json['Crenam'] as String?,
        chadat: json['Chadat'] as String?,
        chatim: json['Chatim'] as String?,
        chanam: json['Chanam'] as String?,
        items: _itemsFromJson(json['to_Items']),
      );

  static List<CheckInItem> _itemsFromJson(dynamic json) {
    if (json == null) {
      return const [];
    }

    if (json is Map<String, dynamic>) {
      final results = json['results'];

      if (results is List) {
        return results.map((item) => CheckInItem.fromJson(item as Map<String, dynamic>)).toList();
      }
    }

    if (json is List) {
      return json.map((item) => CheckInItem.fromJson(item as Map<String, dynamic>)).toList();
    }

    return const [];
  }

  @override
  List<Object?> get props => [
        checkin,
        status,
        credat,
        cretim,
        crenam,
        chadat,
        chatim,
        chanam,
        items,
      ];
}
