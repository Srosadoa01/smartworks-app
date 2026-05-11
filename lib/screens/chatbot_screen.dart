import 'package:flutter/material.dart';

import '../models/chat_message.dart';
import '../services/chat_api_service.dart';

class ChatbotScreen extends StatefulWidget {
  const ChatbotScreen({super.key});

  @override
  State<ChatbotScreen> createState() => _ChatbotScreenState();
}

class _ChatbotScreenState extends State<ChatbotScreen> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _focusNode = FocusNode();

  final ChatApiService _chatApiService = ChatApiService();

  final String conversationId = DateTime.now().millisecondsSinceEpoch.toString();

  final List<ChatMessage> _messages = [
    ChatMessage(
      text:
      'Hola, soy el asistente virtual de SmartWorks. Puedo ayudarte con inventario, stock, clientes, pedidos y análisis del negocio.',
      isUser: false,
    ),
  ];

  bool _isLoading = false;

  final List<_SuggestionItem> _suggestions = const [
    _SuggestionItem(
      title: 'Stock bajo',
      prompt: '¿Qué productos tienen stock bajo?',
      icon: Icons.warning_amber_rounded,
    ),
    _SuggestionItem(
      title: 'Sin stock',
      prompt: '¿Qué productos están agotados?',
      icon: Icons.inventory_2_outlined,
    ),
    _SuggestionItem(
      title: 'Inventario',
      prompt: 'Dame un resumen del inventario',
      icon: Icons.warehouse_rounded,
    ),
    _SuggestionItem(
      title: 'Pedidos',
      prompt: 'Muéstrame los pedidos recientes',
      icon: Icons.receipt_long_rounded,
    ),
    _SuggestionItem(
      title: 'Mes actual',
      prompt: 'Dame un resumen de pedidos del mes',
      icon: Icons.calendar_month_rounded,
    ),
    _SuggestionItem(
      title: 'Crear cliente',
      prompt: 'Crea un cliente llamado Samuel con teléfono 600123123',
      icon: Icons.person_add_alt_1_rounded,
    ),
  ];

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _sendMessage({String? customText}) async {
    final text = (customText ?? _controller.text).trim();

    if (text.isEmpty || _isLoading) return;

    setState(() {
      _messages.add(
        ChatMessage(
          text: text,
          isUser: true,
        ),
      );
      _isLoading = true;
    });

    _controller.clear();
    _scrollToBottom();

    try {
      final reply = await _chatApiService.sendMessage(
        message: text,
        conversationId: conversationId,
      );

      if (!mounted) return;

      setState(() {
        _messages.add(
          ChatMessage(
            text: reply,
            isUser: false,
          ),
        );
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _messages.add(
          ChatMessage(
            text:
            'No he podido conectar con el asistente en este momento. Comprueba que la API de SmartWorks esté encendida y que el servidor esté disponible.',
            isUser: false,
          ),
        );
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error de conexión: $e'),
        ),
      );
    } finally {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });

      _scrollToBottom();
    }
  }

  void _clearConversation() {
    setState(() {
      _messages
        ..clear()
        ..add(
          ChatMessage(
            text:
            'Conversación reiniciada. ¿En qué puedo ayudarte con SmartWorks?',
            isUser: false,
          ),
        );
    });

    _scrollToBottom();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;

      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent + 180,
        duration: const Duration(milliseconds: 320),
        curve: Curves.easeOut,
      );
    });
  }

  String _formatTime(DateTime date) {
    final hour = date.hour.toString().padLeft(2, '0');
    final minute = date.minute.toString().padLeft(2, '0');

    return '$hour:$minute';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F8FC),
      body: SafeArea(
        child: Column(
          children: [
            _ChatHeader(
              onBack: () => Navigator.pop(context),
              onClear: _clearConversation,
            ),

            Expanded(
              child: ListView(
                controller: _scrollController,
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 18),
                children: [
                  _AssistantIntroCard(
                    onTapSuggestion: (prompt) {
                      _sendMessage(customText: prompt);
                    },
                  ),

                  const SizedBox(height: 16),

                  _SuggestionCarousel(
                    suggestions: _suggestions,
                    onTap: (prompt) {
                      _sendMessage(customText: prompt);
                    },
                  ),

                  const SizedBox(height: 18),

                  ..._messages.map((message) {
                    return _MessageBubble(
                      message: message,
                      time: _formatTime(message.createdAt),
                    );
                  }),

                  if (_isLoading) const _TypingBubble(),
                ],
              ),
            ),

            _ChatInputBar(
              controller: _controller,
              focusNode: _focusNode,
              loading: _isLoading,
              onSend: () => _sendMessage(),
            ),
          ],
        ),
      ),
    );
  }
}

/* ---------------- UI Chatbot ---------------- */

class _ChatHeader extends StatelessWidget {
  final VoidCallback onBack;
  final VoidCallback onClear;

  const _ChatHeader({
    required this.onBack,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF061A2D),
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF061A2D).withOpacity(0.18),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              IconButton(
                onPressed: onBack,
                style: IconButton.styleFrom(
                  backgroundColor: Colors.white.withOpacity(0.12),
                  foregroundColor: Colors.white,
                ),
                icon: const Icon(Icons.arrow_back_rounded),
              ),
              const SizedBox(width: 10),
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.14),
                  ),
                ),
                child: const Icon(
                  Icons.smart_toy_rounded,
                  color: Colors.white,
                  size: 29,
                ),
              ),
              const SizedBox(width: 13),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Asistente SmartWorks',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 21,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.4,
                      ),
                    ),
                    SizedBox(height: 3),
                    Text(
                      'Inventario · Clientes · Pedidos',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Color(0xFFB7C8D8),
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              PopupMenuButton<String>(
                icon: const Icon(
                  Icons.more_vert_rounded,
                  color: Colors.white,
                ),
                color: Colors.white,
                onSelected: (value) {
                  if (value == 'clear') {
                    onClear();
                  }
                },
                itemBuilder: (_) => const [
                  PopupMenuItem(
                    value: 'clear',
                    child: Row(
                      children: [
                        Icon(Icons.cleaning_services_rounded),
                        SizedBox(width: 10),
                        Text('Limpiar conversación'),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 18),

          Text(
            'Pregunta por productos, stock, clientes, pedidos recientes o solicita operaciones rápidas dentro del sistema.',
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: Colors.white.withOpacity(0.78),
              fontSize: 13.5,
              height: 1.35,
            ),
          ),
        ],
      ),
    );
  }
}

class _AssistantIntroCard extends StatelessWidget {
  final ValueChanged<String> onTapSuggestion;

  const _AssistantIntroCard({
    required this.onTapSuggestion,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(26),
        border: Border.all(
          color: cs.outlineVariant.withOpacity(0.45),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: cs.primaryContainer,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Icon(
                  Icons.auto_awesome_rounded,
                  color: cs.onPrimaryContainer,
                  size: 28,
                ),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Tu copiloto de gestión',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Usa lenguaje natural para consultar y gestionar SmartWorks.',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: cs.onSurfaceVariant,
                        fontSize: 12.5,
                        height: 1.25,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          Row(
            children: [
              Expanded(
                child: _IntroActionCard(
                  title: 'Consultar stock',
                  icon: Icons.inventory_2_rounded,
                  color: const Color(0xFF1AA6FF),
                  background: const Color(0xFFEAF6FF),
                  onTap: () => onTapSuggestion(
                    'Dame un resumen del inventario y los productos con stock bajo',
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _IntroActionCard(
                  title: 'Revisar pedidos',
                  icon: Icons.receipt_long_rounded,
                  color: const Color(0xFFFF8A00),
                  background: const Color(0xFFFFF4E5),
                  onTap: () => onTapSuggestion(
                    'Muéstrame los pedidos recientes y su estado',
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _IntroActionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;
  final Color background;
  final VoidCallback onTap;

  const _IntroActionCard({
    required this.title,
    required this.icon,
    required this.color,
    required this.background,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(13),
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: color.withOpacity(0.18),
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: color,
              size: 25,
            ),
            const SizedBox(height: 8),
            Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w900,
                fontSize: 12.2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SuggestionCarousel extends StatelessWidget {
  final List<_SuggestionItem> suggestions;
  final ValueChanged<String> onTap;

  const _SuggestionCarousel({
    required this.suggestions,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 86,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: suggestions.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (context, index) {
          final suggestion = suggestions[index];

          return _SuggestionCard(
            suggestion: suggestion,
            onTap: () => onTap(suggestion.prompt),
          );
        },
      ),
    );
  }
}

class _SuggestionCard extends StatelessWidget {
  final _SuggestionItem suggestion;
  final VoidCallback onTap;

  const _SuggestionCard({
    required this.suggestion,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(22),
      child: Container(
        width: 150,
        padding: const EdgeInsets.all(13),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: cs.outlineVariant.withOpacity(0.45),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: cs.primaryContainer,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(
                suggestion.icon,
                color: cs.onPrimaryContainer,
                size: 21,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                suggestion.title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 12.5,
                  height: 1.15,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  final ChatMessage message;
  final String time;

  const _MessageBubble({
    required this.message,
    required this.time,
  });

  @override
  Widget build(BuildContext context) {
    final isUser = message.isUser;
    final cs = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Align(
        alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
        child: Row(
          mainAxisAlignment:
          isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            if (!isUser) ...[
              _BotAvatar(),
              const SizedBox(width: 8),
            ],

            Flexible(
              child: Container(
                constraints: const BoxConstraints(
                  maxWidth: 310,
                ),
                padding: const EdgeInsets.fromLTRB(14, 12, 14, 9),
                decoration: BoxDecoration(
                  color: isUser ? cs.primary : Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: const Radius.circular(20),
                    topRight: const Radius.circular(20),
                    bottomLeft: Radius.circular(isUser ? 20 : 6),
                    bottomRight: Radius.circular(isUser ? 6 : 20),
                  ),
                  border: isUser
                      ? null
                      : Border.all(
                    color: cs.outlineVariant.withOpacity(0.45),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.04),
                      blurRadius: 14,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SelectableText(
                      message.text,
                      style: TextStyle(
                        color: isUser ? cs.onPrimary : cs.onSurface,
                        fontSize: 14.5,
                        height: 1.35,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 7),
                    Align(
                      alignment: Alignment.centerRight,
                      child: Text(
                        time,
                        style: TextStyle(
                          color: isUser
                              ? cs.onPrimary.withOpacity(0.72)
                              : cs.onSurfaceVariant,
                          fontSize: 10.5,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            if (isUser) ...[
              const SizedBox(width: 8),
              _UserAvatar(),
            ],
          ],
        ),
      ),
    );
  }
}

class _TypingBubble extends StatelessWidget {
  const _TypingBubble();

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            const _BotAvatar(),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 12,
              ),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                  bottomLeft: Radius.circular(6),
                  bottomRight: Radius.circular(20),
                ),
                border: Border.all(
                  color: cs.outlineVariant.withOpacity(0.45),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 14,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _TypingDot(delay: 0),
                  const SizedBox(width: 4),
                  _TypingDot(delay: 120),
                  const SizedBox(width: 4),
                  _TypingDot(delay: 240),
                  const SizedBox(width: 10),
                  Text(
                    'Pensando...',
                    style: TextStyle(
                      color: cs.onSurfaceVariant,
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                    ),
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

class _TypingDot extends StatefulWidget {
  final int delay;

  const _TypingDot({
    required this.delay,
  });

  @override
  State<_TypingDot> createState() => _TypingDotState();
}

class _TypingDotState extends State<_TypingDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController controller;
  late final Animation<double> animation;

  @override
  void initState() {
    super.initState();

    controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );

    animation = Tween<double>(
      begin: 0.35,
      end: 1,
    ).animate(
      CurvedAnimation(
        parent: controller,
        curve: Curves.easeInOut,
      ),
    );

    Future.delayed(Duration(milliseconds: widget.delay), () {
      if (mounted) {
        controller.repeat(reverse: true);
      }
    });
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return FadeTransition(
      opacity: animation,
      child: Container(
        width: 7,
        height: 7,
        decoration: BoxDecoration(
          color: cs.primary,
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}

class _ChatInputBar extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final bool loading;
  final VoidCallback onSend;

  const _ChatInputBar({
    required this.controller,
    required this.focusNode,
    required this.loading,
    required this.onSend,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border(
            top: BorderSide(
              color: cs.outlineVariant.withOpacity(0.45),
            ),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 18,
              offset: const Offset(0, -6),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 3,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFF4F8FC),
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(
                    color: cs.outlineVariant.withOpacity(0.45),
                  ),
                ),
                child: TextField(
                  controller: controller,
                  focusNode: focusNode,
                  enabled: !loading,
                  minLines: 1,
                  maxLines: 5,
                  textInputAction: TextInputAction.send,
                  onSubmitted: (_) {
                    if (!loading) {
                      onSend();
                    }
                  },
                  decoration: const InputDecoration(
                    hintText: 'Escribe tu consulta...',
                    border: InputBorder.none,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            SizedBox(
              width: 52,
              height: 52,
              child: FilledButton(
                onPressed: loading ? null : onSend,
                style: FilledButton.styleFrom(
                  padding: EdgeInsets.zero,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                ),
                child: loading
                    ? const SizedBox(
                  width: 19,
                  height: 19,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                  ),
                )
                    : const Icon(Icons.send_rounded),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BotAvatar extends StatelessWidget {
  const _BotAvatar();

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Container(
      width: 34,
      height: 34,
      decoration: BoxDecoration(
        color: cs.primaryContainer,
        borderRadius: BorderRadius.circular(13),
      ),
      child: Icon(
        Icons.smart_toy_rounded,
        color: cs.onPrimaryContainer,
        size: 20,
      ),
    );
  }
}

class _UserAvatar extends StatelessWidget {
  const _UserAvatar();

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Container(
      width: 34,
      height: 34,
      decoration: BoxDecoration(
        color: const Color(0xFF061A2D),
        borderRadius: BorderRadius.circular(13),
      ),
      child: Icon(
        Icons.person_rounded,
        color: cs.onPrimary,
        size: 20,
      ),
    );
  }
}

class _SuggestionItem {
  final String title;
  final String prompt;
  final IconData icon;

  const _SuggestionItem({
    required this.title,
    required this.prompt,
    required this.icon,
  });
}