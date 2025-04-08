import 'package:chat_app/widgets/chat_messages.dart';
import 'package:chat_app/widgets/new_message.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {


  void setupPushNoteification () async {
    final fcm = FirebaseMessaging.instance;
     await fcm.requestPermission();

    final token = await fcm.getToken();
    print("user Device ID $token");
    fcm.subscribeToTopic("chat");
  }

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
   setupPushNoteification();
  }
  @override
  Widget build(BuildContext context) {
    return  Scaffold(
        appBar: AppBar(
          title: const Text("Flutter Caht"),
          actions: [
            IconButton(onPressed: () {
              FirebaseAuth.instance.signOut();
            }, icon: Icon(Icons.exit_to_app, size: 30 ,color: Theme.of(context).colorScheme.primary,))
          ],

        ),

        body: const Column(
          children:  [
            Expanded(child: ChatMessages()),
            NewMessage(),
          ],
        )
    );
  }
}


