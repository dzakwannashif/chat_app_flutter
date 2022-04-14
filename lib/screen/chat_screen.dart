import 'package:chat/constants.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

late User loggedInUser;
final _firestore = FirebaseFirestore.instance;

class ChatScreen extends StatefulWidget {
  static const String id = 'CHAT_SCREEN';
  const ChatScreen({Key? key}) : super(key: key);

  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  TextEditingController messageController = TextEditingController();
  final _auth = FirebaseAuth.instance;
  late DateTime now;
  late String formattedDate;
  late String messageText;

  getCurrentUser() {
    try {
      final user = _auth.currentUser!;
      loggedInUser = user;
    } catch (e) {
      print(e);
    }
  }

  //
  // "initState", untuk mengelolah data 1kali
  // ketika halaman pertama kali dibuka akan mengelolah initState
  // dan akan mengecek getCurrentUser
  //

  @override
  void initState() {
    getCurrentUser();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: Icon(Icons.forum),
        centerTitle: true,
        title: Text('Chat Screen'),
        backgroundColor: Colors.lightBlueAccent,
        actions: [
          IconButton(
            icon: Icon(Icons.exit_to_app),
            onPressed: () {
              _auth.signOut();
              Navigator.pop(context);
            },
          )
        ],
      ),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          MessageStream(),
          Container(
            decoration: kMessageContainerDecoration,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: TextField(
                      controller: messageController,
                      style: const TextStyle(color: Colors.black),
                      onChanged: (newValue) {
                        messageText = newValue;
                      },
                      decoration: kMessageTextFieldDecoration),
                ),
                TextButton(
                  child: const Text(
                    'Send',
                    style: kSendButtonTextStyle,
                  ),
                  onPressed: () {
                    // memberitahu bahwa object telah berubah
                    setState(() {
                      now = DateTime.now();
                      formattedDate = DateFormat('kk:mm:ss').format(now);
                    });
                    messageController.clear();
                    _firestore.collection('messages').add({
                      'text': messageText.trim(),
                      'sender': loggedInUser.email!.trim(),
                      'time': formattedDate.trim()
                    });
                  },
                )
              ],
            ),
          )
        ],
      ),
    );
  }
}

class MessageBubble extends StatelessWidget {
  final String sender;
  final String text;
  final bool isMe;
  const MessageBubble({
    Key? key,
    required this.sender,
    required this.text,
    required this.isMe,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8),
      child: Column(
        crossAxisAlignment: 
        isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Text(sender, style:const TextStyle(color: Colors.black54, fontSize: 12),
          ),
          const SizedBox(
            height: 5,
          ),
          Material(
            borderRadius: BorderRadius.only(
              topLeft: isMe ? const Radius.circular(30) : const Radius.circular(0),
              topRight: isMe ? const Radius.circular(0) : const Radius.circular(30),
              bottomLeft: const Radius.circular(30),
              bottomRight: const Radius.circular(30),
            ),
            elevation: 5,
            color: isMe ? Colors.lightBlueAccent : Colors.white,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 20),
              child:  Text(
                text,
                style: TextStyle(
                  color: isMe ? Colors.white : Colors.black54
                ),
              ),
            )
          )
        ],
      ),
    );
  }
}

class MessageStream extends StatelessWidget {
  const MessageStream ({ Key? key})  : super(key: key);

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore
      .collection('messages')
      .orderBy('time', descending: true)
      .snapshots(),
      builder: (context, snapshot){
        if (!snapshot.hasData) {
          return const Center(
            child: CircularProgressIndicator(
              backgroundColor: Colors.lightBlue,
            ),
          );
        }

        final messages = snapshot.data!.docs;
        // ignore: unused_local_variable
        List<MessageBubble> messageBubbles = [];
        for (var message in messages) {
          final messageText = message['text'];
          final messageSender = message['sender'];
          
          final currentUserEmail = loggedInUser.email;

          final messageBubble = MessageBubble(
            sender: messageSender,
            text: messageText, 
            isMe: currentUserEmail == messageSender,
          );
          messageBubbles.add(messageBubble);
        }
        return Expanded(
          child: ListView(
            reverse: true,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            children: messageBubbles,
          )
        );
      },
    );
  }
}
