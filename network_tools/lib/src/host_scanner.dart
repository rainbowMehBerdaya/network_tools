import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'package:dart_ping/dart_ping.dart';
import 'package:dart_ping_ios/dart_ping_ios.dart';
import 'package:network_tools/src/models/active_host.dart';
import 'package:network_tools/src/models/callbacks.dart';
import 'package:network_tools/src/port_scanner.dart';

/// Scans for all hosts in a subnet.
class HostScanner {
  /// Scans for all hosts in a particular subnet (e.g., 192.168.1.0/24)
  /// Set maxHost to higher value if you are not getting results.
  /// It won't firstHostId again unless previous scan is completed due to heavy
  /// resource consumption.
  /// [resultsInAddressAscendingOrder] = false will return results faster but not in
  /// ascending order and without [progressCallback].
  static Stream<ActiveHost> getAllPingableDevices(
    String subnet, {
    int firstHostId = 1,
    int lastHostId = 254,
    int timeoutInSeconds = 1,
    ProgressCallback? progressCallback,
    bool resultsInAddressAscendingOrder = true,
  }) async* {
    final int maxEnd = getMaxHost(subnet);
    if (firstHostId > lastHostId ||
        firstHostId < 1 ||
        lastHostId < 1 ||
        firstHostId > maxEnd ||
        lastHostId > maxEnd) {
      throw 'Invalid subnet range or firstHostId < lastHostId is not true';
    }
    final int lastValidSubnet = min(lastHostId, maxEnd);

    final List<Future<ActiveHost?>> activeHostsFuture = [];
    final StreamController<ActiveHost> activeHostsController =
        StreamController<ActiveHost>();

    for (int i = firstHostId; i <= lastValidSubnet; i++) {
      activeHostsFuture.add(
        _getHostFromPing(
          activeHostsController: activeHostsController,
          host: '$subnet.$i',
          i: i,
          timeoutInSeconds: timeoutInSeconds,
        ),
      );
    }

    if (!resultsInAddressAscendingOrder) {
      yield* activeHostsController.stream;
    }

    int i = 0;
    for (final Future<ActiveHost?> host in activeHostsFuture) {
      i++;
      final ActiveHost? tempHost = await host;

      progressCallback
          ?.call((i - firstHostId) * 100 / (lastValidSubnet - firstHostId));

      if (tempHost == null) {
        continue;
      }
      yield tempHost;
    }
  }

  static Future<ActiveHost?> _getHostFromPing({
    required String host,
    required int i,
    required StreamController<ActiveHost> activeHostsController,
    int timeoutInSeconds = 1,
  }) async {
    await for (final PingData pingData
        in Ping(host, count: 1, timeout: timeoutInSeconds).stream) {
      final PingResponse? response = pingData.response;
      if (response != null) {
        final Duration? time = response.time;
        if (time != null) {
          final ActiveHost tempActiveHost =
              ActiveHost.buildWithAddress(address: host, pingData: pingData);
          activeHostsController.add(tempActiveHost);
          return tempActiveHost;
        }
      }
    }
    return null;
  }

  /// Scans for all hosts that have the specific port that was given.
  /// [resultsInAddressAscendingOrder] = false will return results faster but not in
  /// ascending order and without [progressCallback].
  static Stream<ActiveHost> scanDevicesForSinglePort(
    String subnet,
    int port, {
    int firstHostId = 1,
    int lastHostId = 254,
    Duration timeout = const Duration(milliseconds: 2000),
    ProgressCallback? progressCallback,
    bool resultsInAddressAscendingOrder = true,
  }) async* {
    if (Platform.isIOS) {
      DartPingIOS.register();
    }

    final int maxEnd = getMaxHost(subnet);
    if (firstHostId > lastHostId ||
        firstHostId < 1 ||
        lastHostId < 1 ||
        firstHostId > maxEnd ||
        lastHostId > maxEnd) {
      throw 'Invalid subnet range or firstHostId < lastHostId is not true';
    }
    final int lastValidSubnet = min(lastHostId, maxEnd);
    final List<Future<ActiveHost?>> activeHostOpenPortList = [];
    final StreamController<ActiveHost> activeHostsController =
        StreamController<ActiveHost>();

    for (int i = firstHostId; i <= lastValidSubnet; i++) {
      final host = '$subnet.$i';
      activeHostOpenPortList.add(
        PortScanner.connectToPort(
          address: host,
          port: port,
          timeout: timeout,
          activeHostsController: activeHostsController,
        ),
      );
    }

    if (!resultsInAddressAscendingOrder) {
      yield* activeHostsController.stream;
    }

    int counter = firstHostId;
    for (final Future<ActiveHost?> openPortActiveHostFuture
        in activeHostOpenPortList) {
      final ActiveHost? activeHost = await openPortActiveHostFuture;
      if (activeHost != null) {
        yield activeHost;
      }
      progressCallback?.call(
        (counter - firstHostId) * 100 / (lastValidSubnet - firstHostId),
      );
      counter++;
    }
  }

  static const classASubnets = 16777216;
  static const classBSubnets = 65536;
  static const classCSubnets = 256;
  static int getMaxHost(String subnet) {
    final List<String> lastHostIdStr = subnet.split('.');
    if (lastHostIdStr.isEmpty) {
      throw 'Invalid subnet Address';
    }

    final int lastHostId = int.parse(lastHostIdStr[0]);

    if (lastHostId < 128) {
      return classASubnets;
    } else if (lastHostId >= 128 && lastHostId < 192) {
      return classBSubnets;
    } else if (lastHostId >= 192 && lastHostId < 224) {
      return classCSubnets;
    }
    return classCSubnets;
  }
}
