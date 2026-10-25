/// 앱 전역에서 참조하는 상수 정의
class AppConstants {
  const AppConstants._();

  /// 앱 표시 이름
  static const String appName = '배드민턴 명찰 찾기';

  /// 앱 버전 (Semantic Versioning)
  static const String appVersion = '1.0.0';

  /// 빌드 번호
  static const int buildNumber = 1;

  /// 버전 및 빌드 문자열 (예: v1.0.0)
  static const String versionString = 'v$appVersion';

  /// 상세 버전 문자열 (예: v1.0.0 (Build 1))
  static const String fullVersionString = 'v$appVersion (Build $buildNumber)';
}
