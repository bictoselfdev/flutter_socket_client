import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _msgController = TextEditingController();
  final _ipAddressController = TextEditingController();
  Socket? clientSocket;
  int port = 5555;
  StringBuffer logcat = StringBuffer();

  void connectToServer(String ipAddress) async {
    Socket.connect(ipAddress, port, timeout: const Duration(seconds: 5))
        .then((socket) {

      setState(() {
        clientSocket = socket;
        logcat.write("Socket Connected - ${socket.remoteAddress.address}:${socket.remotePort}\n");
      });

      socket.listen(
        (onData) {
          setState(() {
            logcat.write("Receive : ${utf8.decode(onData)}\n");
          });
        },
        onDone: () {
          disconnect();
        },
        onError: (e) {
          logcat.write("exception : $e\n");
          disconnect();
        },
      );
    }).catchError((e) {
      logcat.write("exception : $e\n");
    });
  }

  void disconnect() {
    clientSocket?.close();

    setState(() {
      clientSocket = null;
      logcat.write("Socket Disconnected\n");
    });
  }

  void sendMessage() {
    if (_msgController.text.isEmpty) return;

    clientSocket?.write(_msgController.text);

    setState(() {
      logcat.write("Send : ${_msgController.text}\n");
      _msgController.clear();
    });
  }

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();

    disconnect();

    _ipAddressController.dispose();
    _msgController.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Flutter Socket Client(클라이언트)')),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            controllerView(),
            logcatView(),
            sendMessageView(),
          ],
        ),
      ),
    );
  }

  Widget controllerView() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 15),
        Text(
          clientSocket == null ? 'DisConnected' : 'Connected',
          style: TextStyle(
              color: clientSocket == null ? Colors.red : Colors.green),
        ),
        const SizedBox(height: 15),
        TextFormField(
          controller: _ipAddressController,
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            hintText: 'IP 주소',
          ),
          keyboardType: TextInputType.number,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'IP 주소를 입력하세요.';
            }
            return null;
          },
        ),
        const SizedBox(height: 15),
        ElevatedButton(
          onPressed: () {
            if (clientSocket == null) {
              connectToServer(_ipAddressController.text);
            } else {
              disconnect();
            }
          },
          style: ElevatedButton.styleFrom(
            minimumSize: const Size.fromHeight(50),
          ),
          child: Text(clientSocket == null ? '연결' : '연결 해제'),
        ),
      ],
    );
  }

  Widget logcatView() {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: SingleChildScrollView(
          child: SizedBox(
            width: double.infinity,
            child: Text(
              logcat.toString(),
            ),
          ),
        ),
      ),
    );
  }

  Widget sendMessageView() {
    return Card(
      child: ListTile(
        title: TextField(
          controller: _msgController,
        ),
        trailing: IconButton(
          icon: const Icon(Icons.send),
          color: Colors.blue,
          disabledColor: Colors.grey,
          onPressed: (clientSocket != null) ? sendMessage : null,
        ),
      ),
    );
  }
}
