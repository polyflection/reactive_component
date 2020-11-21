// @dart=2.9
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:composing_firebase/authentication/user.dart';

import 'message.dart';

class MessagesAddingRepository {
  Future<void> add(String message, AnonymousUser user) async {
    return FirebaseFirestore.instance.collection(_messagesCollection).add({
      MessageSchema.body: message,
      MessageSchema.by: user.id,
      MessageSchema.createdAt: FieldValue.serverTimestamp()
    });
  }
}

class MessagesRepository {
  Stream<List<Message>> get messages {
    return FirebaseFirestore.instance
        .collection(_messagesCollection)
        .orderBy(MessageSchema.createdAt)
        .snapshots()
        .map((snapshot) {
      return snapshot.docChanges
          .where((element) => element.type == DocumentChangeType.added)
          .map((d) => Message(d.doc.id, d.doc.data()[MessageSchema.body]))
          .toList();
    });
  }
}

const _messagesCollection = 'messages';

class MessageSchema {
  static const body = 'body';
  static const by = 'by';
  static const createdAt = 'createdAt';
}
