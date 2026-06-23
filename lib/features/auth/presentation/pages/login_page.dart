import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_inno/core/network/providers.dart';
import 'package:flutter_inno/core/utils/jwt_decoder.dart';
import 'package:flutter_inno/features/auth/auth.dart';

class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _documentoController = TextEditingController();
  final _passwordController = TextEditingController();
  final _documentoFocus = FocusNode();
  final _passwordFocus = FocusNode();

  bool _isLoading = false;
  bool _passwordVisible = false;
  String? _errorMessage;

  @override
  void dispose() {
    _documentoController.dispose();
    _passwordController.dispose();
    _documentoFocus.dispose();
    _passwordFocus.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    FocusScope.of(context).unfocus();

    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final repo = ref.read(authRepositoryProvider);
      final storage = ref.read(secureStorageProvider);

      final response = await repo.login(
        _documentoController.text.trim(),
        _passwordController.text,
      );

      final accessToken = response['accessToken'] as String;
      await storage.saveAccessToken(accessToken);
      await storage.saveRefreshToken(response['refreshToken'] as String);

      final payload = JwtDecoder.decodePayload(accessToken);
      final numDoc = payload['numDoc'] as String? ?? _documentoController.text.trim();
      await storage.saveDocumento(numDoc);

      if (!mounted) return;
      context.replace('/dashboard');
    } on DioException catch (e) {
      final mensaje = _extraerMensajeError(e);
      setState(() {
        _isLoading = false;
        _errorMessage = mensaje;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Ocurrió un error inesperado. Intenta de nuevo.';
      });
    }
  }

  String _extraerMensajeError(DioException e) {
    if (e.response?.data is Map) {
      final data = e.response!.data as Map;
      if (data['message'] != null) return data['message'] as String;
    }
    if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.receiveTimeout) {
      return 'Tiempo de espera agotado. Verifica tu conexión.';
    }
    if (e.type == DioExceptionType.connectionError) {
      return 'No se pudo conectar con el servidor.';
    }
    return 'Credenciales incorrectas.';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F1923),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: Column(
            children: [
              const SizedBox(height: 16),
              _BrandHeader(),
              const SizedBox(height: 32),
              _LoginCard(
                formKey: _formKey,
                documentoController: _documentoController,
                passwordController: _passwordController,
                documentoFocus: _documentoFocus,
                passwordFocus: _passwordFocus,
                isLoading: _isLoading,
                passwordVisible: _passwordVisible,
                errorMessage: _errorMessage,
                onPasswordToggle: () => setState(
                    () => _passwordVisible = !_passwordVisible),
                onLogin: _handleLogin,
              ),
              const SizedBox(height: 24),
              _RegisterLink(),
              const SizedBox(height: 32),
              _FooterLinks(),
            ],
          ),
        ),
      ),
    );
  }
}

class _BrandHeader extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            color: const Color(0xFF1A2840),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFF2A4060)),
          ),
          child: const Icon(Icons.speed_rounded,
              color: Color(0xFF3B9EFF), size: 32),
        ),
        const SizedBox(height: 12),
        const Text(
          'Bienvenido a innogarage',
          style: TextStyle(
            color: Color(0xFF3B9EFF),
            fontSize: 18,
            fontWeight: FontWeight.w600,
            fontStyle: FontStyle.italic,
          ),
        ),
      ],
    );
  }
}

class _LoginCard extends StatelessWidget {
  const _LoginCard({
    required this.formKey,
    required this.documentoController,
    required this.passwordController,
    required this.documentoFocus,
    required this.passwordFocus,
    required this.isLoading,
    required this.passwordVisible,
    required this.errorMessage,
    required this.onPasswordToggle,
    required this.onLogin,
  });

  final GlobalKey<FormState> formKey;
  final TextEditingController documentoController;
  final TextEditingController passwordController;
  final FocusNode documentoFocus;
  final FocusNode passwordFocus;
  final bool isLoading;
  final bool passwordVisible;
  final String? errorMessage;
  final VoidCallback onPasswordToggle;
  final VoidCallback onLogin;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF152030),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF1E3048)),
      ),
      child: Form(
        key: formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Iniciar sesión',
              style: TextStyle(
                color: Color(0xFFF0F6FF),
                fontSize: 22,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Accede a tu panel de servicio.',
              style: TextStyle(color: Color(0xFF5A7A9A), fontSize: 13.5),
            ),
            const SizedBox(height: 24),
            _FieldLabel(label: 'Número de documento'),
            const SizedBox(height: 6),
            _AppTextField(
              controller: documentoController,
              focusNode: documentoFocus,
              nextFocus: passwordFocus,
              hintText: 'Ingresa tu cédula',
              prefixIcon: Icons.badge_outlined,
              keyboardType: TextInputType.number,
              textInputAction: TextInputAction.next,
              validator: (v) {
                if (v == null || v.trim().isEmpty) {
                  return 'El número de documento es obligatorio';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _FieldLabel(label: 'Contraseña'),
              ],
            ),
            const SizedBox(height: 6),
            _AppTextField(
              controller: passwordController,
              focusNode: passwordFocus,
              hintText: '••••••••',
              prefixIcon: Icons.lock_outline_rounded,
              obscureText: !passwordVisible,
              textInputAction: TextInputAction.done,
              onFieldSubmitted: (_) => onLogin(),
              suffixIcon: IconButton(
                onPressed: onPasswordToggle,
                icon: Icon(
                  passwordVisible
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                  color: const Color(0xFF3A5A78),
                  size: 20,
                ),
              ),
              validator: (v) {
                if (v == null || v.isEmpty) return 'La contraseña es obligatoria';
                if (v.length < 6) return 'Mínimo 6 caracteres';
                return null;
              },
            ),
            if (errorMessage != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline,
                        color: Colors.redAccent, size: 16),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        errorMessage!,
                        style:
                            const TextStyle(color: Colors.redAccent, fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: isLoading ? null : onLogin,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF3B9EFF),
                  disabledBackgroundColor:
                      const Color(0xFF3B9EFF).withValues(alpha: 0.5),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                child: isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Iniciar sesión',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          SizedBox(width: 8),
                          Icon(Icons.arrow_forward_rounded, size: 18),
                        ],
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AppTextField extends StatelessWidget {
  const _AppTextField({
    required this.controller,
    required this.hintText,
    required this.prefixIcon,
    this.focusNode,
    this.nextFocus,
    this.obscureText = false,
    this.keyboardType,
    this.textInputAction,
    this.suffixIcon,
    this.onFieldSubmitted,
    this.validator,
  });

  final TextEditingController controller;
  final FocusNode? focusNode;
  final FocusNode? nextFocus;
  final String hintText;
  final IconData prefixIcon;
  final bool obscureText;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final Widget? suffixIcon;
  final ValueChanged<String>? onFieldSubmitted;
  final FormFieldValidator<String>? validator;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      focusNode: focusNode,
      obscureText: obscureText,
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      style: const TextStyle(color: Color(0xFFF0F6FF), fontSize: 14),
      onFieldSubmitted: (v) {
        if (nextFocus != null) {
          FocusScope.of(context).requestFocus(nextFocus);
        }
        onFieldSubmitted?.call(v);
      },
      validator: validator,
      autovalidateMode: AutovalidateMode.onUserInteraction,
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: const TextStyle(color: Color(0xFF2E4A62), fontSize: 14),
        prefixIcon:
            Icon(prefixIcon, color: const Color(0xFF3A5A78), size: 18),
        suffixIcon: suffixIcon,
        filled: true,
        fillColor: const Color(0xFF0D1923),
        contentPadding: const EdgeInsets.symmetric(vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFF1E3048)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFF1E3048)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide:
              const BorderSide(color: Color(0xFF3B9EFF), width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.redAccent.withValues(alpha: 0.7)),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Colors.redAccent, width: 1.5),
        ),
        errorStyle: const TextStyle(color: Colors.redAccent, fontSize: 12),
      ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  const _FieldLabel({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label.toUpperCase(),
      style: const TextStyle(
        color: Color(0xFF2E4A62),
        fontSize: 11,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.8,
      ),
    );
  }
}

class _RegisterLink extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text(
          '¿No tienes cuenta? ',
          style: TextStyle(color: Color(0xFF5A7A9A), fontSize: 13),
        ),
        GestureDetector(
          onTap: () => context.go('/register'),
          child: const Text(
            'Regístrate',
            style: TextStyle(
              color: Color(0xFF3B9EFF),
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}

class _FooterLinks extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: ['PRIVACIDAD', 'TÉRMINOS', 'SOPORTE'].map((label) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: GestureDetector(
            onTap: () {},
            child: Text(
              label,
              style: const TextStyle(
                color: Color(0xFF2E4A62),
                fontSize: 11,
                letterSpacing: 0.6,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}
