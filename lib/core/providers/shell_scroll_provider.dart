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
