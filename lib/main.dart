import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:google_sign_in/google_sign_in.dart';

void main() {
  runApp(TeeMatesApp());
}

class TeeMatesApp extends StatefulWidget {
  @override
  _TeeMatesAppState createState() => _TeeMatesAppState();
}

class _TeeMatesAppState extends State<TeeMatesApp> {
  bool _loggedIn = false;
  final _secureStorage = FlutterSecureStorage();

  @override
  void initState() {
    super.initState();
    _checkLoginStatus();
  }

  Future<void> _checkLoginStatus() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _loggedIn = prefs.getBool('loggedIn') ?? false;
    });
  }

  Future<void> _login(String name, String email) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('loggedIn', true);
    await _secureStorage.write(key: 'user_name', value: name);
    await _secureStorage.write(key: 'user_email', value: email);
    setState(() {
      _loggedIn = true;
    });
  }

  void _logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('loggedIn', false);
    setState(() {
      _loggedIn = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'TeeMates',
      theme: ThemeData(
        fontFamily: 'Inter',
        textTheme: TextTheme(
          bodyMedium: TextStyle(
            fontFamily: 'Inter',
            fontWeight: FontWeight.w400,
            fontStyle: FontStyle.normal,
            fontSize: 12,
            color: Colors.black,
          ),
          titleLarge: TextStyle(
            fontFamily: 'Inter',
            fontWeight: FontWeight.w900,
            fontSize: 16,
            color: Colors.black,
          ),
          bodySmall: TextStyle(
            fontFamily: 'Inter',
            fontWeight: FontWeight.w400,
            fontSize: 12,
            color: Color(0xFF919194),
          ),
        ),
      ),
      home: _loggedIn
          ? MainMenu(onLogout: _logout)
          : LoginPage(onLogin: _login),
    );
  }
}

class LoginPage extends StatelessWidget {
  final Function(String, String) onLogin;
  LoginPage({required this.onLogin});

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();

  Future<void> _loginWithApple(BuildContext context) async {
    try {
      final credential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
      );
      final name = credential.givenName ?? '';
      final email = credential.email ?? '';
      if (email.isNotEmpty) {
        onLogin(name, email);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Apple sign-in did not return an email.')),
        );
      }
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Apple sign-in failed: \$error')),
      );
    }
  }

  Future<void> _loginWithGoogle(BuildContext context) async {
    final GoogleSignIn googleSignIn = GoogleSignIn();
    try {
      final GoogleSignInAccount? account = await googleSignIn.signIn();
      if (account != null) {
        onLogin(account.displayName ?? '', account.email);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Google sign-in cancelled.')),
        );
      }
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Google sign-in failed: \$error')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Login')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton.icon(
              icon: Icon(Icons.apple),
              label: Text('Sign in with Apple'),
              onPressed: () => _loginWithApple(context),
            ),
            // Removed vertical space between menu items
            ElevatedButton.icon(
              icon: Icon(Icons.g_mobiledata),
              label: Text('Sign in with Google'),
              onPressed: () => _loginWithGoogle(context),
            ),
            // Removed vertical space between menu items
            TextField(
              controller: _nameController,
              decoration: InputDecoration(labelText: 'Name'),
            ),
            // Removed vertical space between menu items
            TextField(
              controller: _emailController,
              decoration: InputDecoration(labelText: 'Email'),
              keyboardType: TextInputType.emailAddress,
            ),
            // Removed vertical space between menu items
            ElevatedButton(
              onPressed: () {
                final name = _nameController.text.trim();
                final email = _emailController.text.trim();
                if (name.isNotEmpty && email.isNotEmpty) {
                  onLogin(name, email);
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Please enter both name and email')),
                  );
                }
              },
              child: Text('Login with Email'),
            ),
          ],
        ),
      ),
    );
  }
}

class MainMenu extends StatefulWidget {
  final VoidCallback onLogout;
  MainMenu({required this.onLogout});

  @override
  _MainMenuState createState() => _MainMenuState();
}

class _MainMenuState extends State<MainMenu> {
  int _selectedIndex = 0;
  late final List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    _pages = [
      TeeMatesPage(),
      PlayPage(),
      BookPage(),
      SearchPage(),
      YouPage(onLogout: widget.onLogout),
    ];
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF5F5F5),
      body: _pages[_selectedIndex],
      bottomNavigationBar: Container(
        color: Colors.white,
        height: 100, // Increased height for a taller main menu
        child: Column(
          children: [
            Expanded(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildCustomNavItem(null, 'TeeMates', 0),
                  _buildCustomNavItem(Icons.golf_course, 'Play', 1),
                  _buildCustomNavItem(Icons.book_online, 'Book', 2),
                  _buildCustomNavItem(Icons.search, 'Search', 3),
                  _buildCustomNavItem(Icons.person, 'You', 4),
                ],
              ),
            ),
            Container(
              height: 16, // Extra white space below menu
              color: Colors.white,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCustomNavItem(IconData? icon, String label, int index) {
    final bool isSelected = _selectedIndex == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => _onItemTapped(index),
        child: Container(
          color: isSelected ? Colors.white : Color(0xFFF8F8F8),
          height: double.infinity,
          padding: EdgeInsets.symmetric(vertical: 8), // Add vertical space above and below
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (icon != null)
                Icon(
                  icon,
                  color: isSelected ? Color(0xFF3F768E) : Colors.black54,
                ),
              if (label == 'TeeMates') ...[
                Text(
                  label,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontWeight: FontWeight.w900,
                    fontStyle: FontStyle.normal,
                    fontSize: 12,
                    color: isSelected ? Color(0xFF3F768E) : Colors.black,
                  ),
                ),
                Text(
                  'Home',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontWeight: FontWeight.w400,
                    fontStyle: FontStyle.normal,
                    fontSize: 12,
                    color: isSelected ? Color(0xFF3F768E) : Colors.black,
                  ),
                ),
              ] else ...[
                Text(
                  label,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontWeight: FontWeight.w400,
                    fontStyle: FontStyle.normal,
                    fontSize: 12,
                    color: isSelected ? Color(0xFF3F768E) : Colors.black,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}



class TeeMatesPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      color: Color(0xFFF5F5F5),
      child: Center(child: Text('TeeMates Startpage')),
    );
  }
}

class PlayPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      color: Color(0xFFF5F5F5),
      child: Center(child: Text('Play Page')),
    );
  }
}

class BookPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      color: Color(0xFFF5F5F5),
      child: Center(child: Text('Book Page')),
    );
  }
}

class SearchPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      color: Color(0xFFF5F5F5),
      child: Center(child: Text('Search Page')),
    );
  }
}

class YouPage extends StatelessWidget {
  final VoidCallback? onLogout;
  YouPage({this.onLogout});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF5F5F5),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(
            icon: Icon(Icons.settings),
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: Text('Settings'),
                  content: Text('Do you want to log out?'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: Text('Cancel'),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                        if (onLogout != null) onLogout!();
                      },
                      child: Text('Logout'),
                    ),
                  ],
                ),
              );
            },
          ),
          SizedBox(height: 16),
          Center(child: Text('You Page')),
        ],
      ),
    );
  }
}
