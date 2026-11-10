import 'package:gjamobile/src/di/app_injector.dart';
import 'package:gjamobile/src/features/access/domain/entities/feature.dart';
import 'package:gjamobile/src/features/access/presentation/controllers/admin_status.dart';
import 'package:gjamobile/src/features/access/presentation/controllers/features_controller.dart';
import 'package:gjamobile/src/features/access/presentation/widgets/confirm_dialog.dart';
import 'package:gjamobile/src/features/access/presentation/widgets/feature_list_tile.dart';
import 'package:gjamobile/src/imports/imports.dart';
import 'package:gja_ui/gja_ui.dart' show GjaIcons;

class FeaturesListScreen extends StatefulWidget {
  const FeaturesListScreen({super.key});

  @override
  State<FeaturesListScreen> createState() => _FeaturesListScreenState();
}

class _FeaturesListScreenState extends State<FeaturesListScreen> {
  final _controller = AppInjector.get<FeaturesController>();

  @override
  void initState() {
    super.initState();
    _controller.load();
  }

  Future<void> _onDelete(Feature feature) async {
    final ok = await confirmDialog(
      context,
      title: 'Excluir funcionalidade',
      message: 'Deseja excluir "${feature.label}"?',
      confirmLabel: 'Excluir',
      destructive: true,
    );
    if (!ok) return;
    final error = await _controller.delete(feature.id);
    if (!mounted) return;
    showToast(
      context,
      message: error ?? 'Funcionalidade excluída',
      status: error == null ? 'success' : 'error',
    );
  }

  @override
  Widget build(BuildContext context) {
    return AppPageScaffold(
      scrollable: false,
      appBar: AppTopBar(
        title: 'Funcionalidades',
        actions: [
          IconButton(
            tooltip: 'Nova funcionalidade',
            icon: const Icon(GjaIcons.add),
            onPressed: () => context.go(AppRoutes.gaFeatureNew),
          ),
        ],
      ),
      body: SignalBuilder(builder: (context) {
        final status = _controller.statusSignal.value;
        final features = _controller.featuresSignal.value;

        if (status == AdminStatus.loading || status == AdminStatus.idle) {
          return const AppLoading();
        }
        if (status == AdminStatus.error) {
          return AppErrorWidget(
            message: _controller.errorSignal.value?.message,
            onRetry: _controller.load,
          );
        }
        if (features.isEmpty) {
          return AppEmptyState(
            icon: GjaIcons.puzzle,
            title: 'Nenhuma funcionalidade',
            subtitle: 'Crie uma funcionalidade para começar.',
            actionLabel: 'Nova funcionalidade',
            onAction: () => context.go(AppRoutes.gaFeatureNew),
          );
        }
        return RefreshIndicator(
          onRefresh: _controller.load,
          child: ListView.separated(
            itemCount: features.length,
            separatorBuilder: (_, __) => SizedBox(height: AppSpacing.sm),
            itemBuilder: (context, i) {
              final feature = features[i];
              return FeatureListTile(
                feature: feature,
                onEdit: () => context.go(
                  AppRoutes.gaFeatureEditPath(feature.id),
                  extra: feature,
                ),
                onDelete: () => _onDelete(feature),
              );
            },
          ),
        );
      }),
    );
  }
}
