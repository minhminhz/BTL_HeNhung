import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLogin = true; // true: Đang ở chế độ Đăng nhập, false: Chế độ Đăng ký
  bool _isLoading = false;
  bool _isPasswordVisible =false;
  void _submitAuth() async {
    setState(() => _isLoading = true);
    try {
      if (_isLogin) {
        // ĐĂNG NHẬP
        await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
        );
      } else {
        // ĐĂNG KÝ TÀI KHOẢN MỚI
        await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
        );
      }
      // Không cần dùng Navigator ở đây vì đã có StreamBuilder ở main.dart lo
    } on FirebaseAuthException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message ?? 'Có lỗi xảy ra!'), backgroundColor: Colors.red),
      );
    }
    if(mounted){
        setState(() => _isLoading = false);
    }
  }

  // Hàm xử lý Quên mật khẩu
  void _resetPassword() async {
    final email = _emailController.text.trim();
    if (email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng nhập Email của bạn vào ô bên trên để nhận link khôi phục!'), backgroundColor: Colors.orange),
      );
      return;
    }

    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Đã gửi link khôi phục! Vui lòng kiểm tra hộp thư Email của bạn.'), backgroundColor: Colors.green),
      );
    } on FirebaseAuthException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message ?? 'Lỗi khi gửi email khôi phục!'), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(30),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.home_work, size: 100, color: Colors.blue),
              const SizedBox(height: 20),
              Text(
                _isLogin ? 'ĐĂNG NHẬP HỆ THỐNG' : 'TẠO TÀI KHOẢN MỚI',
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 40),

              // Ô nhập Email
              TextField(
                controller: _emailController,
                decoration: const InputDecoration(labelText: 'Email', border: OutlineInputBorder(), prefixIcon: Icon(Icons.email)),
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 20),

              // Ô nhập Mật khẩu
              TextField(
                controller: _passwordController,
                obscureText: !_isPasswordVisible,
                decoration:  InputDecoration(
                    labelText: 'Mật khẩu',
                    border: const OutlineInputBorder(),
                    prefixIcon: const Icon(Icons.lock),
                    suffixIcon: IconButton(
                        icon: Icon(
                            _isPasswordVisible ? Icons.visibility : Icons.visibility_off,
                            color: Colors.grey,
                        ),
                        onPressed:(){
                            setState((){
                                _isPasswordVisible = !_isPasswordVisible;
                            });
                        }
                    )
                ),
              ),
              const SizedBox(height: 30),

              // Nút Bấm Xử lý
              _isLoading
                  ? const CircularProgressIndicator()
                  : ElevatedButton(
                      onPressed: _submitAuth,
                      style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 50)),
                      child: Text(_isLogin ? 'ĐĂNG NHẬP' : 'ĐĂNG KÝ', style: const TextStyle(fontSize: 18)),
                    ),

              const SizedBox(height: 10), // Thêm khoảng trắng cho thoáng

              // Nút Đổi chế độ Đăng nhập / Đăng ký
              TextButton(
                onPressed: () => setState(() => _isLogin = !_isLogin),
                child: Text(
                  _isLogin ? 'Chưa có tài khoản? Đăng ký ngay' : 'Đã có tài khoản? Quay lại đăng nhập',
                  style: const TextStyle(color: Colors.blue)
                ),
              ),

              // NÚT QUÊN MẬT KHẨU (Chỉ hiện khi đang ở chế độ Đăng nhập)
              if (_isLogin)
                TextButton(
                  onPressed: _resetPassword,
                  child: const Text('Quên mật khẩu?', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                ),
            ],
          ),
        ),
      ),
    );
  }
}