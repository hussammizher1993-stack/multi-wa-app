import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MultiWhatsAppPro());
}

class MultiWhatsAppPro extends StatelessWidget {
  const MultiWhatsAppPro({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'مدير واتساب المتعدد',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        fontFamily: 'Roboto',
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF0F4C3A),
          primary: const Color(0xFF0F4C3A),
          secondary: const Color(0xFF25D366),
        ),
        useMaterial3: true,
      ),
      home: const MainAccountsScreen(),
    );
  }
}

class MainAccountsScreen extends StatefulWidget {
  const MainAccountsScreen({super.key});

  @override
  State<MainAccountsScreen> createState() => _MainAccountsScreenState();
}

class _MainAccountsScreenState extends State<MainAccountsScreen> {
  final int totalAccounts = 10;
  int activeIndex = 0;

  List<String> accountTitles = [];
  List<String> accountPhones = [];
  final Map<int, InAppWebViewController> _controllers = {};

  final List<Color> cardColors = [
    const Color(0xFF075E54),
    const Color(0xFF128C7E),
    const Color(0xFF00796B),
    const Color(0xFF00897B),
    const Color(0xFF004D40),
    const Color(0xFF1B5E20),
    const Color(0xFF2E7D32),
    const Color(0xFF388E3C),
    const Color(0xFF026773),
    const Color(0xFF3CAEA3),
  ];

  final String desktopUserAgent =
      "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/122.0.0.0 Safari/537.36";

  @override
  void initState() {
    super.initState();
    accountTitles = List.generate(totalAccounts, (i) => "واتساب ${i + 1}");
    accountPhones = List.generate(totalAccounts, (i) => "رقم غير محدد");
    _loadStoredData();
  }

  Future<void> _loadStoredData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      for (int i = 0; i < totalAccounts; i++) {
        accountTitles[i] = prefs.getString('title_$i') ?? "واتساب ${i + 1}";
        accountPhones[i] = prefs.getString('phone_$i') ?? "أضف الرقم هنا";
      }
    });
  }

  Future<void> _editAccountDetails(int index) async {
    final nameController = TextEditingController(text: accountTitles[index]);
    final phoneController = TextEditingController(
      text: accountPhones[index] == "أضف الرقم هنا" ? "" : accountPhones[index],
    );

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('تعديل الحساب ${index + 1}', textAlign: TextAlign.right),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              textAlign: TextAlign.right,
              decoration: const InputDecoration(
                labelText: 'اسم الحساب (مثلاً: الإدارة / المبيعات)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: phoneController,
              keyboardType: TextInputType.phone,
              textAlign: TextAlign.left,
              decoration: const InputDecoration(
                labelText: 'رقم الهاتف (مثلاً: 078xxxxxxxx)',
                prefixIcon: Icon(Icons.phone),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0F4C3A),
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              final prefs = await SharedPreferences.getInstance();
              final newName = nameController.text.trim().isEmpty
                  ? "واتساب ${index + 1}"
                  : nameController.text.trim();
              final newPhone = phoneController.text.trim().isEmpty
                  ? "أضف الرقم هنا"
                  : phoneController.text.trim();

              await prefs.setString('title_$index', newName);
              await prefs.setString('phone_$index', newPhone);

              setState(() {
                accountTitles[index] = newName;
                accountPhones[index] = newPhone;
              });

              if (mounted) Navigator.pop(context);
            },
            child: const Text('حفظ'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFFF0F4F3),
        appBar: AppBar(
          elevation: 2,
          backgroundColor: const Color(0xFF0F4C3A),
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                accountTitles[activeIndex],
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
              Text(
                accountPhones[activeIndex],
                style: const TextStyle(
                  color: Color(0xFF25D366),
                  fontSize: 13,
                  letterSpacing: 1,
                ),
              ),
            ],
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.edit_note, color: Colors.white, size: 28),
              tooltip: 'تعديل الاسم والرقم',
              onPressed: () => _editAccountDetails(activeIndex),
            ),
            IconButton(
              icon: const Icon(Icons.refresh, color: Colors.white),
              tooltip: 'تحديث الحساب',
              onPressed: () => _controllers[activeIndex]?.reload(),
            ),
          ],
        ),
        body: Column(
          children: [
            Container(
              height: 95,
              padding: const EdgeInsets.symmetric(vertical: 8),
              decoration: const BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 4,
                    offset: Offset(0, 2),
                  )
                ],
              ),
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: totalAccounts,
                itemBuilder: (context, index) {
                  final isSelected = index == activeIndex;
                  final color = cardColors[index % cardColors.length];

                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        activeIndex = index;
                      });
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      margin: const EdgeInsets.symmetric(horizontal: 5),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        gradient: isSelected
                            ? LinearGradient(
                                colors: [color, color.withOpacity(0.85)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              )
                            : null,
                        color: isSelected ? null : Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSelected ? color : Colors.grey.shade300,
                          width: isSelected ? 2 : 1,
                        ),
                        boxShadow: isSelected
                            ? [
                                BoxShadow(
                                  color: color.withOpacity(0.35),
                                  blurRadius: 6,
                                  offset: const Offset(0, 3),
                                )
                              ]
                            : [],
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.chat_bubble,
                                size: 14,
                                color: isSelected ? Colors.white : color,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                accountTitles[index],
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: isSelected ? Colors.white : Colors.black87,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            accountPhones[index],
                            style: TextStyle(
                              fontSize: 11,
                              color: isSelected
                                  ? Colors.white.withOpacity(0.9)
                                  : Colors.black54,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            Expanded(
              child: IndexedStack(
                index: activeIndex,
                children: List.generate(totalAccounts, (index) {
                  return InAppWebView(
                    initialUrlRequest: URLRequest(
                      url: WebUri("https://web.whatsapp.com"),
                    ),
                    initialSettings: InAppWebViewSettings(
                      userAgent: desktopUserAgent,
                      javaScriptEnabled: true,
                      domStorageEnabled: true,
                      databaseEnabled: true,
                      useWideViewPort: true,
                      loadWithOverviewMode: true,
                      cacheMode: CacheMode.LOAD_DEFAULT,
                      mediaPlaybackRequiresUserGesture: false,
                    ),
                    onWebViewCreated: (controller) {
                      _controllers[index] = controller;
                    },
                  );
                }),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
