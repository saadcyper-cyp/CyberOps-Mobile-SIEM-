import 'package:flutter/material.dart';
import '../security_entry_screen.dart';

class SecurityWrapper extends StatefulWidget {
  final Widget child;
  const SecurityWrapper({super.key, required this.child});

  @override
  State<SecurityWrapper> createState() => _SecurityWrapperState();
}

class _SecurityWrapperState extends State<SecurityWrapper> with WidgetsBindingObserver {
  bool _isLocked = false;

  @override
  void initState() {
    super.initState();
    // تفعيل مراقب نظام أندرويد
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // نلاحظ أن وضع inactive يحدث عند ظهور بصمة الإصبع أو سحب القائمة العلوية
    // لذا يفضل القفل فقط عند paused (خروج كامل للخلفية)
    if (state == AppLifecycleState.paused) {
      if (!_isLocked) {
        setState(() {
          _isLocked = true;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // واجهة التطبيق الأصلية
        widget.child,

        // إذا تم القفل، تظهر شاشة الـ PIN فوق كل شيء
        if (_isLocked)
          Positioned.fill(
            child: SecurityEntryScreen(
              // نمرر هذه الدالة لإخفاء القفل عند نجاح المستخدم
              onAuthenticated: () {
                setState(() {
                  _isLocked = false;
                });
              },
            ),
          ),
      ],
    );
  }
}