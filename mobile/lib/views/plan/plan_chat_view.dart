import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:navgo_mobile/core/extensions/core_extensions.dart';
import 'package:navgo_mobile/core/themes/app_colors.dart';
import 'package:navgo_mobile/i18n/strings.g.dart';
import 'package:navgo_mobile/views/plan/models/plan_suggestion.dart';
import 'package:navgo_mobile/views/plan/repository/service/planner_service.dart';
import 'package:navgo_mobile/views/plan/widgets/route_preview_sheet.dart';

class PlanChatBuildResult {
  const PlanChatBuildResult({required this.area, required this.suggestion});

  final String area;
  final PlanSuggestion suggestion;
}

class PlanChatView extends StatefulWidget {
  const PlanChatView({super.key, required this.service, this.initialArea = ''});

  final PlannerService service;
  final String initialArea;

  @override
  State<PlanChatView> createState() => _PlanChatViewState();
}

class _PlanChatViewState extends State<PlanChatView> {
  final _input = TextEditingController();
  final _inputFocus = FocusNode();
  final _scroll = ScrollController();
  final _items = <_ChatItem>[];
  PlanSuggestion? _quoted;
  var _sending = false;

  @override
  void dispose() {
    _input.dispose();
    _inputFocus.dispose();
    _scroll.dispose();
    super.dispose();
  }

  void _quote(PlanSuggestion card) {
    setState(() => _quoted = card);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _inputFocus.requestFocus();
    });
  }

  void _jumpToEnd() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scroll.hasClients) return;
      _scroll.animateTo(
        _scroll.position.maxScrollExtent,
        duration: const Duration(milliseconds: 240),
        curve: Curves.easeOut,
      );
    });
  }

  Future<void> _send({
    String? promptOverride,
    PlanSuggestion? quotedOverride,
    bool addUserBubble = true,
  }) async {
    final text = (promptOverride ?? _input.text).trim();
    if (text.isEmpty || _sending) return;
    final quoted = quotedOverride ?? _quoted;
    final previous = quoted ?? _lastCard();
    final thread = _threadPayload(pendingUser: addUserBubble ? text : null);
    setState(() {
      _sending = true;
      _quoted = null;
      if (addUserBubble) {
        _items.add(_ChatItem.user(text));
      }
      _items.removeWhere((m) => m.isError);
      _items.add(const _ChatItem.loading());
    });
    if (promptOverride == null) {
      _input.clear();
    }
    _jumpToEnd();

    try {
      final token = await widget.service.ensureSession();
      final card = await widget.service.suggestRouteCard(
        token: token,
        prompt: text,
        locale: LocaleSettings.currentLocale.languageCode,
        defaultArea: widget.initialArea.trim(),
        previous: previous,
        messages: thread,
      );
      if (!mounted) return;
      setState(() {
        _items.removeWhere((m) => m.isLoading);
        _items.add(_ChatItem.card(card, card.area));
        _sending = false;
      });
      _jumpToEnd();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _items.removeWhere((m) => m.isLoading);
        _items.add(
          _ChatItem.error(
            _errorMessage(e),
            retryPrompt: text,
            retryQuoted: previous,
          ),
        );
        _sending = false;
      });
      _jumpToEnd();
    }
  }

  String _errorMessage(Object e) {
    final t = context.t;
    if (e is DioException) {
      switch (e.type) {
        case DioExceptionType.connectionTimeout:
        case DioExceptionType.receiveTimeout:
        case DioExceptionType.sendTimeout:
          return t.plan.errorTimeout;
        default:
          break;
      }
      final code = e.response?.statusCode;
      final body = '${e.response?.data}'.toLowerCase();
      if (code == 401 || body.contains('unauthorized')) {
        return t.plan.chat.errorAuth;
      }
      if (body.contains('context canceled') || body.contains('timeout')) {
        return t.plan.errorTimeout;
      }
    }
    return t.plan.chat.error;
  }

  PlanSuggestion? _lastCard() {
    for (final item in _items.reversed) {
      if (item.card != null) return item.card;
    }
    return null;
  }

  List<Map<String, dynamic>> _threadPayload({String? pendingUser}) {
    final out = <Map<String, dynamic>>[];
    for (final item in _items) {
      if (item.isLoading || item.isError) continue;
      if (item.isUser) {
        out.add({'role': 'user', 'text': item.text});
        continue;
      }
      final card = item.card;
      if (card == null) continue;
      final area = item.area.trim().isNotEmpty
          ? item.area.trim()
          : card.area.trim();
      out.add({
        'role': 'assistant',
        'text': card.title,
        'area': area,
        'title': card.title,
        'query': card.query,
        'intent': card.intent,
      });
    }
    final pending = pendingUser?.trim() ?? '';
    if (pending.isNotEmpty) {
      out.add({'role': 'user', 'text': pending});
    }
    return out;
  }

  Future<void> _preview(_ChatItem item) async {
    final card = item.card;
    if (card == null) return;
    final area = item.area.trim().isNotEmpty
        ? item.area.trim()
        : (card.area.trim().isNotEmpty
              ? card.area.trim()
              : widget.initialArea.trim());
    if (area.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.t.plan.startSheet.areaRequiredSnack)),
      );
      return;
    }
    final outcome = await showModalBottomSheet<RoutePreviewOutcome>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => RoutePreviewSheet(
        area: area,
        suggestion: card,
        query: card.query,
        service: widget.service,
      ),
    );
    if (outcome == RoutePreviewOutcome.confirmed && mounted) {
      Navigator.of(
        context,
      ).pop(PlanChatBuildResult(area: area, suggestion: card));
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    return Scaffold(
      backgroundColor: context.cBackground,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.secondary,
        elevation: 0,
        title: Text(t.plan.chat.title),
      ),
      body: Column(
        children: [
          Expanded(
            child: _items.isEmpty
                ? _ChatEmpty()
                : ListView.builder(
                    controller: _scroll,
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                    itemCount: _items.length,
                    itemBuilder: (context, i) {
                      final item = _items[i];
                      if (item.isUser) {
                        return _UserBubble(text: item.text);
                      }
                      if (item.isLoading) {
                        return const _ThinkingBubble();
                      }
                      if (item.isError) {
                        return _ErrorBubble(
                          message: item.text,
                          onRetry: () => _send(
                            promptOverride: item.retryPrompt,
                            quotedOverride: item.retryQuoted,
                            addUserBubble: false,
                          ),
                        );
                      }
                      return _RouteCardBubble(
                        key: ValueKey('llm-card-$i'),
                        suggestion: item.card!,
                        area: item.area,
                        onTap: () => _preview(item),
                        onReply: () => _quote(item.card!),
                      );
                    },
                  ),
          ),
          _ChatComposer(
            controller: _input,
            focusNode: _inputFocus,
            quoted: _quoted,
            sending: _sending,
            onClearQuote: () => setState(() => _quoted = null),
            onSend: _send,
          ),
        ],
      ),
    );
  }
}

class _ChatItem {
  const _ChatItem.user(this.text)
    : card = null,
      area = '',
      isUser = true,
      isLoading = false,
      isError = false,
      retryPrompt = '',
      retryQuoted = null;

  const _ChatItem.card(this.card, this.area)
    : text = '',
      isUser = false,
      isLoading = false,
      isError = false,
      retryPrompt = '',
      retryQuoted = null;

  const _ChatItem.loading()
    : text = '',
      card = null,
      area = '',
      isUser = false,
      isLoading = true,
      isError = false,
      retryPrompt = '',
      retryQuoted = null;

  const _ChatItem.error(
    this.text, {
    required this.retryPrompt,
    this.retryQuoted,
  }) : card = null,
       area = '',
       isUser = false,
       isLoading = false,
       isError = true;

  final bool isUser;
  final bool isLoading;
  final bool isError;
  final String text;
  final PlanSuggestion? card;
  final String area;
  final String retryPrompt;
  final PlanSuggestion? retryQuoted;
}

class _ChatEmpty extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final t = context.t;
    return Center(
      child: Padding(
        padding: context.paddingNormal,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(24),
              ),
              child: const Icon(
                Icons.chat_bubble_outline,
                color: AppColors.primary,
                size: 32,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              t.plan.chat.emptyTitle,
              textAlign: TextAlign.center,
              style: context.textTheme.headlineMedium,
            ),
            const SizedBox(height: 8),
            Text(
              t.plan.chat.emptyBody,
              textAlign: TextAlign.center,
              style: context.textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }
}

class _UserBubble extends StatelessWidget {
  const _UserBubble({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerRight,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10, left: 48),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.primary,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Text(
          text,
          style: context.textTheme.bodyMedium?.copyWith(color: Colors.white),
        ),
      ),
    );
  }
}

class _ThinkingBubble extends StatefulWidget {
  const _ThinkingBubble();

  @override
  State<_ThinkingBubble> createState() => _ThinkingBubbleState();
}

class _ThinkingBubbleState extends State<_ThinkingBubble>
    with TickerProviderStateMixin {
  Timer? _cycle;
  var _index = 0;
  late final AnimationController _pulse;
  late final AnimationController _dots;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);
    _dots = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat();
    _cycle = Timer.periodic(const Duration(milliseconds: 2200), (_) {
      if (!mounted) return;
      setState(() => _index++);
    });
  }

  @override
  void dispose() {
    _cycle?.cancel();
    _pulse.dispose();
    _dots.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final steps = [
      context.t.plan.chat.thinking.s1,
      context.t.plan.chat.thinking.s2,
      context.t.plan.chat.thinking.s3,
      context.t.plan.chat.thinking.s4,
      context.t.plan.chat.thinking.s5,
    ];
    final label = steps[_index % steps.length];
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12, right: 36),
        padding: const EdgeInsets.fromLTRB(14, 12, 16, 12),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            FadeTransition(
              opacity: Tween<double>(begin: 0.45, end: 1).animate(
                CurvedAnimation(parent: _pulse, curve: Curves.easeInOut),
              ),
              child: const Icon(
                Icons.auto_awesome,
                size: 18,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(width: 10),
            Flexible(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 380),
                switchInCurve: Curves.easeOut,
                switchOutCurve: Curves.easeIn,
                transitionBuilder: (child, animation) {
                  return FadeTransition(
                    opacity: animation,
                    child: SlideTransition(
                      position: Tween<Offset>(
                        begin: const Offset(0, 0.25),
                        end: Offset.zero,
                      ).animate(animation),
                      child: child,
                    ),
                  );
                },
                child: Text(
                  label,
                  key: ValueKey(label),
                  style: context.textTheme.bodyMedium?.copyWith(
                    color: AppColors.secondary,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            AnimatedBuilder(
              animation: _dots,
              builder: (context, _) {
                return Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    for (var i = 0; i < 3; i++) ...[
                      if (i > 0) const SizedBox(width: 3),
                      Opacity(
                        opacity:
                            (0.25 +
                                    (0.75 *
                                        (((_dots.value + i / 3) % 1.0) < 0.5
                                            ? (_dots.value + i / 3) % 1.0 * 2
                                            : 2 -
                                                  ((_dots.value + i / 3) %
                                                          1.0) *
                                                      2)))
                                .clamp(0.25, 1),
                        child: Container(
                          width: 5,
                          height: 5,
                          decoration: const BoxDecoration(
                            color: AppColors.primary,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                    ],
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorBubble extends StatelessWidget {
  const _ErrorBubble({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12, right: 28),
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 8),
        decoration: BoxDecoration(
          color: AppColors.danger.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.danger.withValues(alpha: 0.25)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(message, style: context.textTheme.bodyMedium),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: onRetry,
                child: Text(t.plan.chat.retry),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

enum _CardMenuAction { reply }

class _RouteCardBubble extends StatelessWidget {
  const _RouteCardBubble({
    super.key,
    required this.suggestion,
    required this.area,
    required this.onTap,
    required this.onReply,
  });

  final PlanSuggestion suggestion;
  final String area;
  final VoidCallback onTap;
  final VoidCallback onReply;

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: _SwipeToReply(
              onReply: onReply,
              child: Material(
                color: Colors.transparent,
                borderRadius: BorderRadius.circular(20),
                child: InkWell(
                  onTap: onTap,
                  borderRadius: BorderRadius.circular(20),
                  child: Ink(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          suggestion.accent,
                          Color.lerp(
                            suggestion.accent,
                            const Color(0xFF0F1720),
                            0.45,
                          )!,
                        ],
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.16),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(suggestion.icon, color: Colors.white),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            suggestion.title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: context.textTheme.titleMedium?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                              height: 1.2,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            suggestion.subtitle,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: context.textTheme.bodyMedium?.copyWith(
                              color: Colors.white.withValues(alpha: 0.88),
                            ),
                          ),
                          if (area.trim().isNotEmpty) ...[
                            const SizedBox(height: 8),
                            Text(
                              area,
                              style: context.textTheme.labelLarge?.copyWith(
                                color: Colors.white.withValues(alpha: 0.8),
                              ),
                            ),
                          ],
                          const SizedBox(height: 8),
                          Text(
                            t.plan.chat.tapToPreview,
                            style: context.textTheme.labelLarge?.copyWith(
                              color: Colors.white.withValues(alpha: 0.7),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          PopupMenuButton<_CardMenuAction>(
            tooltip: t.plan.chat.more,
            padding: EdgeInsets.zero,
            icon: const Icon(Icons.more_horiz, color: AppColors.secondary),
            onSelected: (action) {
              if (action == _CardMenuAction.reply) onReply();
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: _CardMenuAction.reply,
                child: Text(t.plan.chat.reply),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SwipeToReply extends StatefulWidget {
  const _SwipeToReply({required this.onReply, required this.child});

  final VoidCallback onReply;
  final Widget child;

  @override
  State<_SwipeToReply> createState() => _SwipeToReplyState();
}

class _SwipeToReplyState extends State<_SwipeToReply>
    with SingleTickerProviderStateMixin {
  static const _extent = 72.0;
  static const _threshold = 40.0;

  double _dx = 0;
  var _replied = false;
  late final AnimationController _settle;
  Animation<double>? _settleAnim;

  @override
  void initState() {
    super.initState();
    _settle =
        AnimationController(
          vsync: this,
          duration: const Duration(milliseconds: 220),
        )..addListener(() {
          final anim = _settleAnim;
          if (anim == null) return;
          setState(() => _dx = anim.value);
        });
  }

  @override
  void dispose() {
    _settle.dispose();
    super.dispose();
  }

  void _springBack({required bool reply}) {
    if (reply && !_replied) {
      _replied = true;
      HapticFeedback.selectionClick();
      widget.onReply();
    }
    _settleAnim = Tween<double>(
      begin: _dx,
      end: 0,
    ).animate(CurvedAnimation(parent: _settle, curve: Curves.easeOutCubic));
    _settle.forward(from: 0).whenComplete(() {
      _replied = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final progress = (_dx.abs() / _threshold).clamp(0.0, 1.0);
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onHorizontalDragStart: (_) => _settle.stop(),
      onHorizontalDragUpdate: (details) {
        setState(() {
          _dx = (_dx + details.delta.dx).clamp(-_extent, _extent);
        });
      },
      onHorizontalDragEnd: (_) => _springBack(reply: _dx.abs() >= _threshold),
      onHorizontalDragCancel: () => _springBack(reply: false),
      child: ClipRect(
        child: Stack(
          alignment: Alignment.center,
          children: [
            Opacity(
              opacity: progress,
              child: Align(
                alignment: _dx >= 0
                    ? Alignment.centerLeft
                    : Alignment.centerRight,
                child: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 10),
                  child: Icon(Icons.reply, color: AppColors.primary),
                ),
              ),
            ),
            Transform.translate(offset: Offset(_dx, 0), child: widget.child),
          ],
        ),
      ),
    );
  }
}

class _ChatComposer extends StatelessWidget {
  const _ChatComposer({
    required this.controller,
    required this.focusNode,
    required this.quoted,
    required this.sending,
    required this.onClearQuote,
    required this.onSend,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final PlanSuggestion? quoted;
  final bool sending;
  final VoidCallback onClearQuote;
  final VoidCallback onSend;

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    return Material(
      color: AppColors.surface,
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          16,
          8,
          16,
          MediaQuery.paddingOf(context).bottom + 12,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (quoted != null)
              Container(
                width: double.infinity,
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.fromLTRB(12, 8, 4, 8),
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(12),
                  border: const Border(
                    left: BorderSide(color: AppColors.primary, width: 3),
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            t.plan.chat.quoting,
                            style: context.textTheme.labelLarge?.copyWith(
                              color: AppColors.primary,
                            ),
                          ),
                          Text(
                            quoted!.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: context.textTheme.bodyMedium,
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: onClearQuote,
                      icon: const Icon(Icons.close, size: 18),
                    ),
                  ],
                ),
              ),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: controller,
                    focusNode: focusNode,
                    minLines: 1,
                    maxLines: 4,
                    enabled: !sending,
                    textInputAction: TextInputAction.send,
                    onSubmitted: (_) => onSend(),
                    decoration: InputDecoration(
                      hintText: quoted == null
                          ? t.plan.chat.inputHint
                          : t.plan.chat.replyHint,
                      filled: true,
                      fillColor: AppColors.background,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide.none,
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide.none,
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: sending ? null : onSend,
                  style: IconButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: AppColors.onPrimary,
                    disabledBackgroundColor: AppColors.surfaceMuted,
                  ),
                  icon: sending
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.send_rounded),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
