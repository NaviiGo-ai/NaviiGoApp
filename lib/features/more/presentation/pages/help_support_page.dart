import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/auth/auth_provider.dart';
import '../../../../core/network/api_provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../navigation/presentation/nav_hub_page.dart';
import '../../../../core/motion/nav_haptics.dart';

class HelpSupportPage extends StatelessWidget {
  const HelpSupportPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: const NavHubLeading(),
        title: Text(
          'CONCIERGE & SUPPORT',
          style: AppTypography.eyebrow(color: AppColors.brown),
        ),
        centerTitle: true,
      ),
      body: ListView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(20),
        children: [
          // AI Chat Hero
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppColors.brown, Color(0xFF3E170B)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(24),
              boxShadow: AppColors.cardShadow,
            ),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white.withAlpha(30),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.auto_awesome_rounded,
                    color: AppColors.yellow,
                    size: 36,
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  'NaviiGo AI Concierge',
                  style: AppTypography.editorialTitle(
                    color: Colors.white,
                  ).copyWith(fontSize: 22),
                ),
                const SizedBox(height: 6),
                Text(
                  'AI planning guidance. Human pilot support hours are still being confirmed. For urgent help, contact local emergency services.',
                  style: AppTypography.caption(color: Colors.white70),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                InkWell(
                  onTap: () {
                    NavHaptics.fire(NavHaptic.light);
                    _openChatSheet(context);
                  },
                  borderRadius: BorderRadius.circular(24),
                  child: Container(
                    width: double.infinity,
                    height: 48,
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: const Center(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.chat_bubble_outline_rounded,
                            color: Colors.white,
                            size: 18,
                          ),
                          SizedBox(width: 8),
                          Text(
                            'START AI CHAT',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 28),

          Text(
            'FREQUENTLY ASKED QUESTIONS',
            style: AppTypography.eyebrow(color: AppColors.primary),
          ),
          const SizedBox(height: 12),

          _buildFaqItem(
            'How do I cancel my booking or stay?',
            'Review any recorded booking references in Bookings & Vouchers. Confirm changes, cancellation terms and refunds directly with the provider that accepted your booking. A generated itinerary is not a reservation.',
          ),
          const SizedBox(height: 10),
          _buildFaqItem(
            'Can I access itineraries and routes offline?',
            'Previously loaded saved itineraries may remain available on this device. Open your plan before departure. New photos, maps, AI guidance, live updates and server changes need a connection; keep important confirmations separately.',
          ),
          const SizedBox(height: 10),
          _buildFaqItem(
            'Can someone monitor my journey?',
            'NaviiGo does not currently provide a monitored safety service. Agree on check-ins with your trusted contacts using your usual communication app. Do not rely on NaviiGo for emergency response.',
          ),
          const SizedBox(height: 10),
          _buildFaqItem(
            'What is the Digital Passport?',
            'Your Digital Passport brings together saved places and recorded journey milestones. Planning a visit does not confirm that you completed it.',
          ),

          const SizedBox(height: 36),
          Center(
            child: Text(
              'Contact the team · response times are not guaranteed',
              style: AppTypography.caption(color: AppColors.textSecondary),
            ),
          ),
          const SizedBox(height: 8),
          Center(
            child: InkWell(
              onTap: () async {
                NavHaptics.fire(NavHaptic.light);
                final uri = Uri.parse(
                  'mailto:NaviiGo24@gmail.com?subject=NaviiGo%20Pilot%20Inquiry',
                );
                if (await canLaunchUrl(uri)) {
                  await launchUrl(uri);
                } else {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Contact email: NaviiGo24@gmail.com'),
                      ),
                    );
                  }
                }
              },
              borderRadius: BorderRadius.circular(8),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                child: Text(
                  'NaviiGo24@gmail.com',
                  style: AppTypography.bodyMedium(color: AppColors.primary)
                      .copyWith(
                        fontWeight: FontWeight.bold,
                        decoration: TextDecoration.underline,
                      ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  void _openChatSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _SupportChatSheet(),
    );
  }

  Widget _buildFaqItem(String question, String answer) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Theme(
        data: ThemeData().copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          iconColor: AppColors.brown,
          collapsedIconColor: AppColors.textSecondary,
          title: Text(
            question,
            style: AppTypography.tripTitle(
              color: AppColors.textPrimary,
            ).copyWith(fontSize: 14),
          ),
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 16, right: 16, bottom: 16),
              child: Text(
                answer,
                style: AppTypography.bodySmall(
                  color: AppColors.textSecondary,
                ).copyWith(height: 1.5),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SupportChatSheet extends ConsumerStatefulWidget {
  @override
  ConsumerState<_SupportChatSheet> createState() => _SupportChatSheetState();
}

class _SupportChatSheetState extends ConsumerState<_SupportChatSheet> {
  final TextEditingController _messageController = TextEditingController();
  final List<Map<String, String>> _messages = [
    {
      'role': 'assistant',
      'text':
          'Namaste! I can help with travel planning. I am an AI assistant, not a human dispatcher. Check current access, prices and bookings with official sources. Avoid sharing private documents or payment details here.',
    },
  ];
  bool _sending = false;
  String? _error;
  String? _failedMessage;
  int _generation = 0;

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _sendMessage([String? preset, bool retry = false]) async {
    if (_sending) return;
    final text = preset ?? _messageController.text.trim();
    if (text.isEmpty) return;
    final owner = ref.read(currentUserProvider)?.uid;
    final generation = ++_generation;
    final history = _messages.where((m) => m['role'] != 'error').toList();
    if (retry && history.isNotEmpty && history.last['role'] == 'user') {
      history.removeLast();
    }
    setState(() {
      if (!retry) _messages.add({'role': 'user', 'text': text});
      if (preset == null) _messageController.clear();
      _sending = true;
      _error = null;
      _failedMessage = null;
    });
    try {
      final response = await ref
          .read(apiClientProvider)
          .post(
            '/api/chat/',
            requiresAuth: false,
            timeout: const Duration(seconds: 45),
            body: {
              'message': text,
              'context': history
                  .skip(history.length > 5 ? history.length - 5 : 0)
                  .map(
                    (m) => {
                      'sender': m['role'] == 'assistant' ? 'ai' : 'user',
                      'text': m['text'],
                    },
                  )
                  .toList(),
            },
          );
      if (!mounted ||
          generation != _generation ||
          owner != ref.read(currentUserProvider)?.uid) {
        return;
      }
      final reply = response is Map ? response['reply'] : null;
      if (reply is! String ||
          reply.trim().isEmpty ||
          reply.contains('AI Chat is in demo mode')) {
        throw const FormatException('No live reply');
      }
      setState(() {
        _messages.add({'role': 'assistant', 'text': reply.trim()});
      });
    } catch (_) {
      if (!mounted ||
          generation != _generation ||
          owner != ref.read(currentUserProvider)?.uid) {
        return;
      }
      setState(() {
        _error =
            'AI guidance is unavailable. Retry, or contact the team by email. No support request has been filed.';
        _failedMessage = text;
      });
    } finally {
      if (mounted && generation == _generation) {
        setState(() => _sending = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(currentUserProvider, (previous, next) {
      if (previous?.uid == next?.uid) return;
      setState(() {
        _generation++;
        _messages.removeRange(1, _messages.length);
        _messageController.clear();
        _sending = false;
        _error = null;
        _failedMessage = null;
      });
    });
    return Container(
      height:
          (MediaQuery.sizeOf(context).height -
              MediaQuery.viewInsetsOf(context).bottom) *
          0.85,
      margin: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: AppColors.border)),
            ),
            child: Row(
              children: [
                const CircleAvatar(
                  backgroundColor: AppColors.cream,
                  child: Icon(
                    Icons.auto_awesome_rounded,
                    color: AppColors.primary,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'NaviiGo AI Concierge',
                        style: AppTypography.tripTitle(color: AppColors.brown),
                      ),
                      Text(
                        _sending
                            ? 'Requesting AI guidance…'
                            : 'AI guidance · not monitored support',
                        style: AppTypography.micro(color: AppColors.teal),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(
                    Icons.close_rounded,
                    color: AppColors.textSecondary,
                  ),
                  tooltip: 'Close AI guidance',
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
          if (_error != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: [
                  Text(
                    _error!,
                    style: AppTypography.caption(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  TextButton(
                    onPressed: _sending
                        ? null
                        : () => _sendMessage(_failedMessage, true),
                    child: const Text('Retry AI reply'),
                  ),
                ],
              ),
            ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length,
              itemBuilder: (ctx, i) {
                final m = _messages[i];
                final isUser = m['role'] == 'user';
                return Align(
                  alignment: isUser
                      ? Alignment.centerRight
                      : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    constraints: BoxConstraints(
                      maxWidth: MediaQuery.of(context).size.width * 0.78,
                    ),
                    decoration: BoxDecoration(
                      color: isUser ? AppColors.primary : AppColors.surfaceWarm,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      m['text']!,
                      style: TextStyle(
                        color: isUser ? Colors.white : AppColors.textPrimary,
                        fontSize: 13,
                        height: 1.4,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          // Suggested prompts
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                _buildPromptChip('Help with Itinerary'),
                const SizedBox(width: 8),
                _buildPromptChip('Booking assistance'),
                const SizedBox(width: 8),
                _buildPromptChip('Emergency contacts'),
              ],
            ),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    maxLength: 4000,
                    enabled: !_sending,
                    controller: _messageController,
                    decoration: InputDecoration(
                      hintText: 'Type your inquiry...',
                      hintStyle: AppTypography.caption(
                        color: AppColors.textTertiary,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      filled: true,
                      fillColor: AppColors.surfaceWarm,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    onSubmitted: (_) => _sendMessage(),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton.filled(
                  icon: const Icon(
                    Icons.send_rounded,
                    color: Colors.white,
                    size: 18,
                  ),
                  style: IconButton.styleFrom(
                    backgroundColor: AppColors.primary,
                  ),
                  tooltip: 'Send message',
                  onPressed: _sending ? null : () => _sendMessage(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPromptChip(String text) {
    return ActionChip(
      label: Text(text, style: AppTypography.micro(color: AppColors.brown)),
      backgroundColor: AppColors.cream,
      side: BorderSide.none,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      onPressed: _sending ? null : () => _sendMessage(text),
    );
  }
}
