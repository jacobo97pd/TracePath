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
  String get liveDuelInviteTitle => 'Invitación de duelo en vivo';

  @override
  String liveDuelInviteBody(Object from) {
    return '$from te desafió a un duelo en vivo.\n¿Quieres aceptar?';
  }

  @override
  String get decline => 'Rechazar';

  @override
  String get accept => 'Aceptar';

  @override
  String get liveInviteCouldNotProcess => 'No se pudo procesar la invitación';

  @override
  String get liveInviteNoLongerAvailable =>
      'La invitación ya no está disponible';

  @override
  String get liveInviteAlreadyClosed => 'Este duelo ya está cerrado';

  @override
  String get liveInviteInvalidAccount =>
      'La invitación no es válida para esta cuenta';

  @override
  String get liveInviteInvalidPayload =>
      'El contenido de la invitación es inválido';

  @override
  String get liveInvitePermissionsBlocked =>
      'Los permisos bloquearon esta acción';

  @override
  String get liveInviteNetworkIssue =>
      'Problema de red al procesar la invitación';

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
      'Traza caminos más rápido, mejora tu precisión y supera cada desafío.';

  @override
  String get homeStartSolving => '¡EMPIEZA A RESOLVER!';

  @override
  String get homeJumpToNextPuzzle => 'Salta a tu próximo puzzle';

  @override
  String get homeContinue => 'Continuar';

  @override
  String get homeContinueFirstRun => 'Empieza tu primera partida';

  @override
  String homeContinueResumeLevel(int level) {
    return 'Nivel $level · Retoma donde lo dejaste';
  }

  @override
  String get homeQuickAccessTitle => 'Accesos rápidos';

  @override
  String get homeQuickAccessSubtitle => 'Entra directo a tus modos favoritos';

  @override
  String get homeQuickDailyTitle => 'Puzzle diario';

  @override
  String get homeQuickDailySubtitle => 'Un desafío cada día';

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
  String get homeMetricHighestLevel => 'Nivel más alto';

  @override
  String homeDailySolved(int count) {
    return 'Puzzles diarios resueltos: $count';
  }

  @override
  String get homeViewProfile => 'Ver perfil';

  @override
  String get duelHubTitle => 'Centro de duelo';

  @override
  String get duelHubSubtitle => 'Desafía amigos y juega partidas en vivo.';

  @override
  String get duelCreating => 'Creando duelo...';

  @override
  String get duelChallengeFriend => 'Desafiar a un amigo';

  @override
  String get duelIncomingInvitesTitle => 'Invitaciones entrantes';

  @override
  String get duelIncomingInvitesSubtitle => 'Acepta o rechaza desafíos en vivo';

  @override
  String get duelNoPendingInvitesTitle => 'No hay invitaciones pendientes';

  @override
  String get duelNoPendingInvitesSubtitle =>
      'Los nuevos desafíos aparecerán aquí.';

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
  String get duelNoActiveSubtitle => 'Empieza un desafío para jugar en vivo.';

  @override
  String get duelActiveLoadErrorTitle =>
      'No se pudieron cargar las partidas activas';

  @override
  String get duelHistoryTitle => 'Historial';

  @override
  String get duelHistorySubtitle => 'Resultados recientes de duelo';

  @override
  String get duelHistoryComingSoonTitle => 'Historial próximamente';

  @override
  String get duelHistoryComingSoonSubtitle =>
      'Tus últimos duelos se mostrarán aquí.';

  @override
  String get duelChooseFriend => 'Elige un amigo';

  @override
  String get duelCouldNotLoadFriends => 'No se pudieron cargar los amigos';

  @override
  String get duelNoFriendsYet => 'Aún no tienes amigos';

  @override
  String get duelInviteSentText => 'te envió una invitación de duelo en vivo.';

  @override
  String duelAcceptError(Object error) {
    return 'No se pudo aceptar la invitación: $error';
  }

  @override
  String duelDeclineError(Object error) {
    return 'No se pudo rechazar la invitación: $error';
  }

  @override
  String get duelAccept => 'Aceptar';

  @override
  String get duelResume => 'Reanudar';

  @override
  String get duelStatusPending => 'Pendiente';

  @override
  String get duelStatusCountdown => 'Cuenta atrás';

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
    return 'Nivel: $level · $status';
  }

  @override
  String get duelErrorFinishCurrentFirst =>
      'Termina primero tu duelo en curso.';

  @override
  String get duelErrorFriendBusy => 'Este amigo ya está en otro duelo.';

  @override
  String get duelErrorNoPuzzles => 'No hay puzzles disponibles ahora mismo.';

  @override
  String get duelErrorInvalidTarget =>
      'No se pudo iniciar duelo con este amigo.';

  @override
  String get duelErrorCreateInvite =>
      'No se pudo crear la invitación de duelo ahora mismo.';

  @override
  String get duelRemoveActiveTitle => 'Eliminar partida activa';

  @override
  String get duelRemoveActiveBody =>
      'Esta partida activa se cerrará y dejará de aparecer en esta lista.';

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
  String get friendChallengeTitle => 'Desafío amistoso';

  @override
  String get friendChallengeUnavailable => 'Desafío no disponible.';

  @override
  String friendChallengePuzzle(Object puzzleId) {
    return 'Puzzle: $puzzleId';
  }

  @override
  String friendChallengeMode(Object mode) {
    return 'Modo: $mode';
  }

  @override
  String get friendChallengePlayButton => 'Jugar desafío amistoso';

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
  String get shopLoadMore => 'Cargar más';

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
      'Estilo visual único para el trazo de tu ruta.';

  @override
  String get profileGuestMode => 'Modo invitado';

  @override
  String get profileGoogleAccount => 'Cuenta de Google';

  @override
  String get profileLogout => 'Cerrar sesion';

  @override
  String get profileLogoutConfirm => 'Quieres cerrar sesion?';

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
  String get profileLockerTitle => 'Locker';

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
  String get profileVaultLockerTitle => 'Boveda / Locker';

  @override
  String get profileReadyToEquip => 'Listo para equipar';
}
