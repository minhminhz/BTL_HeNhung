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
                        DropdownMenuItem(value: 'member', child: Text('Thành viên (Member)', style: TextStyle(color: Colors.green))),
                        DropdownMenuItem(value: 'unauthorized', child: Text('Chờ duyệt / Từ chối', style: TextStyle(color: Colors.grey))),
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
      backgroundColor: Colors.grey.shade50,
      body: StreamBuilder(
        stream: usersRef.onValue,
        builder: (context, snapshot) {
          if (!snapshot.hasData || snapshot.data!.snapshot.value == null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.people_outline, size: 80, color: Colors.grey.shade300),
                  const SizedBox(height: 16),
                  const Text('Chưa có thành viên nào', style: TextStyle(fontSize: 16, color: Colors.grey)),
                ],
              ),
            );
          }

          Map<dynamic, dynamic> usersMap = snapshot.data!.snapshot.value as Map<dynamic, dynamic>;
          List<MapEntry> usersList = usersMap.entries.toList();

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: usersList.length,
            itemBuilder: (context, index) {
              var user = usersList[index].value;
              var key = usersList[index].key;
              String role = user['role'] ?? 'unauthorized';
              
              bool isAdmin = role == 'admin';
              bool isUnauthorized = role == 'unauthorized';

              return Card(
                elevation: 0,
                color: Colors.white,
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                  side: BorderSide(
                    color: isUnauthorized ? Colors.orange.shade200 : Colors.grey.shade200,
                    width: isUnauthorized ? 2 : 1,
                  ),
                ),
                child: InkWell(
                  borderRadius: BorderRadius.circular(20),
                  onTap: () => _showUserDialog(
                    context,
                    userKey: key,
                    currentName: user['name'],
                    currentEmail: user['email'],
                    currentRole: user['role'],
                    currentRfid: user['rfid_code'],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Container(
                          width: 50,
                          height: 50,
                          decoration: BoxDecoration(
                            color: isAdmin 
                              ? Colors.red.shade50 
                              : (isUnauthorized ? Colors.orange.shade50 : Colors.blue.shade50),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            isAdmin ? Icons.admin_panel_settings : (isUnauthorized ? Icons.person_add_disabled : Icons.person),
                            color: isAdmin 
                              ? Colors.red 
                              : (isUnauthorized ? Colors.orange : Colors.blue),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    user['name'] ?? 'Unknown',
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                  ),
                                  if (isUnauthorized)
                                    Container(
                                      margin: const EdgeInsets.only(left: 8),
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: Colors.orange,
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: const Text(
                                        'CHỜ DUYỆT',
                                        style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                user['email'] ?? '',
                                style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                              ),
                              if (isUnauthorized)
                                Padding(
                                  padding: const EdgeInsets.only(top: 8),
                                  child: ElevatedButton.icon(
                                    onPressed: () {
                                      usersRef.child(key).update({'role': 'member'});
                                    },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.green,
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                      minimumSize: Size.zero,
                                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                    ),
                                    icon: const Icon(Icons.check, size: 16),
                                    label: const Text('Duyệt ngay', style: TextStyle(fontSize: 12)),
                                  ),
                                ),
                              if (user['rfid_code'] != null && user['rfid_code'].toString().isNotEmpty)
                                Padding(
                                  padding: const EdgeInsets.only(top: 4),
                                  child: Row(
                                    children: [
                                      const Icon(Icons.nfc, size: 14, color: Colors.blue),
                                      const SizedBox(width: 4),
                                      Text(
                                        'RFID: ${user['rfid_code']}',
                                        style: const TextStyle(fontSize: 12, color: Colors.blue, fontWeight: FontWeight.w500),
                                      ),
                                    ],
                                  ),
                                ),
                            ],
                          ),
                        ),
                        Column(
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit_outlined, color: Colors.blue),
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
                              icon: const Icon(Icons.delete_outline, color: Colors.red),
                              onPressed: () {
                                showDialog(
                                  context: context,
                                  builder: (ctx) => AlertDialog(
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                                    title: const Text('Xác nhận xóa'),
                                    content: Text('Bạn có chắc muốn xóa tài khoản ${user['name']}?'),
                                    actions: [
                                      TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Hủy')),
                                      ElevatedButton(
                                        style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                                        onPressed: () {
                                          usersRef.child(key).remove();
                                          Navigator.pop(ctx);
                                        }, 
                                        child: const Text('Xóa', style: TextStyle(color: Colors.white))
                                      ),
                                    ],
                                  )
                                );
                              },
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showUserDialog(context),
        backgroundColor: Colors.blue.shade700,
        icon: const Icon(Icons.person_add_alt_1, color: Colors.white),
        label: const Text('Thêm mới', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
    );
  }
}