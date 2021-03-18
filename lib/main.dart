import 'package:csv/csv.dart';
import 'package:flutter/material.dart';

import 'package:http/http.dart' as http;

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: FutureBuilder(
        future: getVPNList(),
        builder: (BuildContext context, AsyncSnapshot<List<VPN>> snapshot) {
          if (snapshot.hasData) {
            return ListView.builder(
              itemCount: snapshot.data.length * 2,
              itemBuilder: (context, index) {
                if (index.isOdd) return Divider();

                final idx = index ~/ 2;

                return ListTile(
                  title: Text(snapshot.data[idx].hostname),
                  subtitle: Text('${snapshot.data[idx].countryShort} | ${snapshot.data[idx].ping} | ${snapshot.data[idx].speed}'),
                );
              }
            );
          } else if (snapshot.hasError) {
            return Center(child: Text('Couldn\'t load list from VPN Gate. Please refresh!'),);
          } else {
            return Center(child: CircularProgressIndicator(),);
          }
        }
      )
    );
  }

  Future<List<VPN>> getVPNList() async {
    final url = Uri.http('rimurubot.ml:8080', '/www.vpngate.net/api/iphone/');
    final res = await http.get(url);
    print('Status code: ${res.statusCode}');
    if (res.statusCode == 200) {
      List<List<dynamic>> csv = const CsvToListConverter().convert(res.body);
      print('Raw CSV length: ${csv.length}');
      return csv.sublist(2, csv.length - 1).map<VPN>((raw) => VPN.fromList(raw)).toList();
    } else {
      print('Error!');
      return Future.error('Failed to load VPN list!');
    }
  }

}

class VPN {
  //#HostName,IP,Score,Ping,Speed,CountryLong,CountryShort,NumVpnSessions,Uptime,TotalUsers,TotalTraffic,LogType,Operator,Message,OpenVPN_ConfigData_Base64
  final String hostname;
  final String ip;
  final int score;
  final int ping;
  final int speed;
  final String countryLong;
  final String countryShort;
  final int numVPNSessions;
  final int uptime;
  final int totalUsers;
  final int totalTraffic;
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
    speed: raw[4],
    countryLong: raw[5],
    countryShort: raw[6],
    numVPNSessions: raw[7],
    uptime: raw[8],
    totalUsers: raw[9],
    totalTraffic: raw[10],
    logType: raw[11],
    op: raw[12],
    message: raw[13],
    openVPN64: raw[14],
  );
  
}
