import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../widgets/care_daily_tasks_dashboard.dart';

class CareFilterNotifier extends Notifier<CareFilter> {
  @override
  CareFilter build() => CareFilter.all;

  void setFilter(CareFilter filter) => state = filter;
}

final careFilterProvider = NotifierProvider<CareFilterNotifier, CareFilter>(
  CareFilterNotifier.new,
);
