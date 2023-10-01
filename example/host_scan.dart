import 'package:logging/logging.dart';
import '../lib/network_tools.dart';
import '../lib/src/network_tools_utils.dart';

void main() async {
  await configureNetworkTools('build');

  String subnet = '192.168.0'; //Default network id for home networks

  final interface = await NetInterface.localInterface();
  final netId = interface?.networkId;
  if (netId != null) {
    subnet = netId;
  }

  // or You can also get address using network_info_plus package
  // final String? address = await (NetworkInfo().getWifiIP());
  log.fine("Starting scan on subnet $subnet");

  // You can set [firstHostId] and scan will start from this host in the network.
  // Similarly set [lastHostId] and scan will end at this host in the network.
  final stream = HostScanner.getAllPingableDevicesAsync(
    subnet,
    // firstHostId: 1,
    // lastHostId: 254,
    progressCallback: (progress) {
      log.finer('Progress for host discovery : $progress');
    },
  );

  stream.listen(
    (final host) async {
      //Same host can be emitted multiple times
      //Use Set<ActiveHost> instead of List<ActiveHost>
      log.fine('Found device: ${await host.toStringFull()}');
    },
    onDone: () {
      log.fine('Scan completed');
    },
  ); // Don't forget to cancel the stream when not in use.
}
