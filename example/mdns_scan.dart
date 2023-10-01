import 'package:network_tools/network_tools.dart';

Future<void> main() async {
  await configureNetworkTools('build');
  for (final ActiveHost activeHost in await MdnsScanner.searchMdnsDevices()) {
    final MdnsInfo? mdnsInfo = await activeHost.mdnsInfo;
    print(
      'Address: ${activeHost.address}, Port: ${mdnsInfo!.mdnsPort}, ServiceType: ${mdnsInfo.mdnsServiceType}, MdnsName: ${mdnsInfo.getOnlyTheStartOfMdnsName()}, Mdns Device Name: ${mdnsInfo.mdnsSrvTarget}\n',
    );
  }
}
