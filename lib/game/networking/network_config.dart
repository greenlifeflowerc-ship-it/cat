/// Centralized network configuration. The only place server host/port live.
/// Change the port here if the real WebSocket server uses a different one.
class NetworkConfig {
  static const String serverHostIPv4 = '13.201.118.98';
  static const String serverHostIPv6 = '2406:da1a:b6a:7d00:876:dd83:115f:bb09';

  // Keep the port configurable. Do not hardcode it elsewhere.
  static const int websocketPort = 8080;

  static const String websocketPath = '/ws';

  static String get websocketUrlIPv4 =>
      'ws://$serverHostIPv4:$websocketPort$websocketPath';

  static String get websocketUrlIPv6 =>
      'ws://[$serverHostIPv6]:$websocketPort$websocketPath';

  /// Default URL clients should dial. IPv4 is the most broadly reachable.
  static String get defaultUrl => websocketUrlIPv4;
}
