import 'package:signals_flutter/signals_flutter.dart';

import 'package:gjamobile/src/features/access/data/repositories/access_admin_repository.dart';
import 'package:gjamobile/src/features/access/domain/entities/feature.dart';
import 'package:gjamobile/src/features/access/presentation/controllers/admin_status.dart';
import 'package:gjamobile/src/utils/utils.dart';

/// App-scoped controller for the features list (CRUD).
class FeaturesController {
  FeaturesController({required AccessAdminRepository repository})
      : _repository = repository;

  final AccessAdminRepository _repository;

  late final Signal<AdminStatus> _status = signal(AdminStatus.idle);
  late final Signal<List<Feature>> _features = signal(const []);
  late final Signal<AppFailure?> _error = signal(null);

  ReadonlySignal<AdminStatus> get statusSignal => _status;
  ReadonlySignal<List<Feature>> get featuresSignal => _features;
  ReadonlySignal<AppFailure?> get errorSignal => _error;

  Future<void> load() async {
    _status.value = AdminStatus.loading;
    _error.value = null;
    final result = await _repository.fetchFeatures();
    result.onSuccess((data) {
      _features.value = data;
      _status.value = AdminStatus.loaded;
    }).onFailure((failure) {
      _error.value = failure;
      _status.value = AdminStatus.error;
      AppLogger.warning('FeaturesController.load failed: ${failure.message}');
    });
  }

  /// Creates or updates a feature. Returns the failure message on error, null
  /// on success. When [existing] is provided the feature is updated.
  Future<String?> save({
    Feature? existing,
    required String code,
    required String label,
    String? iconName,
    required String moduleId,
  }) async {
    final result = existing == null
        ? await _repository.createFeature(
            code: code,
            label: label,
            iconName: iconName,
            moduleId: moduleId,
          )
        : await _repository.updateFeature(
            existing.id,
            code: code,
            label: label,
            iconName: iconName,
            moduleId: moduleId,
          );
    return result.fold(
      (feature) {
        _upsertLocal(feature);
        return null;
      },
      (failure) => failure.message,
    );
  }

  Future<String?> delete(String id) async {
    final result = await _repository.deleteFeature(id);
    return result.fold(
      (_) {
        _features.value =
            _features.value.where((f) => f.id != id).toList(growable: false);
        return null;
      },
      (failure) => failure.message,
    );
  }

  void _upsertLocal(Feature feature) {
    final next = [..._features.value];
    final idx = next.indexWhere((f) => f.id == feature.id);
    if (idx >= 0) {
      next[idx] = feature;
    } else {
      next.add(feature);
    }
    next.sort((a, b) {
      final m = a.module.label.compareTo(b.module.label);
      return m != 0 ? m : a.label.toLowerCase().compareTo(b.label.toLowerCase());
    });
    _features.value = next;
  }

  void dispose() {
    _status.dispose();
    _features.dispose();
    _error.dispose();
  }
}
