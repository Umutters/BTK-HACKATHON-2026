import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimensions.dart';
import '../../core/constants/app_text_styles.dart';
import '../../viewmodels/home_viewmodel.dart';
import '../../viewmodels/oracle_viewmodel.dart';

class AiOracleScreen extends StatelessWidget {
  const AiOracleScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const _OracleView();
  }
}

class _OracleView extends StatefulWidget {
  const _OracleView();

  @override
  State<_OracleView> createState() => _OracleViewState();
}

class _OracleViewState extends State<_OracleView> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  int _lastMessageCount = 0;
  bool _wasTyping = false;

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

  void _sendMessage(String text) {
    if (text.trim().isEmpty) return;
    context.read<OracleViewModel>().sendMessage(text);
    context.read<HomeViewModel>().completeQuest('q3');
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<OracleViewModel>(
      builder: (context, vm, _) {
        // Yeni mesaj geldiğinde veya typing başladığında scroll yap
        final newMessage = vm.messages.length != _lastMessageCount;
        final typingStarted = vm.isOracleTyping && !_wasTyping;
        if (newMessage || typingStarted) {
          _lastMessageCount = vm.messages.length;
          _wasTyping = vm.isOracleTyping;
          _scrollToBottom();
        }
        return Scaffold(
          backgroundColor: AppColors.background,
          appBar: _OracleAppBar(),
          body: Column(
            children: [
              Expanded(
                child: ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppDimensions.pagePaddingH,
                    vertical: AppDimensions.spaceL,
                  ),
                  itemCount: vm.messages.length + 2,
                  itemBuilder: (context, index) {
                    if (index == 0) return const _ChatHeader();
                    final msgIndex = index - 1;
                    if (msgIndex < vm.messages.length) {
                      final msg = vm.messages[msgIndex];
                      return msg.sender == MessageSender.oracle
                          ? _OracleBubble(
                              message: msg,
                              onAction: (text) => context
                                  .read<OracleViewModel>()
                                  .sendActionButton(text),
                            )
                          : _UserBubble(message: msg);
                    }
                    // typing indicator
                    if (vm.isOracleTyping) return const _TypingIndicator();
                    return const SizedBox.shrink();
                  },
                ),
              ),
              if (vm.messages.length < 3)
                _QuickSuggestions(onTap: (text) => _sendMessage(text)),
              _InputBar(
                controller: _controller,
                onSend: () {
                  final text = _controller.text;
                  _controller.clear();
                  _sendMessage(text);
                },
              ),
            ],
          ),
        );
      },
    );
  }
}

// ─── AppBar ──────────────────────────────────────────────────────────────────

class _OracleAppBar extends StatelessWidget implements PreferredSizeWidget {
  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: AppColors.background,
      elevation: 0,
      scrolledUnderElevation: 0,
      leadingWidth: 64,
      leading: Padding(
        padding: const EdgeInsets.only(left: AppDimensions.spaceL),
        child: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.cyberBlue10,
            border: Border.all(color: AppColors.cyberBlue15),
          ),
          child: ClipOval(
            child: Image.asset(
              'assets/images/app_logo.png',
              fit: BoxFit.cover,
            ),
          ),
        ),
      ),
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'FortuneFlow Yapay Zeka',
            style: AppTextStyles.titleLarge.copyWith(
              color: AppColors.cyberBlue,
              fontWeight: FontWeight.w800,
            ),
          ),
          Row(
            children: [
              Container(
                width: 7,
                height: 7,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.neonLime,
                  boxShadow: [
                    BoxShadow(color: AppColors.neonLime50, blurRadius: 4),
                  ],
                ),
              ),
              const SizedBox(width: 5),
              Text(
                'KÂHİN ÇEVRİMİÇİ',
                style: AppTextStyles.labelSmall.copyWith(
                  color: AppColors.neonLimeDim,
                  letterSpacing: 1.5,
                ),
              ),
            ],
          ),
        ],
      ),
      actions: [
        IconButton(
          onPressed: () {
            showDialog<void>(
              context: context,
              builder: (ctx) => AlertDialog(
                backgroundColor: AppColors.surfaceContainerLow,
                title: Text(
                  'Sohbeti Temizle',
                  style: AppTextStyles.titleLarge.copyWith(
                    color: AppColors.onSurface,
                  ),
                ),
                content: Text(
                  'Tüm mesajlar silinecek. Devam etmek istiyor musun?',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.onSurfaceVariant,
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: Text(
                      'İptal',
                      style: TextStyle(color: AppColors.onSurfaceVariant),
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      context.read<OracleViewModel>().clearChat();
                      Navigator.pop(ctx);
                    },
                    child: const Text(
                      'Temizle',
                      style: TextStyle(color: AppColors.cyberMagenta),
                    ),
                  ),
                ],
              ),
            );
          },
          icon: const Icon(
            Icons.delete_sweep_rounded,
            color: AppColors.onSurfaceVariant,
            size: AppDimensions.iconL,
          ),
          padding: const EdgeInsets.only(right: AppDimensions.spaceS),
        ),
      ],
    );
  }
}

// ─── Chat Header ──────────────────────────────────────────────────────────────

class _ChatHeader extends StatelessWidget {
  const _ChatHeader();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppDimensions.spaceXXL),
      child: Column(
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppDimensions.radiusL),
              color: AppColors.cyberBlue10,
              border: Border.all(color: AppColors.cyberBlue15),
            ),
            child: const Icon(
              Icons.psychology_alt_rounded,
              color: AppColors.cyberBlue,
              size: 36,
            ),
          ),
          const SizedBox(height: AppDimensions.spaceM),
          Text(
            'Kahin Analizi Hazır',
            style: AppTextStyles.titleLarge.copyWith(
              color: AppColors.onSurface,
            ),
          ),
          const SizedBox(height: AppDimensions.spaceS),
          Text(
            'Gelir, gider ve tasarruf verilerinizi analiz ederek\nkişiselleştirilmiş finansal öneriler sunar.',
            textAlign: TextAlign.center,
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.onSurfaceVariant,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Oracle Bubble ────────────────────────────────────────────────────────────

class _OracleBubble extends StatelessWidget {
  final ChatMessage message;
  final void Function(String)? onAction;
  const _OracleBubble({required this.message, this.onAction});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppDimensions.spaceXL),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'KÂHİN',
            style: AppTextStyles.labelSmall.copyWith(
              color: AppColors.neonLime,
              letterSpacing: 2.0,
            ),
          ),
          const SizedBox(height: AppDimensions.spaceS),
          Container(
            padding: const EdgeInsets.all(AppDimensions.spaceL),
            decoration: BoxDecoration(
              color: AppColors.surfaceContainerLow,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(4),
                topRight: Radius.circular(AppDimensions.radiusL),
                bottomLeft: Radius.circular(AppDimensions.radiusL),
                bottomRight: Radius.circular(AppDimensions.radiusL),
              ),
              border: Border.all(color: AppColors.glass12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _RichOracleText(text: message.text),
                if (message.actionButtons != null) ...[
                  const SizedBox(height: AppDimensions.spaceM),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: message.actionButtons!
                        .map(
                          (btn) => _ActionButton(
                            label: btn,
                            onTap: () => onAction?.call(btn),
                          ),
                        )
                        .toList(),
                  ),
                ],
                if (message.dataCard != null) ...[
                  const SizedBox(height: AppDimensions.spaceM),
                  _DataCardWidget(card: message.dataCard!),
                ],
              ],
            ),
          ),
          const SizedBox(height: AppDimensions.spaceXS),
          Text(
            _formatTime(message.timestamp),
            style: AppTextStyles.labelSmall.copyWith(
              color: AppColors.outline,
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Rich text: **bold** → cyan ───────────────────────────────────────────────

class _RichOracleText extends StatelessWidget {
  final String text;
  const _RichOracleText({required this.text});

  @override
  Widget build(BuildContext context) {
    final spans = <TextSpan>[];
    final regex = RegExp(r'\*\*(.+?)\*\*');
    int last = 0;
    for (final match in regex.allMatches(text)) {
      if (match.start > last) {
        spans.add(TextSpan(text: text.substring(last, match.start)));
      }
      spans.add(
        TextSpan(
          text: match.group(1),
          style: const TextStyle(
            color: AppColors.cyberBlue,
            fontWeight: FontWeight.w700,
          ),
        ),
      );
      last = match.end;
    }
    if (last < text.length) {
      spans.add(TextSpan(text: text.substring(last)));
    }
    return RichText(
      text: TextSpan(
        style: AppTextStyles.bodyMedium.copyWith(
          color: AppColors.onSurface,
          height: 1.55,
        ),
        children: spans,
      ),
    );
  }
}

// ─── Action Button ────────────────────────────────────────────────────────────

class _ActionButton extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;
  const _ActionButton({required this.label, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
          border: Border.all(color: AppColors.cyberBlue),
          color: AppColors.cyberBlue10,
        ),
        child: Text(
          label,
          style: AppTextStyles.labelMedium.copyWith(
            color: AppColors.cyberBlue,
            fontSize: 13,
            letterSpacing: 0.3,
          ),
        ),
      ),
    );
  }
}

// ─── Data Card ────────────────────────────────────────────────────────────────

class _DataCardWidget extends StatelessWidget {
  final DataCard card;
  const _DataCardWidget({required this.card});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.glass08,
        borderRadius: BorderRadius.circular(AppDimensions.radiusM),
        border: Border.all(color: AppColors.glass15),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                card.label,
                style: AppTextStyles.labelMedium.copyWith(
                  color: AppColors.onSurfaceVariant,
                  letterSpacing: 1.5,
                ),
              ),
              Text(
                card.value,
                style: AppTextStyles.labelLarge.copyWith(
                  color: AppColors.neonLime,
                  fontSize: 15,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
            child: LinearProgressIndicator(
              value: card.progress,
              minHeight: 6,
              backgroundColor: AppColors.surfaceContainerHighest,
              valueColor: const AlwaysStoppedAnimation<Color>(
                AppColors.neonLime,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── User Bubble ──────────────────────────────────────────────────────────────

class _UserBubble extends StatelessWidget {
  final ChatMessage message;
  const _UserBubble({required this.message});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppDimensions.spaceXL),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            'SEN',
            style: AppTextStyles.labelSmall.copyWith(
              color: AppColors.cyberBlue,
              letterSpacing: 2.0,
            ),
          ),
          const SizedBox(height: AppDimensions.spaceS),
          Container(
            padding: const EdgeInsets.all(AppDimensions.spaceL),
            decoration: BoxDecoration(
              color: AppColors.cyberBlue15,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(AppDimensions.radiusL),
                topRight: Radius.circular(4),
                bottomLeft: Radius.circular(AppDimensions.radiusL),
                bottomRight: Radius.circular(AppDimensions.radiusL),
              ),
              border: Border.all(color: AppColors.cyberBlue20),
            ),
            child: Text(
              message.text,
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.onSurface,
                height: 1.55,
              ),
            ),
          ),
          const SizedBox(height: AppDimensions.spaceXS),
          Text(
            _formatTime(message.timestamp),
            style: AppTextStyles.labelSmall.copyWith(
              color: AppColors.outline,
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Typing Indicator ─────────────────────────────────────────────────────────

class _TypingIndicator extends StatefulWidget {
  const _TypingIndicator();

  @override
  State<_TypingIndicator> createState() => _TypingIndicatorState();
}

class _TypingIndicatorState extends State<_TypingIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
    _anim = Tween<double>(begin: 0.3, end: 1.0).animate(_ctrl);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppDimensions.spaceXL),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'KÂHİN',
            style: AppTextStyles.labelSmall.copyWith(
              color: AppColors.neonLime,
              letterSpacing: 2.0,
            ),
          ),
          const SizedBox(height: AppDimensions.spaceS),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: AppColors.surfaceContainerLow,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(4),
                topRight: Radius.circular(AppDimensions.radiusL),
                bottomLeft: Radius.circular(AppDimensions.radiusL),
                bottomRight: Radius.circular(AppDimensions.radiusL),
              ),
              border: Border.all(color: AppColors.glass12),
            ),
            child: AnimatedBuilder(
              animation: _anim,
              builder: (_, _) => Row(
                mainAxisSize: MainAxisSize.min,
                children: List.generate(3, (i) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 3),
                    child: Opacity(
                      opacity: (_anim.value - i * 0.15).clamp(0.2, 1.0),
                      child: Container(
                        width: 7,
                        height: 7,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.cyberBlue,
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Input Bar ────────────────────────────────────────────────────────────────

class _InputBar extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback onSend;

  const _InputBar({required this.controller, required this.onSend});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppDimensions.pagePaddingH,
          vertical: AppDimensions.spaceM,
        ),
        decoration: const BoxDecoration(
          color: AppColors.background,
          border: Border(
            top: BorderSide(color: AppColors.outlineVariant, width: 0.5),
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: controller,
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.onSurface,
                  fontSize: 15,
                ),
                decoration: InputDecoration(
                  hintText: 'Kâhine komut ver...',
                  hintStyle: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.outline,
                    fontSize: 15,
                  ),
                  filled: true,
                  fillColor: AppColors.glass08,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppDimensions.radiusL),
                    borderSide: const BorderSide(color: AppColors.glass12),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppDimensions.radiusL),
                    borderSide: const BorderSide(color: AppColors.glass12),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppDimensions.radiusL),
                    borderSide: const BorderSide(
                      color: AppColors.cyberBlue,
                      width: 1,
                    ),
                  ),
                ),
                onSubmitted: (_) => onSend(),
                textInputAction: TextInputAction.send,
              ),
            ),
            const SizedBox(width: AppDimensions.spaceM),
            GestureDetector(
              onTap: onSend,
              child: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.neonLime,
                  borderRadius: BorderRadius.circular(AppDimensions.radiusM),
                  boxShadow: const [
                    BoxShadow(
                      color: AppColors.neonLime20,
                      blurRadius: 12,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.send_rounded,
                  color: AppColors.background,
                  size: 20,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Quick Suggestions ────────────────────────────────────────────────────────

class _QuickSuggestions extends StatelessWidget {
  final void Function(String) onTap;
  const _QuickSuggestions({required this.onTap});

  static const _suggestions = [
    'Günlük harcama analiz et',
    'Tasarruf önerisi ver',
    'Bu ay nasıl gidiyor?',
    'Risk değerlendirmesi yap',
  ];

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(
          horizontal: AppDimensions.pagePaddingH,
        ),
        itemCount: _suggestions.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (_, i) => GestureDetector(
          onTap: () => onTap(_suggestions[i]),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
              border: Border.all(color: AppColors.glass15),
              color: AppColors.glass08,
            ),
            child: Text(
              _suggestions[i],
              style: AppTextStyles.labelMedium.copyWith(
                color: AppColors.onSurfaceVariant,
                fontSize: 13,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Helpers ──────────────────────────────────────────────────────────────────

String _formatTime(DateTime dt) {
  final h = dt.hour.toString().padLeft(2, '0');
  final m = dt.minute.toString().padLeft(2, '0');
  return '$h:$m';
}
