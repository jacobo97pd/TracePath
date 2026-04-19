import 'package:flutter/material.dart';

// Global on-screen log. Set kShowStartupDiagnostics = false before shipping.
const bool kShowStartupDiagnostics = false;

final ValueNotifier<List<String>> _logs = ValueNotifier<List<String>>([]);

void slog(String msg) {
  final t = DateTime.now();
  final ts =
      '${t.minute.toString().padLeft(2, '0')}:${t.second.toString().padLeft(2, '0')}.${t.millisecond.toString().padLeft(3, '0')}';
  final line = '$ts $msg';
  debugPrint('[DIAG] $line');
  if (!kShowStartupDiagnostics) return;
  final next = List<String>.from(_logs.value)..add(line);
  if (next.length > 40) next.removeAt(0);
  _logs.value = next;
}

/// Drop this widget anywhere in the tree — it paints a translucent black log
/// panel over the top half of the screen showing every slog() call in real time.
class DiagnosticsOverlay extends StatelessWidget {
  const DiagnosticsOverlay({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (!kShowStartupDiagnostics) return child;
    return Stack(
      children: [
        child,
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          bottom: 0,
          child: IgnorePointer(
            child: ValueListenableBuilder<List<String>>(
              valueListenable: _logs,
              builder: (context, logs, _) {
                return Container(
                  color: Colors.black.withAlpha(200),
                  padding: const EdgeInsets.fromLTRB(8, 52, 8, 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '▶ STARTUP DIAG',
                        style: TextStyle(
                          color: Colors.yellowAccent,
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Expanded(
                        child: ListView.builder(
                          itemCount: logs.length,
                          itemBuilder: (_, i) => Text(
                            logs[i],
                            style: const TextStyle(
                              color: Colors.greenAccent,
                              fontSize: 11,
                              height: 1.3,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}
