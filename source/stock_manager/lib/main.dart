import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/rendering.dart';
import 'package:stock_manager/model/firestore_user.dart';
import 'package:stock_manager/repository/user_repository.dart';
import 'firebase_options.dart';
import 'UI/trade.dart';
import 'UI/portfolio.dart';
import 'UI/profile.dart';
import 'UI/naviguation.dart';

/// The main function initializes Firebase and runs the MyApp widget.
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(const MyApp());
}

final ThemeData darkTheme = ThemeData(
  brightness: Brightness.dark,
  primaryColor: Colors.blueGrey,
  colorScheme: const ColorScheme.dark(
    secondary: Colors.cyanAccent,
  ),
);

/// The `MyApp` class is a Dart class that represents the main application and defines the routes for
/// different pages in the Stock Manager app.
class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Stock Manager',
      theme: darkTheme,
      home: const MyHomePage(title: 'Stock Manager'),
      routes: {
        '/home': (context) => const MyHomePage(title: 'Stock Manager'),
        '/trade': (context) => Trade(
              stockName: 'TSLA',
            ),
        '/portfolio': (context) => const Portfolio(),
        '/profile': (context) => Profile(),
      },
    );
  }
}

/// The `MyHomePage` class is a stateful widget in Dart that represents the home page of an application
/// and has a title property.
class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});
  final String title;
  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

/// The `_MyHomePageState` class is a stateful widget that represents the home page of an app, allowing
/// users to register, login, and logout.
class _MyHomePageState extends State<MyHomePage> {
  String? username;
  FirestoreUser? user;

  bool _isInError = false;

  late final TextEditingController _email;
  late final TextEditingController _password;

  @override
  void initState() {
    _email = TextEditingController();
    _password = TextEditingController();
    UserRepository.getInstance()
        .getConnected()
        .then((value) => setState(() => user = value));
    super.initState();
  }

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  void _setInError() {
    setState(() {
      _isInError = true;
    });
  }

  void _setUser(UserCredential? userCredential) {
    if (userCredential != null) {
      UserRepository ur = UserRepository.getInstance();
      FirestoreUser newUser =
          FirestoreUser(userCredential.user!.uid, userCredential.user!.email!);
      ur.save(newUser);
      setState(() => user = newUser);
    } else {
      setState(() => user = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
      ),
      body: Center(
        child: SizedBox(
          height: 800,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              // Video player with overlay text (abandoned)
              const Stack(
                alignment: Alignment.center,
                children: [
                  Padding(
                    padding: EdgeInsets.all(20),
                    child: Column(
                      children: [
                        Text(
                          'Stock Manager',
                          style: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text('the stock tool'),
                      ],
                    ),
                  ),
                ],
              ),
              // Restricted width container for the text fields
              SizedBox(
                width: 400,
                child: Column(
                  children: [
                    if (_isInError)
                      AlertDialog(
                        backgroundColor:
                            const Color.fromARGB(45, 197, 141, 230),
                        title: const Text('Something went wrong!'),
                        content: const SingleChildScrollView(
                          child: ListBody(
                            children: <Widget>[
                              Text(
                                  'If you don\' have an account please register yourself.'),
                            ],
                          ),
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => setState(() {
                              _isInError = false;
                            }),
                            child: const Text('Ok'),
                          ),
                        ],
                      ),
                    if (user == null) ...[
                      TextField(
                        controller: _email,
                        keyboardType: TextInputType.emailAddress,
                        enableSuggestions: false,
                        autocorrect: false,
                        decoration: const InputDecoration(
                            hintText: "example@company.com"),
                      ),
                      TextField(
                        controller: _password,
                        obscureText: true,
                        enableSuggestions: false,
                        autocorrect: false,
                        decoration:
                            const InputDecoration(hintText: "Enter password"),
                      ),
                      TextButton(
                          onPressed: () async {
                            final email = _email.text;
                            final password = _password.text;
                            try {
                              final userCredential = await FirebaseAuth.instance
                                  .createUserWithEmailAndPassword(
                                      email: email, password: password);
                              _setUser(userCredential);
                              Navigator.pushReplacement(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => const Portfolio(),
                                  ));
                            } catch (e) {
                              _setInError();
                            }
                          },
                          child: const Text("Register")),
                      TextButton(
                          autofocus: true,
                          onPressed: () async {
                            final email = _email.text;
                            final password = _password.text;

                            try {
                              final userCredential = await FirebaseAuth.instance
                                  .signInWithEmailAndPassword(
                                      email: email, password: password);
                              _setUser(userCredential);
                              Navigator.pushReplacement(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => const Portfolio(),
                                  ));
                            } catch (e) {
                              _setInError();
                            }
                          },
                          child: const Text("Login")),
                    ] else ...[
                      TextButton(
                          onPressed: () async {
                            await FirebaseAuth.instance.signOut();
                            _setUser(null);
                          },
                          child: const Text("Logout")),
                    ]
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: CustomNavigationBar(selectedIndex: 0),
    );
  }
}
