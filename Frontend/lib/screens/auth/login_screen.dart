import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/providers.dart';

/* =======================
   🎨 COLOR THEME
======================= */
const Color kPrimaryBlue = Color(0xFF1E88E5);
const Color kLightBlue = Color(0xFF90CAF9);
const Color kSunYellow = Color(0xFFFFC107);
const Color kBackground = Color(0xFFF4F7FC);
const Color kTextDark = Color(0xFF1F2937);

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();

  bool _isLogin = true;
  bool _obscurePassword = true;

  late AnimationController _controller;
  late Animation<double> _fade;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _fade = CurvedAnimation(parent: _controller, curve: Curves.easeIn);
    _controller.forward();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    _controller.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final auth = context.read<AuthProvider>();
    bool success;

    if (_isLogin) {
      success = await auth.login(
        _emailController.text.trim(),
        _passwordController.text,
      );
    } else {
      success = await auth.register(
        _emailController.text.trim(),
        _passwordController.text,
        _nameController.text.trim(),
      );
    }

    if (!success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(auth.errorMessage ?? 'Đã xảy ra lỗi'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFE3F2FD), kBackground],
          ),
        ),
        child: FadeTransition(
          opacity: _fade,
          child: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  const SizedBox(height: 32),
                  _buildHeader(),
                  const SizedBox(height: 36),
                  _buildForm(),
                  const SizedBox(height: 20),
                  _buildToggle(),
                  const SizedBox(height: 20),
                  _buildDemoAccounts(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  /* =======================
        HEADER
======================= */
  Widget _buildHeader() {
    return Column(
      children: [
        Container(
          width: 96,
          height: 96,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: const LinearGradient(colors: [kPrimaryBlue, kLightBlue]),
            boxShadow: [
              BoxShadow(
                color: kPrimaryBlue.withOpacity(0.35),
                blurRadius: 22,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: const Icon(Icons.sports_tennis, color: Colors.white, size: 46),
        ),
        const SizedBox(height: 22),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Text(
              'PCM ',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: kPrimaryBlue,
              ),
            ),
            Text(
              'Club',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: kSunYellow,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        const Text(
          'Quản lý câu lạc bộ thông minh',
          style: TextStyle(color: Colors.grey),
        ),
      ],
    );
  }

  /* =======================
          FORM
======================= */
  Widget _buildForm() {
    return Consumer<AuthProvider>(
      builder: (context, auth, _) {
        return Card(
          elevation: 14,
          shadowColor: kPrimaryBlue.withOpacity(0.15),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          child: Padding(
            padding: const EdgeInsets.all(26),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  Text(
                    _isLogin ? 'Đăng nhập' : 'Đăng ký',
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: kTextDark,
                    ),
                  ),
                  const SizedBox(height: 26),

                  if (!_isLogin) ...[
                    _input(
                      controller: _nameController,
                      label: 'Họ và tên',
                      icon: Icons.person_outline,
                      validator: (v) =>
                          v == null || v.isEmpty ? 'Nhập họ tên' : null,
                    ),
                    const SizedBox(height: 16),
                  ],

                  _input(
                    controller: _emailController,
                    label: 'Email',
                    icon: Icons.email_outlined,
                    keyboardType: TextInputType.emailAddress,
                    validator: (v) {
                      if (v == null || v.isEmpty) return 'Nhập email';
                      if (!v.contains('@')) return 'Email không hợp lệ';
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  _input(
                    controller: _passwordController,
                    label: 'Mật khẩu',
                    icon: Icons.lock_outline,
                    obscure: _obscurePassword,
                    suffix: IconButton(
                      icon: Icon(
                        _obscurePassword
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                        color: kPrimaryBlue,
                      ),
                      onPressed: () =>
                          setState(() => _obscurePassword = !_obscurePassword),
                    ),
                    validator: (v) {
                      if (v == null || v.isEmpty) return 'Nhập mật khẩu';
                      if (v.length < 6) return 'Tối thiểu 6 ký tự';
                      return null;
                    },
                  ),
                  const SizedBox(height: 26),

                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _submit,
                      style: ElevatedButton.styleFrom(
                        elevation: 6,
                        backgroundColor: kPrimaryBlue,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: Text(
                        _isLogin ? 'Đăng nhập' : 'Đăng ký',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _input({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    bool obscure = false,
    Widget? suffix,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: obscure,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: kPrimaryBlue),
        suffixIcon: suffix,
        filled: true,
        fillColor: const Color(0xFFF9FAFB),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }

  /* =======================
        TOGGLE
======================= */
  Widget _buildToggle() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(_isLogin ? 'Chưa có tài khoản?' : 'Đã có tài khoản?'),
        TextButton(
          onPressed: () => setState(() => _isLogin = !_isLogin),
          child: Text(
            _isLogin ? 'Đăng ký' : 'Đăng nhập',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: kPrimaryBlue,
            ),
          ),
        ),
      ],
    );
  }

  /* =======================
        DEMO
======================= */
  Widget _buildDemoAccounts() {
    return Card(
      elevation: 6,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: const [
                Icon(Icons.info_outline, color: kSunYellow),
                SizedBox(width: 8),
                Text(
                  'Tài khoản Demo',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: kTextDark,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            _demoTile(
              'Admin',
              'admin@pcm.com',
              'Admin@123',
              Icons.admin_panel_settings,
              Colors.deepPurple,
            ),
            const SizedBox(height: 10),
            _demoTile(
              'Thành viên',
              'member1@pcm.com',
              'Member@123',
              Icons.person,
              kPrimaryBlue,
            ),
          ],
        ),
      ),
    );
  }

  Widget _demoTile(
    String role,
    String email,
    String password,
    IconData icon,
    Color color,
  ) {
    return InkWell(
      onTap: () {
        setState(() {
          _emailController.text = email;
          _passwordController.text = password;
          _isLogin = true;
        });
      },
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Row(
          children: [
            Icon(icon, color: color),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                '$role\n$email / $password',
                style: const TextStyle(fontSize: 13),
              ),
            ),
            const Icon(Icons.touch_app, size: 18),
          ],
        ),
      ),
    );
  }
}
