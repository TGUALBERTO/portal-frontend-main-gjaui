import 'package:gjamobile/src/di/app_injector.dart';
import 'package:gjamobile/src/features/access/domain/entities/feature.dart';
import 'package:gjamobile/src/features/access/presentation/controllers/features_controller.dart';
import 'package:gjamobile/src/features/access/presentation/widgets/feature_form_sheet.dart';
import 'package:gjamobile/src/imports/imports.dart';

/// Routed create/edit screen for a feature (replaces the old bottom sheet) so
/// the action shows in the URL: /ga/features/new and /ga/features/:id.
class FeatureEditScreen extends StatefulWidget {
  const FeatureEditScreen({super.key, this.feature, this.featureId});

  /// Feature passed via `extra` when navigating from the list (fast path).
  final Feature? feature;

  /// Feature id from the route path; resolved against the list on a deep-link
  /// where [feature] wasn't passed via `extra`.
  final String? featureId;

  @override
  State<FeatureEditScreen> createState() => _FeatureEditScreenState();
}

class _FeatureEditScreenState extends State<FeatureEditScreen> {
  final _controller = AppInjector.get<FeaturesController>();
  Feature? _feature;
  bool _resolving = false;
  String? _error;

  bool get _isEditing => widget.featureId != null || widget.feature != null;

  @override
  void initState() {
    super.initState();
    _feature = widget.feature;
    if (_feature == null && widget.featureId != null) {
      _resolve(widget.featureId!);
    }
  }

  Future<void> _resolve(String id) async {
    setState(() {
      _resolving = true;
      _error = null;
    });
    if (_controller.featuresSignal.value.isEmpty) {
      await _controller.load();
    }
    Feature? found;
    for (final f in _controller.featuresSignal.value) {
      if (f.id == id) {
        found = f;
        break;
      }
    }
    if (!mounted) return;
    setState(() {
      _feature = found;
      _resolving = false;
      _error = found == null ? 'Funcionalidade não encontrada' : null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return AppPageScaffold(
      appBar: AppTopBar(
        title: _isEditing ? 'Editar funcionalidade' : 'Nova funcionalidade',
        onPressed: () => context.go(AppRoutes.gaFeatures),
      ),
      body: _resolving
          ? const AppLoading()
          : _error != null
              ? AppErrorWidget(
                  message: _error,
                  onRetry: () => _resolve(widget.featureId!),
                )
              : FeatureFormSheet(
                  feature: _feature,
                  embedded: true,
                  onSubmit: _controller.save,
                  onSuccess: () => context.go(AppRoutes.gaFeatures),
                ),
    );
  }
}
