class AppConstants {
  static const String appVersion = '0.8.5';
  static const int minCodeLength = 5;
  static const int maxCodeLength = 15;
  static const int pageSize = 50;
  static const Duration scanCooldown = Duration(milliseconds: 2800);
  static const String csvUrl = 'https://repo.din.uci.cu/alimentacion/app-mobile-siga/-/raw/main/tb_dpersona_activos.csv';
  static const String gitlabToken = String.fromEnvironment('GITLAB_TOKEN', defaultValue: '');
}