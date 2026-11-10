import 'dart:typed_data';

import 'package:signals_flutter/signals_flutter.dart';

import 'package:gjamobile/src/features/profile/domain/entities/graph_profile.dart';
import 'package:gjamobile/src/services/graph_service.dart';

enum ProfileStatus { idle, loading, loaded, error }

/// Controller app-scoped do perfil do usuário logado. Guarda a foto (Microsoft
/// Graph) usada no avatar da AppBar e carrega o perfil completo para a tela
/// `/me`. Singleton: a foto é buscada uma vez e reaproveitada.
class ProfileController {
  ProfileController({required GraphService graphService})
      : _graph = graphService;

  final GraphService _graph;

  late final Signal<Uint8List?> _photo = signal(null);
  late final Signal<ProfileStatus> _status = signal(ProfileStatus.idle);
  late final Signal<GraphProfile?> _profile = signal(null);
  late final Signal<String?> _graphError = signal(null);

  Signal<Uint8List?> get photoSignal => _photo;
  Signal<ProfileStatus> get statusSignal => _status;
  Signal<GraphProfile?> get profileSignal => _profile;

  /// Última falha do Microsoft Graph (diagnóstico exibido na tela `/me`).
  Signal<String?> get graphErrorSignal => _graphError;

  // Guarda contra fetches concorrentes/duplicados da foto.
  String? _photoLoadedFor;
  bool _photoLoading = false;

  /// Busca a foto do usuário [userId] uma vez. Reusa o cache quando já
  /// carregada para o mesmo usuário; refaz se o usuário mudou (troca de conta).
  Future<void> ensurePhoto(String? userId) async {
    if (userId == null || userId.isEmpty) return;
    if (_photoLoading) return;
    if (_photoLoadedFor == userId) return;

    _photoLoading = true;
    try {
      final bytes = await _graph.fetchMyPhoto();
      _photo.value = bytes;
      _photoLoadedFor = userId;
      _graphError.value = _graph.lastError;
    } finally {
      _photoLoading = false;
    }
  }

  /// Carrega o perfil completo (`/me`) para a tela de perfil.
  Future<void> loadProfile() async {
    _status.value = ProfileStatus.loading;
    final profile = await _graph.fetchMyProfile();
    _profile.value = profile;
    _graphError.value = _graph.lastError;
    _status.value = ProfileStatus.loaded;
  }

  /// Limpa o estado no logout (evita foto/perfil obsoletos numa nova conta).
  void clear() {
    _photo.value = null;
    _profile.value = null;
    _status.value = ProfileStatus.idle;
    _graphError.value = null;
    _photoLoadedFor = null;
  }

  void dispose() {
    _photo.dispose();
    _status.dispose();
    _profile.dispose();
    _graphError.dispose();
  }
}
