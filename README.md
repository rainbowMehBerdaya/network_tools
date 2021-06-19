# Network Tools

[![pub package](https://img.shields.io/pub/v/network_tools.svg)](https://pub.dev/packages/network_tools)

Network Tools Supported

1. Host Scanner

2. Port Scanner

What's not supported

1. Mac Address of other devices on network

## Import package in your app

```dart
import 'package:network_tools/network_tools.dart'; 
```

## Usage

### Host Scanner

```dart
  String ip = '192.168.1.12';
  // or You can also get ip using network_info_plus package
  // final String? ip = await (NetworkInfo().getWifiIP());
  final String subnet = ip.substring(0, ip.lastIndexOf('.'));
  final stream = HostScanner.discover(subnet, progressCallback: (progress) {
    print('Progress : $progress');
  });

  stream.listen((host) {
    //Same host can be emitted multiple times
    //Use Set<ActiveHost> instead of List<ActiveHost>
    print('Found device: ${host}');
  }, onDone: () {
    print('Scan completed');
  });// Don't forget to cancel the stream when not in use.

```

### Port Scanner

```dart
  String target = '192.168.1.1';
  PortScanner.discover(target, progressCallback: (progress) {
    print('Progrees : $progress');
  }).listen((event) {
    if (event.isOpen) {
      print('Found open port : $event');
    }
  }, onDone: () {
    print('Scan completed');
  });
```

Inspired from [ping_discover_network](https://github.com/andrey-ushakov/ping_discover_network)
