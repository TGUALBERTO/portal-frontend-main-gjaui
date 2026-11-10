import '../../imports/imports.dart';

/// Kept for API compatibility. The DI container is now committed in `main`,
/// so this wrapper is a pass-through and exists only to keep the existing
/// wrapper composition stable.
class StateWrapper extends StatelessWidget {
  final Widget child;

  const StateWrapper({super.key, required this.child});

  @override
  Widget build(BuildContext context) => child;
}
