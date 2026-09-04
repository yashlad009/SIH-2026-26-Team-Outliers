import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/date_formatters.dart';
import '../../core/widgets/app_scaffold.dart';
import '../../core/widgets/loading_state.dart';
import '../../core/widgets/risk_badge.dart';
import '../../data/repositories/consult_repository.dart';
import '../../models/consult_request_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/consult_provider.dart';
import 'dummy_video_call_screen.dart';
import 'raise_referral_screen.dart';

class ConsultChatScreen extends ConsumerStatefulWidget {
  final ConsultRequestModel consult;
  const ConsultChatScreen({super.key, required this.consult});

  @override
  ConsumerState<ConsultChatScreen> createState() => _ConsultChatScreenState();
}

class _ConsultChatScreenState extends ConsumerState<ConsultChatScreen> {
  final _msgCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();
  bool _sending = false;

  @override
  void dispose() {
    _msgCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final text = _msgCtrl.text.trim();
    if (text.isEmpty) return;
    final user = ref.read(activeUserProfileProvider);
    if (user == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error: No active user profile found')),
        );
      }
      return;
    }

    setState(() => _sending = true);
    _msgCtrl.clear();
    try {
      final msg = ConsultMessage(
        id: '',
        senderUid: user.uid,
        senderName: user.displayName,
        senderRole: user.role.name,
        text: text,
        sentAt: DateTime.now(),
      );
      await ConsultRepository().sendMessage(widget.consult.id, msg);
      // Scroll to bottom
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scrollCtrl.hasClients) {
          _scrollCtrl.animateTo(
            _scrollCtrl.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Send failed: $e')));
      }
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  Future<void> _closeConsult() async {
    final prescCtrl = TextEditingController();
    final note = await showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Close Consultation'),
        content: TextField(
          controller: prescCtrl,
          decoration: const InputDecoration(
              labelText: 'Prescription / Follow-up note'),
          maxLines: 3,
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel')),
          ElevatedButton(
              onPressed: () => Navigator.pop(context, prescCtrl.text),
              child: const Text('Close')),
        ],
      ),
    );
    if (note == null) return;
    try {
      await ConsultRepository().closeConsult(
        consultId: widget.consult.id,
        prescriptionNote: note.trim().isEmpty ? null : note.trim(),
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Consultation closed'),
            backgroundColor: AppColors.riskLow));
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(activeUserProfileProvider);
    final messagesAsync =
        ref.watch(consultMessagesProvider(widget.consult.id));
    final isDoctor = user?.role.name == 'doctor';

    return AppScaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(widget.consult.patientName),
            Text(widget.consult.status.label,
                style: const TextStyle(color: Colors.white70, fontSize: 12)),
          ],
        ),
        actions: [
          // Video call placeholder
          IconButton(
            icon: const Icon(Icons.video_call_outlined),
            tooltip: 'Start Video Call (Demo)',
            onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => DummyVideoCallScreen(
                        patientName: widget.consult.patientName))),
          ),
          if (isDoctor) ...[
            // Raise referral
            IconButton(
              icon: const Icon(Icons.local_hospital_outlined),
              tooltip: 'Raise Referral',
              onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) =>
                          RaiseReferralScreen(consult: widget.consult))),
            ),
            // Close consult
            IconButton(
              icon: const Icon(Icons.check_circle_outline),
              tooltip: 'Close Consultation',
              onPressed: _closeConsult,
            ),
          ],
        ],
      ),
      body: Column(
        children: [
          // Consult info banner
          _InfoBanner(consult: widget.consult),
          const Divider(height: 1),
          // Messages
          Expanded(
            child: messagesAsync.when(
              data: (messages) {
                if (messages.isEmpty) {
                  return const Center(
                    child: Text(
                      'No messages yet.\nStart the conversation.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: AppColors.textSecondary),
                    ),
                  );
                }
                return ListView.builder(
                  controller: _scrollCtrl,
                  padding: const EdgeInsets.all(16),
                  itemCount: messages.length,
                  itemBuilder: (_, i) => _MessageBubble(
                    message: messages[i],
                    isMe: messages[i].senderUid == user?.uid,
                  ),
                );
              },
              loading: () => const LoadingState(),
              error: (e, _) => Center(child: Text('Error: $e')),
            ),
          ),
          // Input
          _MessageInput(
            ctrl: _msgCtrl,
            sending: _sending,
            onSend: _send,
          ),
        ],
      ),
    );
  }
}

class _InfoBanner extends StatelessWidget {
  final ConsultRequestModel consult;
  const _InfoBanner({required this.consult});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: AppColors.surfaceVariant,
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(consult.reason,
                    style: const TextStyle(fontSize: 13),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
                Text('CHW: ${consult.chwName}',
                    style: const TextStyle(
                        fontSize: 11, color: AppColors.textSecondary)),
              ],
            ),
          ),
          if (consult.triageRisk != null)
            RiskBadge(riskLevel: consult.triageRisk!),
        ],
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  final ConsultMessage message;
  final bool isMe;
  const _MessageBubble({required this.message, required this.isMe});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.75),
        child: Column(
          crossAxisAlignment:
              isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: isMe ? AppColors.primary : AppColors.surface,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(16),
                  topRight: const Radius.circular(16),
                  bottomLeft:
                      isMe ? const Radius.circular(16) : const Radius.circular(4),
                  bottomRight:
                      isMe ? const Radius.circular(4) : const Radius.circular(16),
                ),
                border: isMe
                    ? null
                    : Border.all(color: AppColors.divider),
                boxShadow: [
                  BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 4,
                      offset: const Offset(0, 2)),
                ],
              ),
              child: Text(
                message.text,
                style: TextStyle(
                    color: isMe ? Colors.white : AppColors.textPrimary,
                    fontSize: 14,
                    height: 1.4),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(top: 3, left: 4, right: 4),
              child: Text(
                '${message.senderName}  ·  ${DateFormatters.formatTime(message.sentAt)}',
                style: const TextStyle(
                    fontSize: 10, color: AppColors.textHint),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MessageInput extends StatelessWidget {
  final TextEditingController ctrl;
  final bool sending;
  final VoidCallback onSend;
  const _MessageInput(
      {required this.ctrl, required this.sending, required this.onSend});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: const BoxDecoration(
          color: AppColors.surface,
          border: Border(top: BorderSide(color: AppColors.divider)),
        ),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: ctrl,
                decoration: const InputDecoration(
                  hintText: 'Type a message…',
                  border: OutlineInputBorder(),
                  isDense: true,
                  contentPadding:
                      EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                ),
                maxLines: 3,
                minLines: 1,
                onSubmitted: (_) => onSend(),
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              onPressed: sending ? null : onSend,
              icon: sending
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.send_rounded),
              color: AppColors.primary,
              style: IconButton.styleFrom(
                backgroundColor: AppColors.primaryContainer,
                padding: const EdgeInsets.all(10),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
