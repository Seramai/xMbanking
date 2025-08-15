import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:math' as math;

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _logoController;
  late AnimationController _crackController;
  late AnimationController _dotsController;
  late Animation<double> _logoAnimation;
  late Animation<double> _crackAnimation;

  @override
  void initState() {
    super.initState();
    _logoController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
    
    _crackController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    );
    
    _dotsController = AnimationController(
      duration: const Duration(milliseconds: 1400),
      vsync: this,
    );
    _logoAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _logoController,
      curve: Curves.easeOut,
    ));

    _crackAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _crackController,
      curve: Curves.easeInOut,
    ));
    _startAnimations();
    _initializeAndNavigate();
  }

  void _startAnimations() {
    _logoController.forward();
    _crackController.repeat();
    _dotsController.repeat();
  }

  Future<void> _initializeAndNavigate() async {
    await Future.delayed(const Duration(seconds: 9));
    if (mounted) {
      Navigator.of(context).pushReplacementNamed('/login');
    }
  }

  @override
  void dispose() {
    _logoController.dispose();
    _crackController.dispose();
    _dotsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF1A237E),
              Color(0xFF303F9F),
            ],
          ),
        ),
        child: Stack(
          children: [
            _buildGlassContainer(),
            _buildSplashContent(),
          ],
        ),
      ),
    );
  }

  Widget _buildGlassContainer() {
    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white.withOpacity(0.15),
            Colors.white.withOpacity(0.08), 
            Colors.white.withOpacity(0.15), 
          ],
        ),
      ),
      child: Stack(
        children: [
          ..._buildCrackLines(),
          ..._buildGlassFragments(),
          ..._buildFloatingParticles(),
        ],
      ),
    );
  }

  List<Widget> _buildCrackLines() {
    return [
      _buildCrack(0.15, 0.0, 350.0, 6.0, 35.0, 0.0),
      _buildCrack(0.82, 0.1, 300.0, 5.0, -45.0, 0.8),
      _buildCrack(0.25, 0.7, 320.0, 7.0, 65.0, 1.6),
      _buildCrack(0.92, 0.3, 280.0, 4.0, -30.0, 2.4),
      _buildCrack(0.40, 0.5, 260.0, 5.0, 15.0, 0.4),
      _buildCrack(0.35, 0.6, 290.0, 6.0, -60.0, 2.0),
      _buildCrack(0.60, 0.15, 240.0, 4.0, 45.0, 1.2),
      _buildCrack(0.05, 0.4, 270.0, 5.0, -20.0, 2.8),
    ];
  }

  Widget _buildCrack(double leftPercent, double topPercent, double height, 
                     double width, double rotation, double delay) {
    return AnimatedBuilder(
      animation: _crackAnimation,
      builder: (context, child) {
        double animValue = (_crackAnimation.value + delay) % 1.0;
        double opacity = _getCrackOpacity(animValue) * 0.3;
        double scale = _getCrackScale(animValue);
        
        return Positioned(
          left: MediaQuery.of(context).size.width * leftPercent,
          top: MediaQuery.of(context).size.height * topPercent,
          child: Transform.rotate(
            angle: rotation * math.pi / 180,
            child: Transform.scale(
              scale: scale,
              child: Container(
                width: width,
                height: height,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.white.withOpacity(opacity * 0.6),
                      Colors.white.withOpacity(opacity * 0.4),
                      Colors.white.withOpacity(opacity * 0.2), 
                    ],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.white.withOpacity(opacity * 0.3),
                      blurRadius: 10,
                      spreadRadius: 2,
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  double _getCrackOpacity(double animValue) {
    if (animValue < 0.15) return animValue / 0.15 * 0.6;
    if (animValue < 0.35) return 0.9;
    if (animValue < 0.65) return 1.0;
    if (animValue < 0.85) return 1.0 - (animValue - 0.65) / 0.2 * 0.6;
    return (1.0 - animValue) / 0.15 * 0.4;
  }

  double _getCrackScale(double animValue) {
    if (animValue < 0.15) return animValue / 0.15 * 0.8;
    if (animValue < 0.35) return 1.0;
    if (animValue < 0.65) return 1.2;
    if (animValue < 0.85) return 1.2 - (animValue - 0.65) / 0.2 * 0.5;
    return 0.7 - (1.0 - animValue) / 0.15 * 0.5;
  }

  List<Widget> _buildGlassFragments() {
    return [
      _buildFragment(0.28, 0.18, 15.0, 20.0, 0.0),
      _buildFragment(0.72, 0.58, 12.0, 18.0, 1.5),
      _buildFragment(0.48, 0.78, 18.0, 14.0, 3.0),
      _buildFragment(0.68, 0.38, 14.0, 22.0, 0.8),
      _buildFragment(0.88, 0.58, 10.0, 16.0, 2.3),
    ];
  }

  Widget _buildFragment(double leftPercent, double topPercent, double width,
                       double height, double delay) {
    return AnimatedBuilder(
      animation: _crackAnimation,
      builder: (context, child) {
        double animValue = (_crackAnimation.value + delay) % 1.0;
        double translateY = math.sin(animValue * math.pi * 2) * 20;
        double rotation = animValue * math.pi * 2;
        double opacity = (math.sin(animValue * math.pi * 2) * 0.3 + 0.7) * 0.4; 
        
        return Positioned(
          left: MediaQuery.of(context).size.width * leftPercent,
          top: MediaQuery.of(context).size.height * topPercent + translateY,
          child: Transform.rotate(
            angle: rotation,
            child: Container(
              width: width,
              height: height,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.white.withOpacity(opacity * 0.4), 
                    Colors.white.withOpacity(opacity * 0.6),
                    Colors.white.withOpacity(opacity * 0.3),
                  ],
                ),
                borderRadius: BorderRadius.circular(2),
                boxShadow: [
                  BoxShadow(
                    color: Colors.white.withOpacity(opacity * 0.2), 
                    blurRadius: 4,
                    spreadRadius: 1,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  List<Widget> _buildFloatingParticles() {
    return [
      _buildParticle(0.10, 0.20, 4.0, 0.0),
      _buildParticle(0.80, 0.60, 6.0, 2.0),
      _buildParticle(0.30, 0.70, 3.0, 4.0),
      _buildParticle(0.70, 0.40, 5.0, 1.0),
    ];
  }

  Widget _buildParticle(double leftPercent, double topPercent, double size, double delay) {
    return AnimatedBuilder(
      animation: _crackController,
      builder: (context, child) {
        double animValue = (_crackController.value + delay / 6) % 1.0;
        double translateY = math.sin(animValue * math.pi * 2) * 20;
        double opacity = math.sin(animValue * math.pi * 2) * 0.3 + 0.5;
        
        return Positioned(
          left: MediaQuery.of(context).size.width * leftPercent,
          top: MediaQuery.of(context).size.height * topPercent + translateY,
          child: Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(opacity * 0.2),
              shape: BoxShape.circle,
            ),
          ),
        );
      },
    );
  }

  Widget _buildSplashContent() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          AnimatedBuilder(
            animation: _logoAnimation,
            builder: (context, child) {
              return Transform.translate(
                offset: Offset(0, (1 - _logoAnimation.value) * -50),
                child: Transform.scale(
                  scale: 0.8 + _logoAnimation.value * 0.2,
                  child: Opacity(
                    opacity: _logoAnimation.value,
                    child: Container(
                      width: 150,
                      height: 150,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(30),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.3),
                            blurRadius: 30,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(30),
                        child: Image.asset(
                          'assets/images/logo.jpg',
                          width: 120,
                          height: 120,
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
          
          const SizedBox(height: 60),
          AnimatedBuilder(
            animation: _logoAnimation,
            builder: (context, child) {
              return Transform.translate(
                offset: Offset(0, (1 - _logoAnimation.value) * 30),
                child: Opacity(
                  opacity: _logoAnimation.value,
                  child: const Column(
                    children: [
                      Text(
                        'Welcome to',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.w300,
                          shadows: [
                            Shadow(
                              offset: Offset(0, 2),
                              blurRadius: 4,
                              color: Colors.black26,
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: 10),
                      Text(
                        'BUDDU CBS PEWOSA SACCO\nMOBILE APP',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 1,
                          height: 1.2,
                          shadows: [
                            Shadow(
                              offset: Offset(0, 2),
                              blurRadius: 4,
                              color: Colors.black26,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
          
          const SizedBox(height: 80),
          AnimatedBuilder(
            animation: _dotsController,
            builder: (context, child) {
              return Opacity(
                opacity: _logoAnimation.value,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(3, (index) {
                    double delay = index * 0.2;
                    double animValue = (_dotsController.value + delay) % 1.0;
                    double scale = animValue < 0.4 
                        ? (1.0 + math.sin(animValue * math.pi / 0.4) * 0.4)
                        : 0.8;
                    double opacity = animValue < 0.4 ? 1.0 : 0.5;
                    
                    return Container(
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      child: Transform.scale(
                        scale: scale,
                        child: Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(opacity),
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                    );
                  }),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}