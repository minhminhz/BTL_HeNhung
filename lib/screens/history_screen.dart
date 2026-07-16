import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';

class HistoryScreen extends StatelessWidget {
  final bool isAdmin; // 👈 1. Thêm biến nhận diện Admin

  // Yêu cầu bắt buộc phải truyền biến isAdmin vào khi mở màn hình này
  const HistoryScreen({Key? key, required this.isAdmin}) : super(key: key);

  void _showClearHistoryDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xóa Toàn Bộ Lịch Sử', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
        content: const Text('Bạn có chắc chắn muốn dọn dẹp toàn bộ lịch sử đóng/mở cửa không? Hành động này không thể hoàn tác.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              FirebaseDatabase.instance.ref('home/logs').remove();
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Đã dọn sạch lịch sử!'), backgroundColor: Colors.green),
              );
            },
            icon: const Icon(Icons.delete_forever, color: Colors.white),
            label: const Text('Xóa sạch', style: TextStyle(color: Colors.white)),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    DatabaseReference logsRef = FirebaseDatabase.instance.ref('home/logs');

    return Scaffold(
      body: StreamBuilder(
        stream: logsRef.onValue,
        builder: (context, snapshot) {
          if (!snapshot.hasData || snapshot.data!.snapshot.value == null) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.history_toggle_off, size: 80, color: Colors.grey),
                  SizedBox(height: 10),
                  Text('Lịch sử trống', style: TextStyle(fontSize: 18, color: Colors.grey)),
                ],
              ),
            );
          }

          Map<dynamic, dynamic> logsMap = snapshot.data!.snapshot.value as Map<dynamic, dynamic>;
          List<MapEntry> logsList = logsMap.entries.toList().reversed.toList();

          return ListView.builder(
            itemCount: logsList.length,
            itemBuilder: (context, index) {
              var log = logsList[index].value;
              bool isClose = log['action'].toString().contains('Đóng');

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                elevation: 2,
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: isClose ? Colors.red.withOpacity(0.2) : Colors.green.withOpacity(0.2),
                    child: Icon(
                      isClose ? Icons.lock : Icons.lock_open,
                      color: isClose ? Colors.red : Colors.green,
                    ),
                  ),
                  title: Text(log['action'] ?? 'Không rõ', style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text(log['time'] ?? 'No time'),
                  trailing: Text(
                    log['user'] ?? '',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: log['user'] == 'Hệ thống' ? Colors.grey : Colors.blue
                    )
                  ),
                ),
              );
            },
          );
        },
      ),
      // 👈 2. KIỂM TRA QUYỀN TRƯỚC KHI HIỆN NÚT DỌN RÁC
      floatingActionButton: isAdmin
          ? FloatingActionButton(
              onPressed: () => _showClearHistoryDialog(context),
              backgroundColor: Colors.red,
              tooltip: 'Dọn dẹp lịch sử',
              child: const Icon(Icons.delete_sweep, color: Colors.white),
            )
          : null, // Nếu không phải Admin thì ẩn hoàn toàn (trả về null)
    );
  }
}