import 'dart:convert';
import 'dart:io' show Platform;

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

void main() {
  runApp(const CalculatorApp());
}

class CalculatorApp extends StatelessWidget {
  const CalculatorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Pura Calculator',
      debugShowCheckedModeBanner: false,
      themeMode: ThemeMode.system,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF0284C7)),
        useMaterial3: true,
      ),
      darkTheme: ThemeData.dark(useMaterial3: true),
      home: const CalculatorPage(),
    );
  }
}

class CalculatorPage extends StatefulWidget {
  const CalculatorPage({super.key});

  @override
  State<CalculatorPage> createState() => _CalculatorPageState();
}

class _CalculatorPageState extends State<CalculatorPage> {
  static String get backendBaseUrl {
    if (Platform.isAndroid) {
      return 'http://10.0.2.2:8000';
    }
    return 'http://127.0.0.1:8000';
  }

  String input = '';
  String result = '0';
  bool loading = false;
  List<Map<String, dynamic>> history = <Map<String, dynamic>>[];

  final List<String> buttons = <String>[
    'C',
    'DEL',
    '%',
    '÷',
    '7',
    '8',
    '9',
    '×',
    '4',
    '5',
    '6',
    '-',
    '1',
    '2',
    '3',
    '+',
    '^',
    '0',
    '.',
    '=',
  ];

  bool _isOperator(String value) {
    return <String>['+', '-', '×', '÷', '%', '^'].contains(value);
  }

  void _onButtonTap(String value) async {
    if (loading) {
      return;
    }

    if (value == 'C') {
      setState(() {
        input = '';
        result = '0';
      });
      return;
    }

    if (value == 'DEL') {
      if (input.isNotEmpty) {
        setState(() {
          input = input.substring(0, input.length - 1);
        });
      }
      return;
    }

    if (value == '=') {
      if (input.trim().isEmpty) {
        return;
      }
      await _calculate();
      return;
    }

    setState(() {
      input += value;
    });
  }

  String _normalizeExpression(String expression) {
    return expression.replaceAll('×', '*').replaceAll('÷', '/');
  }

  Future<void> _calculate() async {
    setState(() {
      loading = true;
    });

    try {
      final String normalized = _normalizeExpression(input);

      final http.Response response = await http.post(
        Uri.parse('$backendBaseUrl/calculate'),
        headers: <String, String>{'Content-Type': 'application/json'},
        body: jsonEncode(<String, String>{'expression': normalized}),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data =
            jsonDecode(response.body) as Map<String, dynamic>;
        setState(() {
          result = data['result'].toString();
        });
        await _loadHistory();
      } else {
        final Map<String, dynamic> data =
            jsonDecode(response.body) as Map<String, dynamic>;
        setState(() {
          result = 'Error: ${data['detail'] ?? 'Invalid expression'}';
        });
      }
    } catch (_) {
      setState(() {
        result = 'Network error';
      });
    } finally {
      setState(() {
        loading = false;
      });
    }
  }

  Future<void> _loadHistory() async {
    try {
      final http.Response response = await http.get(
        Uri.parse('$backendBaseUrl/history'),
      );
      if (response.statusCode == 200) {
        final Map<String, dynamic> data =
            jsonDecode(response.body) as Map<String, dynamic>;
        final List<dynamic> raw =
            data['items'] as List<dynamic>? ?? <dynamic>[];
        setState(() {
          history = raw
              .map((dynamic item) => item as Map<String, dynamic>)
              .toList();
        });
      }
    } catch (_) {
      // History is optional.
    }
  }

  void _openHistory() {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (BuildContext context) {
        if (history.isEmpty) {
          return const SizedBox(
            height: 220,
            child: Center(child: Text('No history yet')),
          );
        }

        return SizedBox(
          height: 360,
          child: ListView.separated(
            itemCount: history.length,
            separatorBuilder: (_, int index) => const Divider(height: 1),
            itemBuilder: (_, int index) {
              final Map<String, dynamic> item = history[index];
              return ListTile(
                title: Text('${item['expression']} = ${item['result']}'),
                subtitle: Text(item['timestamp']?.toString() ?? ''),
                onTap: () {
                  Navigator.pop(context);
                  setState(() {
                    input = item['expression']?.toString() ?? '';
                    result = item['result']?.toString() ?? '0';
                  });
                },
              );
            },
          ),
        );
      },
    );
  }

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Calculator'),
        actions: <Widget>[
          IconButton(
            onPressed: _openHistory,
            icon: const Icon(Icons.history),
            tooltip: 'History',
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: isDark
              ? const LinearGradient(
                  colors: <Color>[Color(0xFF0F172A), Color(0xFF1E293B)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : const LinearGradient(
                  colors: <Color>[Color(0xFFF7FBFF), Color(0xFFEAF4FF)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
        ),
        child: SafeArea(
          child: Column(
            children: <Widget>[
              Expanded(
                flex: 3,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 24, 20, 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: <Widget>[
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        reverse: true,
                        child: Text(
                          input.isEmpty ? '0' : input,
                          style: TextStyle(
                            fontSize: 34,
                            fontWeight: FontWeight.w500,
                            color: isDark ? Colors.white70 : Colors.black87,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        reverse: true,
                        child: Text(
                          loading ? 'Calculating...' : result,
                          style: TextStyle(
                            fontSize: 48,
                            fontWeight: FontWeight.w700,
                            color: isDark ? Colors.white : Colors.black,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Expanded(
                flex: 5,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  child: GridView.builder(
                    itemCount: buttons.length,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 4,
                          mainAxisSpacing: 10,
                          crossAxisSpacing: 10,
                        ),
                    itemBuilder: (_, int index) {
                      final String label = buttons[index];
                      return CalculatorButton(
                        label: label,
                        isOperator: _isOperator(label) || label == '=',
                        onTap: () => _onButtonTap(label),
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class CalculatorButton extends StatelessWidget {
  const CalculatorButton({
    super.key,
    required this.label,
    required this.isOperator,
    required this.onTap,
  });

  final String label;
  final bool isOperator;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color bg = isOperator
        ? const Color(0xFF0EA5E9)
        : (isDark ? const Color(0xFF1F2937) : Colors.white);
    final Color fg = isOperator
        ? Colors.white
        : (isDark ? Colors.white : Colors.black87);

    return Material(
      color: Colors.transparent,
      child: Ink(
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(22),
          boxShadow: <BoxShadow>[
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.12),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(22),
          splashColor: Colors.white24,
          onTap: onTap,
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                color: fg,
                fontSize: 30,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
