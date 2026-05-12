import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

class VoiceSearchModal extends StatefulWidget {
  final Function(String) onResult;

  const VoiceSearchModal({super.key, required this.onResult});

  @override
  State<VoiceSearchModal> createState() => _VoiceSearchModalState();
}

class _VoiceSearchModalState extends State<VoiceSearchModal>
    with SingleTickerProviderStateMixin {
  final stt.SpeechToText _speech = stt.SpeechToText();
  bool _isListening = false;
  String _text = 'Đang lắng nghe...';

  late AnimationController _pulseCtrl;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    _startListening();
  }

  void _startListening() async {
    try {
      bool available = await _speech.initialize(
        onStatus: (val) {
          debugPrint('Speech Status: $val');
          if (val == 'notListening' || val == 'done') {
            setState(() => _isListening = false);
          }
        },
        onError: (val) {
          debugPrint('Speech Error: ${val.errorMsg}');
          setState(() => _isListening = false);
        },
      );

      if (available) {
        setState(() {
          _isListening = true;
          _text = 'Đang lắng nghe...';
        });
        _speech.listen(
          onResult: (val) {
            setState(() {
              _text = val.recognizedWords;
            });
            if (val.finalResult) {
              Future.delayed(const Duration(milliseconds: 1000), () {
                if (mounted &&
                    _text.trim().isNotEmpty &&
                    _text != 'Đang lắng nghe...') {
                  widget.onResult(_text);
                }
              });
            }
          },
          localeId: 'vi_VN',
          cancelOnError: true,
          listenMode: stt.ListenMode.search,
        );
      } else {
        setState(() {
          _isListening = false;
          _text = 'Không thể sử dụng Micro';
        });
      }
    } catch (e) {
      debugPrint('Speech Exception: $e');
      setState(() {
        _isListening = false;
        _text = 'Lỗi kết nối Micro';
      });
    }
  }

  @override
  void dispose() {
    _speech.stop();
    _pulseCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          // blur bgr
          Positioned.fill(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
              child: Container(color: Colors.black.withValues(alpha: 0.2)),
            ),
          ),

          SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 16,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: const BoxDecoration(
                            color: Colors.white10,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            LucideIcons.x,
                            size: 18,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(),

                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 40),
                  child: AnimatedDefaultTextStyle(
                    duration: const Duration(milliseconds: 300),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      letterSpacing: -1,
                      height: 1.2,
                      shadows: [
                        Shadow(
                          color: Colors.black26,
                          blurRadius: 10,
                          offset: Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Text(_text),
                  ),
                ),

                const SizedBox(height: 24),

                Text(
                  _isListening
                      ? 'Vui lòng nói từ khóa cần tìm...'
                      : 'Nhấn để thử lại',
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.white38,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const Spacer(flex: 2),

                // voice recognition animation
                SizedBox(
                  width: double.infinity,
                  height: 140,
                  child: Stack(
                    alignment: Alignment.bottomCenter,
                    children: [
                      if (_isListening)
                        Transform.translate(
                          offset: const Offset(0, 8),
                          child: Opacity(
                            opacity: 1.0,
                            child: Lottie.asset(
                              'assets/animations/voice-recognition.json',
                              width: MediaQuery.of(context).size.width * 1.1,
                              height: 180,
                              fit: BoxFit.contain,
                            ),
                          ),
                        )
                      else
                        Padding(
                          padding: const EdgeInsets.only(bottom: 24),
                          child: GestureDetector(
                            onTap: _startListening,
                            child: Container(
                              width: 76,
                              height: 76,
                              decoration: BoxDecoration(
                                color: const Color(0xFFF5F7FA),
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(
                                      0xFFF5F7FA,
                                    ).withValues(alpha: 0.4),
                                    blurRadius: 30,
                                    spreadRadius: 5,
                                  ),
                                ],
                              ),
                              child: const Icon(
                                LucideIcons.mic,
                                size: 34,
                                color: Colors.black,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),

                const SizedBox(height: 10),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
