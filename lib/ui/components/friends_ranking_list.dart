import 'package:flutter/material.dart';

import '../avatar_utils.dart';
import 'network_image_compat.dart';

class FriendsRankingRow {
  const FriendsRankingRow({
    required this.uid,
    required this.displayName,
    required this.bestTimeMs,
    required this.photoUrl,
    required this.skinPreviewUrl,
    required this.preferSkin,
  });

  final String uid;
  final String displayName;
  final int bestTimeMs;
  final String photoUrl;
  final String skinPreviewUrl;
  final bool preferSkin;
}

class FriendsRankingList extends StatelessWidget {
  const FriendsRankingList({
    super.key,
    required this.future,
    required this.currentUid,
    this.emptyText = 'No friends scores yet for this level.',
    this.errorText = 'Friends ranking unavailable right now.',
    this.scrollable = false,
  });

  final Future<List<FriendsRankingRow>> future;
  final String currentUid;
  final String emptyText;
  final String errorText;
  final bool scrollable;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<FriendsRankingRow>>(
      future: future,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Text(
              errorText,
              style: const TextStyle(color: Color(0xFF9EB0D2)),
            ),
          );
        }
        final rows = snapshot.data;
        if (rows == null) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 10),
            child: Center(
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          );
        }
        if (rows.isEmpty) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Text(
              emptyText,
              style: const TextStyle(color: Color(0xFF9EB0D2)),
            ),
          );
        }
        if (!scrollable) {
          return Column(
            children: [
              for (var i = 0; i < rows.length; i++) ...[
                _FriendsRankingRowTile(
                  row: rows[i],
                  rank: _rankAtIndexByTime(
                    rows.map((r) => r.bestTimeMs).toList(growable: false),
                    i,
                  ),
                  isCurrentUser: rows[i].uid == currentUid,
                ),
                if (i < rows.length - 1) const SizedBox(height: 2),
              ],
            ],
          );
        }

        final times = rows.map((r) => r.bestTimeMs).toList(growable: false);
        return ListView.separated(
          padding: EdgeInsets.zero,
          itemCount: rows.length,
          itemBuilder: (context, i) => _FriendsRankingRowTile(
            row: rows[i],
            rank: _rankAtIndexByTime(times, i),
            isCurrentUser: rows[i].uid == currentUid,
          ),
          separatorBuilder: (_, __) => const SizedBox(height: 2),
        );
      },
    );
  }

  int _rankAtIndexByTime(List<int> timesMs, int index) {
    if (index <= 0) return 1;
    var rank = index + 1;
    for (var j = index - 1; j >= 0; j--) {
      if (timesMs[j] == timesMs[index]) {
        rank = j + 1;
      } else {
        break;
      }
    }
    return rank;
  }
}

class _FriendsRankingRowTile extends StatelessWidget {
  const _FriendsRankingRowTile({
    required this.row,
    required this.rank,
    required this.isCurrentUser,
  });

  final FriendsRankingRow row;
  final int rank;
  final bool isCurrentUser;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: isCurrentUser ? const Color(0x1A4A7CFF) : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 28,
            child: Text(
              '#$rank',
              style: TextStyle(
                color: rank == 1
                    ? const Color(0xFFFFD166)
                    : rank == 2
                        ? const Color(0xFFD7E3F4)
                        : rank == 3
                            ? const Color(0xFFC7935F)
                            : const Color(0xFF8FA6CF),
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(width: 8),
          _FriendsRankingAvatar(
            photoUrl: row.photoUrl,
            skinUrl: row.skinPreviewUrl,
            preferSkin: row.preferSkin,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              row.displayName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            _formatMs(row.bestTimeMs),
            style: const TextStyle(
              color: Color(0xFF9BB4FF),
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }

  String _formatMs(int ms) {
    if (ms <= 0) return '--:--';
    final seconds = (ms / 1000).round();
    final mm = (seconds ~/ 60).toString().padLeft(2, '0');
    final ss = (seconds % 60).toString().padLeft(2, '0');
    return '$mm:$ss';
  }
}

class _FriendsRankingAvatar extends StatefulWidget {
  const _FriendsRankingAvatar({
    required this.photoUrl,
    required this.skinUrl,
    required this.preferSkin,
  });

  final String photoUrl;
  final String skinUrl;
  final bool preferSkin;

  @override
  State<_FriendsRankingAvatar> createState() => _FriendsRankingAvatarState();
}

class _FriendsRankingAvatarState extends State<_FriendsRankingAvatar> {
  int _index = 0;

  List<String> get _candidates {
    return orderedAvatarCandidates(
      photoUrl: widget.photoUrl,
      skinUrl: widget.skinUrl,
      preferSkin: widget.preferSkin,
    );
  }

  @override
  void didUpdateWidget(covariant _FriendsRankingAvatar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.photoUrl != widget.photoUrl ||
        oldWidget.skinUrl != widget.skinUrl ||
        oldWidget.preferSkin != widget.preferSkin) {
      _index = 0;
    }
  }

  void _next() {
    final candidates = _candidates;
    if (_index < candidates.length - 1) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        setState(() {
          _index += 1;
        });
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final candidates = _candidates;
    Widget child = const _FriendsRankingAvatarPlaceholder();
    if (_index < candidates.length) {
      final path = candidates[_index];
      if (path.startsWith('assets/')) {
        child = Image.asset(
          path,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) =>
              _FriendsRankingAvatarFallback(onFailed: _next),
        );
      } else if (path.startsWith('http://') || path.startsWith('https://')) {
        child = buildNetworkImageCompat(
          url: path,
          fit: BoxFit.cover,
          filterQuality: FilterQuality.medium,
          fallback: _FriendsRankingAvatarFallback(onFailed: _next),
        );
      } else {
        child = _FriendsRankingAvatarFallback(onFailed: _next);
      }
    }

    return Container(
      width: 34,
      height: 34,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: const Color(0xFF182234),
        border: Border.all(color: const Color(0xFF334155)),
      ),
      clipBehavior: Clip.antiAlias,
      child: child,
    );
  }
}

class _FriendsRankingAvatarFallback extends StatefulWidget {
  const _FriendsRankingAvatarFallback({required this.onFailed});

  final VoidCallback onFailed;

  @override
  State<_FriendsRankingAvatarFallback> createState() =>
      _FriendsRankingAvatarFallbackState();
}

class _FriendsRankingAvatarFallbackState
    extends State<_FriendsRankingAvatarFallback> {
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
    return const _FriendsRankingAvatarPlaceholder();
  }
}

class _FriendsRankingAvatarPlaceholder extends StatelessWidget {
  const _FriendsRankingAvatarPlaceholder();

  @override
  Widget build(BuildContext context) {
    return const ColoredBox(
      color: Color(0xFF182234),
      child: Center(
        child: Icon(
          Icons.person_rounded,
          color: Color(0xFF9EB0D2),
          size: 18,
        ),
      ),
    );
  }
}
