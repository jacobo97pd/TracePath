import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_es.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
      : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('es')
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'TracePath'**
  String get appTitle;

  /// No description provided for @victoryDataMissing.
  ///
  /// In en, this message translates to:
  /// **'Victory data missing'**
  String get victoryDataMissing;

  /// No description provided for @liveDuelInviteTitle.
  ///
  /// In en, this message translates to:
  /// **'Live Duel Invite'**
  String get liveDuelInviteTitle;

  /// No description provided for @liveDuelInviteBody.
  ///
  /// In en, this message translates to:
  /// **'{from} challenged you to a live duel.\nDo you want to accept?'**
  String liveDuelInviteBody(Object from);

  /// No description provided for @decline.
  ///
  /// In en, this message translates to:
  /// **'Decline'**
  String get decline;

  /// No description provided for @accept.
  ///
  /// In en, this message translates to:
  /// **'Accept'**
  String get accept;

  /// No description provided for @liveInviteCouldNotProcess.
  ///
  /// In en, this message translates to:
  /// **'Could not process live invite'**
  String get liveInviteCouldNotProcess;

  /// No description provided for @liveInviteNoLongerAvailable.
  ///
  /// In en, this message translates to:
  /// **'Invite is no longer available'**
  String get liveInviteNoLongerAvailable;

  /// No description provided for @liveInviteAlreadyClosed.
  ///
  /// In en, this message translates to:
  /// **'This duel is already closed'**
  String get liveInviteAlreadyClosed;

  /// No description provided for @liveInviteInvalidAccount.
  ///
  /// In en, this message translates to:
  /// **'Invite is not valid for this account'**
  String get liveInviteInvalidAccount;

  /// No description provided for @liveInviteInvalidPayload.
  ///
  /// In en, this message translates to:
  /// **'Invite payload is invalid'**
  String get liveInviteInvalidPayload;

  /// No description provided for @liveInvitePermissionsBlocked.
  ///
  /// In en, this message translates to:
  /// **'Permissions blocked this invite action'**
  String get liveInvitePermissionsBlocked;

  /// No description provided for @liveInviteNetworkIssue.
  ///
  /// In en, this message translates to:
  /// **'Network issue while processing invite'**
  String get liveInviteNetworkIssue;

  /// No description provided for @tabHome.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get tabHome;

  /// No description provided for @tabShop.
  ///
  /// In en, this message translates to:
  /// **'Shop'**
  String get tabShop;

  /// No description provided for @tabDuel.
  ///
  /// In en, this message translates to:
  /// **'Duel'**
  String get tabDuel;

  /// No description provided for @tabCards.
  ///
  /// In en, this message translates to:
  /// **'Cards'**
  String get tabCards;

  /// No description provided for @tabProfile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get tabProfile;

  /// No description provided for @playModeWorlds.
  ///
  /// In en, this message translates to:
  /// **'Worlds'**
  String get playModeWorlds;

  /// No description provided for @playModeDaily.
  ///
  /// In en, this message translates to:
  /// **'Daily'**
  String get playModeDaily;

  /// No description provided for @playModeRanked.
  ///
  /// In en, this message translates to:
  /// **'Ranked'**
  String get playModeRanked;

  /// No description provided for @playModeEvents.
  ///
  /// In en, this message translates to:
  /// **'Events'**
  String get playModeEvents;

  /// No description provided for @playModeDuels.
  ///
  /// In en, this message translates to:
  /// **'Duels'**
  String get playModeDuels;

  /// No description provided for @playButton.
  ///
  /// In en, this message translates to:
  /// **'Play'**
  String get playButton;

  /// No description provided for @homePlayerName.
  ///
  /// In en, this message translates to:
  /// **'Player'**
  String get homePlayerName;

  /// No description provided for @homeTitle.
  ///
  /// In en, this message translates to:
  /// **'TracePath'**
  String get homeTitle;

  /// No description provided for @homeStreakPill.
  ///
  /// In en, this message translates to:
  /// **'Streak {count}'**
  String homeStreakPill(int count);

  /// No description provided for @homeLevelPill.
  ///
  /// In en, this message translates to:
  /// **'Lv {count}'**
  String homeLevelPill(int count);

  /// No description provided for @homeTrainTitle.
  ///
  /// In en, this message translates to:
  /// **'Train your brain'**
  String get homeTrainTitle;

  /// No description provided for @homeTrainSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Trace paths faster, improve precision, and climb every challenge.'**
  String get homeTrainSubtitle;

  /// No description provided for @homeStartSolving.
  ///
  /// In en, this message translates to:
  /// **'START SOLVING!'**
  String get homeStartSolving;

  /// No description provided for @homeJumpToNextPuzzle.
  ///
  /// In en, this message translates to:
  /// **'Jump into your next puzzle'**
  String get homeJumpToNextPuzzle;

  /// No description provided for @homeContinue.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get homeContinue;

  /// No description provided for @homeContinueFirstRun.
  ///
  /// In en, this message translates to:
  /// **'Start your first run'**
  String get homeContinueFirstRun;

  /// No description provided for @homeContinueResumeLevel.
  ///
  /// In en, this message translates to:
  /// **'Level {level} · Pick up where you left off'**
  String homeContinueResumeLevel(int level);

  /// No description provided for @homeQuickAccessTitle.
  ///
  /// In en, this message translates to:
  /// **'Quick Access'**
  String get homeQuickAccessTitle;

  /// No description provided for @homeQuickAccessSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Jump directly into your favorite modes'**
  String get homeQuickAccessSubtitle;

  /// No description provided for @homeQuickDailyTitle.
  ///
  /// In en, this message translates to:
  /// **'Daily Puzzle'**
  String get homeQuickDailyTitle;

  /// No description provided for @homeQuickDailySubtitle.
  ///
  /// In en, this message translates to:
  /// **'One challenge each day'**
  String get homeQuickDailySubtitle;

  /// No description provided for @homeQuickLevelsTitle.
  ///
  /// In en, this message translates to:
  /// **'Levels'**
  String get homeQuickLevelsTitle;

  /// No description provided for @homeQuickLevelsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Choose any available level'**
  String get homeQuickLevelsSubtitle;

  /// No description provided for @homeQuickSocialTitle.
  ///
  /// In en, this message translates to:
  /// **'Social'**
  String get homeQuickSocialTitle;

  /// No description provided for @homeQuickSocialSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Friends, inbox and multiplayer'**
  String get homeQuickSocialSubtitle;

  /// No description provided for @homeProgressTitle.
  ///
  /// In en, this message translates to:
  /// **'Progress'**
  String get homeProgressTitle;

  /// No description provided for @homeProgressSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Your latest performance and momentum'**
  String get homeProgressSubtitle;

  /// No description provided for @homeMetricLevelsSolved.
  ///
  /// In en, this message translates to:
  /// **'Levels solved'**
  String get homeMetricLevelsSolved;

  /// No description provided for @homeMetricCurrentStreak.
  ///
  /// In en, this message translates to:
  /// **'Current streak'**
  String get homeMetricCurrentStreak;

  /// No description provided for @homeMetricBestStreak.
  ///
  /// In en, this message translates to:
  /// **'Best streak'**
  String get homeMetricBestStreak;

  /// No description provided for @homeMetricHighestLevel.
  ///
  /// In en, this message translates to:
  /// **'Highest level'**
  String get homeMetricHighestLevel;

  /// No description provided for @homeDailySolved.
  ///
  /// In en, this message translates to:
  /// **'Daily puzzles solved: {count}'**
  String homeDailySolved(int count);

  /// No description provided for @homeViewProfile.
  ///
  /// In en, this message translates to:
  /// **'View profile'**
  String get homeViewProfile;

  /// No description provided for @duelHubTitle.
  ///
  /// In en, this message translates to:
  /// **'Duel Hub'**
  String get duelHubTitle;

  /// No description provided for @duelHubSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Challenge friends and play live matches.'**
  String get duelHubSubtitle;

  /// No description provided for @duelCreating.
  ///
  /// In en, this message translates to:
  /// **'Creating duel...'**
  String get duelCreating;

  /// No description provided for @duelChallengeFriend.
  ///
  /// In en, this message translates to:
  /// **'Challenge a Friend'**
  String get duelChallengeFriend;

  /// No description provided for @duelIncomingInvitesTitle.
  ///
  /// In en, this message translates to:
  /// **'Incoming Invites'**
  String get duelIncomingInvitesTitle;

  /// No description provided for @duelIncomingInvitesSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Accept or decline live duel requests'**
  String get duelIncomingInvitesSubtitle;

  /// No description provided for @duelNoPendingInvitesTitle.
  ///
  /// In en, this message translates to:
  /// **'No pending invites'**
  String get duelNoPendingInvitesTitle;

  /// No description provided for @duelNoPendingInvitesSubtitle.
  ///
  /// In en, this message translates to:
  /// **'New challenges will appear here.'**
  String get duelNoPendingInvitesSubtitle;

  /// No description provided for @duelInviteLoadErrorTitle.
  ///
  /// In en, this message translates to:
  /// **'Could not load invites'**
  String get duelInviteLoadErrorTitle;

  /// No description provided for @duelTryAgainLater.
  ///
  /// In en, this message translates to:
  /// **'Try again in a moment.'**
  String get duelTryAgainLater;

  /// No description provided for @duelActiveMatchesTitle.
  ///
  /// In en, this message translates to:
  /// **'Active Matches'**
  String get duelActiveMatchesTitle;

  /// No description provided for @duelActiveMatchesSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Resume your current live duels'**
  String get duelActiveMatchesSubtitle;

  /// No description provided for @duelNoActiveTitle.
  ///
  /// In en, this message translates to:
  /// **'No active duels'**
  String get duelNoActiveTitle;

  /// No description provided for @duelNoActiveSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Start a challenge to play live.'**
  String get duelNoActiveSubtitle;

  /// No description provided for @duelActiveLoadErrorTitle.
  ///
  /// In en, this message translates to:
  /// **'Could not load active matches'**
  String get duelActiveLoadErrorTitle;

  /// No description provided for @duelHistoryTitle.
  ///
  /// In en, this message translates to:
  /// **'History'**
  String get duelHistoryTitle;

  /// No description provided for @duelHistorySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Recent duel results'**
  String get duelHistorySubtitle;

  /// No description provided for @duelHistoryComingSoonTitle.
  ///
  /// In en, this message translates to:
  /// **'History coming soon'**
  String get duelHistoryComingSoonTitle;

  /// No description provided for @duelHistoryComingSoonSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Your last duels will be shown here.'**
  String get duelHistoryComingSoonSubtitle;

  /// No description provided for @duelChooseFriend.
  ///
  /// In en, this message translates to:
  /// **'Choose a friend'**
  String get duelChooseFriend;

  /// No description provided for @duelCouldNotLoadFriends.
  ///
  /// In en, this message translates to:
  /// **'Could not load friends'**
  String get duelCouldNotLoadFriends;

  /// No description provided for @duelNoFriendsYet.
  ///
  /// In en, this message translates to:
  /// **'No friends yet'**
  String get duelNoFriendsYet;

  /// No description provided for @duelInviteSentText.
  ///
  /// In en, this message translates to:
  /// **'sent you a live duel invite.'**
  String get duelInviteSentText;

  /// No description provided for @duelAcceptError.
  ///
  /// In en, this message translates to:
  /// **'Could not accept duel invite: {error}'**
  String duelAcceptError(Object error);

  /// No description provided for @duelDeclineError.
  ///
  /// In en, this message translates to:
  /// **'Could not decline duel invite: {error}'**
  String duelDeclineError(Object error);

  /// No description provided for @duelAccept.
  ///
  /// In en, this message translates to:
  /// **'Accept'**
  String get duelAccept;

  /// No description provided for @duelResume.
  ///
  /// In en, this message translates to:
  /// **'Resume'**
  String get duelResume;

  /// No description provided for @duelStatusPending.
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get duelStatusPending;

  /// No description provided for @duelStatusCountdown.
  ///
  /// In en, this message translates to:
  /// **'Countdown'**
  String get duelStatusCountdown;

  /// No description provided for @duelStatusPlaying.
  ///
  /// In en, this message translates to:
  /// **'Playing'**
  String get duelStatusPlaying;

  /// No description provided for @duelStatusFinished.
  ///
  /// In en, this message translates to:
  /// **'Finished'**
  String get duelStatusFinished;

  /// No description provided for @duelStatusCancelled.
  ///
  /// In en, this message translates to:
  /// **'Cancelled'**
  String get duelStatusCancelled;

  /// No description provided for @duelUnknownOpponent.
  ///
  /// In en, this message translates to:
  /// **'Unknown'**
  String get duelUnknownOpponent;

  /// No description provided for @duelVersusOpponent.
  ///
  /// In en, this message translates to:
  /// **'VS {name}'**
  String duelVersusOpponent(Object name);

  /// No description provided for @duelLevelAndStatus.
  ///
  /// In en, this message translates to:
  /// **'Level: {level} · {status}'**
  String duelLevelAndStatus(Object level, Object status);

  /// No description provided for @duelErrorFinishCurrentFirst.
  ///
  /// In en, this message translates to:
  /// **'Finish your current live duel first.'**
  String get duelErrorFinishCurrentFirst;

  /// No description provided for @duelErrorFriendBusy.
  ///
  /// In en, this message translates to:
  /// **'This friend is already in another duel.'**
  String get duelErrorFriendBusy;

  /// No description provided for @duelErrorNoPuzzles.
  ///
  /// In en, this message translates to:
  /// **'No puzzles available right now.'**
  String get duelErrorNoPuzzles;

  /// No description provided for @duelErrorInvalidTarget.
  ///
  /// In en, this message translates to:
  /// **'Could not start duel with this friend.'**
  String get duelErrorInvalidTarget;

  /// No description provided for @duelErrorCreateInvite.
  ///
  /// In en, this message translates to:
  /// **'Could not create duel invite right now.'**
  String get duelErrorCreateInvite;

  /// No description provided for @duelRemoveActiveTitle.
  ///
  /// In en, this message translates to:
  /// **'Remove active match'**
  String get duelRemoveActiveTitle;

  /// No description provided for @duelRemoveActiveBody.
  ///
  /// In en, this message translates to:
  /// **'This active match will be closed and removed from this list.'**
  String get duelRemoveActiveBody;

  /// No description provided for @duelKeep.
  ///
  /// In en, this message translates to:
  /// **'Keep'**
  String get duelKeep;

  /// No description provided for @duelRemove.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get duelRemove;

  /// No description provided for @duelRemoving.
  ///
  /// In en, this message translates to:
  /// **'Removing...'**
  String get duelRemoving;

  /// No description provided for @duelRemovedActive.
  ///
  /// In en, this message translates to:
  /// **'Active match removed'**
  String get duelRemovedActive;

  /// No description provided for @duelRemoveError.
  ///
  /// In en, this message translates to:
  /// **'Could not remove match: {error}'**
  String duelRemoveError(Object error);

  /// No description provided for @friendChallengeTitle.
  ///
  /// In en, this message translates to:
  /// **'Friendly Challenge'**
  String get friendChallengeTitle;

  /// No description provided for @friendChallengeUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Challenge unavailable.'**
  String get friendChallengeUnavailable;

  /// No description provided for @friendChallengePuzzle.
  ///
  /// In en, this message translates to:
  /// **'Puzzle: {puzzleId}'**
  String friendChallengePuzzle(Object puzzleId);

  /// No description provided for @friendChallengeMode.
  ///
  /// In en, this message translates to:
  /// **'Mode: {mode}'**
  String friendChallengeMode(Object mode);

  /// No description provided for @friendChallengePlayButton.
  ///
  /// In en, this message translates to:
  /// **'Play Friendly Challenge'**
  String get friendChallengePlayButton;

  /// No description provided for @shopTitle.
  ///
  /// In en, this message translates to:
  /// **'Shop'**
  String get shopTitle;

  /// No description provided for @shopSkinEditorTooltip.
  ///
  /// In en, this message translates to:
  /// **'Skin editor'**
  String get shopSkinEditorTooltip;

  /// No description provided for @shopTabSkins.
  ///
  /// In en, this message translates to:
  /// **'Skins'**
  String get shopTabSkins;

  /// No description provided for @shopTabTrails.
  ///
  /// In en, this message translates to:
  /// **'Trails'**
  String get shopTabTrails;

  /// No description provided for @shopTabCoinPacks.
  ///
  /// In en, this message translates to:
  /// **'Coin Packs'**
  String get shopTabCoinPacks;

  /// No description provided for @shopSkinsLoaded.
  ///
  /// In en, this message translates to:
  /// **'Skins loaded: {visible}/{total}'**
  String shopSkinsLoaded(int visible, int total);

  /// No description provided for @shopFeaturedSkin.
  ///
  /// In en, this message translates to:
  /// **'Featured Skin'**
  String get shopFeaturedSkin;

  /// No description provided for @shopPointerSkins.
  ///
  /// In en, this message translates to:
  /// **'Pointer Skins'**
  String get shopPointerSkins;

  /// No description provided for @shopLoadMore.
  ///
  /// In en, this message translates to:
  /// **'Load more'**
  String get shopLoadMore;

  /// No description provided for @shopOwned.
  ///
  /// In en, this message translates to:
  /// **'Owned'**
  String get shopOwned;

  /// No description provided for @shopCoinsAmount.
  ///
  /// In en, this message translates to:
  /// **'{coins} coins'**
  String shopCoinsAmount(int coins);

  /// No description provided for @shopEquipped.
  ///
  /// In en, this message translates to:
  /// **'Equipped'**
  String get shopEquipped;

  /// No description provided for @shopEquip.
  ///
  /// In en, this message translates to:
  /// **'Equip'**
  String get shopEquip;

  /// No description provided for @shopBuyCoins.
  ///
  /// In en, this message translates to:
  /// **'Buy {coins}'**
  String shopBuyCoins(int coins);

  /// No description provided for @shopNewTrail.
  ///
  /// In en, this message translates to:
  /// **'NEW TRAIL'**
  String get shopNewTrail;

  /// No description provided for @shopUnlockedAndEquipped.
  ///
  /// In en, this message translates to:
  /// **'Unlocked and equipped'**
  String get shopUnlockedAndEquipped;

  /// No description provided for @shopDefaultTrailDescription.
  ///
  /// In en, this message translates to:
  /// **'Unique visual style for your path trace.'**
  String get shopDefaultTrailDescription;

  /// No description provided for @profileGuestMode.
  ///
  /// In en, this message translates to:
  /// **'Guest mode'**
  String get profileGuestMode;

  /// No description provided for @profileGoogleAccount.
  ///
  /// In en, this message translates to:
  /// **'Google account'**
  String get profileGoogleAccount;

  /// No description provided for @profileLogout.
  ///
  /// In en, this message translates to:
  /// **'Logout'**
  String get profileLogout;

  /// No description provided for @profileLogoutConfirm.
  ///
  /// In en, this message translates to:
  /// **'Do you want to sign out?'**
  String get profileLogoutConfirm;

  /// No description provided for @profileCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get profileCancel;

  /// No description provided for @profileSignedOut.
  ///
  /// In en, this message translates to:
  /// **'Signed out'**
  String get profileSignedOut;

  /// No description provided for @profileDefaultName.
  ///
  /// In en, this message translates to:
  /// **'Default'**
  String get profileDefaultName;

  /// No description provided for @profileLevelLabel.
  ///
  /// In en, this message translates to:
  /// **'Level'**
  String get profileLevelLabel;

  /// No description provided for @profileStreakLabel.
  ///
  /// In en, this message translates to:
  /// **'Streak'**
  String get profileStreakLabel;

  /// No description provided for @profileBestLabel.
  ///
  /// In en, this message translates to:
  /// **'Best'**
  String get profileBestLabel;

  /// No description provided for @profileBestStreak.
  ///
  /// In en, this message translates to:
  /// **'Best streak: {count}'**
  String profileBestStreak(int count);

  /// No description provided for @profileEquippedSkin.
  ///
  /// In en, this message translates to:
  /// **'Equipped Skin: {name}'**
  String profileEquippedSkin(Object name);

  /// No description provided for @profileStatsTitle.
  ///
  /// In en, this message translates to:
  /// **'Stats'**
  String get profileStatsTitle;

  /// No description provided for @profileGamesPlayed.
  ///
  /// In en, this message translates to:
  /// **'Games Played'**
  String get profileGamesPlayed;

  /// No description provided for @profileBestTime.
  ///
  /// In en, this message translates to:
  /// **'Best Time'**
  String get profileBestTime;

  /// No description provided for @profileVaultTitle.
  ///
  /// In en, this message translates to:
  /// **'Vault'**
  String get profileVaultTitle;

  /// No description provided for @profileLockerTitle.
  ///
  /// In en, this message translates to:
  /// **'Locker'**
  String get profileLockerTitle;

  /// No description provided for @profileLockerHint.
  ///
  /// In en, this message translates to:
  /// **'Tap an equipped item to open inventory.'**
  String get profileLockerHint;

  /// No description provided for @profileOpenVault.
  ///
  /// In en, this message translates to:
  /// **'Open Vault'**
  String get profileOpenVault;

  /// No description provided for @profileInboxTitle.
  ///
  /// In en, this message translates to:
  /// **'Inbox'**
  String get profileInboxTitle;

  /// No description provided for @profileInboxWithCount.
  ///
  /// In en, this message translates to:
  /// **'Inbox ({count})'**
  String profileInboxWithCount(int count);

  /// No description provided for @profileInboxUnavailableTitle.
  ///
  /// In en, this message translates to:
  /// **'Inbox unavailable right now'**
  String get profileInboxUnavailableTitle;

  /// No description provided for @profileInboxEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No messages yet'**
  String get profileInboxEmptyTitle;

  /// No description provided for @profileInboxEmptySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Friend requests, rewards and news will appear here.'**
  String get profileInboxEmptySubtitle;

  /// No description provided for @profileVaultLockerTitle.
  ///
  /// In en, this message translates to:
  /// **'Vault / Locker'**
  String get profileVaultLockerTitle;

  /// No description provided for @profileReadyToEquip.
  ///
  /// In en, this message translates to:
  /// **'Ready to equip'**
  String get profileReadyToEquip;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'es'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'es':
      return AppLocalizationsEs();
  }

  throw FlutterError(
      'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
