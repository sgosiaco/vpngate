import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'dart:convert';
import 'dart:html' as html;
import 'package:http/http.dart' as http;
import 'package:csv/csv.dart';


void main() {
  runApp(App());
}

class App extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'VPN Gate',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: HomePage(title: 'VPN Gate'),
    );
  }
}

class HomePage extends StatefulWidget {
  HomePage({Key key, this.title}) : super(key: key);

  final String title;

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List<VPN> _data = [];
  List<VPN> _view = [];

  @override
  void initState() {
    super.initState();
    getVPNList().then(
      (data) {
        setState(() {
          _data = data;
          _view = data;
        });
      }
    ).onError((error, stackTrace) {
      setState(() {
        _data = null;
      });
    });
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Builder(
        builder: (context) {
          if (_data != []) {
            return Column(
              children: [
                ButtonBar(
                  alignment: MainAxisAlignment.start,
                  children: [
                    TextButton(child: Text('Canada'), onPressed: () {
                      setState(() {
                        _view = _data.where((element) => element.countryShort == 'CA').toList();
                      });
                    }),
                    TextButton(child: Text('Japan'), onPressed: () {
                      setState(() {
                        _view = _data.where((element) => element.countryShort == 'JP').toList();
                      });
                    }),
                    TextButton(child: Text('Korea'), onPressed: () {
                      setState(() {
                        _view = _data.where((element) => element.countryShort == 'KR').toList();
                      });
                    }),
                    TextButton(child: Text('United States'), onPressed: () {
                      setState(() {
                        _view = _data.where((element) => element.countryShort == 'US').toList();
                      });
                    }),
                    TextButton(child: Text('Vietnam'), onPressed: () {
                      setState(() {
                        _view = _data.where((element) => element.countryShort == 'VN').toList();
                      });
                    }),
                    TextButton(child: Text('Reset'), onPressed: () {
                      setState(() {
                        _view = _data;
                      });
                    })
                  ],
                ),
                Expanded(child: VPNList(data: _view))
              ]
            );
          } else if (_data == null) {
            return Center(child: Text('Couldn\'t load list from VPN Gate. Please refresh!'),);
          } else {
            return Center(child: CircularProgressIndicator(),);
          }
        },
      )
    );
  }

  Future<List<VPN>> getVPNList() async {
    var url;
    if (kDebugMode) {
      url = Uri.http('rimurubot.ml:8080', '/www.vpngate.net/api/iphone/');
    } else {
      url = Uri.https('rimurubot.ml:8080', '/www.vpngate.net/api/iphone/');
    }
    final res = await http.get(url);
    print('Status code: ${res.statusCode}');
    if (res.statusCode == 200) {
      List<List<dynamic>> csv = const CsvToListConverter().convert(res.body);
      print('Raw CSV length: ${csv.length}');
      return csv.sublist(2, csv.length - 1).map<VPN>((raw) => VPN.fromList(raw)).toList()..sort((a, b) => a.ping - b.ping);
    } else {
      print('Error!');
      return Future.error('Failed to load VPN list!');
    }
  }
}

class VPNList extends StatelessWidget {
  final List<VPN> data;

  VPNList({this.data});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      shrinkWrap: true,
      itemCount: data.length * 2,
      itemBuilder: (context, index) {
        if (index.isOdd) return Divider();

          final idx = index ~/ 2;

          return ListTile(
            title: Text('${data[idx].hostname} | ${data[idx].ip}'),
            subtitle: Text('${data[idx].countryShort} | ${data[idx].ping} ms | ${data[idx].speed.toStringAsFixed(2)} Mbps | ${data[idx].uptime.toStringAsFixed(0)} days | ${data[idx].totalTraffic.toStringAsFixed(2)} GB'),
            trailing: Text('${data[idx].score}'),
            onTap: () {
              html.window.open(html.Url.createObjectUrlFromBlob(html.Blob([utf8.decode(base64Decode(data[idx].openVPN64))], 'text/plan', 'native')), "text");
            },
          );
        }
    );
  }
}

class VPN {
  //#HostName,IP,Score,Ping,Speed,CountryLong,CountryShort,NumVpnSessions,Uptime,TotalUsers,TotalTraffic,LogType,Operator,Message,OpenVPN_ConfigData_Base64
  final String hostname;
  final String ip;
  final int score;
  final int ping;
  final double speed;
  final String countryLong;
  final String countryShort;
  final int numVPNSessions;
  final double uptime;
  final int totalUsers;
  final double totalTraffic;
  final String logType;
  final String op;
  final String message;
  final String openVPN64;

  VPN({this.hostname, this.ip, this.score, this.ping, this.speed, this.countryLong, this.countryShort, this.numVPNSessions, this.uptime, this.totalUsers, this.totalTraffic, this.logType, this.op, this.message, this.openVPN64});
  
  factory VPN.fromList(List raw) => VPN(
    hostname: raw[0],
    ip: raw[1],
    score: raw[2],
    ping: raw[3],
    speed: raw[4] / 1000000, // in bps so divide by 1mil to get Mbps
    countryLong: raw[5],
    countryShort: raw[6].toUpperCase(),
    numVPNSessions: raw[7],
    uptime: raw[8] / (1000*60*60*24), // in ms so divide by 1000 60 60 24
    totalUsers: raw[9],
    totalTraffic: raw[10] / 1000000000, // in bytes so divide by 1bil to get GB
    logType: raw[11],
    op: raw[12],
    message: raw[13],
    openVPN64: raw[14],
  );
  
}
