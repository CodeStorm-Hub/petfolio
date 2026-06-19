class AppConfig {
  AppConfig._();

  static const dashboardUrl = String.fromEnvironment(
    'DASHBOARD_URL',
    defaultValue: 'https://petfolio-dashboard.vercel.app',
  );
}
