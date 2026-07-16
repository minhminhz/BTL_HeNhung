import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';

class PasswordScreen extends StatefulWidget {
  const PasswordScreen({Key? key}) : super(key: key);

  @override
  State<PasswordScreen> createState() => _PasswordScreenState();
}

class _PasswordScreenState extends State<PasswordScreen> {
  final TextEditingController _passController = TextEditingController();
  final DatabaseReference _dbRef = FirebaseDatabase.instance.ref('home/config/door_password');
  String _currentPassword = "Đang tải...";

  @override
  void initState() {
    super.initState();
    _loadCurrentPassword();
  }

  // Hàm lắng nghe mật khẩu hiện tại từ Firebase
  void _loadCurrentPassword() {
    _dbRef.onValue.listen((event) {
      if (event.snapshot.value != null) {
        if (mounted) {
          setState(() {
            _currentPassword = event.snapshot.value.toString();
          });
        }
      }
    });
  }

  // Hàm đẩy mật khẩu mới lên Firebase
  void _changePassword() {
    if (_passController.text.isNotEmpty) {
      _dbRef.set(_passController.text).then((_) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Đổi mật khẩu thành công!'),
            backgroundColor: Colors.green
          ),
        );
        _passController.clear();
        // Ẩn bàn phím sau khi lưu
        FocusScope.of(context).unfocus();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.password, size: 80, color: Colors.blueGrey),
          const SizedBox(height: 20),

          // Hiển thị mật khẩu hiện tại
          Text(
            'Mật khẩu cửa hiện tại: $_currentPassword',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.red),
          ),
          const SizedBox(height: 40),

          // Ô nhập mật khẩu mới
          TextField(
            controller: _passController,
            decoration: const InputDecoration(
              labelText: 'Nhập mật khẩu mới',
              hintText: 'VD: 123456',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.lock_outline),
            ),
            keyboardType: TextInputType.number, // Chỉ cho phép nhập số
          ),
          const SizedBox(height: 20),

          // Nút lưu
          ElevatedButton(
            onPressed: _changePassword,
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(double.infinity, 50),
              backgroundColor: Colors.blue,
            ),
            child: const Text('CẬP NHẬT MẬT KHẨU', style: TextStyle(fontSize: 16, color: Colors.white, fontWeight: FontWeight.bold)),
          )
        ],
      ),
    );
  }
}