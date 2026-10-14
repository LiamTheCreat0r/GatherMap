import 'package:flutter/material.dart';

import '../core/theme/custom_colors.dart';
import '../core/theme/custom_text_styles.dart';

enum ChatType { circle, event, friend }

/// Minimal chat shape used to render the Messages list before chats are fetched.
class ChatItem {
  const ChatItem({
    required this.name,
    required this.lastMessageDate,
    required this.lastMessage,
    required this.lastUser,
    required this.numberNewMessages,
    required this.emojiIcon,
    required this.chatType,
    this.members = const [],
  });

  /// Conversation title, such as a circle, event, or friend's name.
  final String name;

  /// Date and time when the latest message was sent.
  final DateTime lastMessageDate;

  /// The content of the latest message.
  final String lastMessage;

  /// The user who sent the latest message.
  final String lastUser;

  final int numberNewMessages;

  /// Emoji displayed as the conversation avatar.
  final String emojiIcon;

  /// Display names of the people in the conversation.
  final List<String> members;

  /// Whether this conversation belongs to a circle, an event, or a friend.
  final ChatType chatType;

  /// Whether [lastMessageDate] is before [now].
  bool isUpcoming(DateTime now) => lastMessageDate.isBefore(now);
}

/// Placeholder chats around Toulouse with recent message dates.
List<ChatItem> _placeholderChats() {
  final now = DateTime.now();
  return [
    ChatItem(
      name: 'Les bons plans des Carmes',
      lastMessageDate: now.subtract(const Duration(minutes: 8)),
      lastMessage: 'On se retrouve place du Salin ?',
      lastUser: 'Léa',
      numberNewMessages: 2,
      emojiIcon: '☕',
      chatType: ChatType.circle,
      members: const ['Léa', 'Hugo', 'Inès', 'Thomas'],
    ),
    ChatItem(
      name: 'Balade le long du canal du Midi',
      lastMessageDate: now.subtract(const Duration(hours: 2)),
      lastMessage: 'J’apporte de quoi grignoter !',
      lastUser: 'Manon',
      numberNewMessages: 0,
      emojiIcon: '🚲',
      chatType: ChatType.circle,
      members: const ['Manon', 'Yanis', 'Camille'],
    ),
    ChatItem(
      name: 'Pique-nique à la Prairie des Filtres',
      lastMessageDate: now.subtract(const Duration(minutes: 24)),
      lastMessage: 'Le soleil est au rendez-vous 🌞',
      lastUser: 'Sarah',
      numberNewMessages: 3,
      emojiIcon: '🧺',
      chatType: ChatType.event,
      members: const ['Jules', 'Sarah', 'Nina', 'Maxime', 'Lou'],
    ),
    ChatItem(
      name: 'Marché de Saint-Cyprien',
      lastMessageDate: now.subtract(const Duration(days: 1, hours: 3)),
      lastMessage: 'Les fraises étaient délicieuses !',
      lastUser: 'Élodie',
      numberNewMessages: 0,
      emojiIcon: '🍓',
      chatType: ChatType.event,
      members: const ['Élodie', 'Paul', 'Mila'],
    ),
    ChatItem(
      name: 'Camille Martin',
      lastMessageDate: now.subtract(const Duration(minutes: 3)),
      lastMessage: 'On prend un café aux Carmes ?',
      lastUser: 'Camille',
      numberNewMessages: 1,
      emojiIcon: '👋',
      chatType: ChatType.friend,
    ),
    ChatItem(
      name: 'Théo Bernard',
      lastMessageDate: now.subtract(const Duration(hours: 5)),
      lastMessage: 'Je suis près de la place du Capitole',
      lastUser: 'Théo',
      numberNewMessages: 0,
      emojiIcon: '🙂',
      chatType: ChatType.friend,
    ),
  ];
}

/// Events tab: an orange header over a scrollable, sectioned list of
/// upcoming and past events.
///
/// All colours and text styles come from the [CustomColors] and
/// [CustomTextStyles] theme extensions, so light and dark mode are handled by
/// the active theme with no branching here.
class Chat extends StatelessWidget {
  const Chat({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<CustomColors>()!;
    final textStyles = Theme.of(context).extension<CustomTextStyles>()!;

    final chats = _placeholderChats();
    final friendChats = chats
        .where((e) => e.chatType == ChatType.friend)
        .toList();
    final circleChats = chats
        .where((e) => e.chatType == ChatType.circle)
        .toList();
    final eventChats = chats
        .where((e) => e.chatType == ChatType.event)
        .toList();

    return Scaffold(
      backgroundColor: colors.mainBackgroundColor,
      body: Column(
        children: [
          _ChatsHeader(colors: colors, textStyles: textStyles),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                if (friendChats.isNotEmpty) ...[
                  _SectionTitle(
                    label: 'AMIS',
                    textStyles: textStyles,
                    colors: colors,
                  ),
                  const SizedBox(height: 8),
                  for (var i = 0; i < friendChats.length; i++) ...[
                    if (i > 0) const SizedBox(height: 10),
                    _ChatRow(
                      chat: friendChats[i],
                      colors: colors,
                      textStyles: textStyles,
                    ),
                  ],
                ],

                if (friendChats.isNotEmpty && circleChats.isNotEmpty ||
                    friendChats.isNotEmpty && eventChats.isNotEmpty)
                  const SizedBox(height: 30),

                if (circleChats.isNotEmpty) ...[
                  _SectionTitle(
                    label: 'CERCLES',
                    textStyles: textStyles,
                    colors: colors,
                  ),
                  const SizedBox(height: 8),
                  for (var i = 0; i < circleChats.length; i++) ...[
                    if (i > 0) const SizedBox(height: 10),
                    _ChatRow(
                      chat: circleChats[i],
                      colors: colors,
                      textStyles: textStyles,
                    ),
                  ],
                ],

                if (circleChats.isNotEmpty && eventChats.isNotEmpty ||
                    friendChats.isNotEmpty && eventChats.isNotEmpty)
                  const SizedBox(height: 30),

                if (eventChats.isNotEmpty) ...[
                  _SectionTitle(
                    label: 'ÉVÉNEMENTS',
                    textStyles: textStyles,
                    colors: colors,
                  ),
                  const SizedBox(height: 8),
                  for (var i = 0; i < eventChats.length; i++) ...[
                    if (i > 0) const SizedBox(height: 10),
                    _ChatRow(
                      chat: eventChats[i],
                      colors: colors,
                      textStyles: textStyles,
                    ),
                  ],
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Orange page header holding the page title.
class _ChatsHeader extends StatelessWidget {
  const _ChatsHeader({required this.colors, required this.textStyles});

  final CustomColors colors;
  final CustomTextStyles textStyles;

  @override
  Widget build(BuildContext context) {
    // Let the orange fill the status bar area, and keep the title clear of the
    // notch/cutout.
    final topInset = MediaQuery.of(context).padding.top;

    return ColoredBox(
      color: colors.accentColor,
      child: Padding(
        padding: EdgeInsets.only(
          top: topInset + 6,
          left: 10,
          right: 10,
          bottom: 12,
        ),
        child: Align(
          alignment: Alignment.centerLeft,
          child: Text(
            'Messages',
            style: textStyles.pageTitleStyle.copyWith(color: Colors.white),
          ),
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({
    required this.label,
    required this.textStyles,
    required this.colors,
  });

  final String label;
  final CustomTextStyles textStyles;
  final CustomColors colors;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        label,
        style: textStyles.legendStyle.copyWith(
          color: colors.secondaryTextColor,
          letterSpacing: 1.0,
        ),
      ),
    );
  }
}

/// One full-width clickable chat row: a fixed-width date block plus a flexible
/// information card.
class _ChatRow extends StatelessWidget {
  const _ChatRow({
    required this.chat,
    required this.colors,
    required this.textStyles,
  });

  final ChatItem chat;
  final CustomColors colors;
  final CustomTextStyles textStyles;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => Navigator.pushNamed(context, '/chat/placeholder'),
      borderRadius: BorderRadius.circular(12),
      child: SizedBox(
        height: 70,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            _ChatIcon(chat: chat, colors: colors, textStyles: textStyles),
            const SizedBox(width: 12),
            Expanded(
              child: _InfoCard(
                chat: chat,
                colors: colors,
                textStyles: textStyles,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ChatIcon extends StatelessWidget {
  const _ChatIcon({
    required this.chat,
    required this.colors,
    required this.textStyles,
  });

  final ChatItem chat;
  final CustomColors colors;
  final CustomTextStyles textStyles;

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: colors.translucentSurfaceColor,
            border: Border.all(color: colors.borderColor, width: 1),
            borderRadius: BorderRadius.circular(12),
          ),
          alignment: Alignment.center,
          child: chat.chatType == ChatType.friend
              ? ClipRect(
                  child: _ChatAvatar(
                    name: chat.name,
                    index: 0,
                    ringColor: colors.cardColor,
                  ),
                )
              : Text(
                  chat.emojiIcon,
                  textAlign: TextAlign.center,
                  style: textStyles.subTitleStyle.copyWith(
                    color: colors.primaryTextColor,
                  ),
                ),
        ),
        if (chat.numberNewMessages > 0)
          Positioned(
            top: -5,
            right: -5,
            child: Container(
              constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
              padding: const EdgeInsets.symmetric(horizontal: 4),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: colors.dangerColor,
                borderRadius: BorderRadius.circular(9),
                border: Border.all(color: colors.mainBackgroundColor, width: 2),
              ),
              child: Text(
                chat.numberNewMessages > 99
                    ? '99+'
                    : chat.numberNewMessages.toString(),
                style: textStyles.labelStyle.copyWith(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

/// Flexible rounded information card: title, meta line and attendee avatars,
/// with a trailing chevron (upcoming) or photo indicator (past).
class _InfoCard extends StatelessWidget {
  const _InfoCard({
    required this.chat,
    required this.colors,
    required this.textStyles,
  });

  final ChatItem chat;
  final CustomColors colors;
  final CustomTextStyles textStyles;

  String _formatMessageTime(DateTime date) =>
      '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        chat.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: textStyles.bodyTextStyle.copyWith(
                          color: colors.primaryTextColor,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _formatMessageTime(chat.lastMessageDate),
                      style: textStyles.labelStyle.copyWith(
                        color: colors.secondaryTextColor,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 1),
                Text(
                  '${chat.lastUser} : ${chat.lastMessage}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: textStyles.labelStyle.copyWith(
                    color: colors.secondaryTextColor,
                  ),
                ),
                if (chat.members.isNotEmpty) ...[
                  const SizedBox(height: 3),
                  _AvatarRow(names: chat.members, ringColor: colors.cardColor),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

const List<Color> _avatarPalette = [
  Color(0xFFC77D51),
  Color(0xFF8A9A7B),
  Color(0xFF7C8AA0),
  Color(0xFFB08B9E),
  Color(0xFFA88B5C),
];

/// Up to four overlapping 16px circular avatars drawn from attendee initials.
class _AvatarRow extends StatelessWidget {
  const _AvatarRow({required this.names, required this.ringColor});

  final List<String> names;
  final Color ringColor;

  static const double _size = 16;
  static const double _overlapStep = 12;

  @override
  Widget build(BuildContext context) {
    final shown = names.take(4).toList();

    return SizedBox(
      height: _size,
      width: _size + (shown.length - 1) * _overlapStep,
      child: Stack(
        children: [
          for (var i = 0; i < shown.length; i++)
            Positioned(
              left: i * _overlapStep,
              child: _Avatar(name: shown[i], index: i, ringColor: ringColor),
            ),
        ],
      ),
    );
  }
}

/// A single 16px circle showing an attendee's initial.
class _Avatar extends StatelessWidget {
  const _Avatar({
    required this.name,
    required this.index,
    required this.ringColor,
  });

  final String name;
  final int index;
  final Color ringColor;

  static const double _size = 16;

  @override
  Widget build(BuildContext context) {
    final initial = name.isNotEmpty ? name.characters.first.toUpperCase() : '?';

    return Container(
      width: _size,
      height: _size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: _avatarPalette[index % _avatarPalette.length],
        shape: BoxShape.circle,
        border: Border.all(color: ringColor, width: 1.5),
      ),
      child: Text(
        initial,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 8,
          fontWeight: FontWeight.w600,
          height: 1,
        ),
      ),
    );
  }
}

class _ChatAvatar extends StatelessWidget {
  const _ChatAvatar({
    required this.name,
    required this.index,
    required this.ringColor,
  });

  final String name;
  final int index;
  final Color ringColor;

  static const double _size = 48;

  @override
  Widget build(BuildContext context) {
    final initial = name.isNotEmpty ? name.characters.first.toUpperCase() : '?';

    return Container(
      width: _size,
      height: _size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: _avatarPalette[index % _avatarPalette.length],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        initial,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.w600,
          height: 1,
        ),
      ),
    );
  }
}
