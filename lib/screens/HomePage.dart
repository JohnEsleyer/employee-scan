import 'package:employee_scan/widgets/navbar.dart';
import 'package:employee_scan/screens/ShowAttendanceScreen.dart';
import 'package:employee_scan/widgets/CountdownTimerSync.dart';
import 'package:flutter/material.dart';

import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../providers/DBProvider.dart';
import '../providers/InternetProvider.dart';

import 'ScanScreen.dart';

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late InternetProvider internetProvider;
  late SharedPreferences _prefs;
  late int _seconds;
  late bool _auto_sync;

  late DatabaseProvider db_provider;
  String debug = '';
  int _selectedIndex = 1;

  final List<BottomNavigationBarItem> _bottomNavigationBarItems = [
    BottomNavigationBarItem(
      icon: Icon(Icons.people),
      label: 'Attendance',
    ),
    BottomNavigationBarItem(
      icon: Icon(Icons.search),
      label: 'Scan',
    ),
  ];

  void initState() {
    super.initState();
    initPrefs();
  }

  Future<void> initPrefs() async {
    _prefs = await SharedPreferences.getInstance();
    _auto_sync = _prefs.getBool('auto_sync') ?? true;
    int option = _prefs.getInt('seconds') ?? 0;

    if (option == 0) {
      setState(() {
        _seconds = 30;
      });
    } else if (option == 1) {
      setState(() {
        _seconds = 60;
      });
    } else {
      setState(() {
        _seconds = 300;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    db_provider = Provider.of<DatabaseProvider>(context);
    internetProvider = Provider.of<InternetProvider>(context);

    if (internetProvider.isConnected == true) {
      db_provider.sync();
    }

    final GlobalKey<ScaffoldState> _key = GlobalKey();

    return Scaffold(
      key: _key,
      drawer: Navbar(),
      bottomNavigationBar: BottomNavigationBar(
        items: _bottomNavigationBarItems,
        currentIndex: _selectedIndex,
        onTap: (int index) {
          setState(() {
            _selectedIndex = index;
          });
        },
      ),
      appBar: AppBar(
        leading: GestureDetector(
          onTap: () {
            _key.currentState!.openDrawer();
          },
          child: Icon(
            Icons.menu,
            color: Colors.black,
          ),
        ),
        title: const Text(
          'Employee Scan',
          style: TextStyle(
            color: Colors.black,
          ),
        ),
        actions: [
          _auto_sync
              ? internetProvider.isConnected
                  ? Padding(
                      padding: const EdgeInsets.only(right: 15, top: 15),
                      child: CountdownTimerSync(
                        duration: _seconds,
                        onFinished: () async {
                          SharedPreferences _prefs =
                              await SharedPreferences.getInstance();

                          bool is_syncing = _prefs.getBool('syncing') ?? false;
                          if (!is_syncing) {
                            db_provider.sync();
                          }
                        },
                      ),
                    )
                  : Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Column(
                        children: [
                          Icon(Icons.wifi, color: Colors.red),
                          Text(
                            'Disconnected',
                            style: TextStyle(
                              color: Colors.red,
                            ),
                          ),
                        ],
                      ),
                    )
              : Container(),
        ],
        backgroundColor: Colors.white,
      ),
      body: _getBody(),
    );
  }

  Widget _getBody() {
    switch (_selectedIndex) {
      case 0:
        return ShowAttendanceScreen();
      case 1:
        return QRViewScreen();

      default:
        return Container();
    }
  }
}
