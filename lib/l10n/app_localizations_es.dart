// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Spanish Castilian (`es`).
class AppLocalizationsEs extends AppLocalizations {
  AppLocalizationsEs([String locale = 'es']) : super(locale);

  @override
  String get appTitle => 'TracePath';

  @override
  String get victoryDataMissing => 'Faltan datos de victoria';

  @override
  String get liveDuelInviteTitle => 'Invitacion de duelo en vivo';

  @override
  String liveDuelInviteBody(Object from) {
    return '$from te desafio a un duelo en vivo.\nQuieres aceptar';
  }

  @override
  String get decline => 'Rechazar';

  @override
  String get accept => 'Aceptar';

  @override
  String get liveInviteCouldNotProcess => 'No se pudo procesar la invitacion';

  @override
  String get liveInviteNoLongerAvailable =>
      'La invitacion ya no esta disponible';

  @override
  String get liveInviteAlreadyClosed => 'Este duelo ya esta cerrado';

  @override
  String get liveInviteInvalidAccount =>
      'La invitacion no es valida para esta cuenta';

  @override
  String get liveInviteInvalidPayload =>
      'El contenido de la invitacion es invalido';

  @override
  String get liveInvitePermissionsBlocked =>
      'Los permisos bloquearon esta accion';

  @override
  String get liveInviteNetworkIssue =>
      'Problema de red al procesar la invitacion';

  @override
  String get tabHome => 'Inicio';

  @override
  String get tabShop => 'Tienda';

  @override
  String get tabDuel => 'Duelo';

  @override
  String get tabCards => 'Cartas';

  @override
  String get tabProfile => 'Perfil';

  @override
  String get playModeWorlds => 'Mundos';

  @override
  String get playModeDaily => 'Diario';

  @override
  String get playModeRanked => 'Ranking';

  @override
  String get playModeEvents => 'Eventos';

  @override
  String get playModeDuels => 'Duelos';

  @override
  String get playButton => 'Jugar';

  @override
  String get homePlayerName => 'Jugador';

  @override
  String get homeTitle => 'TracePath';

  @override
  String homeStreakPill(int count) {
    return 'Racha $count';
  }

  @override
  String homeLevelPill(int count) {
    return 'Nv $count';
  }

  @override
  String get homeTrainTitle => 'Entrena tu mente';

  @override
  String get homeTrainSubtitle =>
      'Traza caminos mas rapido, mejora tu precision y supera cada desafio.';

  @override
  String get homeStartSolving => 'EMPIEZA A RESOLVER!';

  @override
  String get homeJumpToNextPuzzle => 'Salta a tu proximo puzzle';

  @override
  String get homeContinue => 'Continuar';

  @override
  String get homeContinueFirstRun => 'Empieza tu primera partida';

  @override
  String homeContinueResumeLevel(int level) {
    return 'Nivel $level Retoma donde lo dejaste';
  }

  @override
  String get homeQuickAccessTitle => 'Accesos rapidos';

  @override
  String get homeQuickAccessSubtitle => 'Entra directo a tus modos favoritos';

  @override
  String get homeQuickDailyTitle => 'Puzzle diario';

  @override
  String get homeQuickDailySubtitle => 'Un desafio cada dia';

  @override
  String get homeQuickLevelsTitle => 'Niveles';

  @override
  String get homeQuickLevelsSubtitle => 'Elige cualquier nivel disponible';

  @override
  String get homeQuickSocialTitle => 'Social';

  @override
  String get homeQuickSocialSubtitle => 'Amigos, inbox y multijugador';

  @override
  String get homeProgressTitle => 'Progreso';

  @override
  String get homeProgressSubtitle => 'Tu rendimiento y momentum recientes';

  @override
  String get homeMetricLevelsSolved => 'Niveles resueltos';

  @override
  String get homeMetricCurrentStreak => 'Racha actual';

  @override
  String get homeMetricBestStreak => 'Mejor racha';

  @override
  String get homeMetricHighestLevel => 'Nivel mas alto';

  @override
  String homeDailySolved(int count) {
    return 'Puzzles diarios resueltos: $count';
  }

  @override
  String get homeViewProfile => 'Ver perfil';

  @override
  String get duelHubTitle => 'Centro de duelo';

  @override
  String get duelHubSubtitle => 'Desafia amigos y juega partidas en vivo.';

  @override
  String get duelCreating => 'Creando duelo...';

  @override
  String get duelChallengeFriend => 'Desafiar a un amigo';

  @override
  String get duelIncomingInvitesTitle => 'Invitaciones entrantes';

  @override
  String get duelIncomingInvitesSubtitle => 'Acepta o rechaza desafios en vivo';

  @override
  String get duelNoPendingInvitesTitle => 'No hay invitaciones pendientes';

  @override
  String get duelNoPendingInvitesSubtitle =>
      'Los nuevos desafios apareceran aqui.';

  @override
  String get duelInviteLoadErrorTitle =>
      'No se pudieron cargar las invitaciones';

  @override
  String get duelTryAgainLater => 'Intentalo de nuevo en un momento.';

  @override
  String get duelActiveMatchesTitle => 'Partidas activas';

  @override
  String get duelActiveMatchesSubtitle => 'Reanuda tus duelos en vivo';

  @override
  String get duelNoActiveTitle => 'No hay duelos activos';

  @override
  String get duelNoActiveSubtitle => 'Empieza un desafio para jugar en vivo.';

  @override
  String get duelActiveLoadErrorTitle =>
      'No se pudieron cargar las partidas activas';

  @override
  String get duelHistoryTitle => 'Historial';

  @override
  String get duelHistorySubtitle => 'Resultados recientes de duelo';

  @override
  String get duelHistoryComingSoonTitle => 'Historial proximamente';

  @override
  String get duelHistoryComingSoonSubtitle =>
      'Tus ultimos duelos se mostraran aqui.';

  @override
  String get duelChooseFriend => 'Elige un amigo';

  @override
  String get duelCouldNotLoadFriends => 'No se pudieron cargar los amigos';

  @override
  String get duelNoFriendsYet => 'Aun no tienes amigos';

  @override
  String get duelInviteSentText => 'te envio una invitacion de duelo en vivo.';

  @override
  String duelAcceptError(Object error) {
    return 'No se pudo aceptar la invitacion: $error';
  }

  @override
  String duelDeclineError(Object error) {
    return 'No se pudo rechazar la invitacion: $error';
  }

  @override
  String get duelAccept => 'Aceptar';

  @override
  String get duelResume => 'Reanudar';

  @override
  String get duelStatusPending => 'Pendiente';

  @override
  String get duelStatusCountdown => 'Cuenta atras';

  @override
  String get duelStatusPlaying => 'Jugando';

  @override
  String get duelStatusFinished => 'Finalizado';

  @override
  String get duelStatusCancelled => 'Cancelado';

  @override
  String get duelUnknownOpponent => 'Desconocido';

  @override
  String duelVersusOpponent(Object name) {
    return 'VS $name';
  }

  @override
  String duelLevelAndStatus(Object level, Object status) {
    return 'Nivel: $level $status';
  }

  @override
  String get duelErrorFinishCurrentFirst =>
      'Termina primero tu duelo en curso.';

  @override
  String get duelErrorFriendBusy => 'Este amigo ya esta en otro duelo.';

  @override
  String get duelErrorNoPuzzles => 'No hay puzzles disponibles ahora mismo.';

  @override
  String get duelErrorInvalidTarget =>
      'No se pudo iniciar duelo con este amigo.';

  @override
  String get duelErrorCreateInvite =>
      'No se pudo crear la invitacion de duelo ahora mismo.';

  @override
  String get duelRemoveActiveTitle => 'Eliminar partida activa';

  @override
  String get duelRemoveActiveBody =>
      'Esta partida activa se cerrara y dejara de aparecer en esta lista.';

  @override
  String get duelKeep => 'Mantener';

  @override
  String get duelRemove => 'Eliminar';

  @override
  String get duelRemoving => 'Eliminando...';

  @override
  String get duelRemovedActive => 'Partida activa eliminada';

  @override
  String duelRemoveError(Object error) {
    return 'No se pudo eliminar la partida: $error';
  }

  @override
  String get friendChallengeTitle => 'Desafio amistoso';

  @override
  String get friendChallengeUnavailable => 'Desafio no disponible.';

  @override
  String friendChallengePuzzle(Object puzzleId) {
    return 'Puzzle: $puzzleId';
  }

  @override
  String friendChallengeMode(Object mode) {
    return 'Modo: $mode';
  }

  @override
  String get friendChallengePlayButton => 'Jugar desafio amistoso';

  @override
  String get shopTitle => 'Tienda';

  @override
  String get shopSkinEditorTooltip => 'Editor de skins';

  @override
  String get shopTabSkins => 'Skins';

  @override
  String get shopTabTrails => 'Estelas';

  @override
  String get shopTabCoinPacks => 'Packs de monedas';

  @override
  String shopSkinsLoaded(int visible, int total) {
    return 'Skins cargadas: $visible/$total';
  }

  @override
  String get shopFeaturedSkin => 'Skin destacada';

  @override
  String get shopPointerSkins => 'Skins de puntero';

  @override
  String get shopLoadMore => 'Cargar mas';

  @override
  String get shopOwned => 'Comprado';

  @override
  String shopCoinsAmount(int coins) {
    return '$coins monedas';
  }

  @override
  String get shopEquipped => 'Equipado';

  @override
  String get shopEquip => 'Equipar';

  @override
  String shopBuyCoins(int coins) {
    return 'Comprar $coins';
  }

  @override
  String get shopNewTrail => 'NUEVA ESTELA';

  @override
  String get shopUnlockedAndEquipped => 'Desbloqueado y equipado';

  @override
  String get shopDefaultTrailDescription =>
      'Estilo visual unico para el trazo de tu ruta.';

  @override
  String get profileGuestMode => 'Modo invitado';

  @override
  String get profileGoogleAccount => 'Cuenta de Google';

  @override
  String get profileLogout => 'Cerrar sesion';

  @override
  String get profileLogoutConfirm => 'Quieres cerrar sesion\'';

  @override
  String get profileCancel => 'Cancelar';

  @override
  String get profileSignedOut => 'Sesion cerrada';

  @override
  String get profileDefaultName => 'Default';

  @override
  String get profileLevelLabel => 'Nivel';

  @override
  String get profileStreakLabel => 'Racha';

  @override
  String get profileBestLabel => 'Mejor';

  @override
  String profileBestStreak(int count) {
    return 'Mejor racha: $count';
  }

  @override
  String profileEquippedSkin(Object name) {
    return 'Skin equipada: $name';
  }

  @override
  String get profileStatsTitle => 'Estadisticas';

  @override
  String get profileGamesPlayed => 'Partidas jugadas';

  @override
  String get profileBestTime => 'Mejor tiempo';

  @override
  String get profileVaultTitle => 'Boveda';

  @override
  String get profileLockerTitle => 'Taquilla';

  @override
  String get profileLockerHint =>
      'Toca un item equipado para abrir el inventario.';

  @override
  String get profileOpenVault => 'Abrir boveda';

  @override
  String get profileInboxTitle => 'Inbox';

  @override
  String profileInboxWithCount(int count) {
    return 'Inbox ($count)';
  }

  @override
  String get profileInboxUnavailableTitle => 'Inbox no disponible ahora';

  @override
  String get profileInboxEmptyTitle => 'Aun no hay mensajes';

  @override
  String get profileInboxEmptySubtitle =>
      'Las solicitudes de amistad, recompensas y noticias apareceran aqui.';

  @override
  String get profileVaultLockerTitle => 'Boveda / Taquilla';

  @override
  String get profileReadyToEquip => 'Listo para equipar';

  @override
  String profileRewardClaimed(int coins) {
    return 'Recompensa reclamada: +$coins monedas';
  }

  @override
  String get profileRewardAlreadyClaimed => 'Recompensa ya reclamada';

  @override
  String get profileRewardClaimFailed => 'No se pudo reclamar la recompensa';

  @override
  String get profileFriendRequestAccepted => 'Solicitud de amistad aceptada';

  @override
  String get profileFriendRequestDeclined => 'Solicitud de amistad rechazada';

  @override
  String get profileFriendRequestDeclineFailed =>
      'No se pudo rechazar la solicitud de amistad';

  @override
  String get profileChallengeDeclined => 'Desafio rechazado';

  @override
  String get profileChallengeDeclineFailed => 'No se pudo rechazar el desafio';

  @override
  String get profileChallengeDeclinedTitle => 'Desafio rechazado';

  @override
  String get profileChallengeDeclinedBodySuffix => 'rechazo tu desafio.';

  @override
  String get profileChallengeAcceptedTitle => 'Desafio aceptado';

  @override
  String get profileChallengeAcceptedBodySuffix => 'acepto tu desafio.';

  @override
  String get profileFunctionUnavailableTitle => 'Funcion no disponible';

  @override
  String get profileFunctionUnavailableBody =>
      'Esta funcion solo esta disponible cuando compres y equipes una skin.';

  @override
  String get profileUnderstand => 'Entendido';

  @override
  String get profileCardUnavailableTitle => 'Carta no disponible';

  @override
  String get profileCardUnavailableBody =>
      'Todavia no hay carta para esta skin.';

  @override
  String get profileWorldProgressTitle => 'Progreso del mundo';

  @override
  String profileLevelsCompleted(int solved, int total) {
    return '$solved / $total niveles completados';
  }

  @override
  String profileHighestLevelValue(int level) {
    return 'Maximo $level';
  }

  @override
  String get profileAchievementsTitle => 'Logros';

  @override
  String profileAchievementsProgress(int unlocked, int total) {
    return '$unlocked / $total desbloqueados';
  }

  @override
  String profileAchievementCompleted(Object datePart) {
    return 'Completado$datePart';
  }

  @override
  String get profileAchievementLocked => 'Bloqueado';

  @override
  String profileAchievementUnlocked(Object datePart) {
    return 'Desbloqueado$datePart';
  }

  @override
  String profileAchievementOnDate(Object date) {
    return 'el $date';
  }

  @override
  String get profileInboxOpen => 'Abrir';

  @override
  String profileInboxClaim(int coins) {
    return 'Reclamar $coins';
  }

  @override
  String get profileInboxNow => 'ahora';

  @override
  String get loginTagline =>
      'Entrena tu mente. Traza el camino mas rapido que nadie.';

  @override
  String get loginBenefitSaveProgress => 'Guardar progreso';

  @override
  String get loginBenefitChallengeFriends => 'Desafiar amigos';

  @override
  String get loginBenefitKeepStreak => 'Mantener racha';

  @override
  String get loginContinueGuest => 'Continuar como invitado';

  @override
  String get loginGuestModeHint => 'Modo invitado: sin amigos ni desafios.';

  @override
  String get loginConnecting => 'Conectando...';

  @override
  String get loginContinueGoogle => 'Continuar con Google';

  @override
  String get cardsCollectionTitle => 'Coleccion de cartas';

  @override
  String get cardsCollectionEmpty =>
      'Aun no tienes cartas desbloqueadas.\nCompra o desbloquea skins para coleccionarlas.';

  @override
  String get cardsRarityLegendary => 'Legendaria';

  @override
  String get cardsRarityEpic => 'Epica';

  @override
  String get cardsRarityRare => 'Rara';

  @override
  String get cardsRarityCommon => 'Comun';

  @override
  String get campaignTitle => 'Campana';

  @override
  String get campaignLoading => 'Cargando...';

  @override
  String get campaignPreparingStatus => 'Preparando estado de pack';

  @override
  String get campaignLoadError => 'No se pudieron cargar los packs de campana.';

  @override
  String get campaignPackClassic => 'Introduccion equilibrada';

  @override
  String get campaignPackArchitect => 'Mas muros y planificacion precisa';

  @override
  String get campaignPackExpert => 'Tableros grandes y rutas dificiles';

  @override
  String leaderboardFriendsTitleWithLevel(int level) {
    return 'Ranking de amigos - N$level';
  }

  @override
  String get leaderboardFriendsTitle => 'Ranking de amigos';

  @override
  String leaderboardLevelPack(int level, Object packId) {
    return 'Nivel $level - $packId';
  }

  @override
  String get leaderboardNoFriendsScores =>
      'Aun no hay tiempos de amigos en este nivel.';

  @override
  String get leaderboardUnavailable => 'Ranking de amigos no disponible ahora.';

  @override
  String get dailyTitle => 'Diario';

  @override
  String get dailyUnknownLoadError => 'Error desconocido al cargar diario';

  @override
  String get dailyLoadError => 'No se pudo cargar el puzzle diario.';

  @override
  String get dailyRetry => 'Reintentar';

  @override
  String get dailyChallengeTitle => 'Desafio diario';

  @override
  String dailyNextPuzzleIn(Object countdown) {
    return 'Siguiente puzzle en $countdown';
  }

  @override
  String get dailyRewardLabel => 'Recompensa';

  @override
  String dailyCoinsReward(int coins) {
    return '$coins monedas';
  }

  @override
  String get dailyStreakLabel => 'Racha';

  @override
  String get dailyBestTimeLabel => 'Mejor tiempo';

  @override
  String get dailyPlayAgain => 'Jugar otra vez';

  @override
  String get dailyPlayDaily => 'Jugar diario';

  @override
  String dailyAttemptsSummary(int attempts, Object bestScore) {
    return 'Intentos hoy: $attempts - Mejor score: $bestScore';
  }

  @override
  String get dailyNewPersonalBestToday => 'Nuevo record personal de hoy';

  @override
  String get dailyCompletedTitle => 'Diario completado';

  @override
  String get dailySavedWithPartialSync =>
      'Guardado con sincronizacion parcial. Intenta de nuevo luego.';

  @override
  String get dailyRewardSyncFailed =>
      'Fallo la sincronizacion de recompensa. Intentalo otra vez.';

  @override
  String get dailyAchievementUnlocked => 'Logro desbloqueado';

  @override
  String get dailyRewardToastTitle => 'Recompensa diaria';

  @override
  String dailyRewardToastMessage(int coins) {
    return '+$coins monedas';
  }

  @override
  String dailyShareText(Object time) {
    return 'Diario completado en $time.';
  }

  @override
  String dailyCopyText(int day, Object time, int streak) {
    return 'Zip #$day - $time - Racha $streak Y';
  }

  @override
  String get liveDuelTitle => 'Duelo en vivo';

  @override
  String get liveDuelCouldNotUpdateReady => 'No se pudo actualizar Ready';

  @override
  String get liveDuelAcceptInviteFirst => 'Acepta primero la invitacion';

  @override
  String get liveDuelAlreadyClosed => 'Este duelo ya esta cerrado';

  @override
  String get liveDuelOpponent => 'Rival';

  @override
  String liveDuelReacted(Object sender) {
    return '$sender reacciono';
  }

  @override
  String get liveDuelUnavailableNow => 'Duelo en vivo no disponible ahora.';

  @override
  String get liveDuelMatchNotFound => 'Partida no encontrada';

  @override
  String get liveDuelYou => 'Tu';

  @override
  String get liveDuelWaitingPlayer => 'Esperando jugador...';

  @override
  String get liveDuelLeave => 'Salir del duelo';

  @override
  String get liveDuelHeroYouAbandoned => 'ABANDONASTE';

  @override
  String get liveDuelHeroYouWin => 'GANASTE';

  @override
  String get liveDuelHeroDraw => 'EMPATE';

  @override
  String get liveDuelHeroYouLost => 'PERDISTE';

  @override
  String get liveDuelInvitationReceived => 'Invitacion recibida';

  @override
  String get liveDuelWaitingFriendJoin => 'Esperando a que tu amigo se una...';

  @override
  String get liveDuelOpponentReady => 'El rival esta listo';

  @override
  String get liveDuelOpponentJoinedWaitingReady =>
      'El rival se unio, esperando Ready';

  @override
  String get liveDuelOpponentNotJoined => 'El rival aun no se unio';

  @override
  String get liveDuelAccepting => 'Aceptando...';

  @override
  String get liveDuelAcceptDuel => 'Aceptar duelo';

  @override
  String get liveDuelSaving => 'Guardando...';

  @override
  String get liveDuelUnready => 'Quitar ready';

  @override
  String get liveDuelReady => 'Ready';

  @override
  String get liveDuelAcceptFirstThenReady =>
      'Acepta primero y luego marca Ready.';

  @override
  String get liveDuelGo => 'GO!';

  @override
  String liveDuelStartingIn(Object value) {
    return 'Empieza en $value...';
  }

  @override
  String get liveDuelStartingMatch => 'Iniciando partida...';

  @override
  String get liveDuelWaitingRoom => 'Sala de espera';

  @override
  String get liveDuelGetReady => 'Preparate';

  @override
  String get liveDuelMatchStarted => 'Partida iniciada';

  @override
  String get liveDuelMatchResult => 'Resultado';

  @override
  String get liveDuelMatchCancelled => 'Partida cancelada';

  @override
  String get liveDuelYouAbandoned => 'Abandonaste';

  @override
  String get liveDuelYouWonSmiley => 'Ganaste Y';

  @override
  String get liveDuelDraw => 'Empate';

  @override
  String get liveDuelDefeat => 'Derrota';

  @override
  String get liveDuelDefeatByAbandon => 'Derrota por abandono';

  @override
  String get liveDuelWinByAbandon => 'Victoria por abandono';

  @override
  String get liveDuelYouWonDuel => 'Ganaste el duelo';

  @override
  String get liveDuelNoWinner => 'Sin ganador';

  @override
  String get liveDuelYouLost => 'Perdiste';

  @override
  String get liveDuelYourTime => 'Tu tiempo';

  @override
  String get liveDuelOpponentTime => 'Tiempo rival';

  @override
  String get liveDuelCouldNotCreateRematch => 'No se pudo crear revancha';

  @override
  String get liveDuelOpponentBusyAnother => 'El rival esta en otro duelo';

  @override
  String get liveDuelFinishActiveFirst => 'Termina tu duelo activo primero';

  @override
  String get liveDuelCreatingRematch => 'Creando revancha...';

  @override
  String get liveDuelRematch => 'Revancha';

  @override
  String get liveDuelBack => 'Volver';

  @override
  String get liveDuelEmoteCooldown => 'Cooldown de emote';

  @override
  String get liveDuelCouldNotSendEmote => 'No se pudo enviar emote';

  @override
  String get liveDuelInviteExpired => 'Invitacion expirada';

  @override
  String get liveDuelCountdownExpired => 'Cuenta atras expirada';

  @override
  String get liveDuelMatchTimedOut => 'Partida sin tiempo';

  @override
  String get liveDuelCancelled => 'Duelo cancelado';

  @override
  String get liveDuelStateInvited => 'Invitado';

  @override
  String get liveDuelStateJoined => 'Unido';

  @override
  String get liveDuelStateReady => 'Ready';

  @override
  String get liveDuelStatePlaying => 'Jugando';

  @override
  String get liveDuelStateFinished => 'Finalizado';

  @override
  String get liveDuelStateAbandoned => 'Abandonado';

  @override
  String get victoryChallengeOnlyLevelRuns =>
      'Este desafio solo esta disponible en niveles normales.';

  @override
  String get victoryAddFriendsFirst =>
      'Agrega amigos primero para enviar desafios.';

  @override
  String get victoryChallengeFriendTitle => 'Desafiar a un amigo';

  @override
  String get victoryChallengeFriendSubtitle =>
      'Envia una invitacion de duelo en vivo aleatorio';

  @override
  String get victoryInviteOnline => 'Invitar a duelo 1v1 en vivo - En linea';

  @override
  String get victoryInviteOffline =>
      'Invitar a duelo 1v1 en vivo - Desconectado';

  @override
  String get victoryLiveInviteSent => 'Invitacion de duelo enviada';

  @override
  String get victoryChallengeSendError => 'No se pudo enviar el desafio ahora';

  @override
  String get victoryChallengeBlockedByRules =>
      'Las reglas de Firestore bloquearon el desafio';

  @override
  String get victoryChallengeSetupNotReady =>
      'El setup del desafio no esta listo aun. Intenta en un momento.';

  @override
  String get victoryFinishActiveDuelFirst => 'Termina primero tu duelo activo';

  @override
  String victoryFriendAlreadyInDuel(Object name) {
    return '$name ya esta en otro duelo';
  }

  @override
  String get victoryNoPuzzlesForDuel => 'No hay puzzles disponibles para duelo';

  @override
  String get victoryStatTime => 'Tiempo';

  @override
  String get victoryStatBestTime => 'Mejor tiempo';

  @override
  String victoryCoinsWithAd(int coins) {
    return 'Monedas (+$coins ad)';
  }

  @override
  String get victoryCoinsReward => 'Monedas recompensa';

  @override
  String get victoryLevelComplete => 'NIVEL COMPLETADO';

  @override
  String victoryCurrentStreak(int streak) {
    return 'Racha actual: $streak';
  }

  @override
  String get victoryFriendsRanking => 'Ranking de amigos';

  @override
  String get victoryReplay => 'Repetir';

  @override
  String get victoryChallengeFriendCta => 'Desafiar amigo';

  @override
  String get socialTitle => 'Social';

  @override
  String get socialHubTitle => 'Hub social';

  @override
  String get socialHubSubtitle => 'Amigos, rankings y desafios';

  @override
  String get socialFriendsLabel => 'Amigos';

  @override
  String get socialBestRankLabel => 'Mejor rank';

  @override
  String get socialTopTimeLabel => 'Top tiempo';

  @override
  String get socialGlobalTierLabel => 'Tier global';

  @override
  String get socialFriendActionsTitle => 'Acciones de amigos';

  @override
  String get socialFriendActionsSubtitle =>
      'Define tu usuario y agrega amigos por username o UID';

  @override
  String get socialSetUsernameHint => 'Define tu username';

  @override
  String get socialSave => 'Guardar';

  @override
  String get socialFriendLookupHint => 'Username, email o UID de amigo';

  @override
  String get socialAdd => 'Agregar';

  @override
  String get socialFriendsSectionTitle => 'Amigos';

  @override
  String get socialFriendsSectionSubtitle => 'Tus rivales y companeros';

  @override
  String socialFriendsWithCount(int count) {
    return 'Amigos ($count)';
  }

  @override
  String get socialNoFriendsTitle => 'Aun no tienes amigos';

  @override
  String get socialNoFriendsSubtitle =>
      'Agrega amigos para competir y enviar desafios.';

  @override
  String get socialGlobalTop10Title => 'Top 10 global';

  @override
  String get socialGlobalTop10Subtitle => 'Mejores jugadores del mundo';

  @override
  String get socialNoGlobalScoresTitle => 'Aun no hay scores globales';

  @override
  String get socialNoGlobalScoresSubtitle =>
      'Completa niveles para aparecer en el ranking mundial.';

  @override
  String get socialChallengesTitle => 'Desafios';

  @override
  String get socialChallengesSubtitle => 'Invita o desafia a tus amigos ahora';

  @override
  String get socialChallengeFriend => 'Desafiar amigo';

  @override
  String get socialInviteFriend => 'Invitar amigo';

  @override
  String get socialFriendRequestTitle => 'Solicitud de amistad';

  @override
  String get socialFriendRequestSent => 'Solicitud enviada';

  @override
  String get socialCouldNotSendRequest => 'No se pudo enviar la solicitud';

  @override
  String get socialCannotAddSelf => 'No puedes agregarte a ti mismo';

  @override
  String get socialInvalidEmail => 'Formato de email invalido';

  @override
  String get socialUserNotFound => 'Usuario no encontrado';

  @override
  String get socialAlreadyFriends => 'Ya sois amigos';

  @override
  String get socialRequestAlreadySent => 'Solicitud ya enviada';

  @override
  String get socialRequestAlreadyReceived =>
      'Ese usuario ya te envio una solicitud';

  @override
  String get socialNeedSignIn => 'Debes iniciar sesion';

  @override
  String get socialRulesBlockedAction =>
      'Las reglas de Firestore bloquearon esta accion';

  @override
  String get socialAddFriendsFirstForChallenges =>
      'Agrega amigos primero para enviar desafios.';

  @override
  String get socialChallengeFriendSheetTitle => 'Desafiar a un amigo';

  @override
  String get socialChallengeFriendSheetSubtitle =>
      'Envia una invitacion de duelo en vivo';

  @override
  String get socialLiveInviteOnline => 'Invitar a duelo 1v1 en vivo - En linea';

  @override
  String get socialLiveInviteOffline =>
      'Invitar a duelo 1v1 en vivo - Desconectado';

  @override
  String get socialLiveInviteSentTitle => 'Invitacion de duelo enviada';

  @override
  String socialLiveInviteSentBody(Object name) {
    return 'Esperando a que $name acepte.';
  }

  @override
  String get socialCouldNotSendChallenge =>
      'No se pudo enviar el desafio ahora.';

  @override
  String get socialChallengeBlockedByRules =>
      'Las reglas de Firestore bloquearon el desafio.';

  @override
  String get socialChallengeSetupNotReady =>
      'El setup del desafio no esta listo aun. Intenta en un momento.';

  @override
  String get socialFinishCurrentLiveDuelFirst =>
      'Termina primero tu duelo en vivo actual.';

  @override
  String socialFriendAlreadyInLiveDuel(Object name) {
    return '$name ya esta en otro duelo en vivo.';
  }

  @override
  String get socialNoPuzzlesForLiveDuel =>
      'No hay puzzles disponibles para duelo en vivo.';

  @override
  String get socialRemoveFriendTitle => 'Eliminar amigo';

  @override
  String get socialRemoveFriendBody =>
      'Seguro que quieres eliminar a este amigo\'';

  @override
  String get socialUsernameTitle => 'Username';

  @override
  String get socialUsernameNotAvailable => 'Username no disponible';

  @override
  String get socialUsernameUpdated => 'Username actualizado';

  @override
  String get socialUsernameAlreadyUsed => 'Username ya en uso';

  @override
  String get socialUsernameInvalid =>
      'Username invalido (3-20, letras/numeros/._)';

  @override
  String get socialRulesBlockedUsernameWrite =>
      'Las reglas de Firestore bloquearon el guardado del username';

  @override
  String get socialCouldNotSaveUsername => 'No se pudo guardar el username';

  @override
  String get socialInviteReadyTitle => 'Invitacion lista';

  @override
  String get socialInviteReadyBody =>
      'Invitacion copiada. Compartela por WhatsApp o email.';

  @override
  String socialMovesShort(int count) {
    return '$count movimientos';
  }

  @override
  String socialStarsShort(int count) {
    return '$count estrellas';
  }

  @override
  String get socialGuestLockedTitle => 'Social esta bloqueado en modo invitado';

  @override
  String get socialGuestLockedSubtitle =>
      'Inicia sesion con Google desde Home para desafiar amigos y ver rankings.';

  @override
  String get socialGoHome => 'Ir a Home';

  @override
  String socialSkinTrail(Object skin, Object trail) {
    return 'Skin: $skin - Estela: $trail';
  }

  @override
  String get socialOnline => 'En linea';

  @override
  String get socialOffline => 'Desconectado';

  @override
  String get socialStatusLabel => 'Estado';

  @override
  String get socialSkinLabel => 'Skin';

  @override
  String get socialTrailLabel => 'Estela';

  @override
  String get socialReadyToCompete => 'Listo para competir';

  @override
  String get energyNoEnergyTitle => 'Sin energia';

  @override
  String energyOutWithBattery(Object reset) {
    return 'No te queda energia. Espera $reset al reset, o usa una bateria ahora.';
  }

  @override
  String energyOutWithoutBattery(Object reset) {
    return 'No te queda energia. Espera $reset al reset, o compra una bateria.';
  }

  @override
  String get energyCouldNotUseBattery => 'No se pudo usar la bateria ahora.';

  @override
  String energyRestored(int current, int max) {
    return 'Energia restaurada a $current/$max.';
  }

  @override
  String get energyUseBattery => 'Usar bateria';

  @override
  String get energyNotEnoughCoinsBattery =>
      'No tienes monedas suficientes para comprar una bateria.';

  @override
  String get energyBatteryPurchaseFailed =>
      'Fallo la compra de bateria. Intentalo de nuevo.';

  @override
  String energyBatteryPurchasedAndUsed(int current, int max) {
    return 'Bateria comprada y usada. Energia $current/$max.';
  }

  @override
  String energyBatteryPurchasedCount(int count) {
    return 'Bateria comprada. Baterias: $count.';
  }

  @override
  String energyBuyBattery(int coins) {
    return 'Comprar ($coins monedas)';
  }

  @override
  String playLevelsCompletedToGo(int completed, int remaining) {
    return '$completed completados - $remaining por completar';
  }

  @override
  String playLevelsContinueLevel(int level) {
    return 'Continuar N$level';
  }

  @override
  String get playLevelsRanking => 'Ranking';

  @override
  String get commonCancel => 'Cancelar';

  @override
  String get commonClose => 'Cerrar';

  @override
  String get commonNo => 'No';

  @override
  String get commonOk => 'OK';

  @override
  String get commonReload => 'Recargar';

  @override
  String get commonRetry => 'Reintentar';

  @override
  String get commonYes => 'Si';

  @override
  String get gameGotIt => 'Entendido';

  @override
  String get gameHowToPlayTitle => 'Como jugar';

  @override
  String get gameCoreTutorialBody =>
      '1) Empieza en el numero 1.\n2) Arrastra para conectar numeros en orden (1,2,3...).\n3) Aunque haya pocos numeros, debes rellenar todas las celdas del tablero.\n4) Si te equivocas, usa Deshacer o Reiniciar.';

  @override
  String get gameLetsGo => 'Vamos';

  @override
  String get gameVariantAlphabetTitle => 'Modo alfabeto';

  @override
  String get gameVariantAlphabetBody =>
      'Conecta celdas en orden alfabetico siguiendo las pistas.';

  @override
  String get gameVariantAlphabetReverseTitle => 'Modo alfabeto inverso';

  @override
  String get gameVariantAlphabetReverseBody =>
      'Conecta celdas en orden alfabetico inverso.';

  @override
  String get gameVariantMultiplesTitle => 'Modo multiplos';

  @override
  String get gameVariantMultiplesBody =>
      'Los numeros son multiplos de una base. Sigue los multiplos en orden.';

  @override
  String get gameVariantRomanMultiplesTitle => 'Modo multiplos romanos';

  @override
  String get gameVariantRomanMultiplesBody =>
      'Sigue multiplos crecientes mostrados en numeros romanos.';

  @override
  String get gameVariantRomanTitle => 'Modo numeros romanos';

  @override
  String get gameVariantRomanBody =>
      'Sigue la secuencia de numeros romanos en orden.';

  @override
  String get gameVariantDefaultTitle => 'Modo variante';

  @override
  String get gameVariantDefaultBody =>
      'Sigue la secuencia de pistas en el orden correcto.';

  @override
  String gameVariantExample(Object example) {
    return 'Ejemplo: $example';
  }

  @override
  String get gamePackNotFound => 'Pack no encontrado';

  @override
  String get gameLoadingLevel => 'Cargando nivel';

  @override
  String get gameLevelUnavailable => 'Nivel no disponible';

  @override
  String get gameCouldNotLoadLevel => 'No se pudo cargar este nivel.';

  @override
  String gameEnergyCounter(int current, int max) {
    return 'Energia $current/$max';
  }

  @override
  String gameEnergyResetIn(Object time) {
    return 'Reset en $time';
  }

  @override
  String get gameDuelFinishedBoardLocked =>
      'Duelo finalizado. Tablero bloqueado.';

  @override
  String get gameUndo => 'Deshacer';

  @override
  String get gameRestart => 'Reiniciar';

  @override
  String get gameHintInfinite => 'Pista (INF)';

  @override
  String gameHintCount(int count) {
    return 'Pista ($count)';
  }

  @override
  String get gameReporting => 'Reportando...';

  @override
  String get gameReported => 'Reportado';

  @override
  String get gameReportLevel => 'Reportar nivel';

  @override
  String get gameWatchAd => 'Ver anuncio';

  @override
  String get gameAdStatus => 'Estado anuncio';

  @override
  String get gameDailyAdLimitReached =>
      'Limite diario alcanzado. No hay mas anuncios hoy.';

  @override
  String gameNextAdIn(Object time) {
    return 'Siguiente anuncio en $time';
  }

  @override
  String gameLevelCompleteReward(Object reward) {
    return 'NIVEL COMPLETADO! $reward';
  }

  @override
  String get gameRankingUnavailable => 'Ranking no disponible';

  @override
  String get gameTryAgainMoment => 'Prueba de nuevo en un momento.';

  @override
  String get gameFriendsRanking => 'Ranking de amigos';

  @override
  String gameLevelLabel(int level) {
    return 'Nivel $level';
  }

  @override
  String get gameNoFriendsRankingTitle => 'Ningun amigo ha jugado este nivel.';

  @override
  String get gameNoFriendsRankingBody =>
      'Completa el nivel e invita a tus amigos a competir.';

  @override
  String get gameReportUnavailableTitle => 'Reporte no disponible';

  @override
  String gameReportUnavailableBody(int seconds) {
    return 'Juega al menos $seconds segundos antes de reportar este nivel.';
  }

  @override
  String get gameReportConfirmTitle => 'Reportar este nivel\'';

  @override
  String get gameReportConfirmBody =>
      'Si este nivel no se puede resolver, puedes reportarlo y desbloquear el siguiente.';

  @override
  String get gameReportAndSkip => 'Reportar y saltar';

  @override
  String get gameSignInRequiredTitle => 'Inicio de sesion requerido';

  @override
  String get gameSignInRequiredBody =>
      'Inicia sesion para reportar y saltar niveles.';

  @override
  String get gameAlreadyReportedTitle => 'Ya reportado';

  @override
  String get gameAlreadyReportedBody =>
      'Este nivel ya fue reportado desde esta cuenta.';

  @override
  String get gameLevelReportedTitle => 'Nivel reportado';

  @override
  String get gameLevelReportedBody =>
      'Reporte enviado. Siguiente nivel desbloqueado.';

  @override
  String get gameCouldNotReportTitle => 'No se pudo reportar el nivel';

  @override
  String get gameReportErrorPermissionDenied =>
      'Los permisos bloquearon esta accion. Intentalo mas tarde.';

  @override
  String get gameReportErrorEndpointNotConfigured =>
      'El endpoint de reportes no esta configurado en esta build.';

  @override
  String get gameReportErrorInvalidEndpoint =>
      'La URL del endpoint de reportes no es valida.';

  @override
  String get gameReportErrorTimeout =>
      'La solicitud de reporte agoto el tiempo. Reintenta.';

  @override
  String get gameReportErrorNetwork =>
      'Problema de red al reportar. Intentalo de nuevo.';

  @override
  String get gameReportErrorServerRejected =>
      'El servidor rechazo el reporte. Intentalo en un momento.';

  @override
  String get gameReportErrorUnauthenticated =>
      'Vuelve a iniciar sesion y reintenta.';

  @override
  String get gameReportErrorGeneric =>
      'No se pudo reportar este nivel ahora. Intentalo de nuevo.';

  @override
  String get gameHintTitle => 'Pista';

  @override
  String get gameNoHintsLeft => 'No quedan pistas';

  @override
  String get gameAlmostThereTitle => 'Casi listo';

  @override
  String gameAlmostThereBody(Object label) {
    return 'Termina en $label para completar el nivel.';
  }

  @override
  String get gameTimeTitle => 'Tiempo!';

  @override
  String get gameWaitingForDuelResult => 'Esperando resultado del duelo...';

  @override
  String get gameLevelAlreadyCompletedTitle => 'Nivel ya completado';

  @override
  String get gameNoCoinRewardReplay =>
      'Sin recompensa de monedas en repeticion';

  @override
  String get gameNewBestTitle => 'Nuevo mejor tiempo';

  @override
  String get gameBeatYourGhost => 'Has superado a tu fantasma!';

  @override
  String get gameAchievementUnlocked => 'Logro desbloqueado';

  @override
  String get gameRewardedAdUnavailableTitle =>
      'Anuncio recompensado no disponible';

  @override
  String get gameContinuingWithoutBonus => 'Continuando sin bonus.';

  @override
  String get gameBonusRewardTitle => 'Recompensa bonus';

  @override
  String gameBonusCoins(int coins) {
    return '+$coins monedas';
  }

  @override
  String get gameDailyLimitReachedTitle => 'Limite diario alcanzado';

  @override
  String get gameNoMoreAdsToday => 'No hay mas anuncios hoy';

  @override
  String get gamePleaseWaitTitle => 'Espera';

  @override
  String get gameAdRewardTitle => 'Recompensa de anuncio';

  @override
  String get gameRewardedAdStatusTitle => 'Estado anuncio recompensado';

  @override
  String gameRewardedAdStatusBody(Object loaded, Object loading) {
    return 'Cargado: $loaded\nCargando: $loading';
  }

  @override
  String get gameAdReloadRequestedTitle => 'Recarga de anuncio solicitada';

  @override
  String get gameAdReloadRequestedBody =>
      'Intentando cargar un anuncio recompensado.';

  @override
  String get gameDuelYouWonTitle => 'HAS GANADO!';

  @override
  String get gameDuelYouLostTitle => 'HAS PERDIDO ;(';

  @override
  String get gameDuelYouFinishedFirst => 'Terminaste primero en el duelo.';

  @override
  String get gameDuelFriendFinishedFirst => 'Tu amigo termino primero.';

  @override
  String gameLiveDuelFinishedWaiting(Object time) {
    return 'Terminado en $time. Esperando resultado...';
  }

  @override
  String get gameLiveDuelResultTitle => 'Resultado del duelo';

  @override
  String get gameOpponentAbandoned => 'El rival abandono';

  @override
  String get gameLevel => 'Nivel';

  @override
  String get gameOpponent => 'Rival';

  @override
  String get gamePlayer => 'Jugador';

  @override
  String get gameEmotesAfterDuelResult =>
      'Emotes disponibles al terminar el duelo';

  @override
  String get gameEmoteLaugh => 'Risa';

  @override
  String get gameEmoteCool => 'Cool';

  @override
  String get gameEmoteWow => 'Wow';

  @override
  String get gameEmoteCry => 'Lloro';

  @override
  String get gameEmoteClap => 'Aplaudir';

  @override
  String get gameEmoteHeart => 'Corazon';

  @override
  String gameEnergyEmptyResetIn(Object time) {
    return 'Energia vacia. Reset en $time.';
  }

  @override
  String get gameBatteries => 'Baterias';

  @override
  String gameGhostBest(Object time) {
    return 'Mejor fantasma: $time';
  }

  @override
  String get gameGhostOn => 'Fantasma: ON';

  @override
  String get gameGhostOff => 'Fantasma: OFF';

  @override
  String get gameGhostAvailableAfterFirst =>
      'Fantasma disponible tras la primera completada';

  @override
  String get gameNoRankingImpact => 'Sin impacto en ranking';

  @override
  String get shopTrailEffects => 'Efectos de estela';

  @override
  String get shopCoinPacksUnavailable => 'Packs de monedas no disponibles';

  @override
  String get shopCouldNotLoadCoinPacksRetry =>
      'No se pudieron cargar los packs de monedas. Reintenta.';

  @override
  String get shopCheckConnectionRetry => 'Revisa tu conexion y reintenta.';

  @override
  String get shopNoCoinPacksAvailable => 'No hay packs de monedas disponibles';

  @override
  String get shopStoreProductsUnavailableNow =>
      'Los productos de tienda no estan disponibles ahora. Prueba mas tarde.';

  @override
  String get shopRestore => 'Restaurar';

  @override
  String get shopLoadingStoreProducts => 'Cargando productos de tienda...';

  @override
  String get shopStoreUnavailable => 'Tienda no disponible';

  @override
  String get shopPurchasesDisabledBrowse =>
      'Puedes ver los packs de monedas, pero las compras estan desactivadas ahora.';

  @override
  String get shopShowingLocalCatalogFallback =>
      'Mostrando catalogo local de respaldo';

  @override
  String get shopEnergyBatteries => 'Baterias de energia';

  @override
  String shopBatteriesResetIn(int count, Object time) {
    return 'Baterias: $count - Reset en $time';
  }

  @override
  String get shopUseOneBatteryNow => 'Usar 1 bateria ahora';

  @override
  String get shopProcessingPurchase => 'Procesando compra...';

  @override
  String shopPurchasedBatteries(int units, int total) {
    return 'Compradas $units bateria(s). Total: $total.';
  }

  @override
  String get shopPurchaseSuccessful => 'Compra completada';

  @override
  String get shopConfirmPurchaseTitle => 'Confirmar compra';

  @override
  String shopConfirmPurchaseBody(Object name, int coins) {
    return 'Quieres comprar \"$name\" por $coins monedas\'';
  }

  @override
  String get shopBuyNow => 'Comprar ahora';

  @override
  String get playWorldFallbackTitle => 'Mundo';

  @override
  String get playWorldFallbackSubtitle => 'Ruta de puzzles';

  @override
  String playWorldTitle(int number) {
    return 'Mundo $number';
  }

  @override
  String playWorldSubtitle(int number) {
    return 'Ruta de puzzles $number';
  }

  @override
  String get onboardingInProgress => 'En progreso';

  @override
  String get onboardingGoNow => 'Ir ahora';

  @override
  String duelHistoryTimes(Object youTime, Object opponentTime) {
    return 'Tu $youTime Rival $opponentTime';
  }

  @override
  String get duelStatusVictory => 'Victoria';

  @override
  String get duelStatusDefeat => 'Derrota';

  @override
  String get playLevelsWorldLockedCompletePrevious =>
      'Mundo bloqueado. Completa o reporta todos los niveles del mundo anterior primero.';

  @override
  String playLevelsEnergyStatus(int current, int max, Object time) {
    return '$current/$max - reset $time';
  }

  @override
  String playLevelsWorldProgressSummary(int total, int completed) {
    return '$total niveles - $completed completados';
  }

  @override
  String playLevelsEnergyDetailed(int current, int max, Object time) {
    return 'Energia $current/$max. Reset en $time.';
  }

  @override
  String get playLevelsSelectedLevel => 'Nivel seleccionado';

  @override
  String playLevelsSelectedLevelVariant(int level, Object variant) {
    return 'Nivel $level $variant';
  }

  @override
  String get playLevelsPlay => 'Jugar';

  @override
  String get playLevelsLocked => 'Bloqueado';

  @override
  String get playLevelsDifficultyWarmup => 'Calentamiento';

  @override
  String get playLevelsDifficultyEasy => 'Facil';

  @override
  String get playLevelsDifficultyMedium => 'Medio';

  @override
  String get playLevelsDifficultyHard => 'Dificil';

  @override
  String get playLevelsDifficultyExpert => 'Experto';

  @override
  String get playLevelsDifficultyClassic => 'Clasico';

  @override
  String get playLevelsVariantMultiplesRoman => 'Multiplos Romanos';

  @override
  String get playLevelsVariantAlphabetReverse => 'Alfabeto Inverso';

  @override
  String get playLevelsVariantAlphabet => 'Alfabeto';

  @override
  String get playLevelsVariantMultiples => 'Multiplos';

  @override
  String get playLevelsVariantRoman => 'Romano';

  @override
  String get playLevelsVariantClassic => 'Clasico';

  @override
  String gameLevelProgress(int level, int total) {
    return 'Nivel $level / $total';
  }

  @override
  String get gameFriendlyChallengeCompleteHeadline =>
      'Reto amistoso completado';

  @override
  String get gameReplay => 'Repetir';

  @override
  String gameFriendlyChallengeShare(Object time) {
    return 'Reto amistoso completado en $time.';
  }

  @override
  String gameFriendlyChallengeCopy(Object time) {
    return 'Reto amistoso | $time';
  }

  @override
  String get gameContinueTutorial => 'Continuar tutorial';

  @override
  String gameVictoryShareText(int level, Object time, int score) {
    return 'He resuelto Zip #$level en $time. Puntuacion $score.';
  }

  @override
  String gameVictoryCopyText(int level, Object time, int streak) {
    return 'Zip #$level - $time - Racha $streak Y';
  }

  @override
  String gameReacted(Object name) {
    return '$name reacciono';
  }

  @override
  String get victoryHeadlineFire => 'Estas que ardes!';

  @override
  String get victoryHeadlineCrushing => 'Lo estas rompiendo!';

  @override
  String get victoryHeadlinePerfect => 'Partida perfecta!';

  @override
  String get victoryHeadlineSharp => 'Movimiento preciso!';

  @override
  String get endlessTitle => 'Infinito';

  @override
  String endlessDifficulty(int difficulty) {
    return 'Dificultad $difficulty';
  }

  @override
  String get endlessNewRun => 'Nuevo';

  @override
  String endlessResumeAt(int index) {
    return 'Reanudar en $index';
  }

  @override
  String get endlessStartNewRun => 'Iniciar nueva run infinita';

  @override
  String endlessBestSummary(int score, int index, Object avg) {
    return 'Mejor puntuacion: $score | Mejor indice: $index | Mejor media: $avg';
  }

  @override
  String get endlessCouldNotLoadPuzzle =>
      'No se pudo cargar el puzzle infinito.';

  @override
  String endlessRunSeed(int seed) {
    return 'Semilla de run: $seed';
  }

  @override
  String get endlessSolved => 'Completado!';

  @override
  String endlessShareText(int difficulty, int index, Object time) {
    return 'Infinito D$difficulty #$index en $time.';
  }

  @override
  String endlessCopyText(int index, Object time, int streak) {
    return 'Zip #$index - $time - Racha $streak Y';
  }

  @override
  String levelsPackTitle(Object pack) {
    return 'Niveles de $pack';
  }

  @override
  String get gameClear => 'Limpiar';

  @override
  String gameNext(Object value) {
    return 'Siguiente $value';
  }

  @override
  String gameStars(Object value) {
    return 'Estrellas $value';
  }

  @override
  String get victoryPrimaryNextLevel => 'Siguiente nivel';

  @override
  String get victoryPrimaryPlayAgain => 'Jugar de nuevo';

  @override
  String get retry => 'Reintentar';
}
