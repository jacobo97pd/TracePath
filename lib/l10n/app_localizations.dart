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
  /// **'{from} challenged you to a live duel.\nDo you want to accept'**
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
  /// **'Level {level} Pick up where you left off'**
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
  /// **'Level: {level} {status}'**
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
  /// **'Do you want to sign out\''**
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

  /// No description provided for @profileRewardClaimed.
  ///
  /// In en, this message translates to:
  /// **'Reward claimed: +{coins} coins'**
  String profileRewardClaimed(int coins);

  /// No description provided for @profileRewardAlreadyClaimed.
  ///
  /// In en, this message translates to:
  /// **'Reward already claimed'**
  String get profileRewardAlreadyClaimed;

  /// No description provided for @profileRewardClaimFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not claim reward'**
  String get profileRewardClaimFailed;

  /// No description provided for @profileFriendRequestAccepted.
  ///
  /// In en, this message translates to:
  /// **'Friend request accepted'**
  String get profileFriendRequestAccepted;

  /// No description provided for @profileFriendRequestDeclined.
  ///
  /// In en, this message translates to:
  /// **'Friend request declined'**
  String get profileFriendRequestDeclined;

  /// No description provided for @profileFriendRequestDeclineFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not decline friend request'**
  String get profileFriendRequestDeclineFailed;

  /// No description provided for @profileChallengeDeclined.
  ///
  /// In en, this message translates to:
  /// **'Challenge declined'**
  String get profileChallengeDeclined;

  /// No description provided for @profileChallengeDeclineFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not decline challenge'**
  String get profileChallengeDeclineFailed;

  /// No description provided for @profileChallengeDeclinedTitle.
  ///
  /// In en, this message translates to:
  /// **'Challenge declined'**
  String get profileChallengeDeclinedTitle;

  /// No description provided for @profileChallengeDeclinedBodySuffix.
  ///
  /// In en, this message translates to:
  /// **'declined your challenge.'**
  String get profileChallengeDeclinedBodySuffix;

  /// No description provided for @profileChallengeAcceptedTitle.
  ///
  /// In en, this message translates to:
  /// **'Challenge accepted'**
  String get profileChallengeAcceptedTitle;

  /// No description provided for @profileChallengeAcceptedBodySuffix.
  ///
  /// In en, this message translates to:
  /// **'accepted your challenge.'**
  String get profileChallengeAcceptedBodySuffix;

  /// No description provided for @profileFunctionUnavailableTitle.
  ///
  /// In en, this message translates to:
  /// **'Feature unavailable'**
  String get profileFunctionUnavailableTitle;

  /// No description provided for @profileFunctionUnavailableBody.
  ///
  /// In en, this message translates to:
  /// **'This feature is only available after buying and equipping a skin.'**
  String get profileFunctionUnavailableBody;

  /// No description provided for @profileUnderstand.
  ///
  /// In en, this message translates to:
  /// **'Understood'**
  String get profileUnderstand;

  /// No description provided for @profileCardUnavailableTitle.
  ///
  /// In en, this message translates to:
  /// **'Card unavailable'**
  String get profileCardUnavailableTitle;

  /// No description provided for @profileCardUnavailableBody.
  ///
  /// In en, this message translates to:
  /// **'There is no card for this skin yet.'**
  String get profileCardUnavailableBody;

  /// No description provided for @profileWorldProgressTitle.
  ///
  /// In en, this message translates to:
  /// **'World progress'**
  String get profileWorldProgressTitle;

  /// No description provided for @profileLevelsCompleted.
  ///
  /// In en, this message translates to:
  /// **'{solved} / {total} levels completed'**
  String profileLevelsCompleted(int solved, int total);

  /// No description provided for @profileHighestLevelValue.
  ///
  /// In en, this message translates to:
  /// **'Highest {level}'**
  String profileHighestLevelValue(int level);

  /// No description provided for @profileAchievementsTitle.
  ///
  /// In en, this message translates to:
  /// **'Achievements'**
  String get profileAchievementsTitle;

  /// No description provided for @profileAchievementsProgress.
  ///
  /// In en, this message translates to:
  /// **'{unlocked} / {total} unlocked'**
  String profileAchievementsProgress(int unlocked, int total);

  /// No description provided for @profileAchievementCompleted.
  ///
  /// In en, this message translates to:
  /// **'Completed{datePart}'**
  String profileAchievementCompleted(Object datePart);

  /// No description provided for @profileAchievementLocked.
  ///
  /// In en, this message translates to:
  /// **'Locked'**
  String get profileAchievementLocked;

  /// No description provided for @profileAchievementUnlocked.
  ///
  /// In en, this message translates to:
  /// **'Unlocked{datePart}'**
  String profileAchievementUnlocked(Object datePart);

  /// No description provided for @profileAchievementOnDate.
  ///
  /// In en, this message translates to:
  /// **'on {date}'**
  String profileAchievementOnDate(Object date);

  /// No description provided for @profileInboxOpen.
  ///
  /// In en, this message translates to:
  /// **'Open'**
  String get profileInboxOpen;

  /// No description provided for @profileInboxClaim.
  ///
  /// In en, this message translates to:
  /// **'Claim {coins}'**
  String profileInboxClaim(int coins);

  /// No description provided for @profileInboxNow.
  ///
  /// In en, this message translates to:
  /// **'now'**
  String get profileInboxNow;

  /// No description provided for @loginTagline.
  ///
  /// In en, this message translates to:
  /// **'Train your brain. Trace the path faster than anyone.'**
  String get loginTagline;

  /// No description provided for @loginBenefitSaveProgress.
  ///
  /// In en, this message translates to:
  /// **'Save progress'**
  String get loginBenefitSaveProgress;

  /// No description provided for @loginBenefitChallengeFriends.
  ///
  /// In en, this message translates to:
  /// **'Challenge friends'**
  String get loginBenefitChallengeFriends;

  /// No description provided for @loginBenefitKeepStreak.
  ///
  /// In en, this message translates to:
  /// **'Keep your streak'**
  String get loginBenefitKeepStreak;

  /// No description provided for @loginContinueGuest.
  ///
  /// In en, this message translates to:
  /// **'Continue as Guest'**
  String get loginContinueGuest;

  /// No description provided for @loginGuestModeHint.
  ///
  /// In en, this message translates to:
  /// **'Guest mode: no friends, no challenges.'**
  String get loginGuestModeHint;

  /// No description provided for @loginConnecting.
  ///
  /// In en, this message translates to:
  /// **'Connecting...'**
  String get loginConnecting;

  /// No description provided for @loginContinueGoogle.
  ///
  /// In en, this message translates to:
  /// **'Continue with Google'**
  String get loginContinueGoogle;

  /// No description provided for @cardsCollectionTitle.
  ///
  /// In en, this message translates to:
  /// **'Card Collection'**
  String get cardsCollectionTitle;

  /// No description provided for @cardsCollectionEmpty.
  ///
  /// In en, this message translates to:
  /// **'No cards unlocked yet.\nBuy or unlock skins to collect cards.'**
  String get cardsCollectionEmpty;

  /// No description provided for @cardsRarityLegendary.
  ///
  /// In en, this message translates to:
  /// **'Legendary'**
  String get cardsRarityLegendary;

  /// No description provided for @cardsRarityEpic.
  ///
  /// In en, this message translates to:
  /// **'Epic'**
  String get cardsRarityEpic;

  /// No description provided for @cardsRarityRare.
  ///
  /// In en, this message translates to:
  /// **'Rare'**
  String get cardsRarityRare;

  /// No description provided for @cardsRarityCommon.
  ///
  /// In en, this message translates to:
  /// **'Common'**
  String get cardsRarityCommon;

  /// No description provided for @campaignTitle.
  ///
  /// In en, this message translates to:
  /// **'Campaign'**
  String get campaignTitle;

  /// No description provided for @campaignLoading.
  ///
  /// In en, this message translates to:
  /// **'Loading...'**
  String get campaignLoading;

  /// No description provided for @campaignPreparingStatus.
  ///
  /// In en, this message translates to:
  /// **'Preparing pack status'**
  String get campaignPreparingStatus;

  /// No description provided for @campaignLoadError.
  ///
  /// In en, this message translates to:
  /// **'Could not load campaign packs.'**
  String get campaignLoadError;

  /// No description provided for @campaignPackClassic.
  ///
  /// In en, this message translates to:
  /// **'Balanced introduction'**
  String get campaignPackClassic;

  /// No description provided for @campaignPackArchitect.
  ///
  /// In en, this message translates to:
  /// **'More walls and tighter planning'**
  String get campaignPackArchitect;

  /// No description provided for @campaignPackExpert.
  ///
  /// In en, this message translates to:
  /// **'Larger boards and harder routes'**
  String get campaignPackExpert;

  /// No description provided for @leaderboardFriendsTitleWithLevel.
  ///
  /// In en, this message translates to:
  /// **'Friends ranking - L{level}'**
  String leaderboardFriendsTitleWithLevel(int level);

  /// No description provided for @leaderboardFriendsTitle.
  ///
  /// In en, this message translates to:
  /// **'Friends ranking'**
  String get leaderboardFriendsTitle;

  /// No description provided for @leaderboardLevelPack.
  ///
  /// In en, this message translates to:
  /// **'Level {level} - {packId}'**
  String leaderboardLevelPack(int level, Object packId);

  /// No description provided for @leaderboardNoFriendsScores.
  ///
  /// In en, this message translates to:
  /// **'No friends scores yet for this level.'**
  String get leaderboardNoFriendsScores;

  /// No description provided for @leaderboardUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Friends ranking unavailable right now.'**
  String get leaderboardUnavailable;

  /// No description provided for @dailyTitle.
  ///
  /// In en, this message translates to:
  /// **'Daily'**
  String get dailyTitle;

  /// No description provided for @dailyUnknownLoadError.
  ///
  /// In en, this message translates to:
  /// **'Unknown daily load error'**
  String get dailyUnknownLoadError;

  /// No description provided for @dailyLoadError.
  ///
  /// In en, this message translates to:
  /// **'Could not load daily puzzle.'**
  String get dailyLoadError;

  /// No description provided for @dailyRetry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get dailyRetry;

  /// No description provided for @dailyChallengeTitle.
  ///
  /// In en, this message translates to:
  /// **'Daily Challenge'**
  String get dailyChallengeTitle;

  /// No description provided for @dailyNextPuzzleIn.
  ///
  /// In en, this message translates to:
  /// **'Next puzzle in {countdown}'**
  String dailyNextPuzzleIn(Object countdown);

  /// No description provided for @dailyRewardLabel.
  ///
  /// In en, this message translates to:
  /// **'Reward'**
  String get dailyRewardLabel;

  /// No description provided for @dailyCoinsReward.
  ///
  /// In en, this message translates to:
  /// **'{coins} coins'**
  String dailyCoinsReward(int coins);

  /// No description provided for @dailyStreakLabel.
  ///
  /// In en, this message translates to:
  /// **'Streak'**
  String get dailyStreakLabel;

  /// No description provided for @dailyBestTimeLabel.
  ///
  /// In en, this message translates to:
  /// **'Best Time'**
  String get dailyBestTimeLabel;

  /// No description provided for @dailyPlayAgain.
  ///
  /// In en, this message translates to:
  /// **'Play Again'**
  String get dailyPlayAgain;

  /// No description provided for @dailyPlayDaily.
  ///
  /// In en, this message translates to:
  /// **'Play Daily'**
  String get dailyPlayDaily;

  /// No description provided for @dailyAttemptsSummary.
  ///
  /// In en, this message translates to:
  /// **'Attempts today: {attempts} - Best score: {bestScore}'**
  String dailyAttemptsSummary(int attempts, Object bestScore);

  /// No description provided for @dailyNewPersonalBestToday.
  ///
  /// In en, this message translates to:
  /// **'New personal best today'**
  String get dailyNewPersonalBestToday;

  /// No description provided for @dailyCompletedTitle.
  ///
  /// In en, this message translates to:
  /// **'Daily completed'**
  String get dailyCompletedTitle;

  /// No description provided for @dailySavedWithPartialSync.
  ///
  /// In en, this message translates to:
  /// **'Saved with partial sync issue. Try again later.'**
  String get dailySavedWithPartialSync;

  /// No description provided for @dailyRewardSyncFailed.
  ///
  /// In en, this message translates to:
  /// **'Reward sync failed. Please try again.'**
  String get dailyRewardSyncFailed;

  /// No description provided for @dailyAchievementUnlocked.
  ///
  /// In en, this message translates to:
  /// **'Achievement Unlocked'**
  String get dailyAchievementUnlocked;

  /// No description provided for @dailyRewardToastTitle.
  ///
  /// In en, this message translates to:
  /// **'Daily reward'**
  String get dailyRewardToastTitle;

  /// No description provided for @dailyRewardToastMessage.
  ///
  /// In en, this message translates to:
  /// **'+{coins} coins'**
  String dailyRewardToastMessage(int coins);

  /// No description provided for @dailyShareText.
  ///
  /// In en, this message translates to:
  /// **'Daily complete in {time}.'**
  String dailyShareText(Object time);

  /// No description provided for @dailyCopyText.
  ///
  /// In en, this message translates to:
  /// **'Zip #{day} - {time} - Streak {streak} '**
  String dailyCopyText(int day, Object time, int streak);

  /// No description provided for @liveDuelTitle.
  ///
  /// In en, this message translates to:
  /// **'Live Duel'**
  String get liveDuelTitle;

  /// No description provided for @liveDuelCouldNotUpdateReady.
  ///
  /// In en, this message translates to:
  /// **'Could not update ready state'**
  String get liveDuelCouldNotUpdateReady;

  /// No description provided for @liveDuelAcceptInviteFirst.
  ///
  /// In en, this message translates to:
  /// **'Accept the duel invite first'**
  String get liveDuelAcceptInviteFirst;

  /// No description provided for @liveDuelAlreadyClosed.
  ///
  /// In en, this message translates to:
  /// **'This duel is already closed'**
  String get liveDuelAlreadyClosed;

  /// No description provided for @liveDuelOpponent.
  ///
  /// In en, this message translates to:
  /// **'Opponent'**
  String get liveDuelOpponent;

  /// No description provided for @liveDuelReacted.
  ///
  /// In en, this message translates to:
  /// **'{sender} reacted'**
  String liveDuelReacted(Object sender);

  /// No description provided for @liveDuelUnavailableNow.
  ///
  /// In en, this message translates to:
  /// **'Live duel unavailable right now.'**
  String get liveDuelUnavailableNow;

  /// No description provided for @liveDuelMatchNotFound.
  ///
  /// In en, this message translates to:
  /// **'Match not found'**
  String get liveDuelMatchNotFound;

  /// No description provided for @liveDuelYou.
  ///
  /// In en, this message translates to:
  /// **'You'**
  String get liveDuelYou;

  /// No description provided for @liveDuelWaitingPlayer.
  ///
  /// In en, this message translates to:
  /// **'Waiting player...'**
  String get liveDuelWaitingPlayer;

  /// No description provided for @liveDuelLeave.
  ///
  /// In en, this message translates to:
  /// **'Leave duel'**
  String get liveDuelLeave;

  /// No description provided for @liveDuelHeroYouAbandoned.
  ///
  /// In en, this message translates to:
  /// **'YOU ABANDONED'**
  String get liveDuelHeroYouAbandoned;

  /// No description provided for @liveDuelHeroYouWin.
  ///
  /// In en, this message translates to:
  /// **'YOU WIN!'**
  String get liveDuelHeroYouWin;

  /// No description provided for @liveDuelHeroDraw.
  ///
  /// In en, this message translates to:
  /// **'DRAW'**
  String get liveDuelHeroDraw;

  /// No description provided for @liveDuelHeroYouLost.
  ///
  /// In en, this message translates to:
  /// **'YOU LOST'**
  String get liveDuelHeroYouLost;

  /// No description provided for @liveDuelInvitationReceived.
  ///
  /// In en, this message translates to:
  /// **'Invitation received'**
  String get liveDuelInvitationReceived;

  /// No description provided for @liveDuelWaitingFriendJoin.
  ///
  /// In en, this message translates to:
  /// **'Waiting for your friend to join...'**
  String get liveDuelWaitingFriendJoin;

  /// No description provided for @liveDuelOpponentReady.
  ///
  /// In en, this message translates to:
  /// **'Opponent is ready'**
  String get liveDuelOpponentReady;

  /// No description provided for @liveDuelOpponentJoinedWaitingReady.
  ///
  /// In en, this message translates to:
  /// **'Opponent joined, waiting ready'**
  String get liveDuelOpponentJoinedWaitingReady;

  /// No description provided for @liveDuelOpponentNotJoined.
  ///
  /// In en, this message translates to:
  /// **'Opponent has not joined yet'**
  String get liveDuelOpponentNotJoined;

  /// No description provided for @liveDuelAccepting.
  ///
  /// In en, this message translates to:
  /// **'Accepting...'**
  String get liveDuelAccepting;

  /// No description provided for @liveDuelAcceptDuel.
  ///
  /// In en, this message translates to:
  /// **'Accept duel'**
  String get liveDuelAcceptDuel;

  /// No description provided for @liveDuelSaving.
  ///
  /// In en, this message translates to:
  /// **'Saving...'**
  String get liveDuelSaving;

  /// No description provided for @liveDuelUnready.
  ///
  /// In en, this message translates to:
  /// **'Unready'**
  String get liveDuelUnready;

  /// No description provided for @liveDuelReady.
  ///
  /// In en, this message translates to:
  /// **'Ready'**
  String get liveDuelReady;

  /// No description provided for @liveDuelAcceptFirstThenReady.
  ///
  /// In en, this message translates to:
  /// **'Accept first, then mark Ready.'**
  String get liveDuelAcceptFirstThenReady;

  /// No description provided for @liveDuelGo.
  ///
  /// In en, this message translates to:
  /// **'GO!'**
  String get liveDuelGo;

  /// No description provided for @liveDuelStartingIn.
  ///
  /// In en, this message translates to:
  /// **'Starting in {value}...'**
  String liveDuelStartingIn(Object value);

  /// No description provided for @liveDuelStartingMatch.
  ///
  /// In en, this message translates to:
  /// **'Starting match...'**
  String get liveDuelStartingMatch;

  /// No description provided for @liveDuelWaitingRoom.
  ///
  /// In en, this message translates to:
  /// **'Waiting Room'**
  String get liveDuelWaitingRoom;

  /// No description provided for @liveDuelGetReady.
  ///
  /// In en, this message translates to:
  /// **'Get Ready'**
  String get liveDuelGetReady;

  /// No description provided for @liveDuelMatchStarted.
  ///
  /// In en, this message translates to:
  /// **'Match Started'**
  String get liveDuelMatchStarted;

  /// No description provided for @liveDuelMatchResult.
  ///
  /// In en, this message translates to:
  /// **'Match Result'**
  String get liveDuelMatchResult;

  /// No description provided for @liveDuelMatchCancelled.
  ///
  /// In en, this message translates to:
  /// **'Match Cancelled'**
  String get liveDuelMatchCancelled;

  /// No description provided for @liveDuelYouAbandoned.
  ///
  /// In en, this message translates to:
  /// **'You abandoned'**
  String get liveDuelYouAbandoned;

  /// No description provided for @liveDuelYouWonSmiley.
  ///
  /// In en, this message translates to:
  /// **'You won '**
  String get liveDuelYouWonSmiley;

  /// No description provided for @liveDuelDraw.
  ///
  /// In en, this message translates to:
  /// **'Draw'**
  String get liveDuelDraw;

  /// No description provided for @liveDuelDefeat.
  ///
  /// In en, this message translates to:
  /// **'Defeat'**
  String get liveDuelDefeat;

  /// No description provided for @liveDuelDefeatByAbandon.
  ///
  /// In en, this message translates to:
  /// **'Defeat by abandon'**
  String get liveDuelDefeatByAbandon;

  /// No description provided for @liveDuelWinByAbandon.
  ///
  /// In en, this message translates to:
  /// **'Win by abandon'**
  String get liveDuelWinByAbandon;

  /// No description provided for @liveDuelYouWonDuel.
  ///
  /// In en, this message translates to:
  /// **'You won the duel'**
  String get liveDuelYouWonDuel;

  /// No description provided for @liveDuelNoWinner.
  ///
  /// In en, this message translates to:
  /// **'No winner'**
  String get liveDuelNoWinner;

  /// No description provided for @liveDuelYouLost.
  ///
  /// In en, this message translates to:
  /// **'You lost'**
  String get liveDuelYouLost;

  /// No description provided for @liveDuelYourTime.
  ///
  /// In en, this message translates to:
  /// **'Your time'**
  String get liveDuelYourTime;

  /// No description provided for @liveDuelOpponentTime.
  ///
  /// In en, this message translates to:
  /// **'Opponent time'**
  String get liveDuelOpponentTime;

  /// No description provided for @liveDuelCouldNotCreateRematch.
  ///
  /// In en, this message translates to:
  /// **'Could not create rematch'**
  String get liveDuelCouldNotCreateRematch;

  /// No description provided for @liveDuelOpponentBusyAnother.
  ///
  /// In en, this message translates to:
  /// **'Opponent is busy in another duel'**
  String get liveDuelOpponentBusyAnother;

  /// No description provided for @liveDuelFinishActiveFirst.
  ///
  /// In en, this message translates to:
  /// **'Finish your active duel first'**
  String get liveDuelFinishActiveFirst;

  /// No description provided for @liveDuelCreatingRematch.
  ///
  /// In en, this message translates to:
  /// **'Creating rematch...'**
  String get liveDuelCreatingRematch;

  /// No description provided for @liveDuelRematch.
  ///
  /// In en, this message translates to:
  /// **'Rematch'**
  String get liveDuelRematch;

  /// No description provided for @liveDuelBack.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get liveDuelBack;

  /// No description provided for @liveDuelEmoteCooldown.
  ///
  /// In en, this message translates to:
  /// **'Emote cooldown'**
  String get liveDuelEmoteCooldown;

  /// No description provided for @liveDuelCouldNotSendEmote.
  ///
  /// In en, this message translates to:
  /// **'Could not send emote'**
  String get liveDuelCouldNotSendEmote;

  /// No description provided for @liveDuelInviteExpired.
  ///
  /// In en, this message translates to:
  /// **'Invitation expired'**
  String get liveDuelInviteExpired;

  /// No description provided for @liveDuelCountdownExpired.
  ///
  /// In en, this message translates to:
  /// **'Countdown expired'**
  String get liveDuelCountdownExpired;

  /// No description provided for @liveDuelMatchTimedOut.
  ///
  /// In en, this message translates to:
  /// **'Match timed out'**
  String get liveDuelMatchTimedOut;

  /// No description provided for @liveDuelCancelled.
  ///
  /// In en, this message translates to:
  /// **'Duel cancelled'**
  String get liveDuelCancelled;

  /// No description provided for @liveDuelStateInvited.
  ///
  /// In en, this message translates to:
  /// **'Invited'**
  String get liveDuelStateInvited;

  /// No description provided for @liveDuelStateJoined.
  ///
  /// In en, this message translates to:
  /// **'Joined'**
  String get liveDuelStateJoined;

  /// No description provided for @liveDuelStateReady.
  ///
  /// In en, this message translates to:
  /// **'Ready'**
  String get liveDuelStateReady;

  /// No description provided for @liveDuelStatePlaying.
  ///
  /// In en, this message translates to:
  /// **'Playing'**
  String get liveDuelStatePlaying;

  /// No description provided for @liveDuelStateFinished.
  ///
  /// In en, this message translates to:
  /// **'Finished'**
  String get liveDuelStateFinished;

  /// No description provided for @liveDuelStateAbandoned.
  ///
  /// In en, this message translates to:
  /// **'Abandoned'**
  String get liveDuelStateAbandoned;

  /// No description provided for @victoryChallengeOnlyLevelRuns.
  ///
  /// In en, this message translates to:
  /// **'This challenge is only available for level runs.'**
  String get victoryChallengeOnlyLevelRuns;

  /// No description provided for @victoryAddFriendsFirst.
  ///
  /// In en, this message translates to:
  /// **'Add friends first to send in-game challenges.'**
  String get victoryAddFriendsFirst;

  /// No description provided for @victoryChallengeFriendTitle.
  ///
  /// In en, this message translates to:
  /// **'Challenge a friend'**
  String get victoryChallengeFriendTitle;

  /// No description provided for @victoryChallengeFriendSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Send a live duel invite with a random puzzle'**
  String get victoryChallengeFriendSubtitle;

  /// No description provided for @victoryInviteOnline.
  ///
  /// In en, this message translates to:
  /// **'Invite to a live 1v1 duel - Online'**
  String get victoryInviteOnline;

  /// No description provided for @victoryInviteOffline.
  ///
  /// In en, this message translates to:
  /// **'Invite to a live 1v1 duel - Offline'**
  String get victoryInviteOffline;

  /// No description provided for @victoryLiveInviteSent.
  ///
  /// In en, this message translates to:
  /// **'Live duel invite sent'**
  String get victoryLiveInviteSent;

  /// No description provided for @victoryChallengeSendError.
  ///
  /// In en, this message translates to:
  /// **'Could not send challenge right now'**
  String get victoryChallengeSendError;

  /// No description provided for @victoryChallengeBlockedByRules.
  ///
  /// In en, this message translates to:
  /// **'Challenge blocked by Firestore rules'**
  String get victoryChallengeBlockedByRules;

  /// No description provided for @victoryChallengeSetupNotReady.
  ///
  /// In en, this message translates to:
  /// **'Challenge setup is not ready yet. Try again in a moment.'**
  String get victoryChallengeSetupNotReady;

  /// No description provided for @victoryFinishActiveDuelFirst.
  ///
  /// In en, this message translates to:
  /// **'Finish your active duel first'**
  String get victoryFinishActiveDuelFirst;

  /// No description provided for @victoryFriendAlreadyInDuel.
  ///
  /// In en, this message translates to:
  /// **'{name} is already in another duel'**
  String victoryFriendAlreadyInDuel(Object name);

  /// No description provided for @victoryNoPuzzlesForDuel.
  ///
  /// In en, this message translates to:
  /// **'No puzzles available for duel'**
  String get victoryNoPuzzlesForDuel;

  /// No description provided for @victoryStatTime.
  ///
  /// In en, this message translates to:
  /// **'Time'**
  String get victoryStatTime;

  /// No description provided for @victoryStatBestTime.
  ///
  /// In en, this message translates to:
  /// **'Best time'**
  String get victoryStatBestTime;

  /// No description provided for @victoryCoinsWithAd.
  ///
  /// In en, this message translates to:
  /// **'Coins (+{coins} ad)'**
  String victoryCoinsWithAd(int coins);

  /// No description provided for @victoryCoinsReward.
  ///
  /// In en, this message translates to:
  /// **'Coins reward'**
  String get victoryCoinsReward;

  /// No description provided for @victoryLevelComplete.
  ///
  /// In en, this message translates to:
  /// **'LEVEL COMPLETE'**
  String get victoryLevelComplete;

  /// No description provided for @victoryCurrentStreak.
  ///
  /// In en, this message translates to:
  /// **'Current streak: {streak}'**
  String victoryCurrentStreak(int streak);

  /// No description provided for @victoryFriendsRanking.
  ///
  /// In en, this message translates to:
  /// **'Friends ranking'**
  String get victoryFriendsRanking;

  /// No description provided for @victoryReplay.
  ///
  /// In en, this message translates to:
  /// **'Replay'**
  String get victoryReplay;

  /// No description provided for @victoryChallengeFriendCta.
  ///
  /// In en, this message translates to:
  /// **'Challenge Friend'**
  String get victoryChallengeFriendCta;

  /// No description provided for @socialTitle.
  ///
  /// In en, this message translates to:
  /// **'Social'**
  String get socialTitle;

  /// No description provided for @socialHubTitle.
  ///
  /// In en, this message translates to:
  /// **'Social Hub'**
  String get socialHubTitle;

  /// No description provided for @socialHubSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Friends, rankings and challenges'**
  String get socialHubSubtitle;

  /// No description provided for @socialFriendsLabel.
  ///
  /// In en, this message translates to:
  /// **'Friends'**
  String get socialFriendsLabel;

  /// No description provided for @socialBestRankLabel.
  ///
  /// In en, this message translates to:
  /// **'Best Rank'**
  String get socialBestRankLabel;

  /// No description provided for @socialTopTimeLabel.
  ///
  /// In en, this message translates to:
  /// **'Top Time'**
  String get socialTopTimeLabel;

  /// No description provided for @socialGlobalTierLabel.
  ///
  /// In en, this message translates to:
  /// **'Global Tier'**
  String get socialGlobalTierLabel;

  /// No description provided for @socialFriendActionsTitle.
  ///
  /// In en, this message translates to:
  /// **'Friend Actions'**
  String get socialFriendActionsTitle;

  /// No description provided for @socialFriendActionsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Set your handle and add friends by username or UID'**
  String get socialFriendActionsSubtitle;

  /// No description provided for @socialSetUsernameHint.
  ///
  /// In en, this message translates to:
  /// **'Set your username'**
  String get socialSetUsernameHint;

  /// No description provided for @socialSave.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get socialSave;

  /// No description provided for @socialFriendLookupHint.
  ///
  /// In en, this message translates to:
  /// **'Friend username, email or UID'**
  String get socialFriendLookupHint;

  /// No description provided for @socialAdd.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get socialAdd;

  /// No description provided for @socialFriendsSectionTitle.
  ///
  /// In en, this message translates to:
  /// **'Friends'**
  String get socialFriendsSectionTitle;

  /// No description provided for @socialFriendsSectionSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Your rivals and teammates'**
  String get socialFriendsSectionSubtitle;

  /// No description provided for @socialFriendsWithCount.
  ///
  /// In en, this message translates to:
  /// **'Friends ({count})'**
  String socialFriendsWithCount(int count);

  /// No description provided for @socialNoFriendsTitle.
  ///
  /// In en, this message translates to:
  /// **'No friends added yet'**
  String get socialNoFriendsTitle;

  /// No description provided for @socialNoFriendsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Add friends to compete on rankings and send challenges.'**
  String get socialNoFriendsSubtitle;

  /// No description provided for @socialGlobalTop10Title.
  ///
  /// In en, this message translates to:
  /// **'Global Top 10'**
  String get socialGlobalTop10Title;

  /// No description provided for @socialGlobalTop10Subtitle.
  ///
  /// In en, this message translates to:
  /// **'Best players in the world'**
  String get socialGlobalTop10Subtitle;

  /// No description provided for @socialNoGlobalScoresTitle.
  ///
  /// In en, this message translates to:
  /// **'No global scores yet'**
  String get socialNoGlobalScoresTitle;

  /// No description provided for @socialNoGlobalScoresSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Complete levels to appear in the world ranking.'**
  String get socialNoGlobalScoresSubtitle;

  /// No description provided for @socialChallengesTitle.
  ///
  /// In en, this message translates to:
  /// **'Challenges'**
  String get socialChallengesTitle;

  /// No description provided for @socialChallengesSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Invite or challenge your friends now'**
  String get socialChallengesSubtitle;

  /// No description provided for @socialChallengeFriend.
  ///
  /// In en, this message translates to:
  /// **'Challenge Friend'**
  String get socialChallengeFriend;

  /// No description provided for @socialInviteFriend.
  ///
  /// In en, this message translates to:
  /// **'Invite Friend'**
  String get socialInviteFriend;

  /// No description provided for @socialFriendRequestTitle.
  ///
  /// In en, this message translates to:
  /// **'Friend Request'**
  String get socialFriendRequestTitle;

  /// No description provided for @socialFriendRequestSent.
  ///
  /// In en, this message translates to:
  /// **'Friend request sent'**
  String get socialFriendRequestSent;

  /// No description provided for @socialCouldNotSendRequest.
  ///
  /// In en, this message translates to:
  /// **'Could not send friend request'**
  String get socialCouldNotSendRequest;

  /// No description provided for @socialCannotAddSelf.
  ///
  /// In en, this message translates to:
  /// **'You can\'t add yourself'**
  String get socialCannotAddSelf;

  /// No description provided for @socialInvalidEmail.
  ///
  /// In en, this message translates to:
  /// **'Invalid email format'**
  String get socialInvalidEmail;

  /// No description provided for @socialUserNotFound.
  ///
  /// In en, this message translates to:
  /// **'User not found'**
  String get socialUserNotFound;

  /// No description provided for @socialAlreadyFriends.
  ///
  /// In en, this message translates to:
  /// **'You are already friends'**
  String get socialAlreadyFriends;

  /// No description provided for @socialRequestAlreadySent.
  ///
  /// In en, this message translates to:
  /// **'Friend request already sent'**
  String get socialRequestAlreadySent;

  /// No description provided for @socialRequestAlreadyReceived.
  ///
  /// In en, this message translates to:
  /// **'This user already sent you a request'**
  String get socialRequestAlreadyReceived;

  /// No description provided for @socialNeedSignIn.
  ///
  /// In en, this message translates to:
  /// **'You need to be signed in'**
  String get socialNeedSignIn;

  /// No description provided for @socialRulesBlockedAction.
  ///
  /// In en, this message translates to:
  /// **'Firestore rules blocked this action'**
  String get socialRulesBlockedAction;

  /// No description provided for @socialAddFriendsFirstForChallenges.
  ///
  /// In en, this message translates to:
  /// **'Add friends first to send challenges.'**
  String get socialAddFriendsFirstForChallenges;

  /// No description provided for @socialChallengeFriendSheetTitle.
  ///
  /// In en, this message translates to:
  /// **'Challenge a friend'**
  String get socialChallengeFriendSheetTitle;

  /// No description provided for @socialChallengeFriendSheetSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Send a real-time live duel invite'**
  String get socialChallengeFriendSheetSubtitle;

  /// No description provided for @socialLiveInviteOnline.
  ///
  /// In en, this message translates to:
  /// **'Invite to a live 1v1 duel - Online'**
  String get socialLiveInviteOnline;

  /// No description provided for @socialLiveInviteOffline.
  ///
  /// In en, this message translates to:
  /// **'Invite to a live 1v1 duel - Offline'**
  String get socialLiveInviteOffline;

  /// No description provided for @socialLiveInviteSentTitle.
  ///
  /// In en, this message translates to:
  /// **'Live duel invite sent'**
  String get socialLiveInviteSentTitle;

  /// No description provided for @socialLiveInviteSentBody.
  ///
  /// In en, this message translates to:
  /// **'Waiting for {name} to accept.'**
  String socialLiveInviteSentBody(Object name);

  /// No description provided for @socialCouldNotSendChallenge.
  ///
  /// In en, this message translates to:
  /// **'Could not send challenge right now.'**
  String get socialCouldNotSendChallenge;

  /// No description provided for @socialChallengeBlockedByRules.
  ///
  /// In en, this message translates to:
  /// **'Challenge blocked by Firestore rules.'**
  String get socialChallengeBlockedByRules;

  /// No description provided for @socialChallengeSetupNotReady.
  ///
  /// In en, this message translates to:
  /// **'Challenge setup is not ready yet. Try again in a moment.'**
  String get socialChallengeSetupNotReady;

  /// No description provided for @socialFinishCurrentLiveDuelFirst.
  ///
  /// In en, this message translates to:
  /// **'Finish your current live duel first.'**
  String get socialFinishCurrentLiveDuelFirst;

  /// No description provided for @socialFriendAlreadyInLiveDuel.
  ///
  /// In en, this message translates to:
  /// **'{name} is already in another live duel.'**
  String socialFriendAlreadyInLiveDuel(Object name);

  /// No description provided for @socialNoPuzzlesForLiveDuel.
  ///
  /// In en, this message translates to:
  /// **'No puzzles available for live duel.'**
  String get socialNoPuzzlesForLiveDuel;

  /// No description provided for @socialRemoveFriendTitle.
  ///
  /// In en, this message translates to:
  /// **'Remove friend'**
  String get socialRemoveFriendTitle;

  /// No description provided for @socialRemoveFriendBody.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to remove this friend\''**
  String get socialRemoveFriendBody;

  /// No description provided for @socialUsernameTitle.
  ///
  /// In en, this message translates to:
  /// **'Username'**
  String get socialUsernameTitle;

  /// No description provided for @socialUsernameNotAvailable.
  ///
  /// In en, this message translates to:
  /// **'Username not available'**
  String get socialUsernameNotAvailable;

  /// No description provided for @socialUsernameUpdated.
  ///
  /// In en, this message translates to:
  /// **'Username updated'**
  String get socialUsernameUpdated;

  /// No description provided for @socialUsernameAlreadyUsed.
  ///
  /// In en, this message translates to:
  /// **'Username already in use'**
  String get socialUsernameAlreadyUsed;

  /// No description provided for @socialUsernameInvalid.
  ///
  /// In en, this message translates to:
  /// **'Invalid username (3-20, letters/numbers/._)'**
  String get socialUsernameInvalid;

  /// No description provided for @socialRulesBlockedUsernameWrite.
  ///
  /// In en, this message translates to:
  /// **'Firestore rules blocked username write'**
  String get socialRulesBlockedUsernameWrite;

  /// No description provided for @socialCouldNotSaveUsername.
  ///
  /// In en, this message translates to:
  /// **'Could not save username'**
  String get socialCouldNotSaveUsername;

  /// No description provided for @socialInviteReadyTitle.
  ///
  /// In en, this message translates to:
  /// **'Invite Ready'**
  String get socialInviteReadyTitle;

  /// No description provided for @socialInviteReadyBody.
  ///
  /// In en, this message translates to:
  /// **'Invite copied. Share it on WhatsApp or email.'**
  String get socialInviteReadyBody;

  /// No description provided for @socialMovesShort.
  ///
  /// In en, this message translates to:
  /// **'{count} moves'**
  String socialMovesShort(int count);

  /// No description provided for @socialStarsShort.
  ///
  /// In en, this message translates to:
  /// **'{count} stars'**
  String socialStarsShort(int count);

  /// No description provided for @socialGuestLockedTitle.
  ///
  /// In en, this message translates to:
  /// **'Social is locked in Guest mode'**
  String get socialGuestLockedTitle;

  /// No description provided for @socialGuestLockedSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Sign in with Google from Home to challenge friends and view rankings.'**
  String get socialGuestLockedSubtitle;

  /// No description provided for @socialGoHome.
  ///
  /// In en, this message translates to:
  /// **'Go Home'**
  String get socialGoHome;

  /// No description provided for @socialSkinTrail.
  ///
  /// In en, this message translates to:
  /// **'Skin: {skin} - Trail: {trail}'**
  String socialSkinTrail(Object skin, Object trail);

  /// No description provided for @socialOnline.
  ///
  /// In en, this message translates to:
  /// **'Online'**
  String get socialOnline;

  /// No description provided for @socialOffline.
  ///
  /// In en, this message translates to:
  /// **'Offline'**
  String get socialOffline;

  /// No description provided for @socialStatusLabel.
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get socialStatusLabel;

  /// No description provided for @socialSkinLabel.
  ///
  /// In en, this message translates to:
  /// **'Skin'**
  String get socialSkinLabel;

  /// No description provided for @socialTrailLabel.
  ///
  /// In en, this message translates to:
  /// **'Trail'**
  String get socialTrailLabel;

  /// No description provided for @socialReadyToCompete.
  ///
  /// In en, this message translates to:
  /// **'Ready to compete'**
  String get socialReadyToCompete;

  /// No description provided for @energyNoEnergyTitle.
  ///
  /// In en, this message translates to:
  /// **'No energy'**
  String get energyNoEnergyTitle;

  /// No description provided for @energyOutWithBattery.
  ///
  /// In en, this message translates to:
  /// **'You are out of energy. Wait {reset} for reset, or use a battery now.'**
  String energyOutWithBattery(Object reset);

  /// No description provided for @energyOutWithoutBattery.
  ///
  /// In en, this message translates to:
  /// **'You are out of energy. Wait {reset} for reset, or buy a battery.'**
  String energyOutWithoutBattery(Object reset);

  /// No description provided for @energyCouldNotUseBattery.
  ///
  /// In en, this message translates to:
  /// **'Could not use battery right now.'**
  String get energyCouldNotUseBattery;

  /// No description provided for @energyRestored.
  ///
  /// In en, this message translates to:
  /// **'Energy restored to {current}/{max}.'**
  String energyRestored(int current, int max);

  /// No description provided for @energyUseBattery.
  ///
  /// In en, this message translates to:
  /// **'Use battery'**
  String get energyUseBattery;

  /// No description provided for @energyNotEnoughCoinsBattery.
  ///
  /// In en, this message translates to:
  /// **'Not enough coins to buy a battery.'**
  String get energyNotEnoughCoinsBattery;

  /// No description provided for @energyBatteryPurchaseFailed.
  ///
  /// In en, this message translates to:
  /// **'Battery purchase failed. Try again.'**
  String get energyBatteryPurchaseFailed;

  /// No description provided for @energyBatteryPurchasedAndUsed.
  ///
  /// In en, this message translates to:
  /// **'Battery purchased and used. Energy {current}/{max}.'**
  String energyBatteryPurchasedAndUsed(int current, int max);

  /// No description provided for @energyBatteryPurchasedCount.
  ///
  /// In en, this message translates to:
  /// **'Battery purchased. Batteries: {count}.'**
  String energyBatteryPurchasedCount(int count);

  /// No description provided for @energyBuyBattery.
  ///
  /// In en, this message translates to:
  /// **'Buy ({coins} coins)'**
  String energyBuyBattery(int coins);

  /// No description provided for @playLevelsCompletedToGo.
  ///
  /// In en, this message translates to:
  /// **'{completed} completed - {remaining} to go'**
  String playLevelsCompletedToGo(int completed, int remaining);

  /// No description provided for @playLevelsContinueLevel.
  ///
  /// In en, this message translates to:
  /// **'Continue L{level}'**
  String playLevelsContinueLevel(int level);

  /// No description provided for @playLevelsRanking.
  ///
  /// In en, this message translates to:
  /// **'Ranking'**
  String get playLevelsRanking;

  /// No description provided for @commonCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get commonCancel;

  /// No description provided for @commonClose.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get commonClose;

  /// No description provided for @commonNo.
  ///
  /// In en, this message translates to:
  /// **'No'**
  String get commonNo;

  /// No description provided for @commonOk.
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get commonOk;

  /// No description provided for @commonReload.
  ///
  /// In en, this message translates to:
  /// **'Reload'**
  String get commonReload;

  /// No description provided for @commonRetry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get commonRetry;

  /// No description provided for @commonYes.
  ///
  /// In en, this message translates to:
  /// **'Yes'**
  String get commonYes;

  /// No description provided for @gameGotIt.
  ///
  /// In en, this message translates to:
  /// **'Got it'**
  String get gameGotIt;

  /// No description provided for @gameHowToPlayTitle.
  ///
  /// In en, this message translates to:
  /// **'How to play'**
  String get gameHowToPlayTitle;

  /// No description provided for @gameCoreTutorialBody.
  ///
  /// In en, this message translates to:
  /// **'1) Start at number 1.\n2) Drag to connect numbers in order (1,2,3...).\n3) Even with few numbers, you must fill every cell of the board.\n4) If you make a mistake, use Undo or Restart.'**
  String get gameCoreTutorialBody;

  /// No description provided for @gameLetsGo.
  ///
  /// In en, this message translates to:
  /// **'Let\'s go'**
  String get gameLetsGo;

  /// No description provided for @gameVariantAlphabetTitle.
  ///
  /// In en, this message translates to:
  /// **'Alphabet Mode'**
  String get gameVariantAlphabetTitle;

  /// No description provided for @gameVariantAlphabetBody.
  ///
  /// In en, this message translates to:
  /// **'Connect cells in alphabetical order following the path clues.'**
  String get gameVariantAlphabetBody;

  /// No description provided for @gameVariantAlphabetReverseTitle.
  ///
  /// In en, this message translates to:
  /// **'Reverse Alphabet Mode'**
  String get gameVariantAlphabetReverseTitle;

  /// No description provided for @gameVariantAlphabetReverseBody.
  ///
  /// In en, this message translates to:
  /// **'Connect cells in reverse alphabetical order.'**
  String get gameVariantAlphabetReverseBody;

  /// No description provided for @gameVariantMultiplesTitle.
  ///
  /// In en, this message translates to:
  /// **'Multiples Mode'**
  String get gameVariantMultiplesTitle;

  /// No description provided for @gameVariantMultiplesBody.
  ///
  /// In en, this message translates to:
  /// **'Numbers are multiples of a base. Follow increasing multiples in order.'**
  String get gameVariantMultiplesBody;

  /// No description provided for @gameVariantRomanMultiplesTitle.
  ///
  /// In en, this message translates to:
  /// **'Roman Multiples Mode'**
  String get gameVariantRomanMultiplesTitle;

  /// No description provided for @gameVariantRomanMultiplesBody.
  ///
  /// In en, this message translates to:
  /// **'Follow increasing multiples shown as roman numerals.'**
  String get gameVariantRomanMultiplesBody;

  /// No description provided for @gameVariantRomanTitle.
  ///
  /// In en, this message translates to:
  /// **'Roman Numerals Mode'**
  String get gameVariantRomanTitle;

  /// No description provided for @gameVariantRomanBody.
  ///
  /// In en, this message translates to:
  /// **'Follow the sequence of roman numerals in order.'**
  String get gameVariantRomanBody;

  /// No description provided for @gameVariantDefaultTitle.
  ///
  /// In en, this message translates to:
  /// **'Variant Mode'**
  String get gameVariantDefaultTitle;

  /// No description provided for @gameVariantDefaultBody.
  ///
  /// In en, this message translates to:
  /// **'Follow the clue sequence in the correct order.'**
  String get gameVariantDefaultBody;

  /// No description provided for @gameVariantExample.
  ///
  /// In en, this message translates to:
  /// **'Example: {example}'**
  String gameVariantExample(Object example);

  /// No description provided for @gamePackNotFound.
  ///
  /// In en, this message translates to:
  /// **'Pack not found'**
  String get gamePackNotFound;

  /// No description provided for @gameLoadingLevel.
  ///
  /// In en, this message translates to:
  /// **'Loading level'**
  String get gameLoadingLevel;

  /// No description provided for @gameLevelUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Level unavailable'**
  String get gameLevelUnavailable;

  /// No description provided for @gameCouldNotLoadLevel.
  ///
  /// In en, this message translates to:
  /// **'Could not load this level.'**
  String get gameCouldNotLoadLevel;

  /// No description provided for @gameEnergyCounter.
  ///
  /// In en, this message translates to:
  /// **'Energy {current}/{max}'**
  String gameEnergyCounter(int current, int max);

  /// No description provided for @gameEnergyResetIn.
  ///
  /// In en, this message translates to:
  /// **'Reset {time}'**
  String gameEnergyResetIn(Object time);

  /// No description provided for @gameDuelFinishedBoardLocked.
  ///
  /// In en, this message translates to:
  /// **'Duel finished. Board locked.'**
  String get gameDuelFinishedBoardLocked;

  /// No description provided for @gameUndo.
  ///
  /// In en, this message translates to:
  /// **'Undo'**
  String get gameUndo;

  /// No description provided for @gameRestart.
  ///
  /// In en, this message translates to:
  /// **'Restart'**
  String get gameRestart;

  /// No description provided for @gameHintInfinite.
  ///
  /// In en, this message translates to:
  /// **'Hint (INF)'**
  String get gameHintInfinite;

  /// No description provided for @gameHintCount.
  ///
  /// In en, this message translates to:
  /// **'Hint ({count})'**
  String gameHintCount(int count);

  /// No description provided for @gameReporting.
  ///
  /// In en, this message translates to:
  /// **'Reporting...'**
  String get gameReporting;

  /// No description provided for @gameReported.
  ///
  /// In en, this message translates to:
  /// **'Reported'**
  String get gameReported;

  /// No description provided for @gameReportLevel.
  ///
  /// In en, this message translates to:
  /// **'Report level'**
  String get gameReportLevel;

  /// No description provided for @gameWatchAd.
  ///
  /// In en, this message translates to:
  /// **'Watch Ad'**
  String get gameWatchAd;

  /// No description provided for @gameAdStatus.
  ///
  /// In en, this message translates to:
  /// **'Ad Status'**
  String get gameAdStatus;

  /// No description provided for @gameDailyAdLimitReached.
  ///
  /// In en, this message translates to:
  /// **'Daily limit reached. No more ads available today.'**
  String get gameDailyAdLimitReached;

  /// No description provided for @gameNextAdIn.
  ///
  /// In en, this message translates to:
  /// **'Next ad in {time}'**
  String gameNextAdIn(Object time);

  /// No description provided for @gameLevelCompleteReward.
  ///
  /// In en, this message translates to:
  /// **'LEVEL COMPLETE! {reward}'**
  String gameLevelCompleteReward(Object reward);

  /// No description provided for @gameRankingUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Ranking unavailable'**
  String get gameRankingUnavailable;

  /// No description provided for @gameTryAgainMoment.
  ///
  /// In en, this message translates to:
  /// **'Try again in a moment.'**
  String get gameTryAgainMoment;

  /// No description provided for @gameFriendsRanking.
  ///
  /// In en, this message translates to:
  /// **'Friends ranking'**
  String get gameFriendsRanking;

  /// No description provided for @gameLevelLabel.
  ///
  /// In en, this message translates to:
  /// **'Level {level}'**
  String gameLevelLabel(int level);

  /// No description provided for @gameNoFriendsRankingTitle.
  ///
  /// In en, this message translates to:
  /// **'No friends have played this level yet.'**
  String get gameNoFriendsRankingTitle;

  /// No description provided for @gameNoFriendsRankingBody.
  ///
  /// In en, this message translates to:
  /// **'Complete the level and invite friends to compete.'**
  String get gameNoFriendsRankingBody;

  /// No description provided for @gameReportUnavailableTitle.
  ///
  /// In en, this message translates to:
  /// **'Report unavailable'**
  String get gameReportUnavailableTitle;

  /// No description provided for @gameReportUnavailableBody.
  ///
  /// In en, this message translates to:
  /// **'Play at least {seconds} seconds before reporting this level.'**
  String gameReportUnavailableBody(int seconds);

  /// No description provided for @gameReportConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Report this level\''**
  String get gameReportConfirmTitle;

  /// No description provided for @gameReportConfirmBody.
  ///
  /// In en, this message translates to:
  /// **'If this level is unsolvable, you can report it and unlock the next one.'**
  String get gameReportConfirmBody;

  /// No description provided for @gameReportAndSkip.
  ///
  /// In en, this message translates to:
  /// **'Report & Skip'**
  String get gameReportAndSkip;

  /// No description provided for @gameSignInRequiredTitle.
  ///
  /// In en, this message translates to:
  /// **'Sign-in required'**
  String get gameSignInRequiredTitle;

  /// No description provided for @gameSignInRequiredBody.
  ///
  /// In en, this message translates to:
  /// **'Please sign in to report and skip levels.'**
  String get gameSignInRequiredBody;

  /// No description provided for @gameAlreadyReportedTitle.
  ///
  /// In en, this message translates to:
  /// **'Already reported'**
  String get gameAlreadyReportedTitle;

  /// No description provided for @gameAlreadyReportedBody.
  ///
  /// In en, this message translates to:
  /// **'This level was already reported from this account.'**
  String get gameAlreadyReportedBody;

  /// No description provided for @gameLevelReportedTitle.
  ///
  /// In en, this message translates to:
  /// **'Level reported'**
  String get gameLevelReportedTitle;

  /// No description provided for @gameLevelReportedBody.
  ///
  /// In en, this message translates to:
  /// **'Report sent. Next level unlocked.'**
  String get gameLevelReportedBody;

  /// No description provided for @gameCouldNotReportTitle.
  ///
  /// In en, this message translates to:
  /// **'Could not report level'**
  String get gameCouldNotReportTitle;

  /// No description provided for @gameReportErrorPermissionDenied.
  ///
  /// In en, this message translates to:
  /// **'Permissions blocked this action. Please try again later.'**
  String get gameReportErrorPermissionDenied;

  /// No description provided for @gameReportErrorEndpointNotConfigured.
  ///
  /// In en, this message translates to:
  /// **'Report endpoint is not configured in this build.'**
  String get gameReportErrorEndpointNotConfigured;

  /// No description provided for @gameReportErrorInvalidEndpoint.
  ///
  /// In en, this message translates to:
  /// **'Report endpoint URL is invalid.'**
  String get gameReportErrorInvalidEndpoint;

  /// No description provided for @gameReportErrorTimeout.
  ///
  /// In en, this message translates to:
  /// **'Report request timed out. Please retry.'**
  String get gameReportErrorTimeout;

  /// No description provided for @gameReportErrorNetwork.
  ///
  /// In en, this message translates to:
  /// **'Network issue while reporting. Please try again.'**
  String get gameReportErrorNetwork;

  /// No description provided for @gameReportErrorServerRejected.
  ///
  /// In en, this message translates to:
  /// **'Server rejected the report. Please try again in a moment.'**
  String get gameReportErrorServerRejected;

  /// No description provided for @gameReportErrorUnauthenticated.
  ///
  /// In en, this message translates to:
  /// **'Please sign in again and retry.'**
  String get gameReportErrorUnauthenticated;

  /// No description provided for @gameReportErrorGeneric.
  ///
  /// In en, this message translates to:
  /// **'Could not report this level right now. Please try again.'**
  String get gameReportErrorGeneric;

  /// No description provided for @gameHintTitle.
  ///
  /// In en, this message translates to:
  /// **'Hint'**
  String get gameHintTitle;

  /// No description provided for @gameNoHintsLeft.
  ///
  /// In en, this message translates to:
  /// **'No hints left'**
  String get gameNoHintsLeft;

  /// No description provided for @gameAlmostThereTitle.
  ///
  /// In en, this message translates to:
  /// **'Almost there'**
  String get gameAlmostThereTitle;

  /// No description provided for @gameAlmostThereBody.
  ///
  /// In en, this message translates to:
  /// **'Finish on {label} to complete the level.'**
  String gameAlmostThereBody(Object label);

  /// No description provided for @gameTimeTitle.
  ///
  /// In en, this message translates to:
  /// **'Time!'**
  String get gameTimeTitle;

  /// No description provided for @gameWaitingForDuelResult.
  ///
  /// In en, this message translates to:
  /// **'Waiting for duel result...'**
  String get gameWaitingForDuelResult;

  /// No description provided for @gameLevelAlreadyCompletedTitle.
  ///
  /// In en, this message translates to:
  /// **'Level already completed'**
  String get gameLevelAlreadyCompletedTitle;

  /// No description provided for @gameNoCoinRewardReplay.
  ///
  /// In en, this message translates to:
  /// **'No coin reward on replay'**
  String get gameNoCoinRewardReplay;

  /// No description provided for @gameNewBestTitle.
  ///
  /// In en, this message translates to:
  /// **'New best'**
  String get gameNewBestTitle;

  /// No description provided for @gameBeatYourGhost.
  ///
  /// In en, this message translates to:
  /// **'You beat your ghost!'**
  String get gameBeatYourGhost;

  /// No description provided for @gameAchievementUnlocked.
  ///
  /// In en, this message translates to:
  /// **'Achievement unlocked'**
  String get gameAchievementUnlocked;

  /// No description provided for @gameRewardedAdUnavailableTitle.
  ///
  /// In en, this message translates to:
  /// **'Rewarded ad unavailable'**
  String get gameRewardedAdUnavailableTitle;

  /// No description provided for @gameContinuingWithoutBonus.
  ///
  /// In en, this message translates to:
  /// **'Continuing without bonus.'**
  String get gameContinuingWithoutBonus;

  /// No description provided for @gameBonusRewardTitle.
  ///
  /// In en, this message translates to:
  /// **'Bonus reward'**
  String get gameBonusRewardTitle;

  /// No description provided for @gameBonusCoins.
  ///
  /// In en, this message translates to:
  /// **'+{coins} coins'**
  String gameBonusCoins(int coins);

  /// No description provided for @gameDailyLimitReachedTitle.
  ///
  /// In en, this message translates to:
  /// **'Daily limit reached'**
  String get gameDailyLimitReachedTitle;

  /// No description provided for @gameNoMoreAdsToday.
  ///
  /// In en, this message translates to:
  /// **'No more ads available today'**
  String get gameNoMoreAdsToday;

  /// No description provided for @gamePleaseWaitTitle.
  ///
  /// In en, this message translates to:
  /// **'Please wait'**
  String get gamePleaseWaitTitle;

  /// No description provided for @gameAdRewardTitle.
  ///
  /// In en, this message translates to:
  /// **'Ad reward'**
  String get gameAdRewardTitle;

  /// No description provided for @gameRewardedAdStatusTitle.
  ///
  /// In en, this message translates to:
  /// **'Rewarded ad status'**
  String get gameRewardedAdStatusTitle;

  /// No description provided for @gameRewardedAdStatusBody.
  ///
  /// In en, this message translates to:
  /// **'Loaded: {loaded}\nLoading: {loading}'**
  String gameRewardedAdStatusBody(Object loaded, Object loading);

  /// No description provided for @gameAdReloadRequestedTitle.
  ///
  /// In en, this message translates to:
  /// **'Ad reload requested'**
  String get gameAdReloadRequestedTitle;

  /// No description provided for @gameAdReloadRequestedBody.
  ///
  /// In en, this message translates to:
  /// **'Trying to load a rewarded ad.'**
  String get gameAdReloadRequestedBody;

  /// No description provided for @gameDuelYouWonTitle.
  ///
  /// In en, this message translates to:
  /// **'YOU WON!'**
  String get gameDuelYouWonTitle;

  /// No description provided for @gameDuelYouLostTitle.
  ///
  /// In en, this message translates to:
  /// **'YOU LOST ;('**
  String get gameDuelYouLostTitle;

  /// No description provided for @gameDuelYouFinishedFirst.
  ///
  /// In en, this message translates to:
  /// **'You finished first in the duel.'**
  String get gameDuelYouFinishedFirst;

  /// No description provided for @gameDuelFriendFinishedFirst.
  ///
  /// In en, this message translates to:
  /// **'Your friend finished first.'**
  String get gameDuelFriendFinishedFirst;

  /// No description provided for @gameLiveDuelFinishedWaiting.
  ///
  /// In en, this message translates to:
  /// **'Finished in {time}. Waiting result...'**
  String gameLiveDuelFinishedWaiting(Object time);

  /// No description provided for @gameLiveDuelResultTitle.
  ///
  /// In en, this message translates to:
  /// **'Live duel result'**
  String get gameLiveDuelResultTitle;

  /// No description provided for @gameOpponentAbandoned.
  ///
  /// In en, this message translates to:
  /// **'Opponent abandoned'**
  String get gameOpponentAbandoned;

  /// No description provided for @gameLevel.
  ///
  /// In en, this message translates to:
  /// **'Level'**
  String get gameLevel;

  /// No description provided for @gameOpponent.
  ///
  /// In en, this message translates to:
  /// **'Opponent'**
  String get gameOpponent;

  /// No description provided for @gamePlayer.
  ///
  /// In en, this message translates to:
  /// **'Player'**
  String get gamePlayer;

  /// No description provided for @gameEmotesAfterDuelResult.
  ///
  /// In en, this message translates to:
  /// **'Emotes available after duel result'**
  String get gameEmotesAfterDuelResult;

  /// No description provided for @gameEmoteLaugh.
  ///
  /// In en, this message translates to:
  /// **'Laugh'**
  String get gameEmoteLaugh;

  /// No description provided for @gameEmoteCool.
  ///
  /// In en, this message translates to:
  /// **'Cool'**
  String get gameEmoteCool;

  /// No description provided for @gameEmoteWow.
  ///
  /// In en, this message translates to:
  /// **'Wow'**
  String get gameEmoteWow;

  /// No description provided for @gameEmoteCry.
  ///
  /// In en, this message translates to:
  /// **'Cry'**
  String get gameEmoteCry;

  /// No description provided for @gameEmoteClap.
  ///
  /// In en, this message translates to:
  /// **'Clap'**
  String get gameEmoteClap;

  /// No description provided for @gameEmoteHeart.
  ///
  /// In en, this message translates to:
  /// **'Heart'**
  String get gameEmoteHeart;

  /// No description provided for @gameEnergyEmptyResetIn.
  ///
  /// In en, this message translates to:
  /// **'Energy empty. Reset in {time}.'**
  String gameEnergyEmptyResetIn(Object time);

  /// No description provided for @gameBatteries.
  ///
  /// In en, this message translates to:
  /// **'Batteries'**
  String get gameBatteries;

  /// No description provided for @gameGhostBest.
  ///
  /// In en, this message translates to:
  /// **'Ghost best: {time}'**
  String gameGhostBest(Object time);

  /// No description provided for @gameGhostOn.
  ///
  /// In en, this message translates to:
  /// **'Ghost: ON'**
  String get gameGhostOn;

  /// No description provided for @gameGhostOff.
  ///
  /// In en, this message translates to:
  /// **'Ghost: OFF'**
  String get gameGhostOff;

  /// No description provided for @gameGhostAvailableAfterFirst.
  ///
  /// In en, this message translates to:
  /// **'Ghost available after first completion'**
  String get gameGhostAvailableAfterFirst;

  /// No description provided for @gameNoRankingImpact.
  ///
  /// In en, this message translates to:
  /// **'No ranking impact'**
  String get gameNoRankingImpact;

  /// No description provided for @shopTrailEffects.
  ///
  /// In en, this message translates to:
  /// **'Trail Effects'**
  String get shopTrailEffects;

  /// No description provided for @shopCoinPacksUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Coin packs unavailable'**
  String get shopCoinPacksUnavailable;

  /// No description provided for @shopCouldNotLoadCoinPacksRetry.
  ///
  /// In en, this message translates to:
  /// **'Could not load coin packs. Please retry.'**
  String get shopCouldNotLoadCoinPacksRetry;

  /// No description provided for @shopCheckConnectionRetry.
  ///
  /// In en, this message translates to:
  /// **'Please check your connection and retry.'**
  String get shopCheckConnectionRetry;

  /// No description provided for @shopNoCoinPacksAvailable.
  ///
  /// In en, this message translates to:
  /// **'No coin packs available'**
  String get shopNoCoinPacksAvailable;

  /// No description provided for @shopStoreProductsUnavailableNow.
  ///
  /// In en, this message translates to:
  /// **'Store products are not available right now. Please try again later.'**
  String get shopStoreProductsUnavailableNow;

  /// No description provided for @shopRestore.
  ///
  /// In en, this message translates to:
  /// **'Restore'**
  String get shopRestore;

  /// No description provided for @shopLoadingStoreProducts.
  ///
  /// In en, this message translates to:
  /// **'Loading store products...'**
  String get shopLoadingStoreProducts;

  /// No description provided for @shopStoreUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Store unavailable'**
  String get shopStoreUnavailable;

  /// No description provided for @shopPurchasesDisabledBrowse.
  ///
  /// In en, this message translates to:
  /// **'You can still browse all coin packs. Purchases are disabled right now.'**
  String get shopPurchasesDisabledBrowse;

  /// No description provided for @shopShowingLocalCatalogFallback.
  ///
  /// In en, this message translates to:
  /// **'Showing local catalog fallback'**
  String get shopShowingLocalCatalogFallback;

  /// No description provided for @shopEnergyBatteries.
  ///
  /// In en, this message translates to:
  /// **'Energy batteries'**
  String get shopEnergyBatteries;

  /// No description provided for @shopBatteriesResetIn.
  ///
  /// In en, this message translates to:
  /// **'Batteries: {count} - Reset in {time}'**
  String shopBatteriesResetIn(int count, Object time);

  /// No description provided for @shopUseOneBatteryNow.
  ///
  /// In en, this message translates to:
  /// **'Use 1 battery now'**
  String get shopUseOneBatteryNow;

  /// No description provided for @shopProcessingPurchase.
  ///
  /// In en, this message translates to:
  /// **'Processing purchase...'**
  String get shopProcessingPurchase;

  /// No description provided for @shopPurchasedBatteries.
  ///
  /// In en, this message translates to:
  /// **'Purchased {units} battery(s). Total: {total}.'**
  String shopPurchasedBatteries(int units, int total);

  /// No description provided for @shopPurchaseSuccessful.
  ///
  /// In en, this message translates to:
  /// **'Purchase successful'**
  String get shopPurchaseSuccessful;

  /// No description provided for @shopConfirmPurchaseTitle.
  ///
  /// In en, this message translates to:
  /// **'Confirm purchase'**
  String get shopConfirmPurchaseTitle;

  /// No description provided for @shopConfirmPurchaseBody.
  ///
  /// In en, this message translates to:
  /// **'Do you want to buy \"{name}\" for {coins} coins\''**
  String shopConfirmPurchaseBody(Object name, int coins);

  /// No description provided for @shopBuyNow.
  ///
  /// In en, this message translates to:
  /// **'Buy now'**
  String get shopBuyNow;

  /// No description provided for @playWorldFallbackTitle.
  ///
  /// In en, this message translates to:
  /// **'World'**
  String get playWorldFallbackTitle;

  /// No description provided for @playWorldFallbackSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Puzzle journey'**
  String get playWorldFallbackSubtitle;

  /// No description provided for @playWorldTitle.
  ///
  /// In en, this message translates to:
  /// **'World {number}'**
  String playWorldTitle(int number);

  /// No description provided for @playWorldSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Puzzle journey {number}'**
  String playWorldSubtitle(int number);

  /// No description provided for @onboardingInProgress.
  ///
  /// In en, this message translates to:
  /// **'In progress'**
  String get onboardingInProgress;

  /// No description provided for @onboardingGoNow.
  ///
  /// In en, this message translates to:
  /// **'Go now'**
  String get onboardingGoNow;

  /// No description provided for @duelHistoryTimes.
  ///
  /// In en, this message translates to:
  /// **'You {youTime} Opp {opponentTime}'**
  String duelHistoryTimes(Object youTime, Object opponentTime);

  /// No description provided for @duelStatusVictory.
  ///
  /// In en, this message translates to:
  /// **'Victory'**
  String get duelStatusVictory;

  /// No description provided for @duelStatusDefeat.
  ///
  /// In en, this message translates to:
  /// **'Defeat'**
  String get duelStatusDefeat;

  /// No description provided for @playLevelsWorldLockedCompletePrevious.
  ///
  /// In en, this message translates to:
  /// **'World locked. Complete or report all levels in previous world first.'**
  String get playLevelsWorldLockedCompletePrevious;

  /// No description provided for @playLevelsEnergyStatus.
  ///
  /// In en, this message translates to:
  /// **'{current}/{max} - reset {time}'**
  String playLevelsEnergyStatus(int current, int max, Object time);

  /// No description provided for @playLevelsWorldProgressSummary.
  ///
  /// In en, this message translates to:
  /// **'{total} levels - {completed} completed'**
  String playLevelsWorldProgressSummary(int total, int completed);

  /// No description provided for @playLevelsEnergyDetailed.
  ///
  /// In en, this message translates to:
  /// **'Energy {current}/{max}. Reset in {time}.'**
  String playLevelsEnergyDetailed(int current, int max, Object time);

  /// No description provided for @playLevelsSelectedLevel.
  ///
  /// In en, this message translates to:
  /// **'Selected Level'**
  String get playLevelsSelectedLevel;

  /// No description provided for @playLevelsSelectedLevelVariant.
  ///
  /// In en, this message translates to:
  /// **'Level {level} {variant}'**
  String playLevelsSelectedLevelVariant(int level, Object variant);

  /// No description provided for @playLevelsPlay.
  ///
  /// In en, this message translates to:
  /// **'Play'**
  String get playLevelsPlay;

  /// No description provided for @playLevelsLocked.
  ///
  /// In en, this message translates to:
  /// **'Locked'**
  String get playLevelsLocked;

  /// No description provided for @playLevelsDifficultyWarmup.
  ///
  /// In en, this message translates to:
  /// **'Warm-up'**
  String get playLevelsDifficultyWarmup;

  /// No description provided for @playLevelsDifficultyEasy.
  ///
  /// In en, this message translates to:
  /// **'Easy'**
  String get playLevelsDifficultyEasy;

  /// No description provided for @playLevelsDifficultyMedium.
  ///
  /// In en, this message translates to:
  /// **'Medium'**
  String get playLevelsDifficultyMedium;

  /// No description provided for @playLevelsDifficultyHard.
  ///
  /// In en, this message translates to:
  /// **'Hard'**
  String get playLevelsDifficultyHard;

  /// No description provided for @playLevelsDifficultyExpert.
  ///
  /// In en, this message translates to:
  /// **'Expert'**
  String get playLevelsDifficultyExpert;

  /// No description provided for @playLevelsDifficultyClassic.
  ///
  /// In en, this message translates to:
  /// **'Classic'**
  String get playLevelsDifficultyClassic;

  /// No description provided for @playLevelsVariantMultiplesRoman.
  ///
  /// In en, this message translates to:
  /// **'Multiples Roman'**
  String get playLevelsVariantMultiplesRoman;

  /// No description provided for @playLevelsVariantAlphabetReverse.
  ///
  /// In en, this message translates to:
  /// **'Alphabet Reverse'**
  String get playLevelsVariantAlphabetReverse;

  /// No description provided for @playLevelsVariantAlphabet.
  ///
  /// In en, this message translates to:
  /// **'Alphabet'**
  String get playLevelsVariantAlphabet;

  /// No description provided for @playLevelsVariantMultiples.
  ///
  /// In en, this message translates to:
  /// **'Multiples'**
  String get playLevelsVariantMultiples;

  /// No description provided for @playLevelsVariantRoman.
  ///
  /// In en, this message translates to:
  /// **'Roman'**
  String get playLevelsVariantRoman;

  /// No description provided for @playLevelsVariantClassic.
  ///
  /// In en, this message translates to:
  /// **'Classic'**
  String get playLevelsVariantClassic;

  /// No description provided for @gameLevelProgress.
  ///
  /// In en, this message translates to:
  /// **'Level {level} / {total}'**
  String gameLevelProgress(int level, int total);

  /// No description provided for @gameFriendlyChallengeCompleteHeadline.
  ///
  /// In en, this message translates to:
  /// **'Friendly Challenge Complete'**
  String get gameFriendlyChallengeCompleteHeadline;

  /// No description provided for @gameReplay.
  ///
  /// In en, this message translates to:
  /// **'Replay'**
  String get gameReplay;

  /// No description provided for @gameFriendlyChallengeShare.
  ///
  /// In en, this message translates to:
  /// **'Friendly challenge done in {time}.'**
  String gameFriendlyChallengeShare(Object time);

  /// No description provided for @gameFriendlyChallengeCopy.
  ///
  /// In en, this message translates to:
  /// **'Friendly challenge | {time}'**
  String gameFriendlyChallengeCopy(Object time);

  /// No description provided for @gameContinueTutorial.
  ///
  /// In en, this message translates to:
  /// **'Continue Tutorial'**
  String get gameContinueTutorial;

  /// No description provided for @gameVictoryShareText.
  ///
  /// In en, this message translates to:
  /// **'I solved Zip #{level} in {time}. Score {score}.'**
  String gameVictoryShareText(int level, Object time, int score);

  /// No description provided for @gameVictoryCopyText.
  ///
  /// In en, this message translates to:
  /// **'Zip #{level} - {time} - Streak {streak} '**
  String gameVictoryCopyText(int level, Object time, int streak);

  /// No description provided for @gameReacted.
  ///
  /// In en, this message translates to:
  /// **'{name} reacted'**
  String gameReacted(Object name);

  /// No description provided for @victoryHeadlineFire.
  ///
  /// In en, this message translates to:
  /// **'You\'re on fire!'**
  String get victoryHeadlineFire;

  /// No description provided for @victoryHeadlineCrushing.
  ///
  /// In en, this message translates to:
  /// **'Crushing it!'**
  String get victoryHeadlineCrushing;

  /// No description provided for @victoryHeadlinePerfect.
  ///
  /// In en, this message translates to:
  /// **'Perfect run!'**
  String get victoryHeadlinePerfect;

  /// No description provided for @victoryHeadlineSharp.
  ///
  /// In en, this message translates to:
  /// **'Sharp move!'**
  String get victoryHeadlineSharp;

  /// No description provided for @endlessTitle.
  ///
  /// In en, this message translates to:
  /// **'Endless'**
  String get endlessTitle;

  /// No description provided for @endlessDifficulty.
  ///
  /// In en, this message translates to:
  /// **'Difficulty {difficulty}'**
  String endlessDifficulty(int difficulty);

  /// No description provided for @endlessNewRun.
  ///
  /// In en, this message translates to:
  /// **'New'**
  String get endlessNewRun;

  /// No description provided for @endlessResumeAt.
  ///
  /// In en, this message translates to:
  /// **'Resume at {index}'**
  String endlessResumeAt(int index);

  /// No description provided for @endlessStartNewRun.
  ///
  /// In en, this message translates to:
  /// **'Start a new endless run'**
  String get endlessStartNewRun;

  /// No description provided for @endlessBestSummary.
  ///
  /// In en, this message translates to:
  /// **'Best score: {score} | Best index: {index} | Best avg: {avg}'**
  String endlessBestSummary(int score, int index, Object avg);

  /// No description provided for @endlessCouldNotLoadPuzzle.
  ///
  /// In en, this message translates to:
  /// **'Could not load endless puzzle.'**
  String get endlessCouldNotLoadPuzzle;

  /// No description provided for @endlessRunSeed.
  ///
  /// In en, this message translates to:
  /// **'Run seed: {seed}'**
  String endlessRunSeed(int seed);

  /// No description provided for @endlessSolved.
  ///
  /// In en, this message translates to:
  /// **'Solved!'**
  String get endlessSolved;

  /// No description provided for @endlessShareText.
  ///
  /// In en, this message translates to:
  /// **'Endless D{difficulty} #{index} in {time}.'**
  String endlessShareText(int difficulty, int index, Object time);

  /// No description provided for @endlessCopyText.
  ///
  /// In en, this message translates to:
  /// **'Zip #{index} - {time} - Streak {streak} '**
  String endlessCopyText(int index, Object time, int streak);

  /// No description provided for @levelsPackTitle.
  ///
  /// In en, this message translates to:
  /// **'{pack} levels'**
  String levelsPackTitle(Object pack);

  /// No description provided for @gameClear.
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get gameClear;

  /// No description provided for @gameNext.
  ///
  /// In en, this message translates to:
  /// **'Next {value}'**
  String gameNext(Object value);

  /// No description provided for @gameStars.
  ///
  /// In en, this message translates to:
  /// **'Stars {value}'**
  String gameStars(Object value);

  /// No description provided for @victoryPrimaryNextLevel.
  ///
  /// In en, this message translates to:
  /// **'Next Level'**
  String get victoryPrimaryNextLevel;

  /// No description provided for @victoryPrimaryPlayAgain.
  ///
  /// In en, this message translates to:
  /// **'Play Again'**
  String get victoryPrimaryPlayAgain;

  /// No description provided for @retry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retry;
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
