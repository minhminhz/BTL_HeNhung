import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'firebase_options.dart';
import 'package:firebase_database/firebase_database.dart';
// Import các màn hình từ thư mục screens
import 'screens/control_screen.dart';
import 'screens/users_screen.dart';
import 'screens/otp_screen.dart';
import 'screens/history_screen.dart';
import 'screens/password_screen.dart';

import 'screens/login_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();


  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(const SmartDoorApp());
}

class SmartDoorApp extends StatelessWidget {
  const SmartDoorApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Smart Door IoT',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blueAccent,
          brightness: Brightness.light,
        ),
        appBarTheme: const AppBarTheme(
          centerTitle: true,
          elevation: 0,
          backgroundColor: Colors.transparent,
          foregroundColor: Colors.black87,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            elevation: 2,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        cardTheme: CardThemeData(
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
      ),
      debugShowCheckedModeBanner: false,
      home: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasData) {
            return const MainScreen();
          }

          return const LoginScreen();
        },
      ),
    );
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({Key? key}) : super(key: key);

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;
  bool _isLoading = true;
  String _userRole = 'unauthorized';
  String _userName = '';

  StreamSubscription? _userSubscription;

  @override
  void initState() {
    super.initState();
    _listenUserPermission();
  }

  @override
  void dispose() {
    _userSubscription?.cancel();
    super.dispose();
  }

  void _listenUserPermission() {
    User? currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      setState(() => _isLoading = false);
      return;
    }

    String currentEmail = currentUser.email ?? '';
    DatabaseReference usersRef = FirebaseDatabase.instance.ref('home/users');

    // Lắng nghe thay đổi quyền theo thời gian thực
    _userSubscription = usersRef.orderByChild('email').equalTo(currentEmail.toLowerCase()).onValue.listen((event) {
      if (mounted) {
        if (event.snapshot.value != null) {
          Map<dynamic, dynamic> usersData = event.snapshot.value as Map<dynamic, dynamic>;
          var userData = usersData.values.first;

          setState(() {
            _userRole = userData['role'] ?? 'unauthorized';
            _userName = userData['name'] ?? 'Thành viên';
            _isLoading = false;
          });
        } else {
          setState(() {
            _userRole = 'unauthorized';
            _isLoading = false;
          });
        }
      }
    }, onError: (error) {
      debugPrint("Lỗi Firebase: $error");
      if (mounted) {
        setState(() {
          _isLoading = false;
          _userRole = 'error';
        });
      }
    });
  }
  // HÀM HIỆN KHUNG ĐỔI MẬT KHẨU TÀI KHOẢN
    void _showChangePasswordDialog(BuildContext context) {
      TextEditingController newPassController = TextEditingController();

      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Đổi Mật Khẩu Đăng Nhập'),
          content: TextField(
            controller: newPassController,
            obscureText: true, // Che mật khẩu bằng dấu sao
            decoration: const InputDecoration(
              labelText: 'Nhập mật khẩu mới (Ít nhất 6 ký tự)',
              prefixIcon: Icon(Icons.lock),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Hủy')),
            ElevatedButton(
              onPressed: () async {
                if (newPassController.text.length < 6) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Mật khẩu phải từ 6 ký tự trở lên!'), backgroundColor: Colors.orange));
                  return;
                }
                try {
                  // Lệnh đổi pass của Firebase
                  await FirebaseAuth.instance.currentUser?.updatePassword(newPassController.text);
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Đổi mật khẩu thành công!'), backgroundColor: Colors.green));
                } on FirebaseAuthException catch (e) {
                  // Lỗi thường gặp: Firebase bắt phải đăng nhập lại mới cho đổi pass (Vì lý do bảo mật)
                  if (e.code == 'requires-recent-login') {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Bảo mật: Vui lòng Đăng xuất và Đăng nhập lại để thực hiện đổi mật khẩu!'), backgroundColor: Colors.red));
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message ?? 'Lỗi đổi pass'), backgroundColor: Colors.red));
                  }
                }
              },
              child: const Text('Cập nhật'),
            )
          ],
        ),
      );
    }

  @override
  Widget build(BuildContext context) {
    // 1. NẾU ĐANG TẢI DỮ LIỆU THÌ HIỆN VÒNG QUAY
    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 20),
              Text("Đang kiểm tra quyền truy cập..."),
            ],
          ),
        ),
      );
    }

    // 2. NẾU CÓ LỖI KẾT NỐI FIREBASE
    if (_userRole == 'error') {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 80, color: Colors.red),
              const SizedBox(height: 20),
              const Text("Lỗi kết nối Database!", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const Padding(
                padding: EdgeInsets.all(20),
                child: Text("Vui lòng kiểm tra lại cấu hình Rules trên Firebase hoặc kết nối mạng của bạn.", textAlign: TextAlign.center),
              ),
              ElevatedButton(onPressed: _listenUserPermission, child: const Text("Thử lại")),
              TextButton(onPressed: () => FirebaseAuth.instance.signOut(), child: const Text("Đăng xuất và dùng email khác")),
            ],
          ),
        ),
      );
    }

    // 3. NẾU LÀ TÀI KHOẢN RÁC (CHƯA ĐƯỢC ADMIN THÊM VÀO)
    if (_userRole == 'unauthorized') {
      return Scaffold(
        appBar: AppBar(title: const Text('Truy cập bị từ chối')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.security_rounded, size: 100, color: Colors.red),
              const SizedBox(height: 20),
              const Text(
                'Tài khoản chưa được cấp quyền!',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              const Padding(
                padding: EdgeInsets.all(20.0),
                child: Text(
                  'Bạn đã đăng ký tài khoản thành công, nhưng hệ thống chưa ghi nhận bạn là thành viên của ngôi nhà này. Vui lòng liên hệ Admin để được thêm vào danh sách.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16),
                ),
              ),
              ElevatedButton.icon(
                onPressed: () => FirebaseAuth.instance.signOut(),
                icon: const Icon(Icons.logout),
                label: const Text('Đăng xuất'),
              )
            ],
          ),
        ),
      );
    }

    bool isAdmin = _userRole == 'admin';

    final List<Widget> screens = isAdmin
      ? const [ControlScreen(), UsersScreen(), OtpScreen(), HistoryScreen(isAdmin:true), PasswordScreen()]
      : const [ControlScreen(), HistoryScreen(isAdmin:false)];

    final List<BottomNavigationBarItem> navItems = isAdmin
      ? const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Điều khiển'),
          BottomNavigationBarItem(icon: Icon(Icons.people), label: 'Thành viên'),
          BottomNavigationBarItem(icon: Icon(Icons.vpn_key), label: 'OTP'),
          BottomNavigationBarItem(icon: Icon(Icons.history), label: 'Lịch sử'),
          BottomNavigationBarItem(icon: Icon(Icons.settings), label: 'Mật khẩu'),
        ]
      : const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Điều khiển'),
          BottomNavigationBarItem(icon: Icon(Icons.history), label: 'Lịch sử'),
        ];


    if (_currentIndex >= screens.length) {
      _currentIndex = 0;
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(isAdmin ? 'Admin Dashboard' : 'Nhà của $_userName'),
        backgroundColor: isAdmin ? Colors.blue : Colors.green,
        actions: [
           PopupMenuButton<String>(
                       icon: const Icon(Icons.account_circle, size: 30, color: Colors.white),
                       onSelected: (value) async {
                         if (value == 'logout') {
                           await FirebaseAuth.instance.signOut();
                         } else if (value == 'change_password') {
                           _showChangePasswordDialog(context);
                         }
                       },
                       itemBuilder: (BuildContext context) => [
                         const PopupMenuItem(
                           value: 'change_password',
                           child: ListTile(leading: Icon(Icons.password, color: Colors.blue), title: Text('Đổi mật khẩu App')),
                         ),
                       ],
                     ),
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Đăng xuất',
            onPressed: () async => await FirebaseAuth.instance.signOut(),
          ),
        ],
      ),
      body: screens[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: isAdmin ? Colors.blue : Colors.green,
        onTap: (index) => setState(() => _currentIndex = index),
        items: navItems,
      ),
    );
  }
}