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
    return '$from challenged you to a live duel.\nDo you want to accept';
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
    return 'Level $level Pick up where you left off';
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
    return 'Level: $level $status';
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
  String get profileLogoutConfirm => 'Do you want to sign out\'';

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

  @override
  String profileRewardClaimed(int coins) {
    return 'Reward claimed: +$coins coins';
  }

  @override
  String get profileRewardAlreadyClaimed => 'Reward already claimed';

  @override
  String get profileRewardClaimFailed => 'Could not claim reward';

  @override
  String get profileFriendRequestAccepted => 'Friend request accepted';

  @override
  String get profileFriendRequestDeclined => 'Friend request declined';

  @override
  String get profileFriendRequestDeclineFailed =>
      'Could not decline friend request';

  @override
  String get profileChallengeDeclined => 'Challenge declined';

  @override
  String get profileChallengeDeclineFailed => 'Could not decline challenge';

  @override
  String get profileChallengeDeclinedTitle => 'Challenge declined';

  @override
  String get profileChallengeDeclinedBodySuffix => 'declined your challenge.';

  @override
  String get profileChallengeAcceptedTitle => 'Challenge accepted';

  @override
  String get profileChallengeAcceptedBodySuffix => 'accepted your challenge.';

  @override
  String get profileFunctionUnavailableTitle => 'Feature unavailable';

  @override
  String get profileFunctionUnavailableBody =>
      'This feature is only available after buying and equipping a skin.';

  @override
  String get profileUnderstand => 'Understood';

  @override
  String get profileCardUnavailableTitle => 'Card unavailable';

  @override
  String get profileCardUnavailableBody =>
      'There is no card for this skin yet.';

  @override
  String get profileWorldProgressTitle => 'World progress';

  @override
  String profileLevelsCompleted(int solved, int total) {
    return '$solved / $total levels completed';
  }

  @override
  String profileHighestLevelValue(int level) {
    return 'Highest $level';
  }

  @override
  String get profileAchievementsTitle => 'Achievements';

  @override
  String profileAchievementsProgress(int unlocked, int total) {
    return '$unlocked / $total unlocked';
  }

  @override
  String profileAchievementCompleted(Object datePart) {
    return 'Completed$datePart';
  }

  @override
  String get profileAchievementLocked => 'Locked';

  @override
  String profileAchievementUnlocked(Object datePart) {
    return 'Unlocked$datePart';
  }

  @override
  String profileAchievementOnDate(Object date) {
    return 'on $date';
  }

  @override
  String get profileInboxOpen => 'Open';

  @override
  String profileInboxClaim(int coins) {
    return 'Claim $coins';
  }

  @override
  String get profileInboxNow => 'now';

  @override
  String get loginTagline =>
      'Train your brain. Trace the path faster than anyone.';

  @override
  String get loginBenefitSaveProgress => 'Save progress';

  @override
  String get loginBenefitChallengeFriends => 'Challenge friends';

  @override
  String get loginBenefitKeepStreak => 'Keep your streak';

  @override
  String get loginContinueGuest => 'Continue as Guest';

  @override
  String get loginGuestModeHint => 'Guest mode: no friends, no challenges.';

  @override
  String get loginConnecting => 'Connecting...';

  @override
  String get loginContinueGoogle => 'Continue with Google';

  @override
  String get cardsCollectionTitle => 'Card Collection';

  @override
  String get cardsCollectionEmpty =>
      'No cards unlocked yet.\nBuy or unlock skins to collect cards.';

  @override
  String get cardsRarityLegendary => 'Legendary';

  @override
  String get cardsRarityEpic => 'Epic';

  @override
  String get cardsRarityRare => 'Rare';

  @override
  String get cardsRarityCommon => 'Common';

  @override
  String get campaignTitle => 'Campaign';

  @override
  String get campaignLoading => 'Loading...';

  @override
  String get campaignPreparingStatus => 'Preparing pack status';

  @override
  String get campaignLoadError => 'Could not load campaign packs.';

  @override
  String get campaignPackClassic => 'Balanced introduction';

  @override
  String get campaignPackArchitect => 'More walls and tighter planning';

  @override
  String get campaignPackExpert => 'Larger boards and harder routes';

  @override
  String leaderboardFriendsTitleWithLevel(int level) {
    return 'Friends ranking - L$level';
  }

  @override
  String get leaderboardFriendsTitle => 'Friends ranking';

  @override
  String leaderboardLevelPack(int level, Object packId) {
    return 'Level $level - $packId';
  }

  @override
  String get leaderboardNoFriendsScores =>
      'No friends scores yet for this level.';

  @override
  String get leaderboardUnavailable => 'Friends ranking unavailable right now.';

  @override
  String get dailyTitle => 'Daily';

  @override
  String get dailyUnknownLoadError => 'Unknown daily load error';

  @override
  String get dailyLoadError => 'Could not load daily puzzle.';

  @override
  String get dailyRetry => 'Retry';

  @override
  String get dailyChallengeTitle => 'Daily Challenge';

  @override
  String dailyNextPuzzleIn(Object countdown) {
    return 'Next puzzle in $countdown';
  }

  @override
  String get dailyRewardLabel => 'Reward';

  @override
  String dailyCoinsReward(int coins) {
    return '$coins coins';
  }

  @override
  String get dailyStreakLabel => 'Streak';

  @override
  String get dailyBestTimeLabel => 'Best Time';

  @override
  String get dailyPlayAgain => 'Play Again';

  @override
  String get dailyPlayDaily => 'Play Daily';

  @override
  String dailyAttemptsSummary(int attempts, Object bestScore) {
    return 'Attempts today: $attempts - Best score: $bestScore';
  }

  @override
  String get dailyNewPersonalBestToday => 'New personal best today';

  @override
  String get dailyCompletedTitle => 'Daily completed';

  @override
  String get dailySavedWithPartialSync =>
      'Saved with partial sync issue. Try again later.';

  @override
  String get dailyRewardSyncFailed => 'Reward sync failed. Please try again.';

  @override
  String get dailyAchievementUnlocked => 'Achievement Unlocked';

  @override
  String get dailyRewardToastTitle => 'Daily reward';

  @override
  String dailyRewardToastMessage(int coins) {
    return '+$coins coins';
  }

  @override
  String dailyShareText(Object time) {
    return 'Daily complete in $time.';
  }

  @override
  String dailyCopyText(int day, Object time, int streak) {
    return 'Zip #$day - $time - Streak $streak ';
  }

  @override
  String get liveDuelTitle => 'Live Duel';

  @override
  String get liveDuelCouldNotUpdateReady => 'Could not update ready state';

  @override
  String get liveDuelAcceptInviteFirst => 'Accept the duel invite first';

  @override
  String get liveDuelAlreadyClosed => 'This duel is already closed';

  @override
  String get liveDuelOpponent => 'Opponent';

  @override
  String liveDuelReacted(Object sender) {
    return '$sender reacted';
  }

  @override
  String get liveDuelUnavailableNow => 'Live duel unavailable right now.';

  @override
  String get liveDuelMatchNotFound => 'Match not found';

  @override
  String get liveDuelYou => 'You';

  @override
  String get liveDuelWaitingPlayer => 'Waiting player...';

  @override
  String get liveDuelLeave => 'Leave duel';

  @override
  String get liveDuelHeroYouAbandoned => 'YOU ABANDONED';

  @override
  String get liveDuelHeroYouWin => 'YOU WIN!';

  @override
  String get liveDuelHeroDraw => 'DRAW';

  @override
  String get liveDuelHeroYouLost => 'YOU LOST';

  @override
  String get liveDuelInvitationReceived => 'Invitation received';

  @override
  String get liveDuelWaitingFriendJoin => 'Waiting for your friend to join...';

  @override
  String get liveDuelOpponentReady => 'Opponent is ready';

  @override
  String get liveDuelOpponentJoinedWaitingReady =>
      'Opponent joined, waiting ready';

  @override
  String get liveDuelOpponentNotJoined => 'Opponent has not joined yet';

  @override
  String get liveDuelAccepting => 'Accepting...';

  @override
  String get liveDuelAcceptDuel => 'Accept duel';

  @override
  String get liveDuelSaving => 'Saving...';

  @override
  String get liveDuelUnready => 'Unready';

  @override
  String get liveDuelReady => 'Ready';

  @override
  String get liveDuelAcceptFirstThenReady => 'Accept first, then mark Ready.';

  @override
  String get liveDuelGo => 'GO!';

  @override
  String liveDuelStartingIn(Object value) {
    return 'Starting in $value...';
  }

  @override
  String get liveDuelStartingMatch => 'Starting match...';

  @override
  String get liveDuelWaitingRoom => 'Waiting Room';

  @override
  String get liveDuelGetReady => 'Get Ready';

  @override
  String get liveDuelMatchStarted => 'Match Started';

  @override
  String get liveDuelMatchResult => 'Match Result';

  @override
  String get liveDuelMatchCancelled => 'Match Cancelled';

  @override
  String get liveDuelYouAbandoned => 'You abandoned';

  @override
  String get liveDuelYouWonSmiley => 'You won ';

  @override
  String get liveDuelDraw => 'Draw';

  @override
  String get liveDuelDefeat => 'Defeat';

  @override
  String get liveDuelDefeatByAbandon => 'Defeat by abandon';

  @override
  String get liveDuelWinByAbandon => 'Win by abandon';

  @override
  String get liveDuelYouWonDuel => 'You won the duel';

  @override
  String get liveDuelNoWinner => 'No winner';

  @override
  String get liveDuelYouLost => 'You lost';

  @override
  String get liveDuelYourTime => 'Your time';

  @override
  String get liveDuelOpponentTime => 'Opponent time';

  @override
  String get liveDuelCouldNotCreateRematch => 'Could not create rematch';

  @override
  String get liveDuelOpponentBusyAnother => 'Opponent is busy in another duel';

  @override
  String get liveDuelFinishActiveFirst => 'Finish your active duel first';

  @override
  String get liveDuelCreatingRematch => 'Creating rematch...';

  @override
  String get liveDuelRematch => 'Rematch';

  @override
  String get liveDuelBack => 'Back';

  @override
  String get liveDuelEmoteCooldown => 'Emote cooldown';

  @override
  String get liveDuelCouldNotSendEmote => 'Could not send emote';

  @override
  String get liveDuelInviteExpired => 'Invitation expired';

  @override
  String get liveDuelCountdownExpired => 'Countdown expired';

  @override
  String get liveDuelMatchTimedOut => 'Match timed out';

  @override
  String get liveDuelCancelled => 'Duel cancelled';

  @override
  String get liveDuelStateInvited => 'Invited';

  @override
  String get liveDuelStateJoined => 'Joined';

  @override
  String get liveDuelStateReady => 'Ready';

  @override
  String get liveDuelStatePlaying => 'Playing';

  @override
  String get liveDuelStateFinished => 'Finished';

  @override
  String get liveDuelStateAbandoned => 'Abandoned';

  @override
  String get victoryChallengeOnlyLevelRuns =>
      'This challenge is only available for level runs.';

  @override
  String get victoryAddFriendsFirst =>
      'Add friends first to send in-game challenges.';

  @override
  String get victoryChallengeFriendTitle => 'Challenge a friend';

  @override
  String get victoryChallengeFriendSubtitle =>
      'Send a live duel invite with a random puzzle';

  @override
  String get victoryInviteOnline => 'Invite to a live 1v1 duel - Online';

  @override
  String get victoryInviteOffline => 'Invite to a live 1v1 duel - Offline';

  @override
  String get victoryLiveInviteSent => 'Live duel invite sent';

  @override
  String get victoryChallengeSendError => 'Could not send challenge right now';

  @override
  String get victoryChallengeBlockedByRules =>
      'Challenge blocked by Firestore rules';

  @override
  String get victoryChallengeSetupNotReady =>
      'Challenge setup is not ready yet. Try again in a moment.';

  @override
  String get victoryFinishActiveDuelFirst => 'Finish your active duel first';

  @override
  String victoryFriendAlreadyInDuel(Object name) {
    return '$name is already in another duel';
  }

  @override
  String get victoryNoPuzzlesForDuel => 'No puzzles available for duel';

  @override
  String get victoryStatTime => 'Time';

  @override
  String get victoryStatBestTime => 'Best time';

  @override
  String victoryCoinsWithAd(int coins) {
    return 'Coins (+$coins ad)';
  }

  @override
  String get victoryCoinsReward => 'Coins reward';

  @override
  String get victoryLevelComplete => 'LEVEL COMPLETE';

  @override
  String victoryCurrentStreak(int streak) {
    return 'Current streak: $streak';
  }

  @override
  String get victoryFriendsRanking => 'Friends ranking';

  @override
  String get victoryReplay => 'Replay';

  @override
  String get victoryChallengeFriendCta => 'Challenge Friend';

  @override
  String get socialTitle => 'Social';

  @override
  String get socialHubTitle => 'Social Hub';

  @override
  String get socialHubSubtitle => 'Friends, rankings and challenges';

  @override
  String get socialFriendsLabel => 'Friends';

  @override
  String get socialBestRankLabel => 'Best Rank';

  @override
  String get socialTopTimeLabel => 'Top Time';

  @override
  String get socialGlobalTierLabel => 'Global Tier';

  @override
  String get socialFriendActionsTitle => 'Friend Actions';

  @override
  String get socialFriendActionsSubtitle =>
      'Set your handle and add friends by username or UID';

  @override
  String get socialSetUsernameHint => 'Set your username';

  @override
  String get socialSave => 'Save';

  @override
  String get socialFriendLookupHint => 'Friend username, email or UID';

  @override
  String get socialAdd => 'Add';

  @override
  String get socialFriendsSectionTitle => 'Friends';

  @override
  String get socialFriendsSectionSubtitle => 'Your rivals and teammates';

  @override
  String socialFriendsWithCount(int count) {
    return 'Friends ($count)';
  }

  @override
  String get socialNoFriendsTitle => 'No friends added yet';

  @override
  String get socialNoFriendsSubtitle =>
      'Add friends to compete on rankings and send challenges.';

  @override
  String get socialGlobalTop10Title => 'Global Top 10';

  @override
  String get socialGlobalTop10Subtitle => 'Best players in the world';

  @override
  String get socialNoGlobalScoresTitle => 'No global scores yet';

  @override
  String get socialNoGlobalScoresSubtitle =>
      'Complete levels to appear in the world ranking.';

  @override
  String get socialChallengesTitle => 'Challenges';

  @override
  String get socialChallengesSubtitle => 'Invite or challenge your friends now';

  @override
  String get socialChallengeFriend => 'Challenge Friend';

  @override
  String get socialInviteFriend => 'Invite Friend';

  @override
  String get socialFriendRequestTitle => 'Friend Request';

  @override
  String get socialFriendRequestSent => 'Friend request sent';

  @override
  String get socialCouldNotSendRequest => 'Could not send friend request';

  @override
  String get socialCannotAddSelf => 'You can\'t add yourself';

  @override
  String get socialInvalidEmail => 'Invalid email format';

  @override
  String get socialUserNotFound => 'User not found';

  @override
  String get socialAlreadyFriends => 'You are already friends';

  @override
  String get socialRequestAlreadySent => 'Friend request already sent';

  @override
  String get socialRequestAlreadyReceived =>
      'This user already sent you a request';

  @override
  String get socialNeedSignIn => 'You need to be signed in';

  @override
  String get socialRulesBlockedAction => 'Firestore rules blocked this action';

  @override
  String get socialAddFriendsFirstForChallenges =>
      'Add friends first to send challenges.';

  @override
  String get socialChallengeFriendSheetTitle => 'Challenge a friend';

  @override
  String get socialChallengeFriendSheetSubtitle =>
      'Send a real-time live duel invite';

  @override
  String get socialLiveInviteOnline => 'Invite to a live 1v1 duel - Online';

  @override
  String get socialLiveInviteOffline => 'Invite to a live 1v1 duel - Offline';

  @override
  String get socialLiveInviteSentTitle => 'Live duel invite sent';

  @override
  String socialLiveInviteSentBody(Object name) {
    return 'Waiting for $name to accept.';
  }

  @override
  String get socialCouldNotSendChallenge =>
      'Could not send challenge right now.';

  @override
  String get socialChallengeBlockedByRules =>
      'Challenge blocked by Firestore rules.';

  @override
  String get socialChallengeSetupNotReady =>
      'Challenge setup is not ready yet. Try again in a moment.';

  @override
  String get socialFinishCurrentLiveDuelFirst =>
      'Finish your current live duel first.';

  @override
  String socialFriendAlreadyInLiveDuel(Object name) {
    return '$name is already in another live duel.';
  }

  @override
  String get socialNoPuzzlesForLiveDuel =>
      'No puzzles available for live duel.';

  @override
  String get socialRemoveFriendTitle => 'Remove friend';

  @override
  String get socialRemoveFriendBody =>
      'Are you sure you want to remove this friend?';

  @override
  String get socialRemove => 'Remove';

  @override
  String get socialUsernameTitle => 'Username';

  @override
  String get socialUsernameNotAvailable => 'Username not available';

  @override
  String get socialUsernameUpdated => 'Username updated';

  @override
  String get socialUsernameAlreadyUsed => 'Username already in use';

  @override
  String get socialUsernameInvalid =>
      'Invalid username (3-20, letters/numbers/._)';

  @override
  String get socialRulesBlockedUsernameWrite =>
      'Firestore rules blocked username write';

  @override
  String get socialCouldNotSaveUsername => 'Could not save username';

  @override
  String get socialInviteReadyTitle => 'Invite Ready';

  @override
  String get socialInviteReadyBody =>
      'Invite copied. Share it on WhatsApp or email.';

  @override
  String socialMovesShort(int count) {
    return '$count moves';
  }

  @override
  String socialStarsShort(int count) {
    return '$count stars';
  }

  @override
  String get socialGuestLockedTitle => 'Social is locked in Guest mode';

  @override
  String get socialGuestLockedSubtitle =>
      'Sign in with Google from Home to challenge friends and view rankings.';

  @override
  String get socialGoHome => 'Go Home';

  @override
  String get socialPlayerFallback => 'Player';

  @override
  String socialSkinTrail(Object skin, Object trail) {
    return 'Skin: $skin - Trail: $trail';
  }

  @override
  String get socialOnline => 'Online';

  @override
  String get socialOffline => 'Offline';

  @override
  String get socialStatusLabel => 'Status';

  @override
  String get socialSkinLabel => 'Skin';

  @override
  String get socialTrailLabel => 'Trail';

  @override
  String get socialReadyToCompete => 'Ready to compete';

  @override
  String get energyNoEnergyTitle => 'No energy';

  @override
  String energyOutWithBattery(Object reset) {
    return 'You are out of energy. Wait $reset for reset, or use a battery now.';
  }

  @override
  String energyOutWithoutBattery(Object reset) {
    return 'You are out of energy. Wait $reset for reset, or buy a battery.';
  }

  @override
  String get energyCouldNotUseBattery => 'Could not use battery right now.';

  @override
  String energyRestored(int current, int max) {
    return 'Energy restored to $current/$max.';
  }

  @override
  String get energyUseBattery => 'Use battery';

  @override
  String get energyNotEnoughCoinsBattery =>
      'Not enough coins to buy a battery.';

  @override
  String get energyBatteryPurchaseFailed =>
      'Battery purchase failed. Try again.';

  @override
  String energyBatteryPurchasedAndUsed(int current, int max) {
    return 'Battery purchased and used. Energy $current/$max.';
  }

  @override
  String energyBatteryPurchasedCount(int count) {
    return 'Battery purchased. Batteries: $count.';
  }

  @override
  String energyBuyBattery(int coins) {
    return 'Buy ($coins coins)';
  }

  @override
  String playLevelsCompletedToGo(int completed, int remaining) {
    return '$completed completed - $remaining to go';
  }

  @override
  String playLevelsContinueLevel(int level) {
    return 'Continue L$level';
  }

  @override
  String get playLevelsRanking => 'Ranking';

  @override
  String get commonCancel => 'Cancel';

  @override
  String get commonClose => 'Close';

  @override
  String get commonNo => 'No';

  @override
  String get commonOk => 'OK';

  @override
  String get commonReload => 'Reload';

  @override
  String get commonRetry => 'Retry';

  @override
  String get commonYes => 'Yes';

  @override
  String get gameGotIt => 'Got it';

  @override
  String get gameHowToPlayTitle => 'How to play';

  @override
  String get gameCoreTutorialBody =>
      '1) Start at number 1.\n2) Drag to connect numbers in order (1,2,3...).\n3) Even with few numbers, you must fill every cell of the board.\n4) If you make a mistake, use Undo or Restart.';

  @override
  String get gameLetsGo => 'Let\'s go';

  @override
  String get gameVariantAlphabetTitle => 'Alphabet Mode';

  @override
  String get gameVariantAlphabetBody =>
      'Connect cells in alphabetical order following the path clues.';

  @override
  String get gameVariantAlphabetReverseTitle => 'Reverse Alphabet Mode';

  @override
  String get gameVariantAlphabetReverseBody =>
      'Connect cells in reverse alphabetical order.';

  @override
  String get gameVariantMultiplesTitle => 'Multiples Mode';

  @override
  String get gameVariantMultiplesBody =>
      'Numbers are multiples of a base. Follow increasing multiples in order.';

  @override
  String get gameVariantRomanMultiplesTitle => 'Roman Multiples Mode';

  @override
  String get gameVariantRomanMultiplesBody =>
      'Follow increasing multiples shown as roman numerals.';

  @override
  String get gameVariantRomanTitle => 'Roman Numerals Mode';

  @override
  String get gameVariantRomanBody =>
      'Follow the sequence of roman numerals in order.';

  @override
  String get gameVariantDefaultTitle => 'Variant Mode';

  @override
  String get gameVariantDefaultBody =>
      'Follow the clue sequence in the correct order.';

  @override
  String gameVariantExample(Object example) {
    return 'Example: $example';
  }

  @override
  String get gamePackNotFound => 'Pack not found';

  @override
  String get gameLoadingLevel => 'Loading level';

  @override
  String get gameLevelUnavailable => 'Level unavailable';

  @override
  String get gameCouldNotLoadLevel => 'Could not load this level.';

  @override
  String gameEnergyCounter(int current, int max) {
    return 'Energy $current/$max';
  }

  @override
  String gameEnergyResetIn(Object time) {
    return 'Reset $time';
  }

  @override
  String get gameDuelFinishedBoardLocked => 'Duel finished. Board locked.';

  @override
  String get gameUndo => 'Undo';

  @override
  String get gameRestart => 'Restart';

  @override
  String get gameHintInfinite => 'Hint (INF)';

  @override
  String gameHintCount(int count) {
    return 'Hint ($count)';
  }

  @override
  String get gameReporting => 'Reporting...';

  @override
  String get gameReported => 'Reported';

  @override
  String get gameReportLevel => 'Report level';

  @override
  String get gameWatchAd => 'Watch Ad';

  @override
  String get gameAdStatus => 'Ad Status';

  @override
  String get gameDailyAdLimitReached =>
      'Daily limit reached. No more ads available today.';

  @override
  String gameNextAdIn(Object time) {
    return 'Next ad in $time';
  }

  @override
  String gameLevelCompleteReward(Object reward) {
    return 'LEVEL COMPLETE! $reward';
  }

  @override
  String get gameRankingUnavailable => 'Ranking unavailable';

  @override
  String get gameTryAgainMoment => 'Try again in a moment.';

  @override
  String get gameFriendsRanking => 'Friends ranking';

  @override
  String gameLevelLabel(int level) {
    return 'Level $level';
  }

  @override
  String get gameNoFriendsRankingTitle =>
      'No friends have played this level yet.';

  @override
  String get gameNoFriendsRankingBody =>
      'Complete the level and invite friends to compete.';

  @override
  String get gameReportUnavailableTitle => 'Report unavailable';

  @override
  String gameReportUnavailableBody(int seconds) {
    return 'Play at least $seconds seconds before reporting this level.';
  }

  @override
  String get gameReportConfirmTitle => 'Report this level\'';

  @override
  String get gameReportConfirmBody =>
      'If this level is unsolvable, you can report it and unlock the next one.';

  @override
  String get gameReportAndSkip => 'Report & Skip';

  @override
  String get gameSignInRequiredTitle => 'Sign-in required';

  @override
  String get gameSignInRequiredBody =>
      'Please sign in to report and skip levels.';

  @override
  String get gameAlreadyReportedTitle => 'Already reported';

  @override
  String get gameAlreadyReportedBody =>
      'This level was already reported from this account.';

  @override
  String get gameLevelReportedTitle => 'Level reported';

  @override
  String get gameLevelReportedBody => 'Report sent. Next level unlocked.';

  @override
  String get gameCouldNotReportTitle => 'Could not report level';

  @override
  String get gameReportErrorPermissionDenied =>
      'Permissions blocked this action. Please try again later.';

  @override
  String get gameReportErrorEndpointNotConfigured =>
      'Report endpoint is not configured in this build.';

  @override
  String get gameReportErrorInvalidEndpoint =>
      'Report endpoint URL is invalid.';

  @override
  String get gameReportErrorTimeout =>
      'Report request timed out. Please retry.';

  @override
  String get gameReportErrorNetwork =>
      'Network issue while reporting. Please try again.';

  @override
  String get gameReportErrorServerRejected =>
      'Server rejected the report. Please try again in a moment.';

  @override
  String get gameReportErrorUnauthenticated =>
      'Please sign in again and retry.';

  @override
  String get gameReportErrorGeneric =>
      'Could not report this level right now. Please try again.';

  @override
  String get gameHintTitle => 'Hint';

  @override
  String get gameNoHintsLeft => 'No hints left';

  @override
  String get gameAlmostThereTitle => 'Almost there';

  @override
  String gameAlmostThereBody(Object label) {
    return 'Finish on $label to complete the level.';
  }

  @override
  String get gameTimeTitle => 'Time!';

  @override
  String get gameWaitingForDuelResult => 'Waiting for duel result...';

  @override
  String get gameLevelAlreadyCompletedTitle => 'Level already completed';

  @override
  String get gameNoCoinRewardReplay => 'No coin reward on replay';

  @override
  String get gameNewBestTitle => 'New best';

  @override
  String get gameBeatYourGhost => 'You beat your ghost!';

  @override
  String get gameAchievementUnlocked => 'Achievement unlocked';

  @override
  String get gameRewardedAdUnavailableTitle => 'Rewarded ad unavailable';

  @override
  String get gameContinuingWithoutBonus => 'Continuing without bonus.';

  @override
  String get gameBonusRewardTitle => 'Bonus reward';

  @override
  String gameBonusCoins(int coins) {
    return '+$coins coins';
  }

  @override
  String get gameDailyLimitReachedTitle => 'Daily limit reached';

  @override
  String get gameNoMoreAdsToday => 'No more ads available today';

  @override
  String get gamePleaseWaitTitle => 'Please wait';

  @override
  String get gameAdRewardTitle => 'Ad reward';

  @override
  String get gameRewardedAdStatusTitle => 'Rewarded ad status';

  @override
  String gameRewardedAdStatusBody(Object loaded, Object loading) {
    return 'Loaded: $loaded\nLoading: $loading';
  }

  @override
  String get gameAdReloadRequestedTitle => 'Ad reload requested';

  @override
  String get gameAdReloadRequestedBody => 'Trying to load a rewarded ad.';

  @override
  String get gameDuelYouWonTitle => 'YOU WON!';

  @override
  String get gameDuelYouLostTitle => 'YOU LOST ;(';

  @override
  String get gameDuelYouFinishedFirst => 'You finished first in the duel.';

  @override
  String get gameDuelFriendFinishedFirst => 'Your friend finished first.';

  @override
  String gameLiveDuelFinishedWaiting(Object time) {
    return 'Finished in $time. Waiting result...';
  }

  @override
  String get gameLiveDuelResultTitle => 'Live duel result';

  @override
  String get gameOpponentAbandoned => 'Opponent abandoned';

  @override
  String get gameLevel => 'Level';

  @override
  String get gameOpponent => 'Opponent';

  @override
  String get gamePlayer => 'Player';

  @override
  String get gameEmotesAfterDuelResult => 'Emotes available after duel result';

  @override
  String get gameEmoteLaugh => 'Laugh';

  @override
  String get gameEmoteCool => 'Cool';

  @override
  String get gameEmoteWow => 'Wow';

  @override
  String get gameEmoteCry => 'Cry';

  @override
  String get gameEmoteClap => 'Clap';

  @override
  String get gameEmoteHeart => 'Heart';

  @override
  String gameEnergyEmptyResetIn(Object time) {
    return 'Energy empty. Reset in $time.';
  }

  @override
  String get gameBatteries => 'Batteries';

  @override
  String gameGhostBest(Object time) {
    return 'Ghost best: $time';
  }

  @override
  String get gameGhostOn => 'Ghost: ON';

  @override
  String get gameGhostOff => 'Ghost: OFF';

  @override
  String get gameGhostAvailableAfterFirst =>
      'Ghost available after first completion';

  @override
  String get gameNoRankingImpact => 'No ranking impact';

  @override
  String get shopTrailEffects => 'Trail Effects';

  @override
  String get shopCoinPacksUnavailable => 'Coin packs unavailable';

  @override
  String get shopCouldNotLoadCoinPacksRetry =>
      'Could not load coin packs. Please retry.';

  @override
  String get shopCheckConnectionRetry =>
      'Please check your connection and retry.';

  @override
  String get shopNoCoinPacksAvailable => 'No coin packs available';

  @override
  String get shopStoreProductsUnavailableNow =>
      'Store products are not available right now. Please try again later.';

  @override
  String get shopRestore => 'Restore';

  @override
  String get shopLoadingStoreProducts => 'Loading store products...';

  @override
  String get shopStoreUnavailable => 'Store unavailable';

  @override
  String get shopPurchasesDisabledBrowse =>
      'You can still browse all coin packs. Purchases are disabled right now.';

  @override
  String get shopShowingLocalCatalogFallback =>
      'Showing local catalog fallback';

  @override
  String get shopEnergyBatteries => 'Energy batteries';

  @override
  String shopBatteriesResetIn(int count, Object time) {
    return 'Batteries: $count - Reset in $time';
  }

  @override
  String get shopUseOneBatteryNow => 'Use 1 battery now';

  @override
  String get shopProcessingPurchase => 'Processing purchase...';

  @override
  String shopPurchasedBatteries(int units, int total) {
    return 'Purchased $units battery(s). Total: $total.';
  }

  @override
  String get shopPurchaseSuccessful => 'Purchase successful';

  @override
  String get shopConfirmPurchaseTitle => 'Confirm purchase';

  @override
  String shopConfirmPurchaseBody(Object name, int coins) {
    return 'Do you want to buy \"$name\" for $coins coins\'';
  }

  @override
  String get shopBuyNow => 'Buy now';

  @override
  String get playWorldFallbackTitle => 'World';

  @override
  String get playWorldFallbackSubtitle => 'Puzzle journey';

  @override
  String playWorldTitle(int number) {
    return 'World $number';
  }

  @override
  String playWorldSubtitle(int number) {
    return 'Puzzle journey $number';
  }

  @override
  String get onboardingInProgress => 'In progress';

  @override
  String get onboardingGoNow => 'Go now';

  @override
  String duelHistoryTimes(Object youTime, Object opponentTime) {
    return 'You $youTime Opp $opponentTime';
  }

  @override
  String get duelStatusVictory => 'Victory';

  @override
  String get duelStatusDefeat => 'Defeat';

  @override
  String get playLevelsWorldLockedCompletePrevious =>
      'World locked. Complete or report all levels in previous world first.';

  @override
  String playLevelsEnergyStatus(int current, int max, Object time) {
    return '$current/$max - reset $time';
  }

  @override
  String playLevelsWorldProgressSummary(int total, int completed) {
    return '$total levels - $completed completed';
  }

  @override
  String playLevelsEnergyDetailed(int current, int max, Object time) {
    return 'Energy $current/$max. Reset in $time.';
  }

  @override
  String get playLevelsSelectedLevel => 'Selected Level';

  @override
  String playLevelsSelectedLevelVariant(int level, Object variant) {
    return 'Level $level $variant';
  }

  @override
  String get playLevelsPlay => 'Play';

  @override
  String get playLevelsLocked => 'Locked';

  @override
  String get playLevelsDifficultyWarmup => 'Warm-up';

  @override
  String get playLevelsDifficultyEasy => 'Easy';

  @override
  String get playLevelsDifficultyMedium => 'Medium';

  @override
  String get playLevelsDifficultyHard => 'Hard';

  @override
  String get playLevelsDifficultyExpert => 'Expert';

  @override
  String get playLevelsDifficultyClassic => 'Classic';

  @override
  String get playLevelsVariantMultiplesRoman => 'Multiples Roman';

  @override
  String get playLevelsVariantAlphabetReverse => 'Alphabet Reverse';

  @override
  String get playLevelsVariantAlphabet => 'Alphabet';

  @override
  String get playLevelsVariantMultiples => 'Multiples';

  @override
  String get playLevelsVariantRoman => 'Roman';

  @override
  String get playLevelsVariantClassic => 'Classic';

  @override
  String gameLevelProgress(int level, int total) {
    return 'Level $level / $total';
  }

  @override
  String get gameFriendlyChallengeCompleteHeadline =>
      'Friendly Challenge Complete';

  @override
  String get gameReplay => 'Replay';

  @override
  String gameFriendlyChallengeShare(Object time) {
    return 'Friendly challenge done in $time.';
  }

  @override
  String gameFriendlyChallengeCopy(Object time) {
    return 'Friendly challenge | $time';
  }

  @override
  String get gameContinueTutorial => 'Continue Tutorial';

  @override
  String gameVictoryShareText(int level, Object time, int score) {
    return 'I solved Zip #$level in $time. Score $score.';
  }

  @override
  String gameVictoryCopyText(int level, Object time, int streak) {
    return 'Zip #$level - $time - Streak $streak ';
  }

  @override
  String gameReacted(Object name) {
    return '$name reacted';
  }

  @override
  String get victoryHeadlineFire => 'You\'re on fire!';

  @override
  String get victoryHeadlineCrushing => 'Crushing it!';

  @override
  String get victoryHeadlinePerfect => 'Perfect run!';

  @override
  String get victoryHeadlineSharp => 'Sharp move!';

  @override
  String get endlessTitle => 'Endless';

  @override
  String endlessDifficulty(int difficulty) {
    return 'Difficulty $difficulty';
  }

  @override
  String get endlessNewRun => 'New';

  @override
  String endlessResumeAt(int index) {
    return 'Resume at $index';
  }

  @override
  String get endlessStartNewRun => 'Start a new endless run';

  @override
  String endlessBestSummary(int score, int index, Object avg) {
    return 'Best score: $score | Best index: $index | Best avg: $avg';
  }

  @override
  String get endlessCouldNotLoadPuzzle => 'Could not load endless puzzle.';

  @override
  String endlessRunSeed(int seed) {
    return 'Run seed: $seed';
  }

  @override
  String get endlessSolved => 'Solved!';

  @override
  String endlessShareText(int difficulty, int index, Object time) {
    return 'Endless D$difficulty #$index in $time.';
  }

  @override
  String endlessCopyText(int index, Object time, int streak) {
    return 'Zip #$index - $time - Streak $streak ';
  }

  @override
  String levelsPackTitle(Object pack) {
    return '$pack levels';
  }

  @override
  String get gameClear => 'Clear';

  @override
  String gameNext(Object value) {
    return 'Next $value';
  }

  @override
  String gameStars(Object value) {
    return 'Stars $value';
  }

  @override
  String get victoryPrimaryNextLevel => 'Next Level';

  @override
  String get victoryPrimaryPlayAgain => 'Play Again';

  @override
  String get retry => 'Retry';
}
