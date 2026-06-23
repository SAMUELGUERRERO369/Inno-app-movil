import 'package:flutter/material.dart';

// ─────────────────────────────────────────────────
// CONSTANTES DE TEMA
// Centraliza colores para facilitar cambios globales
// ─────────────────────────────────────────────────
class AppColors {
  AppColors._();

  static const bg          = Color(0xFF0F1923); // Fondo principal
  static const surface     = Color(0xFF152030); // Tarjeta/card
  static const surfaceDeep = Color(0xFF0D1923); // Inputs
  static const border      = Color(0xFF1E3048); // Bordes sutiles
  static const accent      = Color(0xFF3B9EFF); // Azul primario
  static const textPrimary = Color(0xFFF0F6FF); // Título
  static const textMuted   = Color(0xFF5A7A9A); // Subtítulo
  static const textHint    = Color(0xFF2E4A62); // Placeholder
  static const iconColor   = Color(0xFF3A5A78); // Íconos de input
}

// ─────────────────────────────────────────────────
// MODELO DE ESTADO DEL FORMULARIO
// Separar la lógica del UI (buena práctica MVVM/BLoC)
// ─────────────────────────────────────────────────
class LoginState {
  final bool isLoading;
  final bool rememberDevice;
  final bool passwordVisible;
  final String? errorMessage;

  const LoginState({
    this.isLoading = false,
    this.rememberDevice = false,
    this.passwordVisible = false,
    this.errorMessage,
  });

  LoginState copyWith({
    bool? isLoading,
    bool? rememberDevice,
    bool? passwordVisible,
    String? errorMessage,
  }) =>
      LoginState(
        isLoading:       isLoading       ?? this.isLoading,
        rememberDevice:  rememberDevice  ?? this.rememberDevice,
        passwordVisible: passwordVisible ?? this.passwordVisible,
        errorMessage:    errorMessage    ?? this.errorMessage,
      );
}

// ─────────────────────────────────────────────────
// PANTALLA PRINCIPAL
// StatefulWidget para manejar el estado local.
// En producción: reemplazar con Provider/Riverpod/BLoC
// ─────────────────────────────────────────────────
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  // GlobalKey para validar el formulario sin acceder a los campos directamente
  final _formKey = GlobalKey<FormState>();

  // Controllers separados para limpiar recursos en dispose()
  final _emailController    = TextEditingController();
  final _passwordController = TextEditingController();

  // FocusNodes permiten gestionar el foco entre campos (UX de teclado)
  final _emailFocus    = FocusNode();
  final _passwordFocus = FocusNode();

  // Estado local centralizado en un objeto inmutable
  LoginState _state = const LoginState();

  @override
  void dispose() {
    // SIEMPRE liberar controllers y focus nodes para evitar memory leaks
    _emailController.dispose();
    _passwordController.dispose();
    _emailFocus.dispose();
    _passwordFocus.dispose();
    super.dispose();
  }

  // ── Lógica de login ───────────────────────────
  Future<void> _handleLogin() async {
    // 1. Quitar el teclado antes de procesar
    FocusScope.of(context).unfocus();

    // 2. Validar el formulario (activa los validators de cada TextFormField)
    if (!(_formKey.currentState?.validate() ?? false)) return;

    // 3. Mostrar loading
    setState(() => _state = _state.copyWith(isLoading: true, errorMessage: null));

    try {
      // 4. Llamar al servicio de autenticación (reemplazar con tu repositorio)
      await _fakeAuthCall(
        email:    _emailController.text.trim(),
        password: _passwordController.text,
      );

      // 5. Navegar al dashboard si el widget sigue montado
      if (!mounted) return;
      Navigator.of(context).pushReplacementNamed('/dashboard');
    } on AuthException catch (e) {
      // 6. Mostrar error de negocio al usuario
      setState(() => _state = _state.copyWith(
        isLoading: false,
        errorMessage: e.message,
      ));
    } catch (_) {
      // 7. Capturar errores inesperados sin exponer detalles internos
      setState(() => _state = _state.copyWith(
        isLoading: false,
        errorMessage: 'Something went wrong. Please try again.',
      ));
    }
  }

  // Simulación de llamada de red (reemplazar con tu AuthRepository)
  Future<void> _fakeAuthCall({
    required String email,
    required String password,
  }) async {
    await Future.delayed(const Duration(seconds: 2));
    if (password.length < 6) throw AuthException('Invalid credentials.');
  }

  // ─────────────────────────────────────────────
  // BUILD
  // ─────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      // SingleChildScrollView evita overflow cuando el teclado sube
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: Column(
            children: [
              const SizedBox(height: 16),

              // ── Logo y título de marca ──────────
              _BrandHeader(),
              const SizedBox(height: 32),

              // ── Tarjeta principal ───────────────
              _LoginCard(
                formKey:            _formKey,
                emailController:    _emailController,
                passwordController: _passwordController,
                emailFocus:         _emailFocus,
                passwordFocus:      _passwordFocus,
                state:              _state,
                onPasswordToggle: () => setState(() => _state = _state.copyWith(
                  passwordVisible: !_state.passwordVisible,
                )),
                onRememberToggle: () => setState(() => _state = _state.copyWith(
                  rememberDevice: !_state.rememberDevice,
                )),
                onLogin:        _handleLogin,
                onForgotPassword: _showForgotPasswordSheet,
                onGoogleLogin:  _handleGoogleLogin,
              ),

              const SizedBox(height: 32),

              // ── Footer legal ────────────────────
              const _FooterLinks(),
            ],
          ),
        ),
      ),
    );
  }

  void _showForgotPasswordSheet() {
    // Implementar bottom sheet de recuperación de contraseña
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => const _ForgotPasswordSheet(),
    );
  }

  Future<void> _handleGoogleLogin() async {
    // Integrar con google_sign_in package
    debugPrint('Google login initiated');
  }
}

// ─────────────────────────────────────────────────
// WIDGETS PRIVADOS
// Extraer sub-widgets mejora la legibilidad y
// permite re-renders más eficientes (solo reconstruye
// el sub-árbol que cambia)
// ─────────────────────────────────────────────────

/// Logo + título de la app
class _BrandHeader extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Ícono de la app
        Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            color: const Color(0xFF1A2840),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFF2A4060)),
          ),
          child: const Icon(Icons.speed_rounded, color: AppColors.accent, size: 32),
        ),
        const SizedBox(height: 12),

        // Título con estilo cursiva azul (igual al diseño original)
        const Text(
          'Bienvenido a innogarage',
          style: TextStyle(
            color: AppColors.accent,
            fontSize: 18,
            fontWeight: FontWeight.w600,
            fontStyle: FontStyle.italic,
          ),
        ),
      ],
    );
  }
}

/// Tarjeta con el formulario de login
class _LoginCard extends StatelessWidget {
  const _LoginCard({
    required this.formKey,
    required this.emailController,
    required this.passwordController,
    required this.emailFocus,
    required this.passwordFocus,
    required this.state,
    required this.onPasswordToggle,
    required this.onRememberToggle,
    required this.onLogin,
    required this.onForgotPassword,
    required this.onGoogleLogin,
  });

  final GlobalKey<FormState> formKey;
  final TextEditingController emailController;
  final TextEditingController passwordController;
  final FocusNode emailFocus;
  final FocusNode passwordFocus;
  final LoginState state;
  final VoidCallback onPasswordToggle;
  final VoidCallback onRememberToggle;
  final VoidCallback onLogin;
  final VoidCallback onForgotPassword;
  final VoidCallback onGoogleLogin;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: Form(
        key: formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Encabezado
            const Text(
              'Welcome Back',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 22,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.3,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Access your service bay dashboard.',
              style: TextStyle(color: AppColors.textMuted, fontSize: 13.5),
            ),
            const SizedBox(height: 24),

            // Campo email
            _FieldLabel(label: 'Work Email'),
            const SizedBox(height: 6),
            _AppTextField(
              controller: emailController,
              focusNode: emailFocus,
              nextFocus: passwordFocus,
              hintText: 'mechanic@obsidian.com',
              prefixIcon: Icons.mail_outline_rounded,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
              // Validador inline — en apps grandes, mover a una clase Validators
              validator: (v) {
                if (v == null || v.isEmpty) return 'Email is required';
                final emailReg = RegExp(r'^[^@]+@[^@]+\.[^@]+$');
                if (!emailReg.hasMatch(v)) return 'Enter a valid email';
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Campo contraseña con "Forgot password?" alineado a la derecha
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _FieldLabel(label: 'Password'),
                GestureDetector(
                  onTap: onForgotPassword,
                  child: const Text(
                    'Forgot password?',
                    style: TextStyle(
                      color: AppColors.accent,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            _AppTextField(
              controller: passwordController,
              focusNode: passwordFocus,
              hintText: '••••••••',
              prefixIcon: Icons.lock_outline_rounded,
              obscureText: !state.passwordVisible,
              textInputAction: TextInputAction.done,
              onFieldSubmitted: (_) => onLogin(),
              suffixIcon: IconButton(
                onPressed: onPasswordToggle,
                icon: Icon(
                  state.passwordVisible
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                  color: AppColors.iconColor,
                  size: 20,
                ),
              ),
              validator: (v) {
                if (v == null || v.isEmpty) return 'Password is required';
                if (v.length < 6) return 'Minimum 6 characters';
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Checkbox "Remember this device"
            GestureDetector(
              onTap: onRememberToggle,
              behavior: HitTestBehavior.opaque, // Área de toque más amplia
              child: Row(
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    width: 18,
                    height: 18,
                    decoration: BoxDecoration(
                      color: state.rememberDevice
                          ? AppColors.accent
                          : AppColors.surfaceDeep,
                      borderRadius: BorderRadius.circular(5),
                      border: Border.all(
                        color: state.rememberDevice
                            ? AppColors.accent
                            : AppColors.border,
                        width: 1.5,
                      ),
                    ),
                    child: state.rememberDevice
                        ? const Icon(Icons.check, color: Colors.white, size: 12)
                        : null,
                  ),
                  const SizedBox(width: 10),
                  const Text(
                    'Remember this device',
                    style: TextStyle(color: AppColors.textMuted, fontSize: 13.5),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),

            // Mensaje de error (visible solo si hay error)
            if (state.errorMessage != null) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline, color: Colors.redAccent, size: 16),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        state.errorMessage!,
                        style: const TextStyle(color: Colors.redAccent, fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 20),

            // Botón primario de login
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: state.isLoading ? null : onLogin,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.accent,
                  disabledBackgroundColor: AppColors.accent.withOpacity(0.5),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                child: state.isLoading
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
                            'Login to Dashboard',
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
            const SizedBox(height: 20),

            // Divisor "or continue with"
            Row(
              children: [
                const Expanded(child: Divider(color: AppColors.border)),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Text(
                    'or continue with',
                    style: TextStyle(
                      color: AppColors.textHint,
                      fontSize: 11,
                      letterSpacing: 0.6,
                    ),
                  ),
                ),
                const Expanded(child: Divider(color: AppColors.border)),
              ],
            ),
            const SizedBox(height: 16),

            // Botón de Google
            SizedBox(
              width: double.infinity,
              height: 48,
              child: OutlinedButton(
                onPressed: onGoogleLogin,
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.textPrimary,
                  side: const BorderSide(color: AppColors.border),
                  backgroundColor: AppColors.surfaceDeep,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // SVG de Google — en producción usar flutter_svg o un asset
                    const Icon(Icons.g_mobiledata, color: AppColors.accent, size: 22),
                    const SizedBox(width: 8),
                    const Text(
                      'Continue with Google',
                      style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w500),
                    ),
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

/// Campo de texto reutilizable con estilo consistente
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
      style: const TextStyle(color: AppColors.textPrimary, fontSize: 14),
      // Al presionar "next" en el teclado, mover el foco al siguiente campo
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
        hintStyle: const TextStyle(color: AppColors.textHint, fontSize: 14),
        prefixIcon: Icon(prefixIcon, color: AppColors.iconColor, size: 18),
        suffixIcon: suffixIcon,
        filled: true,
        fillColor: AppColors.surfaceDeep,
        contentPadding: const EdgeInsets.symmetric(vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.accent, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.redAccent.withOpacity(0.7)),
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

/// Etiqueta de campo en mayúsculas con estilo del diseño
class _FieldLabel extends StatelessWidget {
  const _FieldLabel({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label.toUpperCase(),
      style: const TextStyle(
        color: AppColors.textHint,
        fontSize: 11,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.8,
      ),
    );
  }
}

/// Links de footer: Privacy, Terms, Support
class _FooterLinks extends StatelessWidget {
  const _FooterLinks();

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: ['PRIVACY', 'TERMS', 'SUPPORT'].map((label) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: GestureDetector(
            onTap: () => debugPrint('$label tapped'),
            child: Text(
              label,
              style: const TextStyle(
                color: AppColors.textHint,
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

/// Bottom sheet de recuperación de contraseña
class _ForgotPasswordSheet extends StatelessWidget {
  const _ForgotPasswordSheet();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        24,
        24,
        24,
        MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Reset password',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Enter your work email and we\'ll send a reset link.',
            style: TextStyle(color: AppColors.textMuted, fontSize: 13.5),
          ),
          const SizedBox(height: 20),
          TextFormField(
            keyboardType: TextInputType.emailAddress,
            style: const TextStyle(color: AppColors.textPrimary),
            decoration: InputDecoration(
              hintText: 'mechanic@obsidian.com',
              hintStyle: const TextStyle(color: AppColors.textHint),
              filled: true,
              fillColor: AppColors.surfaceDeep,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: AppColors.border),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: AppColors.border),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: AppColors.accent, width: 1.5),
              ),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.accent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
              child: const Text(
                'Send reset link',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────
// EXCEPCIÓN PERSONALIZADA DE AUTENTICACIÓN
// Permite distinguir errores de negocio de errores
// técnicos en el catch block
// ─────────────────────────────────────────────────
class AuthException implements Exception {
  const AuthException(this.message);
  final String message;
}

// ─────────────────────────────────────────────────
// ENTRY POINT (solo para prueba standalone)
// En producción, LoginScreen se registra en el router
// ─────────────────────────────────────────────────
void main() => runApp(
      MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.dark(surface: AppColors.bg),
          scaffoldBackgroundColor: AppColors.bg,
        ),
        home: const LoginScreen(),
      ),
    );