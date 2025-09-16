import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:pencatatan/pages/auth/login.dart';
import 'package:pencatatan/pages/auth/register.dart';
import 'package:pencatatan/pages/dashboard.dart';
import 'package:pencatatan/pages/pencatatan.dart';
import 'package:pencatatan/pages/profile.dart';
import 'package:pencatatan/pages/formTransaksi.dart';
import 'package:pencatatan/pages/formProfile.dart';
import 'package:toastification/toastification.dart';

Future<void> main() async {
  await dotenv.load(fileName: ".env");
  runApp(ToastificationWrapper(child: const MyApp()));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Pencatatan',
      home: const Login(),
      routes: {
        '/main': (context) => Main(),
        '/login': (context) => Login(),
        '/register': (context) => Register(),
        '/form-transaksi': (context) => FormTransaksi(),
        '/form-profile': (context) => FormProfile(),
      },
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('id', 'ID'), Locale('en', 'US')],
    );
  }
}

class Main extends StatefulWidget {
  final int initialIndex;
  const Main({super.key, this.initialIndex = 0});

  @override
  State<Main> createState() => _MainState();
}

class _MainState extends State<Main> with TickerProviderStateMixin {
  late int _currentIndex;
  late AnimationController _animationController;
  late AnimationController _indicatorController;
  late Animation<double> _indicatorAnimation;

  final List<Widget> _pages = [
    const Dashboard(),
    const Pencatatan(),
    const Profile(),
  ];

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _indicatorController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _indicatorAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _indicatorController, curve: Curves.elasticOut),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    _indicatorController.dispose();
    super.dispose();
  }

  void _onTabTapped(int index) {
    if (_currentIndex != index) {
      _indicatorController.forward().then((_) {
        _indicatorController.reverse();
      });
      setState(() {
        _currentIndex = index;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_currentIndex],
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              spreadRadius: 0,
              blurRadius: 30,
              offset: const Offset(0, -8),
            ),
          ],
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: SizedBox(
              height: 65,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildMinimalNavItem(
                    0,
                    Icons.home_outlined,
                    Icons.home,
                    'Dashboard',
                  ),
                  _buildMinimalNavItem(
                    1,
                    Icons.receipt_long_outlined,
                    Icons.receipt_long,
                    'Pencatatan',
                  ),
                  _buildMinimalNavItem(
                    2,
                    Icons.person_outline,
                    Icons.person,
                    'Profile',
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMinimalNavItem(
    int index,
    IconData outlineIcon,
    IconData filledIcon,
    String label,
  ) {
    final bool isSelected = _currentIndex == index;

    return Expanded(
      child: GestureDetector(
        onTap: () => _onTabTapped(index),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              width: isSelected ? 24 : 0,
              height: 2,
              margin: const EdgeInsets.only(bottom: 4),
              decoration: BoxDecoration(
                color: const Color(0xFF2a5298),
                borderRadius: BorderRadius.circular(1),
              ),
            ),
            // Icon
            AnimatedScale(
              scale: isSelected ? 1.05 : 1.0,
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOutBack,
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: isSelected
                      ? const Color(0xFF2a5298).withOpacity(0.1)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 150),
                  transitionBuilder: (child, animation) {
                    return ScaleTransition(scale: animation, child: child);
                  },
                  child: Icon(
                    isSelected ? filledIcon : outlineIcon,
                    key: ValueKey('${index}_$isSelected'),
                    color: isSelected
                        ? const Color(0xFF2a5298)
                        : Colors.grey[400],
                    size: 22,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 4),
            AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 200),
              style: TextStyle(
                fontSize: isSelected ? 10.5 : 9.5,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                color: isSelected ? const Color(0xFF2a5298) : Colors.grey[500],
                letterSpacing: isSelected ? 0.3 : 0,
              ),
              child: Text(
                label,
                textAlign: TextAlign.center,
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
