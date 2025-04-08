import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class NewMessage extends StatefulWidget {
  const NewMessage({super.key});

  @override
  State<NewMessage> createState() => _NewMessageState();
}

class _NewMessageState extends State<NewMessage> {
  final _messageController = TextEditingController();
  bool _isComposing = false;

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  void _onMessageChanged(String message) {
    setState(() {
      _isComposing = message.trim().isNotEmpty;
    });
  }

  void _submitMessage() async {
    final enteredMessage = _messageController.text;

    if (enteredMessage.trim().isEmpty) {
      return;
    }

    FocusScope.of(context).unfocus();

    try {
      final user = FirebaseAuth.instance.currentUser!;
      final userDoc = await FirebaseFirestore.instance.collection("users").doc(user.uid).get();
      final userData = userDoc.data();

      if (userData == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('User data not found!')),
        );
        return;
      }

      await FirebaseFirestore.instance.collection("chat").add({
        "text": enteredMessage,
        "createdAt": Timestamp.now(),
        "userId": user.uid,
        "username": userData["username"] ?? "Unknown User",
        "userImage": userData["image_url"] ?? "",
      });

      _messageController.clear();
      setState(() {
        _isComposing = false;
      });
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to send message: $error')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 14),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _messageController,
              onChanged: _onMessageChanged,
              textCapitalization: TextCapitalization.sentences,
              autocorrect: true,
              enableSuggestions: true,
              decoration: const InputDecoration(labelText: "Send a message"),
            ),
          ),
          IconButton(
            onPressed: _isComposing ? _submitMessage : null,
            icon: const Icon(Icons.send),
          ),
        ],
      ),
    );
  }
}
