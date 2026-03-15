import 'package:flutter/material.dart';

import 'auth_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({
    super.key,
    required this.authService,
  });

  final AuthService authService;

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool _busy = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      body: Stack(
        children: [
          const Positioned.fill(child: _LoginAtmosphere()),
          SafeArea(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 500),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
                  child: _buildHeroCard(context),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeroCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(22, 24, 22, 20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[
            Color(0xFF1B2642),
            Color(0xFF162037),
            Color(0xFF121A2D),
          ],
        ),
        border: Border.all(color: const Color(0xFF3A4F75), width: 1.15),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: const Color(0xFF070D1A).withOpacity(0.62),
            blurRadius: 28,
            offset: const Offset(0, 16),
          ),
          BoxShadow(
            color: const Color(0xFF2D6CFF).withOpacity(0.18),
            blurRadius: 26,
            spreadRadius: 0.3,
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const _LogoHalo(),
          const SizedBox(height: 16),
          const Text(
            'TracePath',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white,
              fontSize: 34,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.8,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Train your brain. Trace the path faster than anyone.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Color(0xFFB3C4E8),
              fontSize: 14,
              fontWeight: FontWeight.w500,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 16),
          const _BenefitRow(
            items: <String>[
              'Save progress',
              'Challenge friends',
              'Keep your streak',
            ],
          ),
          const SizedBox(height: 20),
          _GoogleButton(
            busy: _busy,
            onTap: _onGoogleTap,
          ),
          const SizedBox(height: 10),
          OutlinedButton.icon(
            onPressed: _busy
                ? null
                : () async {
                    await widget.authService.continueAsGuest();
                  },
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(double.infinity, 54),
              foregroundColor: const Color(0xFFD9E6FF),
              side: const BorderSide(color: Color(0xFF46608D), width: 1.1),
              backgroundColor: const Color(0xFF18243C).withOpacity(0.55),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            icon: const Icon(Icons.person_outline_rounded),
            label: const Text(
              'Continue as Guest',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 15,
              ),
            ),
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFF121C30).withOpacity(0.8),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFF2E3F61)),
            ),
            child: const Text(
              'Guest mode: no friends, no challenges.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Color(0xFF90A3CA),
                fontSize: 12,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.1,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _onGoogleTap() async {
    setState(() => _busy = true);
    final error = await widget.authService.signInWithGoogle();
    if (!mounted) return;
    setState(() => _busy = false);
    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }
}

class _GoogleButton extends StatelessWidget {
  const _GoogleButton({
    required this.busy,
    required this.onTap,
  });

  final bool busy;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: const Color(0xFF60A5FA).withOpacity(0.24),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ElevatedButton.icon(
        onPressed: busy ? null : onTap,
        style: ElevatedButton.styleFrom(
          minimumSize: const Size(double.infinity, 56),
          backgroundColor: Colors.white,
          foregroundColor: const Color(0xFF0F172A),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        icon: busy
            ? const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Text(
                'G',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
              ),
        label: Text(
          busy ? 'Connecting...' : 'Continue with Google',
          style: const TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: 16,
            letterSpacing: 0.2,
          ),
        ),
      ),
    );
  }
}

class _BenefitRow extends StatelessWidget {
  const _BenefitRow({required this.items});

  final List<String> items;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final item in items)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFF1D2A44).withOpacity(0.9),
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: const Color(0xFF3F5D90), width: 1),
            ),
            child: Text(
              item,
              style: const TextStyle(
                color: Color(0xFFD4E3FF),
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
      ],
    );
  }
}

class _LogoHalo extends StatelessWidget {
  const _LogoHalo();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: 126,
            height: 126,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  const Color(0xFF60A5FA).withOpacity(0.24),
                  const Color(0xFF8B5CF6).withOpacity(0.16),
                  Colors.transparent,
                ],
                stops: const [0.0, 0.42, 1.0],
              ),
            ),
          ),
          Container(
            width: 98,
            height: 98,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              color: const Color(0xFF121D32),
              border: Border.all(color: const Color(0xFF3C5682), width: 1.2),
            ),
            child: Padding(
              padding: const EdgeInsets.all(5),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Transform.scale(
                  scale: 1.14,
                  child: Image.asset(
                    'assets/branding/logo_tracePath.png',
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LoginAtmosphere extends StatelessWidget {
  const _LoginAtmosphere();

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: <Color>[
                Color(0xFF0F172A),
                Color(0xFF0C1530),
                Color(0xFF0B1325),
              ],
            ),
          ),
        ),
        Positioned.fill(
          child: IgnorePointer(
            child: CustomPaint(
              painter: _AtmospherePainter(),
            ),
          ),
        ),
      ],
    );
  }
}

class _AtmospherePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final gridPaint = Paint()
      ..style = PaintingStyle.stroke
      ..color = const Color(0xFF6E8CC2).withOpacity(0.06)
      ..strokeWidth = 1;

    const gridStep = 42.0;
    for (double x = 0; x < size.width; x += gridStep) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
    }
    for (double y = 0; y < size.height; y += gridStep) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    final nodePaint = Paint()
      ..color = const Color(0xFF9AB8EE).withOpacity(0.15)
      ..style = PaintingStyle.fill;
    final linkPaint = Paint()
      ..color = const Color(0xFF89A8DD).withOpacity(0.12)
      ..strokeWidth = 1.4
      ..style = PaintingStyle.stroke;

    final points = <Offset>[
      Offset(size.width * 0.18, size.height * 0.24),
      Offset(size.width * 0.36, size.height * 0.17),
      Offset(size.width * 0.56, size.height * 0.26),
      Offset(size.width * 0.78, size.height * 0.19),
      Offset(size.width * 0.24, size.height * 0.68),
      Offset(size.width * 0.46, size.height * 0.61),
      Offset(size.width * 0.72, size.height * 0.72),
    ];

    for (var i = 0; i < points.length - 1; i++) {
      canvas.drawLine(points[i], points[i + 1], linkPaint);
    }
    for (final p in points) {
      canvas.drawCircle(p, 2.6, nodePaint);
    }

    final glowPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          const Color(0xFF5FA4FF).withOpacity(0.18),
          Colors.transparent,
        ],
      ).createShader(
        Rect.fromCircle(
          center: Offset(size.width * 0.68, size.height * 0.30),
          radius: size.shortestSide * 0.42,
        ),
      );
    canvas.drawCircle(
      Offset(size.width * 0.68, size.height * 0.30),
      size.shortestSide * 0.42,
      glowPaint,
    );

    final sparklePaint = Paint()
      ..color = const Color(0xFFC6DBFF).withOpacity(0.18);
    for (var i = 0; i < 14; i++) {
      final dx = (i * 37.0) % size.width;
      final dy = (i * 71.0) % size.height;
      final radius = 0.9 + (i % 3) * 0.5;
      canvas.drawCircle(Offset(dx, dy), radius, sparklePaint);
    }
  }

  @override
  bool shouldRepaint(covariant _AtmospherePainter oldDelegate) => false;
}
