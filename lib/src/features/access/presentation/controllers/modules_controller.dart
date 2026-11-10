import 'package:signals_flutter/signals_flutter.dart';

import 'package:gjamobile/src/features/access/data/repositories/access_admin_repository.dart';
import 'package:gjamobile/src/features/access/domain/entities/module.dart';
import 'package:gjamobile/src/features/access/presentation/controllers/admin_status.dart';
import 'package:gjamobile/src/utils/utils.dart';

/// App-scoped controller for the modules list (CRUD).
class ModulesController {
  ModulesController({required AccessAdminRepository repository})
      : _repository = repository;

  final AccessAdminRepository _repository;

  late final Signal<AdminStatus> _status = signal(AdminStatus.idle);
  late final Signal<List<Module>> _modules = signal(const []);
  late final Signal<AppFailure?> _error = signal(null);

  ReadonlySignal<AdminStatus> get statusSignal => _status;
  ReadonlySignal<List<Module>> get modulesSignal => _modules;
  ReadonlySignal<AppFailure?> get errorSignal => _error;

  Future<void> load() async {
    _status.value = AdminStatus.loading;
    _error.value = null;
    final result = await _repository.fetchModules();
    result.onSuccess((data) {
      _modules.value = data;
      _status.value = AdminStatus.loaded;
    }).onFailure((failure) {
      _error.value = failure;
      _status.value = AdminStatus.error;
      AppLogger.warning('ModulesController.load failed: ${failure.message}');
    });
  }

  /// Creates or updates a module. Returns the failure message on error, null
  /// on success. When [existing] is provided the module is updated.
  Future<String?> save({
    Module? existing,
    required String code,
    required String label,
  }) async {
    final result = existing == null
        ? await _repository.createModule(code: code, label: label)
        : await _repository.updateModule(existing.id, code: code, label: label);
    return result.fold(
      (module) {
        _upsertLocal(module);
        return null;
      },
      (failure) => failure.message,
    );
  }

  Future<String?> delete(String id) async {
    final result = await _repository.deleteModule(id);
    return result.fold(
      (_) {
        _modules.value =
            _modules.value.where((m) => m.id != id).toList(growable: false);
        return null;
      },
      (failure) => failure.message,
    );
  }

  void _upsertLocal(Module module) {
    final next = [..._modules.value];
    final idx = next.indexWhere((m) => m.id == module.id);
    if (idx >= 0) {
      next[idx] = module;
    } else {
      next.add(module);
    }
    next.sort((a, b) => a.label.toLowerCase().compareTo(b.label.toLowerCase()));
    _modules.value = next;
  }

  void dispose() {
    _status.dispose();
    _modules.dispose();
    _error.dispose();
  }
}
