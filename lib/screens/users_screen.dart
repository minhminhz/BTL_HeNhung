import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'dart:async';
class UsersScreen extends StatelessWidget {
  const UsersScreen({Key? key}) : super(key: key);

  void _showUserDialog(BuildContext context, {String? userKey, String? currentName, String? currentRfid, String? currentEmail, String? currentRole}) {
      bool isEdit = userKey != null;

      TextEditingController nameController = TextEditingController(text: currentName ?? '');
      TextEditingController rfidController = TextEditingController(text: currentRfid ?? '');
      TextEditingController emailController = TextEditingController(text: currentEmail ?? '');
      String role = currentRole ?? 'member';
      DatabaseReference db = FirebaseDatabase.instance.ref();

      StreamSubscription<DatabaseEvent>? rfidSubscription;

      showDialog(
        context: context,
        builder: (context) => StatefulBuilder(
          builder: (context, setState) {

            // LẮNG NGHE REAL-TIME: Hễ ESP32 đẩy mã mới lên là tự động gán vào ô Text
            rfidSubscription ??= db.child('home/config/last_scanned_rfid').onValue.listen((event) {
                if (event.snapshot.value != null) {
                  // Tự động điền mã thẻ vào ô nhập liệu mà không cần bấm nút
                  rfidController.text = event.snapshot.value.toString();
                }
              });

            return AlertDialog(
              title: Text(isEdit ? 'Sửa Thông Tin' : 'Thêm Thành Viên', style: const TextStyle(fontWeight: FontWeight.bold)),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(controller: nameController, decoration: const InputDecoration(labelText: 'Tên thành viên', prefixIcon: Icon(Icons.person))),
                    const SizedBox(height: 10),
                    TextField(controller: emailController, keyboardType: TextInputType.emailAddress, decoration: const InputDecoration(labelText: 'Email đăng nhập', prefixIcon: Icon(Icons.email))),
                    const SizedBox(height: 10),
                    DropdownButtonFormField<String>(
                      value: role,
                      decoration: const InputDecoration(labelText: 'Quyền hạn', prefixIcon: Icon(Icons.admin_panel_settings)),
                      items: const [
                        DropdownMenuItem(value: 'admin', child: Text('Quản trị viên (Admin)', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold))),
                        DropdownMenuItem(value: 'member', child: Text('Thành viên (Member)')),
                      ],
                      onChanged: (value) => setState(() => role = value!),
                    ),
                    const SizedBox(height: 10),

                    // Ô nhập RFID bây giờ sẽ tự động nhảy số khi quẹt thẻ!
                    TextField(
                      controller: rfidController,
                      decoration: const InputDecoration(
                        labelText: 'Mã thẻ RFID (Quẹt thẻ để tự điền)',
                        prefixIcon: Icon(Icons.nfc, color: Colors.blue),
                        filled: true,
                        fillColor: Colors.black12, // Đổi màu xám nhẹ cho ngầu
                      )
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(context), child: const Text('Hủy')),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: isEdit ? Colors.orange : Colors.blue),
                  onPressed: () {
                    if (nameController.text.isNotEmpty && emailController.text.isNotEmpty) {
                      Map<String, dynamic> userData = {
                        'name': nameController.text.trim(),
                        'email': emailController.text.trim().toLowerCase(),
                        'role': role,
                        'rfid_code': rfidController.text.trim(),
                      };
                      if (isEdit) {
                        db.child('home/users/$userKey').update(userData);
                      } else {
                        db.child('home/users').push().set(userData);
                      }
                      Navigator.pop(context);
                    }
                  },
                  child: Text(isEdit ? 'Cập Nhật' : 'Lưu', style: const TextStyle(color: Colors.white)),
                )
              ],
            );
          }
        ),
      ).then((_) {
        // CỰC KỲ QUAN TRỌNG: Đóng Dialog thì phải tắt lắng nghe để đỡ tốn RAM
        rfidSubscription?.cancel();
      });
    }

  @override
  Widget build(BuildContext context) {
    DatabaseReference usersRef = FirebaseDatabase.instance.ref('home/users');

    return Scaffold(
      body: StreamBuilder(
        stream: usersRef.onValue,
        builder: (context, snapshot) {
          if (!snapshot.hasData || snapshot.data!.snapshot.value == null) {
            return const Center(child: Text('Chưa có thành viên nào', style: TextStyle(fontSize: 18, color: Colors.grey)));
          }

          Map<dynamic, dynamic> usersMap = snapshot.data!.snapshot.value as Map<dynamic, dynamic>;
          List<MapEntry> usersList = usersMap.entries.toList();

          return ListView.builder(
            itemCount: usersList.length,
            itemBuilder: (context, index) {
              var user = usersList[index].value;
              var key = usersList[index].key;
              bool isAdmin = user['role'] == 'admin';

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: isAdmin ? Colors.redAccent : Colors.blueAccent,
                    child: Icon(isAdmin ? Icons.admin_panel_settings : Icons.person, color: Colors.white)
                  ),
                  title: Text(user['name'] ?? 'Unknown', style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text('${user['email']}\nRFID: ${user['rfid_code'] ?? 'Trống'}'),
                  isThreeLine: true,
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit, color: Colors.orange),
                        onPressed: () => _showUserDialog(
                          context,
                          userKey: key,
                          currentName: user['name'],
                          currentEmail: user['email'],
                          currentRole: user['role'],
                          currentRfid: user['rfid_code'],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () => usersRef.child(key).remove(),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showUserDialog(context),
        backgroundColor: Colors.blue,
        child: const Icon(Icons.person_add, color: Colors.white),
      ),
    );
  }
}