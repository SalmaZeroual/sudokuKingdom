import 'package:flutter/material.dart';
import 'dart:math';

class KingdomParticles extends StatefulWidget {
  final int kingdomId;
  final Color kingdomColor;
  
  const KingdomParticles({
    Key? key,
    required this.kingdomId,
    required this.kingdomColor,
  }) : super(key: key);

  @override
  State<KingdomParticles> createState() => _KingdomParticlesState();
}

class _KingdomParticlesState extends State<KingdomParticles>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final List<Particle> _particles = [];
  final Random _random = Random();

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat();

    // Generate particles based on kingdom
    _generateParticles();
  }

  void _generateParticles() {
    final particleCount = 15;
    for (int i = 0; i < particleCount; i++) {
      _particles.add(
        Particle(
          x: _random.nextDouble(),
          y: _random.nextDouble(),
          size: _random.nextDouble() * 4 + 2,
          speed: _random.nextDouble() * 0.5 + 0.3,
          opacity: _random.nextDouble() * 0.3 + 0.1,
          icon: _getParticleIcon(),
        ),
      );
    }
  }

  String _getParticleIcon() {
    switch (widget.kingdomId) {
      case 1: // Forêt
        return ['🍃', '🌿', '✨'][_random.nextInt(3)];
      case 2: // Désert
        return ['✨', '💫', '⭐'][_random.nextInt(3)];
      case 3: // Océan
        return ['💧', '🫧', '✨'][_random.nextInt(3)];
      case 4: // Montagnes
        return ['❄️', '✨', '💎'][_random.nextInt(3)];
      case 5: // Cosmos
        return ['⭐', '✨', '💫', '🌟'][_random.nextInt(4)];
      default:
        return '✨';
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return CustomPaint(
          painter: ParticlePainter(
            particles: _particles,
            animation: _controller.value,
            color: widget.kingdomColor,
          ),
          size: Size.infinite,
        );
      },
    );
  }
}

class Particle {
  double x;
  double y;
  final double size;
  final double speed;
  final double opacity;
  final String icon;

  Particle({
    required this.x,
    required this.y,
    required this.size,
    required this.speed,
    required this.opacity,
    required this.icon,
  });
}

class ParticlePainter extends CustomPainter {
  final List<Particle> particles;
  final double animation;
  final Color color;

  ParticlePainter({
    required this.particles,
    required this.animation,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    for (var particle in particles) {
      // Update position
      particle.y = (particle.y - particle.speed * 0.001) % 1.0;

      final x = particle.x * size.width;
      final y = particle.y * size.height;

      // Draw particle as emoji
      final textPainter = TextPainter(
        text: TextSpan(
          text: particle.icon,
          style: TextStyle(
            fontSize: particle.size * 4,
            height: 1.0,
          ),
        ),
        textDirection: TextDirection.ltr,
      );
      textPainter.layout();

      final offset = Offset(
        x - textPainter.width / 2,
        y - textPainter.height / 2,
      );

      canvas.save();
      canvas.translate(offset.dx, offset.dy);
      
      // Add opacity
      canvas.saveLayer(
        Rect.fromLTWH(0, 0, textPainter.width, textPainter.height),
        Paint()..color = Colors.white.withOpacity(particle.opacity),
      );
      
      textPainter.paint(canvas, Offset.zero);
      canvas.restore();
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(ParticlePainter oldDelegate) => true;
}