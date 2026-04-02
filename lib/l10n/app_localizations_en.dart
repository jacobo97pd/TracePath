// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'TracePath';

  @override
  String get victoryDataMissing => 'Victory data missing';

  @override
  String get liveDuelInviteTitle => 'Live Duel Invite';

  @override
  String liveDuelInviteBody(Object from) {
    return '$from challenged you to a live duel.\nDo you want to accept?';
  }

  @override
  String get decline => 'Decline';

  @override
  String get accept => 'Accept';

  @override
  String get liveInviteCouldNotProcess => 'Could not process live invite';

  @override
  String get liveInviteNoLongerAvailable => 'Invite is no longer available';

  @override
  String get liveInviteAlreadyClosed => 'This duel is already closed';

  @override
  String get liveInviteInvalidAccount => 'Invite is not valid for this account';

  @override
  String get liveInviteInvalidPayload => 'Invite payload is invalid';

  @override
  String get liveInvitePermissionsBlocked =>
      'Permissions blocked this invite action';

  @override
  String get liveInviteNetworkIssue => 'Network issue while processing invite';

  @override
  String get tabHome => 'Home';

  @override
  String get tabShop => 'Shop';

  @override
  String get tabDuel => 'Duel';

  @override
  String get tabCards => 'Cards';

  @override
  String get tabProfile => 'Profile';

  @override
  String get playModeWorlds => 'Worlds';

  @override
  String get playModeDaily => 'Daily';

  @override
  String get playModeRanked => 'Ranked';

  @override
  String get playModeEvents => 'Events';

  @override
  String get playModeDuels => 'Duels';

  @override
  String get playButton => 'Play';

  @override
  String get homePlayerName => 'Player';

  @override
  String get homeTitle => 'TracePath';

  @override
  String homeStreakPill(int count) {
    return 'Streak $count';
  }

  @override
  String homeLevelPill(int count) {
    return 'Lv $count';
  }

  @override
  String get homeTrainTitle => 'Train your brain';

  @override
  String get homeTrainSubtitle =>
      'Trace paths faster, improve precision, and climb every challenge.';

  @override
  String get homeStartSolving => 'START SOLVING!';

  @override
  String get homeJumpToNextPuzzle => 'Jump into your next puzzle';

  @override
  String get homeContinue => 'Continue';

  @override
  String get homeContinueFirstRun => 'Start your first run';

  @override
  String homeContinueResumeLevel(int level) {
    return 'Level $level · Pick up where you left off';
  }

  @override
  String get homeQuickAccessTitle => 'Quick Access';

  @override
  String get homeQuickAccessSubtitle =>
      'Jump directly into your favorite modes';

  @override
  String get homeQuickDailyTitle => 'Daily Puzzle';

  @override
  String get homeQuickDailySubtitle => 'One challenge each day';

  @override
  String get homeQuickLevelsTitle => 'Levels';

  @override
  String get homeQuickLevelsSubtitle => 'Choose any available level';

  @override
  String get homeQuickSocialTitle => 'Social';

  @override
  String get homeQuickSocialSubtitle => 'Friends, inbox and multiplayer';

  @override
  String get homeProgressTitle => 'Progress';

  @override
  String get homeProgressSubtitle => 'Your latest performance and momentum';

  @override
  String get homeMetricLevelsSolved => 'Levels solved';

  @override
  String get homeMetricCurrentStreak => 'Current streak';

  @override
  String get homeMetricBestStreak => 'Best streak';

  @override
  String get homeMetricHighestLevel => 'Highest level';

  @override
  String homeDailySolved(int count) {
    return 'Daily puzzles solved: $count';
  }

  @override
  String get homeViewProfile => 'View profile';

  @override
  String get duelHubTitle => 'Duel Hub';

  @override
  String get duelHubSubtitle => 'Challenge friends and play live matches.';

  @override
  String get duelCreating => 'Creating duel...';

  @override
  String get duelChallengeFriend => 'Challenge a Friend';

  @override
  String get duelIncomingInvitesTitle => 'Incoming Invites';

  @override
  String get duelIncomingInvitesSubtitle =>
      'Accept or decline live duel requests';

  @override
  String get duelNoPendingInvitesTitle => 'No pending invites';

  @override
  String get duelNoPendingInvitesSubtitle => 'New challenges will appear here.';

  @override
  String get duelInviteLoadErrorTitle => 'Could not load invites';

  @override
  String get duelTryAgainLater => 'Try again in a moment.';

  @override
  String get duelActiveMatchesTitle => 'Active Matches';

  @override
  String get duelActiveMatchesSubtitle => 'Resume your current live duels';

  @override
  String get duelNoActiveTitle => 'No active duels';

  @override
  String get duelNoActiveSubtitle => 'Start a challenge to play live.';

  @override
  String get duelActiveLoadErrorTitle => 'Could not load active matches';

  @override
  String get duelHistoryTitle => 'History';

  @override
  String get duelHistorySubtitle => 'Recent duel results';

  @override
  String get duelHistoryComingSoonTitle => 'History coming soon';

  @override
  String get duelHistoryComingSoonSubtitle =>
      'Your last duels will be shown here.';

  @override
  String get duelChooseFriend => 'Choose a friend';

  @override
  String get duelCouldNotLoadFriends => 'Could not load friends';

  @override
  String get duelNoFriendsYet => 'No friends yet';

  @override
  String get duelInviteSentText => 'sent you a live duel invite.';

  @override
  String duelAcceptError(Object error) {
    return 'Could not accept duel invite: $error';
  }

  @override
  String duelDeclineError(Object error) {
    return 'Could not decline duel invite: $error';
  }

  @override
  String get duelAccept => 'Accept';

  @override
  String get duelResume => 'Resume';

  @override
  String get duelStatusPending => 'Pending';

  @override
  String get duelStatusCountdown => 'Countdown';

  @override
  String get duelStatusPlaying => 'Playing';

  @override
  String get duelStatusFinished => 'Finished';

  @override
  String get duelStatusCancelled => 'Cancelled';

  @override
  String get duelUnknownOpponent => 'Unknown';

  @override
  String duelVersusOpponent(Object name) {
    return 'VS $name';
  }

  @override
  String duelLevelAndStatus(Object level, Object status) {
    return 'Level: $level · $status';
  }

  @override
  String get duelErrorFinishCurrentFirst =>
      'Finish your current live duel first.';

  @override
  String get duelErrorFriendBusy => 'This friend is already in another duel.';

  @override
  String get duelErrorNoPuzzles => 'No puzzles available right now.';

  @override
  String get duelErrorInvalidTarget => 'Could not start duel with this friend.';

  @override
  String get duelErrorCreateInvite => 'Could not create duel invite right now.';

  @override
  String get duelRemoveActiveTitle => 'Remove active match';

  @override
  String get duelRemoveActiveBody =>
      'This active match will be closed and removed from this list.';

  @override
  String get duelKeep => 'Keep';

  @override
  String get duelRemove => 'Remove';

  @override
  String get duelRemoving => 'Removing...';

  @override
  String get duelRemovedActive => 'Active match removed';

  @override
  String duelRemoveError(Object error) {
    return 'Could not remove match: $error';
  }

  @override
  String get friendChallengeTitle => 'Friendly Challenge';

  @override
  String get friendChallengeUnavailable => 'Challenge unavailable.';

  @override
  String friendChallengePuzzle(Object puzzleId) {
    return 'Puzzle: $puzzleId';
  }

  @override
  String friendChallengeMode(Object mode) {
    return 'Mode: $mode';
  }

  @override
  String get friendChallengePlayButton => 'Play Friendly Challenge';

  @override
  String get shopTitle => 'Shop';

  @override
  String get shopSkinEditorTooltip => 'Skin editor';

  @override
  String get shopTabSkins => 'Skins';

  @override
  String get shopTabTrails => 'Trails';

  @override
  String get shopTabCoinPacks => 'Coin Packs';

  @override
  String shopSkinsLoaded(int visible, int total) {
    return 'Skins loaded: $visible/$total';
  }

  @override
  String get shopFeaturedSkin => 'Featured Skin';

  @override
  String get shopPointerSkins => 'Pointer Skins';

  @override
  String get shopLoadMore => 'Load more';

  @override
  String get shopOwned => 'Owned';

  @override
  String shopCoinsAmount(int coins) {
    return '$coins coins';
  }

  @override
  String get shopEquipped => 'Equipped';

  @override
  String get shopEquip => 'Equip';

  @override
  String shopBuyCoins(int coins) {
    return 'Buy $coins';
  }

  @override
  String get shopNewTrail => 'NEW TRAIL';

  @override
  String get shopUnlockedAndEquipped => 'Unlocked and equipped';

  @override
  String get shopDefaultTrailDescription =>
      'Unique visual style for your path trace.';

  @override
  String get profileGuestMode => 'Guest mode';

  @override
  String get profileGoogleAccount => 'Google account';

  @override
  String get profileLogout => 'Logout';

  @override
  String get profileLogoutConfirm => 'Do you want to sign out?';

  @override
  String get profileCancel => 'Cancel';

  @override
  String get profileSignedOut => 'Signed out';

  @override
  String get profileDefaultName => 'Default';

  @override
  String get profileLevelLabel => 'Level';

  @override
  String get profileStreakLabel => 'Streak';

  @override
  String get profileBestLabel => 'Best';

  @override
  String profileBestStreak(int count) {
    return 'Best streak: $count';
  }

  @override
  String profileEquippedSkin(Object name) {
    return 'Equipped Skin: $name';
  }

  @override
  String get profileStatsTitle => 'Stats';

  @override
  String get profileGamesPlayed => 'Games Played';

  @override
  String get profileBestTime => 'Best Time';

  @override
  String get profileVaultTitle => 'Vault';

  @override
  String get profileLockerTitle => 'Locker';

  @override
  String get profileLockerHint => 'Tap an equipped item to open inventory.';

  @override
  String get profileOpenVault => 'Open Vault';

  @override
  String get profileInboxTitle => 'Inbox';

  @override
  String profileInboxWithCount(int count) {
    return 'Inbox ($count)';
  }

  @override
  String get profileInboxUnavailableTitle => 'Inbox unavailable right now';

  @override
  String get profileInboxEmptyTitle => 'No messages yet';

  @override
  String get profileInboxEmptySubtitle =>
      'Friend requests, rewards and news will appear here.';

  @override
  String get profileVaultLockerTitle => 'Vault / Locker';

  @override
  String get profileReadyToEquip => 'Ready to equip';
}
