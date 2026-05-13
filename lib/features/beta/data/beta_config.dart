const bool _isBeta = bool.fromEnvironment('BETA', defaultValue: false);

class BetaConfig {
  static bool get isBeta => _isBeta;
}
