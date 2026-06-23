import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_inno/features/auth/auth.dart';

class RegisterPage extends ConsumerStatefulWidget {
  const RegisterPage({super.key});

  @override
  ConsumerState<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends ConsumerState<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final _documentoController = TextEditingController();
  final _nombresController = TextEditingController();
  final _apellidosController = TextEditingController();
  final _telefonoController = TextEditingController();
  final _correoController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmarPasswordController = TextEditingController();

  final _documentoFocus = FocusNode();
  final _nombresFocus = FocusNode();
  final _apellidosFocus = FocusNode();
  final _telefonoFocus = FocusNode();
  final _correoFocus = FocusNode();
  final _passwordFocus = FocusNode();
  final _confirmarPasswordFocus = FocusNode();

  String _tipoDocumento = 'CC';
  bool _isLoading = false;
  bool _passwordVisible = false;
  bool _confirmarPasswordVisible = false;
  String? _errorMessage;
  String? _successMessage;

  final List<Map<String, String>> _tiposDocumento = [
    {'value': 'CC', 'label': 'Cédula de ciudadanía'},
    {'value': 'TI', 'label': 'Tarjeta de identidad'},
    {'value': 'CE', 'label': 'Cédula de extranjería'},
    {'value': 'PA', 'label': 'Pasaporte'},
  ];

  @override
  void dispose() {
    _documentoController.dispose();
    _nombresController.dispose();
    _apellidosController.dispose();
    _telefonoController.dispose();
    _correoController.dispose();
    _passwordController.dispose();
    _confirmarPasswordController.dispose();
    _documentoFocus.dispose();
    _nombresFocus.dispose();
    _apellidosFocus.dispose();
    _telefonoFocus.dispose();
    _correoFocus.dispose();
    _passwordFocus.dispose();
    _confirmarPasswordFocus.dispose();
    super.dispose();
  }

  Future<void> _handleRegister() async {
    FocusScope.of(context).unfocus();

    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _successMessage = null;
    });

    try {
      final repo = ref.read(authRepositoryProvider);

      await repo.register({
        'tipoDocumento': _tipoDocumento,
        'numeroDocumento': _documentoController.text.trim(),
        'nombres': _nombresController.text.trim(),
        'apellidos': _apellidosController.text.trim(),
        'telefono': _telefonoController.text.trim(),
        'correo': _correoController.text.trim(),
        'password': _passwordController.text,
      });

      setState(() {
        _isLoading = false;
        _successMessage = 'Registro exitoso. Revisa tu correo para verificar tu cuenta.';
      });

      await Future.delayed(const Duration(seconds: 2));
      if (!mounted) return;
      context.go('/login');
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
    return 'Error al registrarse. Intenta de nuevo.';
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
              _RegisterCard(
                formKey: _formKey,
                tipoDocumento: _tipoDocumento,
                tiposDocumento: _tiposDocumento,
                documentoController: _documentoController,
                nombresController: _nombresController,
                apellidosController: _apellidosController,
                telefonoController: _telefonoController,
                correoController: _correoController,
                passwordController: _passwordController,
                confirmarPasswordController: _confirmarPasswordController,
                documentoFocus: _documentoFocus,
                nombresFocus: _nombresFocus,
                apellidosFocus: _apellidosFocus,
                telefonoFocus: _telefonoFocus,
                correoFocus: _correoFocus,
                passwordFocus: _passwordFocus,
                confirmarPasswordFocus: _confirmarPasswordFocus,
                isLoading: _isLoading,
                passwordVisible: _passwordVisible,
                confirmarPasswordVisible: _confirmarPasswordVisible,
                errorMessage: _errorMessage,
                successMessage: _successMessage,
                onTipoDocumentoChanged: (v) =>
                    setState(() => _tipoDocumento = v!),
                onPasswordToggle: () =>
                    setState(() => _passwordVisible = !_passwordVisible),
                onConfirmarPasswordToggle: () => setState(
                    () => _confirmarPasswordVisible = !_confirmarPasswordVisible),
                onRegister: _handleRegister,
              ),
              const SizedBox(height: 24),
              _LoginLink(),
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
          child: const Icon(
            Icons.speed_rounded,
            color: Color(0xFF3B9EFF),
            size: 32,
          ),
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

class _RegisterCard extends StatelessWidget {
  const _RegisterCard({
    required this.formKey,
    required this.tipoDocumento,
    required this.tiposDocumento,
    required this.documentoController,
    required this.nombresController,
    required this.apellidosController,
    required this.telefonoController,
    required this.correoController,
    required this.passwordController,
    required this.confirmarPasswordController,
    required this.documentoFocus,
    required this.nombresFocus,
    required this.apellidosFocus,
    required this.telefonoFocus,
    required this.correoFocus,
    required this.passwordFocus,
    required this.confirmarPasswordFocus,
    required this.isLoading,
    required this.passwordVisible,
    required this.confirmarPasswordVisible,
    required this.errorMessage,
    required this.successMessage,
    required this.onTipoDocumentoChanged,
    required this.onPasswordToggle,
    required this.onConfirmarPasswordToggle,
    required this.onRegister,
  });

  final GlobalKey<FormState> formKey;
  final String tipoDocumento;
  final List<Map<String, String>> tiposDocumento;
  final TextEditingController documentoController;
  final TextEditingController nombresController;
  final TextEditingController apellidosController;
  final TextEditingController telefonoController;
  final TextEditingController correoController;
  final TextEditingController passwordController;
  final TextEditingController confirmarPasswordController;
  final FocusNode documentoFocus;
  final FocusNode nombresFocus;
  final FocusNode apellidosFocus;
  final FocusNode telefonoFocus;
  final FocusNode correoFocus;
  final FocusNode passwordFocus;
  final FocusNode confirmarPasswordFocus;
  final bool isLoading;
  final bool passwordVisible;
  final bool confirmarPasswordVisible;
  final String? errorMessage;
  final String? successMessage;
  final ValueChanged<String?> onTipoDocumentoChanged;
  final VoidCallback onPasswordToggle;
  final VoidCallback onConfirmarPasswordToggle;
  final VoidCallback onRegister;

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
              'Crear cuenta',
              style: TextStyle(
                color: Color(0xFFF0F6FF),
                fontSize: 22,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Regístrate para acceder al servicio.',
              style: TextStyle(color: Color(0xFF5A7A9A), fontSize: 13.5),
            ),
            const SizedBox(height: 24),
            _FieldLabel(label: 'Tipo de documento'),
            const SizedBox(height: 6),
            DropdownButtonFormField<String>(
              initialValue: tipoDocumento,
              dropdownColor: const Color(0xFF0D1923),
              style: const TextStyle(color: Color(0xFFF0F6FF), fontSize: 14),
              items: tiposDocumento
                  .map((t) => DropdownMenuItem(
                        value: t['value'],
                        child: Text(t['label']!),
                      ))
                  .toList(),
              onChanged: onTipoDocumentoChanged,
              decoration: _inputDecoration(
                hintText: 'Selecciona',
                prefixIcon: Icons.assignment_outlined,
              ),
            ),
            const SizedBox(height: 16),
            _FieldLabel(label: 'Número de documento'),
            const SizedBox(height: 6),
            _AppTextField(
              controller: documentoController,
              focusNode: documentoFocus,
              nextFocus: nombresFocus,
              hintText: 'Ingresa tu cédula',
              prefixIcon: Icons.badge_outlined,
              keyboardType: TextInputType.number,
              textInputAction: TextInputAction.next,
              validator: (v) {
                if (v == null || v.trim().isEmpty) {
                  return 'El número de documento es obligatorio';
                }
                if (v.trim().length < 5) return 'Mínimo 5 caracteres';
                return null;
              },
            ),
            const SizedBox(height: 16),
            _FieldLabel(label: 'Nombres'),
            const SizedBox(height: 6),
            _AppTextField(
              controller: nombresController,
              focusNode: nombresFocus,
              nextFocus: apellidosFocus,
              hintText: 'Ingresa tus nombres',
              prefixIcon: Icons.person_outline,
              keyboardType: TextInputType.text,
              textInputAction: TextInputAction.next,
              validator: (v) {
                if (v == null || v.trim().isEmpty) {
                  return 'Los nombres son obligatorios';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            _FieldLabel(label: 'Apellidos'),
            const SizedBox(height: 6),
            _AppTextField(
              controller: apellidosController,
              focusNode: apellidosFocus,
              nextFocus: telefonoFocus,
              hintText: 'Ingresa tus apellidos',
              prefixIcon: Icons.person_outline,
              keyboardType: TextInputType.text,
              textInputAction: TextInputAction.next,
              validator: (v) {
                if (v == null || v.trim().isEmpty) {
                  return 'Los apellidos son obligatorios';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            _FieldLabel(label: 'Teléfono'),
            const SizedBox(height: 6),
            _AppTextField(
              controller: telefonoController,
              focusNode: telefonoFocus,
              nextFocus: correoFocus,
              hintText: 'Ingresa tu teléfono',
              prefixIcon: Icons.phone_outlined,
              keyboardType: TextInputType.phone,
              textInputAction: TextInputAction.next,
              validator: (v) {
                if (v == null || v.trim().isEmpty) {
                  return 'El teléfono es obligatorio';
                }
                final regex = RegExp(r'^[0-9]{7,15}$');
                if (!regex.hasMatch(v.trim())) {
                  return 'Ingresa un teléfono válido (7-15 dígitos)';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            _FieldLabel(label: 'Correo electrónico'),
            const SizedBox(height: 6),
            _AppTextField(
              controller: correoController,
              focusNode: correoFocus,
              nextFocus: passwordFocus,
              hintText: 'correo@ejemplo.com',
              prefixIcon: Icons.mail_outline_rounded,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
              validator: (v) {
                if (v == null || v.trim().isEmpty) {
                  return 'El correo es obligatorio';
                }
                final regex = RegExp(r'^[^@]+@[^@]+\.[^@]+$');
                if (!regex.hasMatch(v.trim())) {
                  return 'Ingresa un correo válido';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            _FieldLabel(label: 'Contraseña'),
            const SizedBox(height: 6),
            _AppTextField(
              controller: passwordController,
              focusNode: passwordFocus,
              nextFocus: confirmarPasswordFocus,
              hintText: '••••••••',
              prefixIcon: Icons.lock_outline_rounded,
              obscureText: !passwordVisible,
              textInputAction: TextInputAction.next,
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
                if (v == null || v.isEmpty) {
                  return 'La contraseña es obligatoria';
                }
                if (v.length < 8) return 'Mínimo 8 caracteres';
                return null;
              },
            ),
            const SizedBox(height: 16),
            _FieldLabel(label: 'Confirmar contraseña'),
            const SizedBox(height: 6),
            _AppTextField(
              controller: confirmarPasswordController,
              focusNode: confirmarPasswordFocus,
              hintText: '••••••••',
              prefixIcon: Icons.lock_outline_rounded,
              obscureText: !confirmarPasswordVisible,
              textInputAction: TextInputAction.done,
              onFieldSubmitted: (_) => onRegister(),
              suffixIcon: IconButton(
                onPressed: onConfirmarPasswordToggle,
                icon: Icon(
                  confirmarPasswordVisible
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                  color: const Color(0xFF3A5A78),
                  size: 20,
                ),
              ),
              validator: (v) {
                if (v == null || v.isEmpty) {
                  return 'Confirma tu contraseña';
                }
                if (v != passwordController.text) {
                  return 'Las contraseñas no coinciden';
                }
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
                        style: const TextStyle(
                            color: Colors.redAccent, fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            if (successMessage != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.green.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border:
                      Border.all(color: Colors.green.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.check_circle_outline,
                        color: Colors.greenAccent, size: 16),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        successMessage!,
                        style: const TextStyle(
                            color: Colors.greenAccent, fontSize: 13),
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
                onPressed: isLoading ? null : onRegister,
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
                            'Crear cuenta',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          SizedBox(width: 8),
                          Icon(Icons.person_add_outlined, size: 18),
                        ],
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  InputDecoration _inputDecoration({
    required String hintText,
    required IconData prefixIcon,
  }) {
    return InputDecoration(
      hintText: hintText,
      hintStyle: const TextStyle(color: Color(0xFF2E4A62), fontSize: 14),
      prefixIcon:
          Icon(prefixIcon, color: const Color(0xFF3A5A78), size: 18),
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
        borderSide:
            BorderSide(color: Colors.redAccent.withValues(alpha: 0.7)),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Colors.redAccent, width: 1.5),
      ),
      errorStyle: const TextStyle(color: Colors.redAccent, fontSize: 12),
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
          borderSide:
              BorderSide(color: Colors.redAccent.withValues(alpha: 0.7)),
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

class _LoginLink extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text(
          '¿Ya tienes cuenta? ',
          style: TextStyle(color: Color(0xFF5A7A9A), fontSize: 13),
        ),
        GestureDetector(
          onTap: () => context.go('/login'),
          child: const Text(
            'Inicia sesión',
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
