import 'dart:convert';
import 'dart:io';
import 'dart:async';
import 'dart:math' as math;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'achievements_service.dart';
import 'auth_service.dart';
import 'coins_service.dart';
import 'models/inbox_item.dart';
import 'notification_service.dart';
import 'services/friend_challenge_service.dart';
import 'services/friends_service.dart';
import 'services/inbox_service.dart';
import 'services/live_duel_service.dart';
import 'skin_catalog_service.dart';
import 'stats_service.dart';
import 'trail/trail_catalog.dart';
import 'trail/trail_skin.dart';
import 'ui/avatar_utils.dart';
import 'ui/components/coin_display.dart';
import 'ui/components/game_card.dart';
import 'ui/components/network_image_compat.dart';
import 'ui/components/section_header.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({
    super.key,
    required this.statsService,
    required this.achievementsService,
    required this.notificationService,
    required this.coinsService,
    required this.skinCatalogService,
    required this.authService,
  });

  final StatsService statsService;
  final AchievementsService achievementsService;
  final NotificationService notificationService;
  final CoinsService coinsService;
  final SkinCatalogService skinCatalogService;
  final AuthService authService;

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final InboxService _inboxService = InboxService();
  final FriendsService _friendsService = FriendsService();
  final FriendChallengeService _friendChallengeService =
      FriendChallengeService();
  final LiveDuelService _liveDuelService = LiveDuelService();
  static const String _firestoreDatabaseId = 'tracepath-database';

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([
        widget.statsService,
        widget.achievementsService,
        widget.notificationService,
        widget.coinsService,
        widget.skinCatalogService,
        widget.authService,
      ]),
      builder: (context, _) {
        final selectedSkinId = widget.coinsService.selectedSkin;
        final selectedCatalogItem = _findSelectedCatalogItem(selectedSkinId);
        final isDefaultSkinSelected = isDefaultSkinId(selectedSkinId) ||
            selectedCatalogItem?.id == 'pointer_default';
        final selectedSkinCandidates = _avatarSkinCandidates(
          selectedCatalogItem,
          preferredFromCoins: widget.coinsService.selectedSkinAssetPath,
        );
        final authUser = FirebaseAuth.instance.currentUser;
        final googleAvatar = _resolveGoogleAvatar(
          authUser: authUser,
          authServiceAvatar: widget.authService.avatarUrl,
        );
        final authName =
            (authUser?.displayName ?? widget.authService.displayName).trim();
        final authEmail =
            (authUser?.email ?? widget.authService.email ?? '').trim();
        final profileSubtitle = widget.authService.isGuest
            ? 'Guest mode'
            : (authEmail.isNotEmpty ? authEmail : 'Google account');
        final ownedSkins = widget.skinCatalogService.items
            .where((e) => widget.coinsService.ownsSkin(e.id))
            .toList(growable: false);
        final ownedTrails = TrailCatalog.all
            .where((e) => widget.coinsService.ownsTrail(e.id))
            .toList(growable: false);
        return Scaffold(
          backgroundColor: const Color(0xFF0F172A),
          appBar: AppBar(
            backgroundColor: const Color(0xFF0F172A),
            leadingWidth: widget.authService.isAuthenticated ? 64 : null,
            leading: widget.authService.isAuthenticated
                ? Padding(
                    padding: const EdgeInsets.only(left: 10, top: 8, bottom: 8),
                    child: Tooltip(
                      message: 'Logout',
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(14),
                          onTap: _onLogoutPressed,
                          child: Ink(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(14),
                              color: const Color(0xFF1A2740),
                              border: Border.all(
                                color: const Color(0xFF4B648F).withOpacity(0.9),
                                width: 1,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color:
                                      const Color(0xFF0A1322).withOpacity(0.55),
                                  blurRadius: 8,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                            ),
                            child: const Center(
                              child: Icon(
                                Icons.logout_rounded,
                                size: 18,
                                color: Color(0xFFBBD1FF),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  )
                : null,
            title: const Text('Profile'),
            actions: [
              Padding(
                padding: const EdgeInsets.only(right: 12),
                child: Center(
                  child: CoinDisplay(coins: widget.coinsService.coins),
                ),
              ),
            ],
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
                  stream: _currentUserDocStream(),
                  builder: (context, snapshot) {
                    final data =
                        snapshot.data?.data() ?? const <String, dynamic>{};
                    final resolvedGoogleAvatar = _resolveGoogleAvatar(
                      authUser: authUser,
                      authServiceAvatar: widget.authService.avatarUrl,
                      firestoreData: data,
                    );
                    final profileName =
                        ((data['playerName'] as String?)?.trim().isNotEmpty ==
                                true)
                            ? (data['playerName'] as String).trim()
                            : (authName.isNotEmpty ? authName : 'Player');
                    final username =
                        (data['username'] as String?)?.trim() ?? '';
                    final highestLevelReached =
                        _readInt(data['highestLevelReached'], fallback: 1);
                    final currentStreak = _readInt(
                      data['currentStreak'],
                      fallback: widget.statsService.currentDailyStreak,
                    );
                    final bestStreak = _readInt(
                      data['bestStreak'],
                      fallback: widget.statsService.bestDailyStreak,
                    );
                    final fastestSolveMs = _readInt(
                      data['fastestSolveMs'],
                      fallback:
                          widget.statsService.bestTimeMsForDifficulty(1) ?? 0,
                    );
                    final equippedSkinName =
                        selectedCatalogItem?.name ?? 'Default';
                    return Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(22),
                        gradient: const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: <Color>[
                            Color(0xFF1A2740),
                            Color(0xFF142037),
                            Color(0xFF101B30),
                          ],
                        ),
                        border: Border.all(
                          color: const Color(0xFF3B5076).withOpacity(0.85),
                        ),
                        boxShadow: <BoxShadow>[
                          BoxShadow(
                            color: const Color(0xFF111A2B).withOpacity(0.6),
                            blurRadius: 18,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                Container(
                                  width: 74,
                                  height: 74,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF0A1323),
                                    borderRadius: BorderRadius.circular(22),
                                    border: Border.all(
                                      color: const Color(0xFF4C6695)
                                          .withOpacity(0.9),
                                    ),
                                  ),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(21),
                                    child: Material(
                                      color: Colors.transparent,
                                      child: InkWell(
                                        onTap: () => _showSkinCardPreview(
                                            selectedSkinId),
                                        child: IgnorePointer(
                                          child: _ProfileHeaderAvatar(
                                            skinCandidates:
                                                isDefaultSkinSelected
                                                    ? const <String>[]
                                                    : selectedSkinCandidates,
                                            googleAvatarUrl:
                                                resolvedGoogleAvatar,
                                            preferSkin: !isDefaultSkinSelected,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        profileName,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w900,
                                          fontSize: 22,
                                          letterSpacing: 0.2,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        username.isNotEmpty
                                            ? '@$username'
                                            : '@player',
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          color: Color(0xFF9DB9FF),
                                          fontSize: 13,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        profileSubtitle,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          color: Color(0xFF8FA3C9),
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                TextButton(
                                  onPressed: () => context.go('/shop'),
                                  child: const Text('Shop'),
                                ),
                              ],
                            ),
                            const SizedBox(height: 14),
                            Row(
                              children: [
                                Expanded(
                                  child: _HeroStatChip(
                                    label: 'Level',
                                    value: '$highestLevelReached',
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: _HeroStatChip(
                                    label: 'Streak',
                                    value: '$currentStreak',
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: _HeroStatChip(
                                    label: 'Best',
                                    value: _formatMs(fastestSolveMs),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Align(
                              alignment: Alignment.centerLeft,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF1A2A44),
                                  borderRadius: BorderRadius.circular(999),
                                  border: Border.all(
                                    color: const Color(0xFF4567A0)
                                        .withOpacity(0.9),
                                  ),
                                ),
                                child: Text(
                                  '🔥 Best streak: $bestStreak',
                                  style: const TextStyle(
                                    color: Color(0xFFC9D8F9),
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 10),
                            Align(
                              alignment: Alignment.centerLeft,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF1A2A44),
                                  borderRadius: BorderRadius.circular(999),
                                  border: Border.all(
                                    color: const Color(0xFF4567A0)
                                        .withOpacity(0.9),
                                  ),
                                ),
                                child: Text(
                                  'Equipped Skin: $equippedSkinName',
                                  style: const TextStyle(
                                    color: Color(0xFFC9D8F9),
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 16),
                _ProfileProgressCard(
                  solvedLevels: widget.statsService.totalCampaignSolved,
                  highestLevel: widget.statsService.totalCampaignSolved + 1,
                ),
                const SizedBox(height: 16),
                const SectionHeader(title: 'Stats'),
                const SizedBox(height: 10),
                StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
                  stream: _currentUserDocStream(),
                  builder: (context, snapshot) {
                    final data =
                        snapshot.data?.data() ?? const <String, dynamic>{};
                    final totalLevelsCompleted = _readInt(
                      data['totalLevelsCompleted'],
                      fallback: widget.statsService.totalCampaignSolved,
                    );
                    final gamesPlayed = _readInt(
                      data['gamesPlayed'],
                      fallback: widget.statsService.totalCampaignSolved +
                          widget.statsService.totalDailySolved,
                    );
                    final fastestSolveMs = _readInt(
                      data['fastestSolveMs'],
                      fallback:
                          widget.statsService.bestTimeMsForDifficulty(1) ?? 0,
                    );
                    final highestLevelReached = _readInt(
                      data['highestLevelReached'],
                      fallback: 1,
                    );
                    if (kDebugMode) {
                      debugPrint(
                        '[profile] stats loaded from firestore totalLevelsCompleted=$totalLevelsCompleted gamesPlayed=$gamesPlayed fastestSolveMs=$fastestSolveMs highestLevelReached=$highestLevelReached',
                      );
                    }
                    return Column(
                      children: [
                        LayoutBuilder(
                          builder: (context, constraints) {
                            final gap = 10.0;
                            final cardWidth = (constraints.maxWidth - gap) / 2;
                            return Wrap(
                              spacing: gap,
                              runSpacing: gap,
                              children: [
                                SizedBox(
                                  width: cardWidth,
                                  child: _PremiumStatTile(
                                    title: 'Levels Solved',
                                    value: '$totalLevelsCompleted',
                                    icon: Icons.check_circle_outline_rounded,
                                  ),
                                ),
                                SizedBox(
                                  width: cardWidth,
                                  child: _PremiumStatTile(
                                    title: 'Games Played',
                                    value: '$gamesPlayed',
                                    icon: Icons.sports_esports_rounded,
                                  ),
                                ),
                                SizedBox(
                                  width: cardWidth,
                                  child: _PremiumStatTile(
                                    title: 'Best Time',
                                    value: _formatMs(fastestSolveMs),
                                    icon: Icons.bolt_rounded,
                                  ),
                                ),
                                SizedBox(
                                  width: cardWidth,
                                  child: _PremiumStatTile(
                                    title: 'Highest Level',
                                    value: '$highestLevelReached',
                                    icon: Icons.flag_rounded,
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 16),
                const SectionHeader(title: 'Wardrobe'),
                const SizedBox(height: 10),
                GameCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: _LoadoutMiniCard(
                              title: 'Skin',
                              name: selectedCatalogItem?.name ?? 'Default',
                              tag: 'Equipped',
                              icon: Icons.face_rounded,
                              preview: Container(
                                decoration: BoxDecoration(
                                  color: const Color(0xFF060E20),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: const Color(0xFF334155),
                                  ),
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(11),
                                  child: _ProfileHeaderAvatar(
                                    skinCandidates: isDefaultSkinSelected
                                        ? const <String>[]
                                        : selectedSkinCandidates,
                                    googleAvatarUrl: isDefaultSkinSelected
                                        ? googleAvatar
                                        : '',
                                    preferSkin: !isDefaultSkinSelected,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _LoadoutMiniCard(
                              title: 'Trail',
                              name: TrailCatalog.resolveByTrailId(
                                      widget.coinsService.selectedTrail)
                                  .name,
                              tag: 'Equipped',
                              icon: Icons.timeline_rounded,
                              preview: Container(
                                decoration: BoxDecoration(
                                  color: const Color(0xFF060E20),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: const Color(0xFF334155),
                                  ),
                                ),
                                child: Center(
                                  child: Icon(
                                    Icons.linear_scale_rounded,
                                    color: TrailCatalog.resolveByTrailId(
                                            widget.coinsService.selectedTrail)
                                        .primaryColor,
                                    size: 26,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'My Skins',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(height: 10),
                      if (ownedSkins.isEmpty)
                        const _WardrobeEmptyState(
                          message: 'No owned skins yet.',
                          icon: Icons.face_retouching_natural_rounded,
                        )
                      else
                        SizedBox(
                          height: 286,
                          child: _SkinWardrobeCarousel(
                            skins: ownedSkins,
                            selectedSkinId: widget.coinsService.selectedSkin,
                            resolveRenderablePath: (skin) =>
                                _bestRenderableSkinPath(skin),
                            onEquip: (skin) async {
                              final fullPathRaw = skin.fullImagePath.trim();
                              final resolved = await widget.skinCatalogService
                                  .resolveDownloadUrl(
                                fullPathRaw,
                                context: 'profile-equip:${skin.id}',
                              );
                              final renderPath =
                                  (resolved ?? '').trim().isNotEmpty
                                      ? resolved!.trim()
                                      : widget.skinCatalogService
                                          .toRenderablePath(skin.imagePath);
                              await widget.coinsService.registerSkinAsset(
                                skin.id,
                                renderPath,
                              );
                              await widget.coinsService.selectSkin(skin.id);
                            },
                          ),
                        ),
                      const SizedBox(height: 16),
                      const Text(
                        'My Trails',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(height: 10),
                      if (ownedTrails.isEmpty)
                        const _WardrobeEmptyState(
                          message: 'No owned trails yet.',
                          icon: Icons.timeline_rounded,
                        )
                      else
                        SizedBox(
                          height: 228,
                          child: _TrailWardrobeCarousel(
                            trails: ownedTrails,
                            selectedTrailId: widget.coinsService.selectedTrail,
                            onEquip: (trail) =>
                                widget.coinsService.selectTrail(trail.id),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                StreamBuilder<List<InboxItem>>(
                  stream: _inboxService.watchInbox(),
                  builder: (context, snapshot) {
                    final inboxItems = snapshot.data ?? const <InboxItem>[];
                    final unreadCount = inboxItems
                        .where((e) => !e.read || e.isPendingFriendRequest)
                        .length;
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SectionHeader(
                          title: unreadCount > 0
                              ? 'Inbox ($unreadCount)'
                              : 'Inbox',
                        ),
                        const SizedBox(height: 10),
                        if (snapshot.hasError)
                          const _InboxEmptyCard(
                            title: 'Inbox unavailable right now',
                            subtitle: 'Please try again in a moment.',
                            icon: Icons.inbox_rounded,
                          )
                        else if (inboxItems.isEmpty)
                          const _InboxEmptyCard(
                            title: 'No messages yet',
                            subtitle:
                                'Friend requests, rewards and news will appear here.',
                            icon: Icons.mark_email_unread_outlined,
                          )
                        else
                          Column(
                            children: [
                              for (final item in inboxItems.take(12))
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 10),
                                  child: _InboxItemCard(
                                    item: item,
                                    onTap: () => _markInboxAsRead(item),
                                    onAccept: item.isPendingFriendRequest
                                        ? () => _acceptFriendRequest(item)
                                        : null,
                                    onDecline: item.isPendingFriendRequest
                                        ? () => _declineFriendRequest(item)
                                        : _isPendingChallengeInvite(item)
                                            ? () =>
                                                _declineChallengeInvite(item)
                                            : null,
                                    onCta: item.hasCta
                                        ? () => unawaited(_handleInboxCta(item))
                                        : null,
                                    onDelete: item.read &&
                                            !item.isPendingFriendRequest
                                        ? () => _deleteInboxItem(item)
                                        : null,
                                  ),
                                ),
                            ],
                          ),
                        const SizedBox(height: 6),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 16),
                _AchievementsSection(
                  states: widget.achievementsService.states,
                  formatDateTime: _formatDateTime,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  SkinCatalogItem? _findSelectedCatalogItem(String selectedSkinId) {
    final direct = widget.skinCatalogService.getById(selectedSkinId);
    if (direct != null) return direct;
    final normalized = selectedSkinId.trim().toLowerCase();
    if (normalized.isEmpty) return null;
    for (final item in widget.skinCatalogService.items) {
      final itemId = item.id.trim().toLowerCase();
      if (itemId == normalized ||
          itemId.replaceAll('-', '_') == normalized.replaceAll('-', '_')) {
        return item;
      }
    }
    return null;
  }

  String _bestRenderableSkinPath(SkinCatalogItem? item) {
    if (item == null) return '';
    final candidates = <String>[
      item.fullImagePath,
      item.previewImagePath,
      item.cardImagePath,
      item.bannerImagePath,
    ];
    for (final raw in candidates) {
      final trimmed = raw.trim();
      if (trimmed.isEmpty) continue;
      final renderable = widget.skinCatalogService.toRenderablePath(trimmed);
      if (renderable.trim().isNotEmpty) return renderable.trim();
    }
    return '';
  }

  List<String> _avatarSkinCandidates(
    SkinCatalogItem? item, {
    String? preferredFromCoins,
  }) {
    final ordered = <String>[
      (preferredFromCoins ?? '').trim(),
      if (item != null) ...<String>[
        item.fullImagePath,
        item.previewImagePath,
        item.cardImagePath,
        item.bannerImagePath,
      ],
    ];
    final out = <String>[];
    for (final raw in ordered) {
      final trimmed = raw.trim();
      if (trimmed.isEmpty) continue;
      final renderable =
          widget.skinCatalogService.toRenderablePath(trimmed).trim();
      if (renderable.isEmpty) continue;
      if (!out.contains(renderable)) {
        out.add(renderable);
      }
    }
    return out;
  }

  String _resolveGoogleAvatar({
    required User? authUser,
    String? authServiceAvatar,
    Map<String, dynamic>? firestoreData,
  }) {
    final candidates = <String>[
      (authUser?.photoURL ?? '').trim(),
      if (authUser != null)
        ...authUser.providerData
            .map((p) => (p.photoURL ?? '').trim())
            .where((v) => v.isNotEmpty),
      (authServiceAvatar ?? '').trim(),
      ((firestoreData?['photoUrl'] as String?) ?? '').trim(),
      ((firestoreData?['photoURL'] as String?) ?? '').trim(),
      ((firestoreData?['avatarUrl'] as String?) ?? '').trim(),
      ((firestoreData?['avatarURL'] as String?) ?? '').trim(),
    ];
    for (final c in candidates) {
      final normalized = _normalizeAvatarPath(c);
      if (normalized.isNotEmpty) return normalized;
    }
    return '';
  }

  String _normalizeAvatarPath(String raw) {
    final value = raw.trim();
    if (value.isEmpty) return '';
    if (value.startsWith('http://') ||
        value.startsWith('https://') ||
        value.startsWith('data:image') ||
        value.startsWith('assets/')) {
      return value;
    }
    if (value.startsWith('gs://')) {
      final withoutPrefix = value.replaceFirst('gs://', '');
      final slash = withoutPrefix.indexOf('/');
      if (slash <= 0 || slash >= withoutPrefix.length - 1) return '';
      final bucket = withoutPrefix.substring(0, slash);
      final objectPath = withoutPrefix.substring(slash + 1);
      return 'https://firebasestorage.googleapis.com/v0/b/'
          '$bucket/o/${Uri.encodeComponent(objectPath)}?alt=media';
    }
    return '';
  }

  Future<void> _markInboxAsRead(InboxItem item) async {
    if (item.read) return;
    try {
      await _inboxService.markAsRead(uid: '', messageId: item.id);
    } catch (_) {}
  }

  Future<void> _deleteInboxItem(InboxItem item) async {
    try {
      await _inboxService.deleteInboxItem(uid: '', messageId: item.id);
    } catch (_) {}
  }

  Future<void> _acceptFriendRequest(InboxItem item) async {
    final fromUid = item.fromUid.trim();
    if (fromUid.isEmpty) return;
    try {
      await _friendsService.acceptFriendRequest(
        fromUid: fromUid,
        inboxMessageId: item.id,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Friend request accepted'),
          duration: Duration(milliseconds: 900),
        ),
      );
    } catch (e) {
      if (kDebugMode) {
        debugPrint(
            '[profile] acceptFriendRequest failed fromUid=$fromUid error=$e');
      }
      var message = 'Could not accept friend request';
      if (e.toString().contains('REQUEST_NOT_FOUND')) {
        message = 'Request not found';
      } else if (e is FirebaseException && e.code == 'permission-denied') {
        message = 'Firestore rules blocked accept request';
      } else if (e is FirebaseException && e.code.isNotEmpty) {
        message = 'Accept failed: ${e.code}';
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          duration: Duration(milliseconds: 900),
        ),
      );
    }
  }

  Future<void> _declineFriendRequest(InboxItem item) async {
    final fromUid = item.fromUid.trim();
    if (fromUid.isEmpty) return;
    try {
      await _friendsService.declineFriendRequest(
        fromUid: fromUid,
        inboxMessageId: item.id,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Friend request declined'),
          duration: Duration(milliseconds: 900),
        ),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not decline friend request'),
          duration: Duration(milliseconds: 900),
        ),
      );
    }
  }

  bool _isPendingChallengeInvite(InboxItem item) {
    if (item.status.trim().toLowerCase() != 'pending') return false;
    return item.type == InboxItemType.friendChallenge ||
        item.type == InboxItemType.levelChallenge ||
        item.type == InboxItemType.liveDuelInvite;
  }

  Future<void> _declineChallengeInvite(InboxItem item) async {
    try {
      switch (item.type) {
        case InboxItemType.friendChallenge:
          final challengeId = item.ctaPayload.trim();
          if (challengeId.isEmpty) {
            await _deleteInboxItem(item);
            throw StateError('INVALID_CHALLENGE_ID');
          }
          await _friendChallengeService.declineInvite(
            challengeId: challengeId,
            inboxMessageId: item.id,
          );
          break;
        case InboxItemType.liveDuelInvite:
          final matchId = item.ctaPayload.trim();
          if (matchId.isEmpty) {
            await _deleteInboxItem(item);
            throw StateError('INVALID_MATCH_ID');
          }
          await _liveDuelService.declineInvite(
            matchId: matchId,
            inboxMessageId: item.id,
          );
          break;
        case InboxItemType.levelChallenge:
          await _sendGenericDeclineResponse(
            item: item,
            title: 'Challenge declined',
            bodySuffix: 'declined your challenge.',
          );
          await _deleteInboxItem(item);
          break;
        case InboxItemType.friendRequest:
        case InboxItemType.friendAccept:
        case InboxItemType.systemNews:
        case InboxItemType.unknown:
          return;
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Challenge declined'),
          duration: Duration(milliseconds: 900),
        ),
      );
    } catch (e) {
      if (kDebugMode) {
        debugPrint(
            '[profile] decline challenge invite failed id=${item.id} error=$e');
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not decline challenge'),
          duration: Duration(milliseconds: 900),
        ),
      );
    }
  }

  Future<void> _sendGenericDeclineResponse({
    required InboxItem item,
    required String title,
    required String bodySuffix,
  }) async {
    final targetUid = item.fromUid.trim();
    if (targetUid.isEmpty) return;
    final me = await _readCurrentUserSocialProfile();
    final username = (me['username'] as String?)?.trim() ?? '';
    final playerName = (me['playerName'] as String?)?.trim().isNotEmpty == true
        ? (me['playerName'] as String).trim()
        : 'Player';
    final avatarId = (me['avatarId'] as String?)?.trim().isNotEmpty == true
        ? (me['avatarId'] as String).trim()
        : 'default';
    final label = username.isNotEmpty ? '@$username' : playerName;

    await _inboxService.addInboxItem(
      uid: targetUid,
      type: 'system_news',
      title: title,
      body: '$label $bodySuffix',
      status: 'declined',
      extraData: <String, dynamic>{
        'fromUid': FirebaseAuth.instance.currentUser?.uid.trim() ?? '',
        'fromUsername': username,
        'fromPlayerName': playerName,
        'fromAvatarId': avatarId,
        'ctaType': 'open_social',
        'ctaPayload': '/social',
      },
      messageId: 'decline_reply_${item.type.name}_${item.id}',
    );
  }

  Future<void> _sendGenericAcceptedResponse({
    required InboxItem item,
    required String title,
    required String bodySuffix,
  }) async {
    final targetUid = item.fromUid.trim();
    if (targetUid.isEmpty) return;
    final me = await _readCurrentUserSocialProfile();
    final username = (me['username'] as String?)?.trim() ?? '';
    final playerName = (me['playerName'] as String?)?.trim().isNotEmpty == true
        ? (me['playerName'] as String).trim()
        : 'Player';
    final avatarId = (me['avatarId'] as String?)?.trim().isNotEmpty == true
        ? (me['avatarId'] as String).trim()
        : 'default';
    final label = username.isNotEmpty ? '@$username' : playerName;

    await _inboxService.addInboxItem(
      uid: targetUid,
      type: 'system_news',
      title: title,
      body: '$label $bodySuffix',
      status: 'accepted',
      extraData: <String, dynamic>{
        'fromUid': FirebaseAuth.instance.currentUser?.uid.trim() ?? '',
        'fromUsername': username,
        'fromPlayerName': playerName,
        'fromAvatarId': avatarId,
        'ctaType': 'open_social',
        'ctaPayload': '/social',
      },
      messageId: 'accept_reply_${item.type.name}_${item.id}',
    );
  }

  Future<void> _handleInboxCta(InboxItem item) async {
    String? targetRoute;
    final ctaPayload = item.ctaPayload.trim();
    switch (item.ctaType) {
      case 'open_shop':
        targetRoute = '/shop';
        break;
      case 'open_social':
        targetRoute = '/social';
        break;
      case 'open_profile':
        targetRoute = '/profile';
        break;
      case 'open_live_duel':
        final matchId = ctaPayload;
        if (matchId.isNotEmpty) {
          targetRoute = '/live-duel/$matchId';
        }
        break;
      case 'open_friend_challenge':
        final challengeId = ctaPayload;
        if (challengeId.isNotEmpty) {
          try {
            await _friendChallengeService.acknowledgeInviteOpened(
              challengeId: challengeId,
            );
          } catch (e) {
            if (kDebugMode) {
              debugPrint(
                '[profile] challenge acknowledge failed challengeId=$challengeId error=$e',
              );
            }
          }
          targetRoute = '/friend-challenge/$challengeId';
        }
        break;
      default:
        if (item.type == InboxItemType.levelChallenge) {
          await _sendGenericAcceptedResponse(
            item: item,
            title: 'Challenge accepted',
            bodySuffix: 'accepted your challenge.',
          );
        }
        if (ctaPayload.isNotEmpty) {
          targetRoute = ctaPayload;
        }
    }
    if (targetRoute == null || targetRoute.trim().isEmpty) {
      return;
    }
    if (!mounted) return;
    context.go(targetRoute.trim());
    try {
      await _inboxService.deleteInboxItem(uid: '', messageId: item.id);
    } catch (_) {
      // Keep navigation flow even if delete fails; user can retry manually.
    }
  }

  Future<void> _showSkinCardPreview(String selectedSkinId) async {
    final selectedCatalogItem =
        widget.skinCatalogService.getById(selectedSkinId);
    final cardPathRaw = (selectedCatalogItem?.cardPath ?? '').trim();
    final rarityBackAsset = _cardBackAssetForRarity(
        (selectedCatalogItem?.rarity ?? 'Common').trim());
    final candidates = <String>[];

    Future<void> addResolvedCandidate(String raw, String contextTag) async {
      final trimmed = raw.trim();
      if (trimmed.isEmpty) return;
      final resolved = await widget.skinCatalogService.resolveDownloadUrl(
            trimmed,
            context: contextTag,
          ) ??
          widget.skinCatalogService.toRenderablePath(trimmed);
      final path = resolved.trim();
      if (path.isEmpty) return;
      if (!candidates.contains(path)) {
        candidates.add(path);
      }
    }

    final rawCardCandidates = <String>{
      cardPathRaw,
      ..._inferTarjetaCandidatesFromPath(
          selectedCatalogItem?.fullImagePath ?? ''),
      ..._inferTarjetaCandidatesFromPath(
          selectedCatalogItem?.previewImagePath ?? ''),
      ..._inferTarjetaCandidatesFromPath(selectedCatalogItem?.imagePath ?? ''),
    }..removeWhere((e) => e.trim().isEmpty);

    for (final raw in rawCardCandidates) {
      await addResolvedCandidate(raw, 'profile-card:$selectedSkinId');
    }

    if (candidates.isEmpty) {
      if (!mounted) return;
      await showDialog<void>(
        context: context,
        barrierColor: Colors.black.withOpacity(0.82),
        builder: (context) => const AlertDialog(
          backgroundColor: Color(0xFF111827),
          title: Text(
            'Card unavailable',
            style: TextStyle(color: Colors.white),
          ),
          content: Text(
            'There is no card for this skin yet.',
            style: TextStyle(color: Color(0xFFB6C2DA)),
          ),
        ),
      );
      return;
    }

    if (!mounted) return;
    await showDialog<void>(
      context: context,
      barrierColor: Colors.black.withOpacity(0.82),
      builder: (context) => _SkinCardViewer(
        candidates: candidates,
        backCandidates: <String>[rarityBackAsset],
      ),
    );
  }

  String _cardBackAssetForRarity(String rarityRaw) {
    switch (rarityRaw.toLowerCase()) {
      case 'rare':
        return 'assets/ui/cards/rare_back.png';
      case 'epic':
        return 'assets/ui/cards/epic_card.png';
      case 'legendary':
        return 'assets/ui/cards/legendary-card.png';
      default:
        return 'assets/ui/cards/common_back.png';
    }
  }

  List<String> _inferTarjetaCandidatesFromPath(String rawPath) {
    final trimmed = rawPath.trim();
    if (trimmed.isEmpty) return const <String>[];
    final normalized = trimmed.replaceAll('\\', '/');
    final out = <String>{};

    String withSuffix(String source, String suffix) {
      final q = source.indexOf('?');
      final base = q >= 0 ? source.substring(0, q) : source;
      final query = q >= 0 ? source.substring(q) : '';
      final dot = base.lastIndexOf('.');
      if (dot <= 0) return '$base$suffix$query';
      final stem = base.substring(0, dot);
      final ext = base.substring(dot);
      return '$stem$suffix$ext$query';
    }

    final tarjeta = withSuffix(normalized, '-tarjeta');
    out.add(tarjeta);
    out.add(tarjeta.replaceAll('-thumb-tarjeta.', '-tarjeta.'));
    out.add(tarjeta.replaceAll('-banner-tarjeta.', '-tarjeta.'));
    out.add(tarjeta.replaceAll('-preview-tarjeta.', '-tarjeta.'));
    if (tarjeta.toLowerCase().contains('.webp')) {
      out.add(tarjeta.replaceAll('.webp', '.png'));
      out.add(tarjeta.replaceAll('.WEBP', '.png'));
    }
    return out.toList(growable: false);
  }

  Stream<DocumentSnapshot<Map<String, dynamic>>> _currentUserDocStream() {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null || uid.trim().isEmpty) {
      return const Stream<DocumentSnapshot<Map<String, dynamic>>>.empty();
    }
    try {
      return FirebaseFirestore.instanceFor(
        app: Firebase.app(),
        databaseId: _firestoreDatabaseId,
      ).collection('users').doc(uid).snapshots();
    } catch (_) {
      return FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .snapshots();
    }
  }

  Future<Map<String, dynamic>> _readCurrentUserSocialProfile() async {
    final uid = FirebaseAuth.instance.currentUser?.uid.trim() ?? '';
    if (uid.isEmpty) return const <String, dynamic>{};
    try {
      final snap = await FirebaseFirestore.instanceFor(
        app: Firebase.app(),
        databaseId: _firestoreDatabaseId,
      ).collection('users').doc(uid).get();
      return snap.data() ?? const <String, dynamic>{};
    } catch (_) {
      final snap =
          await FirebaseFirestore.instance.collection('users').doc(uid).get();
      return snap.data() ?? const <String, dynamic>{};
    }
  }

  Future<void> _onLogoutPressed() async {
    final shouldLogout = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            backgroundColor: const Color(0xFF111827),
            title: const Text(
              'Logout',
              style: TextStyle(color: Colors.white),
            ),
            content: const Text(
              'Do you want to sign out?',
              style: TextStyle(color: Color(0xFFB6C2DA)),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('Logout'),
              ),
            ],
          ),
        ) ??
        false;
    if (!shouldLogout) return;
    await widget.authService.signOut();
    if (!mounted) return;
    context.go('/home');
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Signed out'),
        duration: Duration(milliseconds: 900),
      ),
    );
  }

  static String _formatMs(int? ms) {
    if (ms == null || ms <= 0) return '--:--';
    final totalSeconds = (ms / 1000).round();
    final minutes = (totalSeconds ~/ 60).toString().padLeft(2, '0');
    final seconds = (totalSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  int _readInt(Object? value, {int fallback = 0}) {
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value.trim()) ?? fallback;
    return fallback;
  }

  static String _formatDateTime(DateTime dateTime) {
    final yyyy = dateTime.year.toString().padLeft(4, '0');
    final mm = dateTime.month.toString().padLeft(2, '0');
    final dd = dateTime.day.toString().padLeft(2, '0');
    return '$yyyy-$mm-$dd';
  }
}

class _HeroStatChip extends StatelessWidget {
  const _HeroStatChip({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF0E192B),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF334155)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(
              color: Color(0xFF8CA0C8),
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileProgressCard extends StatelessWidget {
  const _ProfileProgressCard({
    required this.solvedLevels,
    required this.highestLevel,
  });

  final int solvedLevels;
  final int highestLevel;

  @override
  Widget build(BuildContext context) {
    final milestoneTarget = math.max(100, ((highestLevel / 25).ceil()) * 25);
    final progress = milestoneTarget <= 0
        ? 0.0
        : (solvedLevels / milestoneTarget).clamp(0.0, 1.0);
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF16233A),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFF304867)),
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'World Progress',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w800,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 9,
              backgroundColor: const Color(0xFF0A1323),
              color: const Color(0xFF4F86FF),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '$solvedLevels / $milestoneTarget levels completed',
                style: const TextStyle(
                  color: Color(0xFF9CB1D8),
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                'Highest $highestLevel',
                style: const TextStyle(
                  color: Color(0xFF9CB1D8),
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _LoadoutMiniCard extends StatelessWidget {
  const _LoadoutMiniCard({
    required this.title,
    required this.name,
    required this.tag,
    required this.icon,
    required this.preview,
  });

  final String title;
  final String name;
  final String tag;
  final IconData icon;
  final Widget preview;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF141F33),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF324761)),
      ),
      padding: const EdgeInsets.all(10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(height: 56, child: preview),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(icon, color: const Color(0xFF9DB9FF), size: 14),
              const SizedBox(width: 4),
              Text(
                title,
                style: const TextStyle(
                  color: Color(0xFF9CB1D8),
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 3),
          Text(
            name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 5),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFF1C3154),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              tag,
              style: const TextStyle(
                color: Color(0xFFD1DDF8),
                fontSize: 10,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _WardrobeEmptyState extends StatelessWidget {
  const _WardrobeEmptyState({
    required this.message,
    required this.icon,
  });

  final String message;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 94,
      decoration: BoxDecoration(
        color: const Color(0xFF121D31),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF334861)),
      ),
      child: Center(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 20, color: const Color(0xFF8EA3CB)),
            const SizedBox(width: 10),
            Text(
              message,
              style: const TextStyle(
                color: Color(0xFF9BB0D6),
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SkinWardrobeCarousel extends StatefulWidget {
  const _SkinWardrobeCarousel({
    required this.skins,
    required this.selectedSkinId,
    required this.resolveRenderablePath,
    required this.onEquip,
  });

  final List<SkinCatalogItem> skins;
  final String selectedSkinId;
  final String Function(SkinCatalogItem skin) resolveRenderablePath;
  final Future<void> Function(SkinCatalogItem skin) onEquip;

  @override
  State<_SkinWardrobeCarousel> createState() => _SkinWardrobeCarouselState();
}

class _SkinWardrobeCarouselState extends State<_SkinWardrobeCarousel> {
  late final PageController _controller =
      PageController(viewportFraction: 0.78);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PageView.builder(
      controller: _controller,
      itemCount: widget.skins.length,
      padEnds: false,
      itemBuilder: (context, index) {
        final skin = widget.skins[index];
        final equipped = widget.selectedSkinId == skin.id;
        final renderPath = widget.resolveRenderablePath(skin).trim();
        return Padding(
          padding: EdgeInsets.only(
            right: index == widget.skins.length - 1 ? 0 : 12,
          ),
          child: SkinFlipCard(
            skin: skin,
            imagePath: renderPath,
            isEquipped: equipped,
            onEquip: () => widget.onEquip(skin),
          ),
        );
      },
    );
  }
}

class SkinFlipCard extends StatefulWidget {
  const SkinFlipCard({
    super.key,
    required this.skin,
    required this.imagePath,
    required this.isEquipped,
    required this.onEquip,
  });

  final SkinCatalogItem skin;
  final String imagePath;
  final bool isEquipped;
  final Future<void> Function() onEquip;

  @override
  State<SkinFlipCard> createState() => _SkinFlipCardState();
}

class _SkinFlipCardState extends State<SkinFlipCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 400),
  );

  bool _showFront = true;
  bool _busy = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _flip() async {
    if (_controller.isAnimating) return;
    if (_showFront) {
      await _controller.forward();
    } else {
      await _controller.reverse();
    }
    if (!mounted) return;
    setState(() {
      _showFront = !_showFront;
    });
  }

  Future<void> _handleEquip() async {
    if (_busy || widget.isEquipped) return;
    setState(() => _busy = true);
    try {
      await widget.onEquip();
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final rarity = widget.skin.rarity.trim().isEmpty
        ? 'Common'
        : widget.skin.rarity.trim();
    final rarityColor = _rarityColor(rarity);
    return GestureDetector(
      onTap: _flip,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          final angle = _controller.value * math.pi;
          final showFront = angle <= math.pi / 2;
          final effectiveAngle = showFront ? angle : angle - math.pi;
          return Transform(
            alignment: Alignment.center,
            transform: Matrix4.identity()
              ..setEntry(3, 2, 0.001)
              ..rotateY(effectiveAngle),
            child: showFront
                ? _buildFront(rarity, rarityColor)
                : _buildBack(rarity, rarityColor),
          );
        },
      ),
    );
  }

  Widget _buildFront(String rarity, Color rarityColor) {
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1A263C), Color(0xFF151F32)],
        ),
        border: Border.all(
          color: widget.isEquipped ? rarityColor : const Color(0xFF334A68),
          width: widget.isEquipped ? 1.8 : 1.2,
        ),
        boxShadow: [
          if (widget.isEquipped)
            BoxShadow(
              color: rarityColor.withOpacity(0.22),
              blurRadius: 14,
              offset: const Offset(0, 6),
            ),
          BoxShadow(
            color: Colors.black.withOpacity(0.28),
            blurRadius: 12,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: const Color(0xFF070F1F),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFF334155)),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(13),
                  child: widget.imagePath.isEmpty
                      ? const Center(
                          child: Icon(
                            Icons.face_rounded,
                            color: Color(0xFF8EA6D4),
                            size: 44,
                          ),
                        )
                      : buildNetworkImageCompat(
                          url: widget.imagePath,
                          fit: BoxFit.contain,
                          filterQuality: FilterQuality.medium,
                          fallback: const Center(
                            child: Icon(
                              Icons.face_rounded,
                              color: Color(0xFF8EA6D4),
                              size: 44,
                            ),
                          ),
                        ),
                ),
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: Text(
                    widget.skin.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 14,
                    ),
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: rarityColor.withOpacity(0.16),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: rarityColor.withOpacity(0.9)),
                  ),
                  child: Text(
                    rarity,
                    style: TextStyle(
                      color: rarityColor,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: widget.isEquipped || _busy ? null : _handleEquip,
                style: FilledButton.styleFrom(
                  backgroundColor:
                      widget.isEquipped ? const Color(0xFF243858) : rarityColor,
                  foregroundColor: widget.isEquipped
                      ? const Color(0xFFC9D8F4)
                      : Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 10),
                ),
                child: Text(widget.isEquipped ? 'Equipped' : 'Equip'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBack(String rarity, Color rarityColor) {
    final assetPath = _cardBackAssetForRarity(rarity);
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: rarityColor.withOpacity(0.85), width: 1.6),
        boxShadow: [
          BoxShadow(
            color: rarityColor.withOpacity(0.2),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.asset(
              assetPath,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => Container(
                color: const Color(0xFF131E33),
                alignment: Alignment.center,
                child: const Icon(
                  Icons.style_rounded,
                  color: Color(0xFF93A7CC),
                  size: 40,
                ),
              ),
            ),
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withOpacity(0.35),
                  ],
                ),
              ),
            ),
            Positioned(
              left: 12,
              right: 12,
              bottom: 12,
              child: Row(
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(color: rarityColor.withOpacity(0.85)),
                    ),
                    child: Text(
                      rarity.toUpperCase(),
                      style: TextStyle(
                        color: rarityColor,
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.6,
                      ),
                    ),
                  ),
                  const Spacer(),
                  const Icon(
                    Icons.touch_app_rounded,
                    size: 16,
                    color: Color(0xFFE2ECFF),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _rarityColor(String rarityRaw) {
    switch (rarityRaw.toLowerCase()) {
      case 'rare':
        return const Color(0xFF3A8DFF);
      case 'epic':
        return const Color(0xFF9B59FF);
      case 'legendary':
        return const Color(0xFFFFB800);
      default:
        return const Color(0xFF8A8F98);
    }
  }

  String _cardBackAssetForRarity(String rarityRaw) {
    switch (rarityRaw.toLowerCase()) {
      case 'rare':
        return 'assets/ui/cards/rare_back.png';
      case 'epic':
        return 'assets/ui/cards/epic_card.png';
      case 'legendary':
        return 'assets/ui/cards/legendary-card.png';
      default:
        return 'assets/ui/cards/common_back.png';
    }
  }
}

class _TrailWardrobeCarousel extends StatefulWidget {
  const _TrailWardrobeCarousel({
    required this.trails,
    required this.selectedTrailId,
    required this.onEquip,
  });

  final List<TrailSkinConfig> trails;
  final String selectedTrailId;
  final Future<void> Function(TrailSkinConfig trail) onEquip;

  @override
  State<_TrailWardrobeCarousel> createState() => _TrailWardrobeCarouselState();
}

class _TrailWardrobeCarouselState extends State<_TrailWardrobeCarousel> {
  late final PageController _controller =
      PageController(viewportFraction: 0.86);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PageView.builder(
      controller: _controller,
      itemCount: widget.trails.length,
      padEnds: false,
      itemBuilder: (context, index) {
        final trail = widget.trails[index];
        final equipped = widget.selectedTrailId == trail.id;
        final accent = trail.primaryColor;
        return Padding(
          padding: EdgeInsets.only(
            right: index == widget.trails.length - 1 ? 0 : 12,
          ),
          child: DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              color: const Color(0xFF172338),
              border: Border.all(
                color: equipped
                    ? accent.withOpacity(0.95)
                    : const Color(0xFF31465F),
                width: equipped ? 1.6 : 1.1,
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    height: 86,
                    decoration: BoxDecoration(
                      color: const Color(0xFF071023),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFF344A66)),
                    ),
                    child: Center(
                      child: Container(
                        width: 152,
                        height: 8,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(999),
                          gradient: LinearGradient(
                            colors: [
                              accent.withOpacity(0.2),
                              accent,
                              trail.secondaryColor
                            ],
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: accent.withOpacity(0.35),
                              blurRadius: 12,
                              spreadRadius: 1,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    trail.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: equipped ? null : () => widget.onEquip(trail),
                      style: FilledButton.styleFrom(
                        backgroundColor: equipped
                            ? const Color(0xFF263854)
                            : accent.withOpacity(0.9),
                        foregroundColor:
                            equipped ? const Color(0xFFD1DEF8) : Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 10),
                      ),
                      child: Text(equipped ? 'Equipped' : 'Equip'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _PremiumStatTile extends StatelessWidget {
  const _PremiumStatTile({
    required this.title,
    required this.value,
    required this.icon,
  });

  final String title;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 124,
      decoration: BoxDecoration(
        color: const Color(0xFF1A2538),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF304560)),
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: const Color(0xFF8FB3FF), size: 18),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w900,
              height: 1,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: const TextStyle(
              color: Color(0xFF9FB1D5),
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _AchievementsSection extends StatelessWidget {
  const _AchievementsSection({
    required this.states,
    required this.formatDateTime,
  });

  final List<AchievementState> states;
  final String Function(DateTime dateTime) formatDateTime;

  @override
  Widget build(BuildContext context) {
    final unlocked = states.where((e) => e.unlocked).length;
    final total = states.length;
    final progress = total == 0 ? 0.0 : unlocked / total;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeader(title: 'Achievements'),
        const SizedBox(height: 10),
        Container(
          decoration: BoxDecoration(
            color: const Color(0xFF17233A),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0xFF324764)),
          ),
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '$unlocked / $total unlocked',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(999),
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 8,
                  backgroundColor: const Color(0xFF0A1323),
                  color: const Color(0xFF4B86FF),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        LayoutBuilder(
          builder: (context, constraints) {
            final gap = 12.0;
            final cardWidth = (constraints.maxWidth - gap) / 2;
            return Wrap(
              spacing: gap,
              runSpacing: gap,
              children: [
                for (final state in states)
                  SizedBox(
                    width: cardWidth,
                    child: _AchievementMedalCard(
                      state: state,
                      formatDateTime: formatDateTime,
                    ),
                  ),
              ],
            );
          },
        ),
      ],
    );
  }
}

class _AchievementMedalCard extends StatelessWidget {
  const _AchievementMedalCard({
    required this.state,
    required this.formatDateTime,
  });

  final AchievementState state;
  final String Function(DateTime dateTime) formatDateTime;

  @override
  Widget build(BuildContext context) {
    final unlocked = state.unlocked;
    final accent = _accentForAchievementId(state.def.id, unlocked);
    final icon = _iconForAchievementId(state.def.id);
    return GestureDetector(
      onTap: () => _showAchievementDetails(context),
      child: AnimatedContainer(
        height: 210,
        duration: const Duration(milliseconds: 220),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: unlocked
                ? <Color>[
                    const Color(0xFF1C2A42),
                    const Color(0xFF15233A),
                  ]
                : <Color>[
                    const Color(0xFF1A2232),
                    const Color(0xFF141C2A),
                  ],
          ),
          border: Border.all(
            color: unlocked ? accent.withOpacity(0.7) : const Color(0xFF334155),
          ),
          boxShadow: unlocked
              ? <BoxShadow>[
                  BoxShadow(
                    color: accent.withOpacity(0.23),
                    blurRadius: 12,
                    offset: const Offset(0, 6),
                  ),
                ]
              : const <BoxShadow>[],
        ),
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    width: 62,
                    height: 62,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: unlocked
                          ? accent.withOpacity(0.22)
                          : const Color(0xFF1E293B),
                      border: Border.all(
                        color: unlocked ? accent : const Color(0xFF64748B),
                        width: 1.3,
                      ),
                    ),
                    child: Icon(
                      icon,
                      size: 30,
                      color: unlocked ? accent : const Color(0xFF94A3B8),
                    ),
                  ),
                  if (!unlocked)
                    const Positioned(
                      right: 0,
                      bottom: 2,
                      child: Icon(
                        Icons.lock_rounded,
                        color: Color(0xFF9AAAD0),
                        size: 16,
                      ),
                    ),
                  if (unlocked)
                    Positioned(
                      right: 0,
                      bottom: 2,
                      child: Icon(
                        Icons.check_circle_rounded,
                        color: accent,
                        size: 17,
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            Text(
              state.def.title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: Colors.white.withOpacity(unlocked ? 1 : 0.88),
                fontWeight: FontWeight.w800,
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              state.def.description,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Color(0xFF9AAAD0),
                fontSize: 11,
                height: 1.25,
              ),
            ),
            const Spacer(),
            Text(
              unlocked
                  ? 'Completed${state.unlockedAt != null ? ' • ${formatDateTime(state.unlockedAt!)}' : ''}'
                  : 'Locked',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: unlocked ? accent : const Color(0xFF8190AC),
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showAchievementDetails(BuildContext context) {
    final unlocked = state.unlocked;
    final accent = _accentForAchievementId(state.def.id, unlocked);
    final icon = _iconForAchievementId(state.def.id);
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: const Color(0xFF121B2C),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(18, 14, 18, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 34,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFF3A4C6B),
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
              const SizedBox(height: 14),
              CircleAvatar(
                radius: 34,
                backgroundColor: unlocked
                    ? accent.withOpacity(0.2)
                    : const Color(0xFF1E293B),
                child: Icon(
                  icon,
                  color: unlocked ? accent : const Color(0xFF94A3B8),
                  size: 34,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                state.def.title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  fontSize: 18,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                state.def.description,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Color(0xFFA7B6D5),
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                unlocked
                    ? 'Unlocked${state.unlockedAt != null ? ' on ${formatDateTime(state.unlockedAt!)}' : ''}'
                    : 'Locked',
                style: TextStyle(
                  color: unlocked ? accent : const Color(0xFF8CA0C8),
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  static IconData _iconForAchievementId(String id) {
    switch (id) {
      case 'first_steps':
        return Icons.directions_walk_rounded;
      case 'no_help_needed':
        return Icons.psychology_alt_rounded;
      case 'clean_run':
        return Icons.replay_circle_filled_rounded;
      case 'daily_habit':
        return Icons.calendar_month_rounded;
      case 'streak_7':
        return Icons.local_fire_department_rounded;
      case 'hardcore':
        return Icons.whatshot_rounded;
      case 'speedrunner':
        return Icons.bolt_rounded;
      case 'beat_the_ghost':
        return Icons.nightlight_round;
      default:
        return Icons.emoji_events_rounded;
    }
  }

  static Color _accentForAchievementId(String id, bool unlocked) {
    if (!unlocked) return const Color(0xFF94A3B8);
    switch (id) {
      case 'hardcore':
      case 'speedrunner':
        return const Color(0xFFFFD761);
      case 'beat_the_ghost':
        return const Color(0xFF67E8F9);
      case 'streak_7':
      case 'daily_habit':
        return const Color(0xFF60A5FA);
      case 'clean_run':
      case 'no_help_needed':
        return const Color(0xFF22D3EE);
      default:
        return const Color(0xFFA78BFA);
    }
  }
}

class _InboxEmptyCard extends StatelessWidget {
  const _InboxEmptyCard({
    required this.title,
    required this.subtitle,
    required this.icon,
  });

  final String title;
  final String subtitle;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFF1A2538),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF304560)),
      ),
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: const Color(0xFF142238),
              borderRadius: BorderRadius.circular(11),
            ),
            child: Icon(icon, color: const Color(0xFF9DB9FF), size: 18),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: Color(0xFF9AAAD0),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _InboxItemCard extends StatelessWidget {
  const _InboxItemCard({
    required this.item,
    required this.onTap,
    this.onAccept,
    this.onDecline,
    this.onCta,
    this.onDelete,
  });

  final InboxItem item;
  final VoidCallback onTap;
  final VoidCallback? onAccept;
  final VoidCallback? onDecline;
  final VoidCallback? onCta;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    final isUnread = !item.read || item.isPendingFriendRequest;
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        color: const Color(0xFF1A2538),
        border: Border.all(
          color: isUnread ? const Color(0xFF4A6798) : const Color(0xFF334155),
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      color: isUnread
                          ? const Color(0xFF203458)
                          : const Color(0xFF1C283B),
                    ),
                    child: Icon(
                      _iconForType(item.type),
                      color: isUnread
                          ? const Color(0xFF8FB3FF)
                          : const Color(0xFF8CA0C8),
                      size: 16,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      item.title,
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight:
                            isUnread ? FontWeight.w800 : FontWeight.w700,
                      ),
                    ),
                  ),
                  if (item.createdAt != null)
                    Text(
                      _relativeDate(item.createdAt!),
                      style: const TextStyle(
                        color: Color(0xFF8CA0C8),
                        fontSize: 11,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                item.body,
                style: const TextStyle(
                  color: Color(0xFFAFBEDA),
                  height: 1.25,
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  if (onAccept != null)
                    Expanded(
                      child: OutlinedButton(
                        onPressed: onAccept,
                        child: const Text('Accept'),
                      ),
                    ),
                  if (onAccept != null) const SizedBox(width: 8),
                  if (onDecline != null)
                    Expanded(
                      child: OutlinedButton(
                        onPressed: onDecline,
                        child: const Text('Decline'),
                      ),
                    ),
                  if (onDecline != null && onCta != null)
                    const SizedBox(width: 8),
                  if (onCta != null)
                    Expanded(
                      child: ElevatedButton(
                        onPressed: onCta,
                        child: const Text('Open'),
                      ),
                    ),
                  if (onDelete != null)
                    IconButton(
                      onPressed: onDelete,
                      icon: const Icon(
                        Icons.delete_outline_rounded,
                        color: Color(0xFF8CA0C8),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _iconForType(InboxItemType type) {
    switch (type) {
      case InboxItemType.friendRequest:
        return Icons.person_add_alt_1_rounded;
      case InboxItemType.friendAccept:
        return Icons.handshake_rounded;
      case InboxItemType.friendChallenge:
        return Icons.sports_score_rounded;
      case InboxItemType.levelChallenge:
        return Icons.sports_esports_rounded;
      case InboxItemType.liveDuelInvite:
        return Icons.sports_martial_arts_rounded;
      case InboxItemType.systemNews:
        return Icons.campaign_rounded;
      case InboxItemType.unknown:
        return Icons.mail_outline_rounded;
    }
  }

  String _relativeDate(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inMinutes < 1) return 'now';
    if (diff.inHours < 1) return '${diff.inMinutes}m';
    if (diff.inDays < 1) return '${diff.inHours}h';
    if (diff.inDays < 7) return '${diff.inDays}d';
    final y = dt.year.toString().padLeft(4, '0');
    final m = dt.month.toString().padLeft(2, '0');
    final d = dt.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }
}

class _SkinCardViewer extends StatefulWidget {
  const _SkinCardViewer({
    required this.candidates,
    this.backCandidates = const <String>[
      'assets/ui/cards/common_back.png',
    ],
  });

  final List<String> candidates;
  final List<String> backCandidates;

  @override
  State<_SkinCardViewer> createState() => _SkinCardViewerState();
}

class _SkinCardViewerState extends State<_SkinCardViewer> {
  int _candidateIndex = 0;
  bool _showBack = false;

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final cardW = math.min(size.width * 0.76, 360.0);
    final cardH = cardW * 1.38;

    return Dialog(
      insetPadding: const EdgeInsets.all(18),
      backgroundColor: Colors.transparent,
      child: Stack(
        children: [
          SizedBox(
            width: double.infinity,
            child: Align(
              alignment: Alignment.center,
              child: GestureDetector(
                onTap: () {
                  setState(() {
                    _showBack = !_showBack;
                  });
                },
                child: SizedBox(
                  width: cardW,
                  height: cardH,
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 320),
                    switchInCurve: Curves.easeOutCubic,
                    switchOutCurve: Curves.easeInCubic,
                    transitionBuilder: (child, animation) {
                      final rotate = Tween<double>(
                        begin: math.pi / 2,
                        end: 0,
                      ).animate(animation);
                      return AnimatedBuilder(
                        animation: rotate,
                        child: child,
                        builder: (context, child) {
                          return Opacity(
                            opacity: animation.value,
                            child: Transform(
                              alignment: Alignment.center,
                              transform: Matrix4.identity()
                                ..setEntry(3, 2, 0.0013)
                                ..rotateY(rotate.value),
                              child: child,
                            ),
                          );
                        },
                      );
                    },
                    child: _buildCardFace(
                      key: ValueKey<bool>(_showBack),
                      showBack: _showBack,
                    ),
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            right: 2,
            top: 2,
            child: IconButton(
              onPressed: () => Navigator.of(context).pop(),
              style: IconButton.styleFrom(
                backgroundColor: const Color(0xFF1F2937),
                foregroundColor: Colors.white,
              ),
              icon: const Icon(Icons.close_rounded),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCardFace({required Key key, required bool showBack}) {
    return Container(
      key: key,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: const Color(0xFF334155),
          width: 1.2,
        ),
        color: const Color(0xFF111827),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.45),
            blurRadius: 26,
            offset: const Offset(0, 16),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Container(
          color: const Color(0xFF0F172A),
          padding: const EdgeInsets.all(6),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: showBack
                ? _FallbackImage(
                    candidates: widget.backCandidates,
                    fit: BoxFit.cover,
                  )
                : _FallbackImage(
                    candidates: widget.candidates,
                    fit: BoxFit.cover,
                    initialIndex: _candidateIndex,
                    onIndexChanged: (value) {
                      if (value == _candidateIndex) return;
                      setState(() {
                        _candidateIndex = value;
                      });
                    },
                  ),
          ),
        ),
      ),
    );
  }
}

class _FallbackImage extends StatefulWidget {
  const _FallbackImage({
    required this.candidates,
    this.fit = BoxFit.cover,
    this.initialIndex = 0,
    this.onIndexChanged,
  });

  final List<String> candidates;
  final BoxFit fit;
  final int initialIndex;
  final ValueChanged<int>? onIndexChanged;

  @override
  State<_FallbackImage> createState() => _FallbackImageState();
}

class _FallbackImageState extends State<_FallbackImage> {
  late int _index;

  @override
  void initState() {
    super.initState();
    _index = widget.initialIndex.clamp(0, widget.candidates.length - 1);
  }

  @override
  void didUpdateWidget(covariant _FallbackImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialIndex != oldWidget.initialIndex) {
      _index = widget.initialIndex.clamp(0, widget.candidates.length - 1);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.candidates.isEmpty) {
      return const Center(
        child: Icon(
          Icons.image_not_supported_outlined,
          color: Color(0xFF9AAAD0),
          size: 34,
        ),
      );
    }
    final url = widget.candidates[_index];
    return LayoutBuilder(
      builder: (context, constraints) {
        if (url.startsWith('assets/')) {
          return Image.asset(
            url,
            fit: widget.fit,
            filterQuality: FilterQuality.high,
            errorBuilder: (_, __, ___) => _onCandidateError(),
          );
        }
        if (kIsWeb &&
            (url.startsWith('http://') || url.startsWith('https://'))) {
          return buildNetworkImageCompat(
            url: url,
            fit: widget.fit,
            filterQuality: FilterQuality.high,
            fallback:
                _CandidateAdvanceSignal(onAdvance: _advanceToNextCandidate),
          );
        }
        if (!(url.startsWith('http://') || url.startsWith('https://'))) {
          return _onCandidateError();
        }
        final dpr = MediaQuery.of(context).devicePixelRatio;
        final targetW = (constraints.maxWidth * dpr).round();
        final targetH = (constraints.maxHeight * dpr).round();
        return Image.network(
          url,
          fit: widget.fit,
          alignment: Alignment.center,
          filterQuality: FilterQuality.high,
          cacheWidth: targetW > 0 ? targetW : null,
          cacheHeight: targetH > 0 ? targetH : null,
          gaplessPlayback: true,
          errorBuilder: (_, __, ___) => _onCandidateError(),
        );
      },
    );
  }

  Widget _onCandidateError() {
    final advanced = _advanceToNextCandidate();
    if (advanced) {
      return const Center(
        child: CircularProgressIndicator(strokeWidth: 2),
      );
    }
    return const Center(
      child: Icon(
        Icons.image_not_supported_outlined,
        color: Color(0xFF9AAAD0),
        size: 34,
      ),
    );
  }

  bool _advanceToNextCandidate() {
    if (_index >= widget.candidates.length - 1) return false;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      setState(() {
        _index++;
        widget.onIndexChanged?.call(_index);
      });
    });
    return true;
  }
}

class _CandidateAdvanceSignal extends StatefulWidget {
  const _CandidateAdvanceSignal({required this.onAdvance});

  final bool Function() onAdvance;

  @override
  State<_CandidateAdvanceSignal> createState() =>
      _CandidateAdvanceSignalState();
}

class _CandidateAdvanceSignalState extends State<_CandidateAdvanceSignal> {
  bool _fired = false;

  @override
  Widget build(BuildContext context) {
    if (!_fired) {
      _fired = true;
      widget.onAdvance();
    }
    return const Center(
      child: CircularProgressIndicator(strokeWidth: 2),
    );
  }
}

class _ProfileHeaderAvatar extends StatefulWidget {
  const _ProfileHeaderAvatar({
    this.skinCandidates = const <String>[],
    required this.googleAvatarUrl,
    this.preferSkin = false,
  });

  final List<String> skinCandidates;
  final String googleAvatarUrl;
  final bool preferSkin;

  @override
  State<_ProfileHeaderAvatar> createState() => _ProfileHeaderAvatarState();
}

class _ProfileHeaderAvatarState extends State<_ProfileHeaderAvatar> {
  int _index = 0;
  bool _notifiedExhausted = false;

  List<_AvatarCandidate> get _candidates {
    final list = <_AvatarCandidate>[];
    final google = widget.googleAvatarUrl.trim();
    final skins = <String>[
      ...widget.skinCandidates.map((e) => e.trim()).where((e) => e.isNotEmpty),
    ];
    final dedupSkins = <String>[];
    for (final s in skins) {
      if (s.isEmpty) continue;
      if (!dedupSkins.contains(s)) {
        dedupSkins.add(s);
      }
    }
    if (widget.preferSkin) {
      for (final skin in dedupSkins) {
        list.add(_AvatarCandidate(type: 'skin', path: skin));
      }
      if (google.isNotEmpty) {
        list.add(_AvatarCandidate(type: 'google', path: google));
      }
      return list;
    }
    if (google.isNotEmpty) {
      list.add(_AvatarCandidate(type: 'google', path: google));
    }
    for (final skin in dedupSkins) {
      list.add(_AvatarCandidate(type: 'skin', path: skin));
    }
    return list;
  }

  @override
  void didUpdateWidget(covariant _ProfileHeaderAvatar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.skinCandidates != widget.skinCandidates ||
        oldWidget.googleAvatarUrl != widget.googleAvatarUrl ||
        oldWidget.preferSkin != widget.preferSkin) {
      _index = 0;
      _notifiedExhausted = false;
    }
  }

  void _advanceFallback(String fromType, String fromPath) {
    final list = _candidates;
    if (_index < list.length - 1) {
      if (kDebugMode) {
        debugPrint('[profile] avatar fallback $fromType failed -> next');
      }
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        setState(() {
          _index += 1;
        });
      });
      return;
    }
    if (!_notifiedExhausted && kDebugMode) {
      _notifiedExhausted = true;
      debugPrint(
          '[profile] avatar exhausted, using placeholder. source=$fromType path=$fromPath');
    }
  }

  @override
  Widget build(BuildContext context) {
    final list = _candidates;
    if (list.isEmpty || _index >= list.length) {
      return const _ProfileAvatarPlaceholder();
    }
    final candidate = list[_index];
    return _ProfileAvatarImageCandidate(
      path: candidate.path,
      onFailed: () => _advanceFallback(candidate.type, candidate.path),
    );
  }
}

class _ProfileAvatarImageCandidate extends StatelessWidget {
  const _ProfileAvatarImageCandidate({
    required this.path,
    required this.onFailed,
  });

  final String path;
  final VoidCallback onFailed;

  @override
  Widget build(BuildContext context) {
    if (path.startsWith('assets/')) {
      return Image.asset(
        path,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _AvatarFailureSignal(onFailed: onFailed),
      );
    }
    if (path.startsWith('http://') || path.startsWith('https://')) {
      if (_isGoogleAvatarUrl(path)) {
        return Image.network(
          path,
          fit: BoxFit.cover,
          filterQuality: FilterQuality.high,
          errorBuilder: (_, __, ___) =>
              _AvatarFailureSignal(onFailed: onFailed),
        );
      }
      if (kIsWeb) {
        return buildNetworkImageCompat(
          url: path,
          fit: BoxFit.cover,
          filterQuality: FilterQuality.high,
          fallback: _AvatarFailureSignal(onFailed: onFailed),
        );
      }
      return Image.network(
        path,
        fit: BoxFit.cover,
        filterQuality: FilterQuality.high,
        errorBuilder: (_, __, ___) => _AvatarFailureSignal(onFailed: onFailed),
      );
    }
    if (path.startsWith('data:image')) {
      final comma = path.indexOf(',');
      if (comma > 0 && comma < path.length - 1) {
        final bytes = base64Decode(path.substring(comma + 1));
        return Image.memory(
          bytes,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) =>
              _AvatarFailureSignal(onFailed: onFailed),
        );
      }
      return _AvatarFailureSignal(onFailed: onFailed);
    }
    if (kIsWeb) {
      return _AvatarFailureSignal(onFailed: onFailed);
    }
    return Image.file(
      File(path),
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => _AvatarFailureSignal(onFailed: onFailed),
    );
  }

  bool _isGoogleAvatarUrl(String url) {
    final host = Uri.tryParse(url)?.host.toLowerCase() ?? '';
    return host.contains('googleusercontent.com') ||
        host.contains('gstatic.com') ||
        host.contains('googleapis.com');
  }
}

class _AvatarFailureSignal extends StatefulWidget {
  const _AvatarFailureSignal({required this.onFailed});

  final VoidCallback onFailed;

  @override
  State<_AvatarFailureSignal> createState() => _AvatarFailureSignalState();
}

class _AvatarFailureSignalState extends State<_AvatarFailureSignal> {
  bool _fired = false;

  @override
  Widget build(BuildContext context) {
    if (!_fired) {
      _fired = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        widget.onFailed();
      });
    }
    return const _ProfileAvatarPlaceholder();
  }
}

class _ProfileAvatarPlaceholder extends StatelessWidget {
  const _ProfileAvatarPlaceholder();

  @override
  Widget build(BuildContext context) {
    return const ColoredBox(
      color: Color(0xFF111826),
      child: Icon(
        Icons.person_rounded,
        color: Color(0xFFBDD0FF),
        size: 30,
      ),
    );
  }
}

class _AvatarCandidate {
  const _AvatarCandidate({required this.type, required this.path});

  final String type;
  final String path;
}
