import 'package:gjamobile/src/features/access/domain/entities/permission.dart';
import 'package:gjamobile/src/features/access/utils/feature_icon.dart';
import 'package:gjamobile/src/features/home/domain/feature_routes.dart';
import 'package:gjamobile/src/features/home/presentation/models/home_feature.dart';

/// Maps an enabled [Permission] to a Home card view-model.
///
/// Title/icon/module come from the backend feature; the route is resolved from
/// the frontend registry by feature code (null => "em breve").
HomeFeature homeFeatureFromPermission(Permission permission) {
  final feature = permission.feature;
  return HomeFeature(
    code: feature.code,
    title: feature.label,
    icon: iconForFeature(feature.iconName),
    module: feature.module.label,
    route: routeForFeatureCode(feature.code),
  );
}
