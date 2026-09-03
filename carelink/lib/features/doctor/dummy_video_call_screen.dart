import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';

/// Dummy video call screen — visual placeholder only.
/// Real WebRTC is out of scope for this MVP.
class DummyVideoCallScreen extends StatefulWidget {
  final String patientName;
  const DummyVideoCallScreen({super.key, required this.patientName});

  @override
  State<DummyVideoCallScreen> createState() => _DummyVideoCallScreenState();
}

class _DummyVideoCallScreenState extends State<DummyVideoCallScreen> {
  bool _muted = false;
  bool _videoOff = false;
  bool _speakerOn = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A2E),
      body: SafeArea(
        child: Stack(
          children: [
            // "Remote video" background
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircleAvatar(
                    radius: 56,
                    backgroundColor: AppColors.primaryContainer,
                    child: Text(
                      _initials(widget.patientName),
                      style: const TextStyle(
                          fontSize: 36,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primary),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    widget.patientName,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.riskLow.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                      border:
                          Border.all(color: AppColors.riskLow.withOpacity(0.4)),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.circle,
                            color: AppColors.riskLow, size: 8),
                        SizedBox(width: 6),
                        Text('Connected',
                            style: TextStyle(
                                color: AppColors.riskLow, fontSize: 12)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    '⚠️  Demo mode — no real video call',
                    style: TextStyle(
                        color: Colors.white38,
                        fontSize: 11,
                        fontStyle: FontStyle.italic),
                  ),
                ],
              ),
            ),

            // Self-view (PiP placeholder)
            Positioned(
              top: 16,
              right: 16,
              child: Container(
                width: 90,
                height: 130,
                decoration: BoxDecoration(
                  color: const Color(0xFF2D2D44),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.white24),
                ),
                child: const Center(
                  child: Icon(Icons.person_outline,
                      color: Colors.white38, size: 32),
                ),
              ),
            ),

            // Top bar
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: AppBar(
                backgroundColor: Colors.transparent,
                elevation: 0,
                leading: IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.white),
                  onPressed: () => Navigator.pop(context),
                ),
                title: const Text('Video Call',
                    style: TextStyle(color: Colors.white)),
              ),
            ),

            // Controls bar
            Positioned(
              bottom: 24,
              left: 0,
              right: 0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _CallButton(
                    icon: _muted ? Icons.mic_off : Icons.mic,
                    label: _muted ? 'Unmute' : 'Mute',
                    active: _muted,
                    onTap: () => setState(() => _muted = !_muted),
                  ),
                  _CallButton(
                    icon: Icons.call_end,
                    label: 'End',
                    isEndCall: true,
                    onTap: () => Navigator.pop(context),
                  ),
                  _CallButton(
                    icon: _videoOff ? Icons.videocam_off : Icons.videocam,
                    label: _videoOff ? 'Start Video' : 'Stop Video',
                    active: _videoOff,
                    onTap: () => setState(() => _videoOff = !_videoOff),
                  ),
                  _CallButton(
                    icon: _speakerOn ? Icons.volume_up : Icons.volume_off,
                    label: 'Speaker',
                    onTap: () => setState(() => _speakerOn = !_speakerOn),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _initials(String name) {
    final parts = name.trim().split(' ');
    if (parts.length >= 2) return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
    return parts.isNotEmpty ? parts.first[0].toUpperCase() : '?';
  }
}

class _CallButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool active;
  final bool isEndCall;
  final VoidCallback onTap;

  const _CallButton({
    required this.icon,
    required this.label,
    required this.onTap,
    this.active = false,
    this.isEndCall = false,
  });

  @override
  Widget build(BuildContext context) {
    final bg = isEndCall
        ? AppColors.riskHigh
        : active
            ? Colors.white24
            : const Color(0xFF2D2D44);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        GestureDetector(
          onTap: onTap,
          child: Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: bg,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: Colors.white, size: 24),
          ),
        ),
        const SizedBox(height: 6),
        Text(label,
            style: const TextStyle(color: Colors.white60, fontSize: 11)),
      ],
    );
  }
}
