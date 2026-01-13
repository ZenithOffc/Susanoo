import 'dart:convert';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';

class HomePage extends StatefulWidget {
  final String username;
  final String password;
  final String sessionKey;
  final List<Map<String, dynamic>> listBug;
  final String role;
  final String expiredDate;

  const HomePage({
    super.key,
    required this.username,
    required this.password,
    required this.sessionKey,
    required this.listBug,
    required this.role,
    required this.expiredDate,
  });

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with TickerProviderStateMixin {
  final targetController = TextEditingController();
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late AnimationController _pulseController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _pulseAnimation;

  String selectedBugId = "";
  bool _isSending = false;
  String? _responseMessage;

  // Glass Effect Colors
  final Color primaryDark = const Color(0xFF0a0a0f);
  final Color primaryBlue = const Color(0xFF1a1a2e);
  final Color accentBlue = const Color(0xFF00d4ff);
  final Color lightBlue = const Color(0xFF4dd4ff);
  final Color cardDark = const Color(0xFF16162a);
  final Color cardDarker = const Color(0xFF0f0f1e);
  final Color successGreen = const Color(0xFF00ff88);
  final Color warningOrange = const Color(0xFFffa500);
  final Color dangerRed = const Color(0xFFff3366);

  // Video Player Variables
  late VideoPlayerController _videoController;
  late ChewieController _chewieController;
  bool _isVideoInitialized = false;

  @override
  void initState() {
    super.initState();

    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );

    _slideController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _slideController, curve: Curves.easeOut));

    _pulseAnimation = Tween<double>(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _fadeController.forward();
    _slideController.forward();

    if (widget.listBug.isNotEmpty) {
      selectedBugId = widget.listBug[0]['bug_id'];
    }

    _initializeVideoPlayer();
  }

  void _initializeVideoPlayer() {
    _videoController = VideoPlayerController.asset(
      'assets/videos/banner.mp4',
    );

    _videoController.initialize().then((_) {
      setState(() {
        _videoController.setVolume(0.1);
        _chewieController = ChewieController(
          videoPlayerController: _videoController,
          autoPlay: true,
          looping: true,
          showControls: false,
          autoInitialize: true,
        );
        _isVideoInitialized = true;
      });
    }).catchError((error) {
      print("Video initialization error: $error");
      setState(() {
        _isVideoInitialized = false;
      });
    });
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    _pulseController.dispose();
    targetController.dispose();
    _videoController.dispose();
    _chewieController.dispose();
    super.dispose();
  }

  String? formatPhoneNumber(String input) {
    final cleaned = input.replaceAll(RegExp(r'[^\d+]'), '');
    if (!cleaned.startsWith('+') || cleaned.length < 8) return null;
    return cleaned;
  }

  Future<void> _sendBug() async {
    final rawInput = targetController.text.trim();
    final target = formatPhoneNumber(rawInput);
    final key = widget.sessionKey;

    if (target == null || key.isEmpty) {
      _showNotification("Invalid Number",
          "Gunakan nomor internasional (misal: +62, 1, 44), bukan 08xxx.",
          dangerRed);
      return;
    }

    setState(() {
      _isSending = true;
      _responseMessage = null;
    });

    try {
      final res = await http.get(Uri.parse(
          "https://tapops.fanzhosting.my.id/sendBug?key=$key&target=$target&bug=$selectedBugId"));
      final data = jsonDecode(res.body);

      if (data["cooldown"] == true) {
        setState(() => _responseMessage = "⏳ Cooldown: Tunggu beberapa saat.");
      } else if (data["valid"] == false) {
        setState(() => _responseMessage = "❌ Key Invalid: Silakan login ulang.");
      } else if (data["sended"] == false) {
        setState(() => _responseMessage =
        "⚠️ Gagal: Server sedang maintenance.");
      } else {
        setState(() => _responseMessage = "✅ Berhasil mengirim bug ke $target!");
        targetController.clear();
      }
    } catch (_) {
      setState(() =>
      _responseMessage = "❌ Error: Terjadi kesalahan. Coba lagi.");
    } finally {
      setState(() {
        _isSending = false;
      });
    }
  }

  void _showNotification(String title, String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        content: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
            child: Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    color.withOpacity(0.2),
                    color.withOpacity(0.1),
                  ],
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: color.withOpacity(0.4),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: color.withOpacity(0.3),
                    blurRadius: 12,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: color.withOpacity(0.25),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: color.withOpacity(0.4),
                          ),
                        ),
                        child: Icon(
                          color == successGreen ? Icons.check_circle_outline :
                          color == dangerRed ? Icons.error_outline : Icons.info_outline,
                          color: color,
                          size: 24,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          title,
                          style: const TextStyle(
                            color: Color(0xFFffffff),
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                            letterSpacing: 0.3,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          msg,
                          style: TextStyle(
                            color: Color(0xFFffffff).withOpacity(0.85),
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 4),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: primaryDark,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              primaryDark,
              primaryBlue,
              primaryDark,
            ],
          ),
        ),
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: SlideTransition(
            position: _slideAnimation,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _buildHeaderSection(),
                  const SizedBox(height: 24),
                  _buildVideoSection(),
                  const SizedBox(height: 24),
                  _buildControlPanel(),
                  const SizedBox(height: 24),
                  _buildSendButton(),
                  const SizedBox(height: 16),
                  if (_responseMessage != null) _buildResponseMessage(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderSection() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                accentBlue.withOpacity(0.25),
                accentBlue.withOpacity(0.1),
              ],
            ),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: Colors.white.withOpacity(0.2),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: accentBlue.withOpacity(0.2),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            children: [
              Row(
                children: [
                  AnimatedBuilder(
                    animation: _pulseAnimation,
                    builder: (context, child) {
                      return Transform.scale(
                        scale: _pulseAnimation.value,
                        child: Container(
                          width: 70,
                          height: 70,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: LinearGradient(
                              colors: [
                                accentBlue.withOpacity(0.3),
                                lightBlue.withOpacity(0.2),
                              ],
                            ),
                            border: Border.all(
                              color: accentBlue.withOpacity(0.5),
                              width: 2.5,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: accentBlue.withOpacity(0.3),
                                blurRadius: 10,
                                spreadRadius: 2,
                              ),
                            ],
                          ),
                          child: ClipOval(
                            child: Image.asset(
                              'assets/images/logo.jpg',
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(width: 18),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.username,
                          style: const TextStyle(
                            color: Color(0xFFffffff),
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 6),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: BackdropFilter(
                            filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: Colors.white.withOpacity(0.2),
                                ),
                              ),
                              child: Text(
                                widget.role.toUpperCase(),
                                style: const TextStyle(
                                  color: Color(0xFFffffff),
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
                      child: Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.2),
                          ),
                        ),
                        child: Column(
                          children: [
                            Text(
                              "EXPIRES",
                              style: TextStyle(
                                color: Color(0xFFffffff).withOpacity(0.8),
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 0.5,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              widget.expiredDate,
                              style: const TextStyle(
                                color: Color(0xFFffffff),
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildVideoSection() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: Container(
        width: double.infinity,
        height: 220,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: accentBlue.withOpacity(0.15),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Stack(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: _isVideoInitialized
                  ? Chewie(controller: _chewieController)
                  : Container(
                      color: cardDarker,
                      child: Center(
                        child: CircularProgressIndicator(
                          color: accentBlue,
                        ),
                      ),
                    ),
            ),
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                gradient: LinearGradient(
                  colors: [
                    Colors.transparent,
                    Colors.transparent,
                    Colors.black.withOpacity(0.8),
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  stops: [0.0, 0.5, 1.0],
                ),
              ),
            ),
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: ClipRRect(
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(24),
                  bottomRight: Radius.circular(24),
                ),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Colors.black.withOpacity(0.4),
                          Colors.black.withOpacity(0.2),
                        ],
                      ),
                      border: Border(
                        top: BorderSide(
                          color: Colors.white.withOpacity(0.1),
                        ),
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: accentBlue.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: accentBlue.withOpacity(0.4),
                            ),
                          ),
                          child: Icon(
                            Icons.bolt,
                            color: accentBlue,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          "One Tap, One Dead",
                          style: TextStyle(
                            color: Color(0xFFffffff),
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                            shadows: [
                              Shadow(
                                color: Colors.black.withOpacity(0.5),
                                blurRadius: 5,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildControlPanel() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.white.withOpacity(0.1),
                Colors.white.withOpacity(0.05),
              ],
            ),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: Colors.white.withOpacity(0.2),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          accentBlue.withOpacity(0.3),
                          accentBlue.withOpacity(0.1),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: accentBlue.withOpacity(0.3),
                      ),
                    ),
                    child: Icon(
                      Icons.bug_report_outlined,
                      color: accentBlue,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    "Bug Executor",
                    style: TextStyle(
                      color: Color(0xFFffffff),
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              _buildModernInput(
                controller: targetController,
                label: "Target Number",
                hint: "e.g. +62xxxxxxxxxx",
                icon: Icons.phone_android_outlined,
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 18),
              _buildModernDropdown(
                label: "Select Bug",
                value: selectedBugId,
                items: widget.listBug,
                onChanged: (value) {
                  setState(() {
                    selectedBugId = value!;
                  });
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildModernInput({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    TextInputType? keyboardType,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: Color(0xFFffffff).withOpacity(0.9),
            fontSize: 14,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.3,
          ),
        ),
        const SizedBox(height: 10),
        ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.white.withOpacity(0.1),
                    Colors.white.withOpacity(0.05),
                  ],
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: accentBlue.withOpacity(0.3),
                  width: 1.5,
                ),
              ),
              child: TextField(
                controller: controller,
                keyboardType: keyboardType,
                style: const TextStyle(
                  color: Color(0xFFffffff),
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                ),
                decoration: InputDecoration(
                  hintText: hint,
                  hintStyle: TextStyle(
                    color: Color(0xFFffffff).withOpacity(0.4),
                  ),
                  prefixIcon: Icon(icon, color: accentBlue, size: 22),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildModernDropdown({
    required String label,
    required String value,
    required List<Map<String, dynamic>> items,
    required Function(String?) onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: Color(0xFFffffff).withOpacity(0.9),
            fontSize: 14,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.3,
          ),
        ),
        const SizedBox(height: 10),
        ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.white.withOpacity(0.1),
                    Colors.white.withOpacity(0.05),
                  ],
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: accentBlue.withOpacity(0.3),
                  width: 1.5,
                ),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 4),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: value,
                  dropdownColor: cardDarker.withOpacity(0.95),
                  isExpanded: true,
                  icon: Icon(Icons.keyboard_arrow_down_rounded, color: accentBlue, size: 28),
                  style: const TextStyle(
                    color: Color(0xFFffffff),
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                  ),
                  items: items.map((bug) {
                    return DropdownMenuItem<String>(
                      value: bug['bug_id'],
                      child: Text(
                        bug['bug_name'],
                        style: const TextStyle(color: Color(0xFFffffff)),
                      ),
                    );
                  }).toList(),
                  onChanged: onChanged,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSendButton() {
    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (context, child) {
        return ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              width: double.infinity,
              height: 60,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    accentBlue.withOpacity(0.8),
                    lightBlue.withOpacity(0.6),
                  ],
                ),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: Colors.white.withOpacity(0.3),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: accentBlue.withOpacity(0.4 + (_pulseAnimation.value - 1.0) * 0.2),
                    blurRadius: 15 + (_pulseAnimation.value - 1.0) * 15,
                    offset: const Offset(0, 6),
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: ElevatedButton(
                onPressed: _isSending ? null : _sendBug,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  foregroundColor: Color(0xFFffffff),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  elevation: 0,
                  shadowColor: Colors.transparent,
                ),
                child: _isSending
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          color: Color(0xFFffffff),
                          strokeWidth: 3,
                        ),
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.send_rounded, size: 22),
                          const SizedBox(width: 10),
                          const Text(
                            "SEND BUG",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1,
                            ),
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

  Widget _buildResponseMessage() {
    Color messageColor;
    IconData icon;

    if (_responseMessage!.startsWith('✅')) {
      messageColor = successGreen;
      icon = Icons.check_circle_outline;
    } else if (_responseMessage!.startsWith('❌')) {
      messageColor = dangerRed;
      icon = Icons.error_outline;
    } else {
      messageColor = warningOrange;
      icon = Icons.info_outline;
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                messageColor.withOpacity(0.2),
                messageColor.withOpacity(0.1),
              ],
            ),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: messageColor.withOpacity(0.4),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: messageColor.withOpacity(0.2),
                blurRadius: 12,
                spreadRadius: 1,
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: messageColor.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: messageColor.withOpacity(0.4),
                  ),
                ),
                child: Icon(icon, color: messageColor, size: 24),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  _responseMessage!,
                  style: TextStyle(
                    color: Color(0xFFffffff),
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    letterSpacing: 0.3,
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
