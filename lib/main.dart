import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:http/http.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ProxityKit demo',
      theme: ThemeData(
        primarySwatch: Colors.amber,
      ),
      home: MyHomePage(title: 'ProxityKit demo'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key? key, required this.title}) : super(key: key);

  final String title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  List<Map<String, dynamic>> _messages = [];

  @override
  void initState() {
    super.initState();

    final platform = MethodChannel('eu.proxity');
    platform.setMethodCallHandler((call) async {
      switch (call.method) {
        case 'messages':
        final ids = List<String>.from(call.arguments);
        if (ids.isNotEmpty) {
          final response = await post(
            Uri.parse('https://api.proxity.eu/v1/message/list/'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'device': '09A81085-AAF2-4E9D-9CC7-6A28B79F33D2',
              'messages': ids
            })
          );

          final msgs = jsonDecode(response.body);
          setState(() {
            _messages = [];
            for (final m in msgs) {
              _messages.add(Map<String, dynamic>.from(m));
            }
          });
        }
        break;

        case 'webhooks':
        print('Webhooks fired: ${call.arguments}');
        break;

        default:
          print('Unknown method');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: _messages.isEmpty
        ? Center(child: Text('No messages'))
        : ListView(children: _messages.map((m) => _MessageItem(message: m)).toList()),
    );
  }
}

class _MessageItem extends StatelessWidget {
  final Map<String, dynamic> message;

  const _MessageItem({Key? key, required this.message}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final imageUrl = Uri.parse('https://storage.googleapis.com/proxity/')
      .resolve(message['image'] ?? '');

    final title = message['content'][message['default_language']]['title'];

    return SizedBox(
      height: 100,
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Row(
          children: [
            AspectRatio(
              aspectRatio: 3/2,
              child: Image.network(imageUrl.toString())
            ),
            SizedBox(width: 10),
            Expanded(
              child: Text(title)
            )
          ],
        ),
      ),
    );
  }
}