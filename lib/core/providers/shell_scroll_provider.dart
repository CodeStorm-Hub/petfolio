import 'package:flutter_riverpod/flutter_riverpod.dart';

class _ScrollProgressNotifier extends Notifier<double> {
  @override
  double build() => 0.0;

  void set(double value) => state = value;
}

final homeScrollProgressProvider =
    NotifierProvider<_ScrollProgressNotifier, double>(
  _ScrollProgressNotifier.new,
);

class _ShellHeaderVisibleNotifier extends Notifier<bool> {
  @override
  bool build() => true;

  void set(bool value) => state = value;
}

/// When false, [AppShell] hides its floating [AppShellHeader].
/// [PetfolioScaffold] sets this to false while mounted so it can render
/// its own M3-compliant [SliverAppBar] / [AppBar] without visual conflict.
final shellHeaderVisibleProvider =
    NotifierProvider<_ShellHeaderVisibleNotifier, bool>(
  _ShellHeaderVisibleNotifier.new,
);
