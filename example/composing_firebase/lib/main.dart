import 'dart:async';

import 'package:composing_firebase/anonymous_messages/anonymous_messages.dart';
import 'package:composing_firebase/anonymous_messages/message_composer.dart';
import 'package:composing_firebase/anonymous_messages/messages_repository.dart';
import 'package:composing_firebase/authentication/authentication.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'package:reactive_component/reactive_component.dart';

import 'anonymous_messages/message.dart';
import 'authentication/user.dart';

void main() async {
  await WidgetsFlutterBinding.ensureInitialized();
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  final Future<FirebaseApp> _initializeFirebase = Firebase.initializeApp();

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: _initializeFirebase,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.done) {
          return MultiProvider(
            providers: [
              Provider<MessagesRepository>(create: (_) => MessagesRepository()),
              Provider<MessagesAddingRepository>(
                  create: (_) => MessagesAddingRepository()),
            ],
            child: Provider<Authentication>(
              create: (context) => Authentication(),
              dispose: (context, self) => self.dispose(),
              child: MaterialApp(
                title: 'Firebase in ReactiveComponent Demo',
                theme: ThemeData(
                  primarySwatch: Colors.blue,
                  visualDensity: VisualDensity.adaptivePlatformDensity,
                ),
                home: MyHomePage(title: 'Firebase ReactiveComponent'),
              ),
            ),
          );
        } else {
          return Center(
            child: CircularProgressIndicator(),
          );
        }
      },
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key key, this.title}) : super(key: key);
  final String title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  AnonymousMessages _anonymousMessages;
  Authentication _authentication;

  @override
  void initState() {
    super.initState();
    _authentication = Provider.of<Authentication>(context, listen: false);
    _anonymousMessages = AnonymousMessages(
        Provider.of<MessagesRepository>(context, listen: false));
  }

  @override
  void dispose() {
    _anonymousMessages.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<AnonymousMessages>.value(value: _anonymousMessages),
      ],
      child: SafeArea(
        child: Scaffold(
          appBar: AppBar(
            title: Text(widget.title),
          ),
          body: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text('User kind'),
              ),
              StreamBuilder<User>(
                stream: _authentication.user,
                builder: (context, snapshot) {
                  if (!snapshot.hasData) return const SizedBox.shrink();
                  final user = snapshot.data;

                  var authButton;
                  switch (user.kind) {
                    case UserKind.anonymousUser:
                      authButton = ElevatedButton(
                        child: Text('Sign Out'),
                        onPressed: _authentication.signOut,
                      );
                      break;
                    case UserKind.visitor:
                      authButton = ElevatedButton(
                        child: Text('Sign In to write a message.'),
                        onPressed: _authentication.signInAnonymously,
                      );
                      break;
                  }

                  return Column(
                    children: [
                      Text(
                        '${user.runtimeType}',
                        style: Theme.of(context).textTheme.headline4,
                      ),
                      authButton,
                    ],
                  );
                },
              ),
              Flexible(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: _Messages(),
                ),
              ),
              StreamBuilder<User>(
                stream: _authentication.user,
                builder: (context, snapshot) {
                  if (!snapshot.hasData) return const SizedBox.shrink();
                  final user = snapshot.data;
                  switch (snapshot.data.kind) {
                    case UserKind.anonymousUser:
                      return _MessageComposer(user);
                    case UserKind.visitor:
                    default:
                      return const SizedBox.shrink();
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Messages extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final messages = Provider.of<AnonymousMessages>(context, listen: false);
    return StreamBuilder<List<Message>>(
      stream: messages.messages,
      initialData: [],
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }

        final messages = snapshot.data;
        if (messages.isEmpty) return ListView();
        return ListView.builder(
          itemCount: messages.length,
          itemBuilder: (context, index) {
            return Text('${messages[index].body}');
          },
        );
      },
    );
  }
}

class _MessageComposer extends StatefulWidget {
  _MessageComposer(this._user);
  final AnonymousUser _user;
  @override
  __MessageComposerState createState() => __MessageComposerState();
}

class __MessageComposerState extends State<_MessageComposer> {
  _MessageComposerController _controller;

  @override
  void initState() {
    super.initState();
    _controller = _MessageComposerController(
        MessageComposer(
            Provider.of<MessagesAddingRepository>(context, listen: false),
            widget._user),
        context);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: BoxConstraints(
        minHeight: 50,
        maxHeight: 100,
      ),
      child: DecoratedBox(
        decoration: BoxDecoration(
            border: Border(top: BorderSide(width: 0.5)), color: Colors.white),
        child: Row(
          children: <Widget>[
            Flexible(
              child: Container(
                child: TextField(
                  maxLines: null,
                  style: TextStyle(fontSize: 15.0),
                  decoration: const InputDecoration.collapsed(
                      hintText: 'Type your message...'),
                  controller: _controller.textEditingController,
                ),
              ),
            ),
            Material(
              child: Container(
                child: StreamBuilder<bool>(
                  stream: _controller.canSend,
                  initialData: false,
                  builder: (context, snapshot) {
                    return IconButton(
                      icon: Icon(Icons.send),
                      onPressed: snapshot.data ? _controller.send : null,
                      color: Colors.blue,
                    );
                  },
                ),
              ),
              color: Colors.white,
            ),
          ],
        ),
      ),
    );
  }
}

class _MessageComposerController {
  _MessageComposerController(this._model, this._context) {
    textEditingController.addListener(() {
      _textEditingStreamController.add(textEditingController.text);
    });

    _model.updateMessageText.addStream(_textEditingStreamController.stream);
    _model.form.forEach((form) {
      if (form.message != textEditingController.text) {
        textEditingController.text = form.message;
      }
    });

    _model.sent.forEach((_) {
      Scaffold.of(_context).showSnackBar(SnackBar(
        content: Text('Sent!'),
        backgroundColor: Colors.blue,
      ));
    });

    _model.errorMessage.forEach((message) {
      Scaffold.of(_context).showSnackBar(
          SnackBar(content: Text(message), backgroundColor: Colors.red));
    });
  }

  final TextEditingController textEditingController = TextEditingController();
  final _textEditingStreamController = StreamController<String>.broadcast();
  final MessageComposer _model;
  final BuildContext _context;

  Stream<bool> get canSend => _model.canSend;
  VoidReactiveSink get send => _model.send;

  void dispose() {
    textEditingController.dispose();
    _textEditingStreamController.close();
    _model.dispose();
  }
}
