import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/d2c_ai_assistant_service.dart';

class D2CAiAssistantDialog extends StatefulWidget {
  const D2CAiAssistantDialog({super.key});

  static Future<void> show(BuildContext context) {
    return showDialog<void>(
      context: context,
      builder: (dialogContext) => const D2CAiAssistantDialog(),
    );
  }

  @override
  State<D2CAiAssistantDialog> createState() => _D2CAiAssistantDialogState();
}

class _D2CAiAssistantDialogState extends State<D2CAiAssistantDialog> {
  final _aiService = D2CAiAssistantService();
  final _textController = TextEditingController();
  final _scrollController = ScrollController();
  final List<D2CAiChatMessage> _messages = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Welcome message
    _messages.add(
      D2CAiChatMessage(
        sender: 'ai',
        text: '''
🤖 **Selamat datang ke Pembantu AI D2C!**

Saya sedia membantu anda memahami Program **Dare to Change (D2C) SMK Sungai Damit**.

Apa yang boleh saya bantu anda hari ini?''',
        timestamp: DateTime.now(),
      ),
    );
  }

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _sendMessage(String text) async {
    final prompt = text.trim();
    if (prompt.isEmpty || _isLoading) return;

    _textController.clear();
    setState(() {
      _messages.add(
        D2CAiChatMessage(
          sender: 'user',
          text: prompt,
          timestamp: DateTime.now(),
        ),
      );
      _isLoading = true;
    });
    _scrollToBottom();

    try {
      final reply = await _aiService.askAi(prompt, _messages);
      if (mounted) {
        setState(() {
          _messages.add(
            D2CAiChatMessage(
              sender: 'ai',
              text: reply,
              timestamp: DateTime.now(),
            ),
          );
        });
        _scrollToBottom();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _messages.add(
            D2CAiChatMessage(
              sender: 'ai',
              text: 'Maaf, berlaku ralat teknikal. Sila cuba lagi.',
              timestamp: DateTime.now(),
            ),
          );
        });
        _scrollToBottom();
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: Container(
        width: screenWidth > 640 ? 540 : double.infinity,
        height: 620,
        decoration: BoxDecoration(
          color: const Color(0xFF090F1E),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: const Color(0xFF38BDF8), width: 1.8),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF38BDF8).withValues(alpha: 0.3),
              blurRadius: 24,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Column(
          children: [
            // DIALOG HEADER
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              decoration: const BoxDecoration(
                color: Color(0xFF0D172E),
                borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
                border: Border(bottom: BorderSide(color: Color(0x3338BDF8))),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0284C7).withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                      border: Border.all(color: const Color(0xFF38BDF8)),
                    ),
                    child: const Icon(Icons.smart_toy_rounded, color: Color(0xFF38BDF8), size: 22),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'PEMBANTU AI D2C',
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 15, letterSpacing: 0.8),
                      ),
                      Row(
                        children: [
                          Container(width: 6, height: 6, decoration: const BoxDecoration(color: Color(0xFF10B981), shape: BoxShape.circle)),
                          const SizedBox(width: 6),
                          const Text(
                            'GEMINI INTELLIGENCE • ONLINE',
                            style: TextStyle(color: Color(0xFF38BDF8), fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 0.5),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white70),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),

            // CHAT MESSAGES LIST
            Expanded(
              child: ListView.separated(
                controller: _scrollController,
                padding: const EdgeInsets.all(16),
                itemCount: _messages.length,
                separatorBuilder: (_, _) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final msg = _messages[index];
                  final isUser = msg.sender == 'user';
                  final timeFormat = DateFormat('h:mm a');

                  return Align(
                    alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
                    child: Container(
                      constraints: BoxConstraints(maxWidth: screenWidth * 0.75),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: isUser ? const Color(0xFF0284C7) : const Color(0xFF131F37),
                        borderRadius: BorderRadius.only(
                          topLeft: const Radius.circular(16),
                          topRight: const Radius.circular(16),
                          bottomLeft: Radius.circular(isUser ? 16 : 4),
                          bottomRight: Radius.circular(isUser ? 4 : 16),
                        ),
                        border: Border.all(
                          color: isUser ? const Color(0xFF38BDF8) : const Color(0x3338BDF8),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            msg.text,
                            style: TextStyle(
                              color: isUser ? Colors.white : Colors.grey.shade200,
                              fontSize: 13,
                              height: 1.5,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Align(
                            alignment: Alignment.bottomRight,
                            child: Text(
                              timeFormat.format(msg.timestamp),
                              style: TextStyle(
                                fontSize: 9,
                                color: isUser ? Colors.white70 : Colors.grey.shade500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),

            if (_isLoading) ...[
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: [
                    SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF38BDF8))),
                    SizedBox(width: 8),
                    Text('Pembantu AI sedang menaip respon...', style: TextStyle(color: Color(0xFF38BDF8), fontSize: 11, fontStyle: FontStyle.italic)),
                  ],
                ),
              ),
            ],

            // QUICK CHIPS ROW
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              child: Row(
                children: [
                  _QuickChip(label: '🏆 Mata Merit', onTap: () => _sendMessage('Bagaimana 4 mata merit harian dikira?')),
                  _QuickChip(label: '🛡️ 3 Aras Intervensi', onTap: () => _sendMessage('Apakah 3 Aras Intervensi D2C?')),
                  _QuickChip(label: '📣 Suara Murid Rahsia', onTap: () => _sendMessage('Bagaimana hantar Suara Murid secara rahsia?')),
                  _QuickChip(label: '👨‍👩‍👧‍👦 Portal Ibu Bapa', onTap: () => _sendMessage('Bagaimana ibu bapa semak kehadiran?')),
                  _QuickChip(label: '🏛️ Jawatankuasa', onTap: () => _sendMessage('Siapakah Jawatankuasa Induk D2C?')),
                ],
              ),
            ),

            // INPUT BAR
            Container(
              padding: const EdgeInsets.all(12),
              decoration: const BoxDecoration(
                color: Color(0xFF0D172E),
                borderRadius: BorderRadius.vertical(bottom: Radius.circular(22)),
                border: Border(top: BorderSide(color: Color(0x3338BDF8))),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _textController,
                      style: const TextStyle(color: Colors.white, fontSize: 13),
                      decoration: const InputDecoration(
                        hintText: 'Taip soalan mengenai D2C di sini...',
                        hintStyle: TextStyle(color: Colors.white38, fontSize: 13),
                        border: InputBorder.none,
                        isDense: true,
                      ),
                      onSubmitted: _sendMessage,
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.send_rounded, color: Color(0xFF38BDF8)),
                    onPressed: () => _sendMessage(_textController.text),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _QuickChip extends StatelessWidget {
  const _QuickChip({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: ActionChip(
        label: Text(label, style: const TextStyle(color: Color(0xFF38BDF8), fontSize: 11, fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF0284C7).withValues(alpha: 0.15),
        side: const BorderSide(color: Color(0x4438BDF8)),
        onPressed: onTap,
      ),
    );
  }
}
