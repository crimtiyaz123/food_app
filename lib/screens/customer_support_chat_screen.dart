import 'package:flutter/material.dart';
import '../models/chatbot.dart';
import '../services/ai_chatbot_service.dart';
import '../theme/app_theme.dart';

class CustomerSupportChatScreen extends StatefulWidget {
  final String userId;
  final String? initialMessage;
  final String? guestId;

  const CustomerSupportChatScreen({
    super.key,
    required this.userId,
    this.initialMessage,
    this.guestId,
  });

  @override
  State<CustomerSupportChatScreen> createState() => _CustomerSupportChatScreenState();
}

class _CustomerSupportChatScreenState extends State<CustomerSupportChatScreen> with TickerProviderStateMixin {
  final AIChatbotService _chatService = AIChatbotService();
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  
  List<ChatMessage> _messages = [];
  String? _currentSessionId;
  bool _isLoading = false;
  bool _isTyping = false;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _initializeChat();
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  void _initializeChat() async {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeIn),
    );
    _animationController.forward();

    setState(() {
      _isLoading = true;
    });

    try {
      // Start chat session
      final sessionId = await _chatService.startChatSession(
        userId: widget.userId,
        guestId: widget.guestId,
        customerType: widget.guestId != null ? SenderType.customer : SenderType.customer,
      );

      setState(() {
        _currentSessionId = sessionId;
      });

      // Load initial chat history
      _loadChatHistory();

      // Send initial message if provided
      if (widget.initialMessage != null) {
        _sendMessage(widget.initialMessage!);
      }
    } catch (e) {
      debugPrint('Error initializing chat: $e');
      _showErrorSnackBar('Failed to start chat session. Please try again.');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _loadChatHistory() async {
    if (_currentSessionId == null) return;

    try {
      final history = await _chatService.getChatHistory(_currentSessionId!);
      setState(() {
        _messages = history;
      });
      _scrollToBottom();
    } catch (e) {
      debugPrint('Error loading chat history: $e');
    }
  }

  void _sendMessage(String message) async {
    if (message.trim().isEmpty || _currentSessionId == null) return;

    final userMessage = message.trim();
    _messageController.clear();

    setState(() {
      _isTyping = true;
    });

    try {
      // Add user message to UI immediately
      final newUserMessage = ChatMessage(
        id: 'temp_${DateTime.now().millisecondsSinceEpoch}',
        sessionId: _currentSessionId!,
        content: userMessage,
        type: MessageType.text,
        sender: SenderType.customer,
        timestamp: DateTime.now(),
        metadata: {},
        isRead: false,
        attachments: [],
        confidence: 1.0,
        entities: {},
      );

      setState(() {
        _messages.add(newUserMessage);
      });
      _scrollToBottom();

      // Process message with AI
      await _chatService.processMessage(
        sessionId: _currentSessionId!,
        content: userMessage,
        type: MessageType.text,
        senderId: widget.userId,
      );

      // Reload chat history to get AI response
      _loadChatHistory();

    } catch (e) {
      debugPrint('Error sending message: $e');
      _showErrorSnackBar('Failed to send message. Please try again.');
    } finally {
      setState(() {
        _isTyping = false;
      });
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent + 100,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [AppColors.secondaryBlack, AppColors.backgroundGray],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: _isLoading
            ? _buildLoadingView()
            : _buildChatView(),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: AppColors.primaryRed,
      foregroundColor: AppColors.lightTextWhite,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back),
        onPressed: () => Navigator.of(context).pop(),
      ),
      title: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.lightTextWhite.withAlpha(50),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Icon(
              Icons.support_agent,
              color: AppColors.lightTextWhite,
            ),
          ),
          const SizedBox(width: AppSpacing.medium),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'AI Assistant',
                  style: TextStyle(
                    color: AppColors.lightTextWhite,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Online • Usually replies in seconds',
                  style: TextStyle(
                    color: AppColors.lightTextWhite.withAlpha(200),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.more_vert),
          onPressed: _showOptionsMenu,
        ),
      ],
    );
  }

  Widget _buildLoadingView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(
            color: AppColors.primaryRed,
          ),
          const SizedBox(height: 20),
          Text(
            'Connecting you to our AI assistant...',
            style: AppTextStyles.bodyMedium,
          ),
        ],
      ),
    );
  }

  Widget _buildChatView() {
    return Column(
      children: [
        // Quick Action Buttons
        _buildQuickActions(),

        // Messages
        Expanded(
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(AppSpacing.screenPadding),
              itemCount: _messages.length + (_isTyping ? 1 : 0),
              itemBuilder: (context, index) {
                if (index == _messages.length && _isTyping) {
                  return _buildTypingIndicator();
                }
                return _buildMessageBubble(_messages[index]);
              },
            ),
          ),
        ),

        // Message Input
        _buildMessageInput(),
      ],
    );
  }

  Widget _buildQuickActions() {
    final quickActions = [
      {'text': 'Track my order', 'icon': Icons.receipt_long},
      {'text': 'See menu', 'icon': Icons.restaurant_menu},
      {'text': 'Delivery info', 'icon': Icons.local_shipping},
      {'text': 'Payment help', 'icon': Icons.payment},
    ];

    return Container(
      padding: const EdgeInsets.all(AppSpacing.medium),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Quick Actions',
            style: AppTextStyles.titleSmall,
          ),
          const SizedBox(height: AppSpacing.medium),
          Wrap(
            spacing: AppSpacing.small,
            runSpacing: AppSpacing.small,
            children: quickActions.map((action) {
              return ElevatedButton.icon(
                onPressed: () => _sendQuickMessage(action['text'] as String),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.cardBackground,
                  foregroundColor: AppColors.lightTextWhite,
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.medium,
                    vertical: AppSpacing.small,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                    side: BorderSide(
                      color: AppColors.dividerGray,
                      width: 1,
                    ),
                  ),
                ),
                icon: Icon(
                  action['icon'] as IconData,
                  size: 16,
                ),
                label: Text(
                  action['text'] as String,
                  style: AppTextStyles.bodySmall,
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(ChatMessage message) {
    final isUser = message.sender == SenderType.customer;
    final isBot = message.sender == SenderType.chatbot;
    final isSystem = message.sender == SenderType.system;

    if (isSystem) {
      return _buildSystemMessage(message);
    }

    return Container(
      margin: EdgeInsets.only(
        bottom: AppSpacing.medium,
        left: isUser ? 50 : 0,
        right: isUser ? 0 : 50,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          if (!isUser) ...[
            _buildAvatar(message.sender),
            const SizedBox(width: AppSpacing.small),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.all(AppSpacing.large),
              decoration: BoxDecoration(
                gradient: isUser
                    ? LinearGradient(
                        colors: [AppColors.primaryRed, AppColors.accentOrange],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      )
                    : LinearGradient(
                        colors: [AppColors.cardBackground, AppColors.surfaceGray],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(20),
                  topRight: const Radius.circular(20),
                  bottomLeft: isUser 
                      ? const Radius.circular(20)
                      : const Radius.circular(5),
                  bottomRight: isUser 
                      ? const Radius.circular(5)
                      : const Radius.circular(20),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withAlpha(25),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (isBot) ...[
                    Row(
                      children: [
                        Icon(
                          Icons.smart_toy,
                          size: 16,
                          color: AppColors.textSecondary,
                        ),
                        const SizedBox(width: AppSpacing.small),
                        Text(
                          'AI Assistant',
                          style: AppTextStyles.bodySmall.copyWith(
                            color: AppColors.textSecondary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.small),
                  ],
                  
                  Text(
                    message.content,
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: isUser
                          ? AppColors.lightTextWhite
                          : AppColors.lightTextWhite,
                    ),
                  ),

                  const SizedBox(height: AppSpacing.small),

                  // Message metadata
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _formatTime(message.timestamp),
                        style: AppTextStyles.bodySmall.copyWith(
                          color: isUser
                              ? AppColors.lightTextWhite.withAlpha(180)
                              : AppColors.textSecondary,
                          fontSize: 11,
                        ),
                      ),
                      if (isUser) ...[
                        const SizedBox(width: AppSpacing.small),
                        Icon(
                          message.isRead ? Icons.done_all : Icons.done,
                          size: 16,
                          color: AppColors.lightTextWhite.withAlpha(180),
                        ),
                      ],
                      if (isBot && message.confidence < 0.7) ...[
                        const SizedBox(width: AppSpacing.small),
                        Text(
                          '(AI)',
                          style: AppTextStyles.bodySmall.copyWith(
                            color: AppColors.accentOrange,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSystemMessage(ChatMessage message) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: AppSpacing.medium),
      child: Row(
        children: [
          const Expanded(child: Divider()),
          Container(
            margin: const EdgeInsets.symmetric(horizontal: AppSpacing.medium),
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.large,
              vertical: AppSpacing.small,
            ),
            decoration: BoxDecoration(
              color: AppColors.accentOrange.withAlpha(50),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              message.content,
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.accentOrange,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const Expanded(child: Divider()),
        ],
      ),
    );
  }

  Widget _buildTypingIndicator() {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.medium),
      child: Row(
        children: [
          _buildAvatar(SenderType.chatbot),
          const SizedBox(width: AppSpacing.small),
          Container(
            padding: const EdgeInsets.all(AppSpacing.large),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [AppColors.cardBackground, AppColors.surfaceGray],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: const BorderRadius.only(
                topRight: Radius.circular(20),
                bottomLeft: Radius.circular(5),
                bottomRight: Radius.circular(20),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.smart_toy,
                  size: 16,
                  color: AppColors.textSecondary,
                ),
                const SizedBox(width: AppSpacing.small),
                Text(
                  'AI Assistant is typing',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(width: AppSpacing.medium),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildTypingDot(),
                    const SizedBox(width: 4),
                    _buildTypingDot(delay: 0.2),
                    const SizedBox(width: 4),
                    _buildTypingDot(delay: 0.4),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTypingDot({double delay = 0.0}) {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return Transform.scale(
          scale: _animationController.value,
          child: Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: AppColors.textSecondary,
              shape: BoxShape.circle,
            ),
          ),
        );
      },
    );
  }

  Widget _buildAvatar(SenderType sender) {
    IconData icon;
    Color color;
    
    switch (sender) {
      case SenderType.customer:
        icon = Icons.person;
        color = AppColors.primaryRed;
        break;
      case SenderType.chatbot:
        icon = Icons.smart_toy;
        color = AppColors.accentOrange;
        break;
      case SenderType.humanAgent:
        icon = Icons.support_agent;
        color = AppColors.successGreen;
        break;
      default:
        icon = Icons.info;
        color = AppColors.textSecondary;
    }

    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: color.withAlpha(50),
        shape: BoxShape.circle,
      ),
      child: Icon(
        icon,
        size: 16,
        color: color,
      ),
    );
  }

  Widget _buildMessageInput() {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.medium),
      decoration: BoxDecoration(
        color: AppColors.backgroundGray,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(25),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.cardBackground,
                  borderRadius: BorderRadius.circular(25),
                  border: Border.all(
                    color: AppColors.dividerGray,
                    width: 1,
                  ),
                ),
                child: TextField(
                  controller: _messageController,
                  style: AppTextStyles.bodyMedium,
                  maxLines: null,
                  minLines: 1,
                  textInputAction: TextInputAction.newline,
                  decoration: InputDecoration(
                    hintText: 'Type your message...',
                    hintStyle: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.textSecondary,
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.large,
                      vertical: AppSpacing.medium,
                    ),
                    border: InputBorder.none,
                  ),
                  onSubmitted: (value) {
                    if (value.trim().isNotEmpty) {
                      _sendMessage(value);
                    }
                  },
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.medium),
            FloatingActionButton(
              onPressed: _isTyping 
                  ? null 
                  : () {
                      if (_messageController.text.trim().isNotEmpty) {
                        _sendMessage(_messageController.text);
                      }
                    },
              backgroundColor: _isTyping 
                  ? AppColors.textSecondary 
                  : AppColors.primaryRed,
              foregroundColor: AppColors.lightTextWhite,
              mini: true,
              child: Icon(
                _isTyping ? Icons.hourglass_empty : Icons.send,
                size: 20,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Helper methods
  String _formatTime(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);
    
    if (difference.inMinutes < 1) {
      return 'now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else {
      return '${difference.inDays}d ago';
    }
  }

  void _sendQuickMessage(String message) {
    _messageController.text = message;
    _sendMessage(message);
  }

  void _showOptionsMenu() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.backgroundGray,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(AppSpacing.large),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Chat Options',
              style: AppTextStyles.titleMedium,
            ),
            const SizedBox(height: AppSpacing.large),
            ListTile(
              leading: Icon(Icons.refresh, color: AppColors.primaryRed),
              title: const Text('Refresh Chat'),
              onTap: () {
                Navigator.pop(context);
                _loadChatHistory();
              },
            ),
            ListTile(
              leading: Icon(Icons.analytics, color: AppColors.primaryRed),
              title: const Text('View Analytics'),
              onTap: () {
                Navigator.pop(context);
                _showAnalytics();
              },
            ),
            ListTile(
              leading: Icon(Icons.help, color: AppColors.primaryRed),
              title: const Text('Help & FAQ'),
              onTap: () {
                Navigator.pop(context);
                _showHelp();
              },
            ),
            ListTile(
              leading: Icon(Icons.logout, color: AppColors.primaryRed),
              title: const Text('End Chat'),
              onTap: () {
                Navigator.pop(context);
                _endChat();
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showAnalytics() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Chat Analytics'),
        content: const Text('Chat analytics including response times, resolution rates, and customer satisfaction would be displayed here.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showHelp() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Help & FAQ'),
        content: const Text('Common questions and help topics would be displayed here, including how to use the chat, escalation options, and troubleshooting.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _endChat() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('End Chat'),
        content: const Text('Are you sure you want to end this chat session? You can start a new one anytime.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              if (mounted && _currentSessionId != null) {
                await _chatService.endChatSession(sessionId: _currentSessionId!);
              }
              if (mounted) {
                Navigator.pop(context);
              }
            },
            child: const Text('End Chat'),
          ),
        ],
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: AppColors.primaryRed,
        content: Text(message),
        duration: const Duration(seconds: 3),
      ),
    );
  }
}