import 'dart:async';

import 'package:flutter/material.dart';
import 'package:pdf_viewer/pdf_viewer_page.dart';
import 'package:http/http.dart' as http;
import 'package:connectivity_plus/connectivity_plus.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        // This is the theme of your application.
        //
        // Try running your application with "flutter run". You'll see the
        // application has a blue toolbar. Then, without quitting the app, try
        // changing the primarySwatch below to Colors.green and then invoke
        // "hot reload" (press "r" in the console where you ran "flutter run",
        // or simply save your changes to "hot reload" in a Flutter IDE).
        // Notice that the counter didn't reset back to zero; the application
        // is not restarted.
        primarySwatch: Colors.blue,
      ),
      home: const MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  late StreamSubscription<ConnectivityResult> subscription;
  String _connectionStatus = 'Unknown';
  @override
  void initState() {
    super.initState();
    subscription = Connectivity().onConnectivityChanged.listen((ConnectivityResult result) {
      setState(() {
        _connectionStatus = result.toString();
      });
    });
    Future.delayed(const Duration(milliseconds: 300),_testHttp);
  }

  // test http
  _testHttp(){
    http.get(Uri.parse('https://www.baidu.com')).then((value){
      print('http请求成功');
    }).catchError((e){
      print('http请求错误：$e');
    });
  }

  @override
  void dispose() {
    subscription.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('PDF VIEWER'),
      ),
      body: Container(
        alignment: Alignment.center,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('网络状态：$_connectionStatus'),
            const SizedBox(height: 30),
            OutlinedButton(onPressed: (){
              Navigator.push(context, MaterialPageRoute(builder: (ctx){
                return const PdfViewerPage();
              }));
            }, child: const Text('Open PDF Detail Page'))
          ],
    ),
      ),
    );
  }
}
