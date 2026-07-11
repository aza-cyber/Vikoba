import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/state/app_state.dart';

/// Pushes a page while preserving the currently scoped group state.
///
/// Routes are siblings in Flutter's overlay, so providers created inside the
/// logged-in shell route are not automatically visible to pages pushed above it.
Route<T> appStateRoute<T>(BuildContext context, Widget page) {
  final state = context.read<AppState>();
  return MaterialPageRoute<T>(
    builder: (_) => ChangeNotifierProvider<AppState>.value(
      value: state,
      child: page,
    ),
  );
}
