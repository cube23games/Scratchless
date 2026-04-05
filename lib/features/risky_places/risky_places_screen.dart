import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';

import '../../app/app_theme.dart';
import '../../core/models/premium_state.dart';
import '../../core/models/risky_place.dart';
import '../../core/services/distance_formatter_service.dart';
import '../../core/services/live_place_alert_service.dart';
import '../../core/services/place_search_service.dart';
import 'place_search_screen.dart';
import 'place_pin_confirm_screen.dart';
import 'widgets/place_map_preview.dart';
import '../../core/services/risky_time_service.dart';
import '../../shared/widgets/app_button.dart';
import '../../shared/widgets/app_card.dart';

class RiskyPlacesScreen extends StatefulWidget {
  final List<RiskyPlace> places;
  final PremiumState premiumState;
  final RiskyTimeInsight riskyTimeInsight;
  final VoidCallback onStartPremiumTrial;
  final Future<String> Function() onEnableLivePlaceAlertsBackground;
  final ValueChanged<RiskyPlace> onAddPlace;
  final ValueChanged<RiskyPlace> onEditPlace;
  final void Function(String id) onDeletePlace;

  const RiskyPlacesScreen({
    super.key,
    required this.places,
    required this.premiumState,
    required this.riskyTimeInsight,
    required this.onStartPremiumTrial,
    required this.onEnableLivePlaceAlertsBackground,
    required this.onAddPlace,
    required this.onEditPlace,
    required this.onDeletePlace,
  });

  @override
  State<RiskyPlacesScreen> createState() => _RiskyPlacesScreenState();
}

class _RiskyPlacesScreenState extends State<RiskyPlacesScreen> {
  late List<RiskyPlace> _places;
  LiveAlertDebugState _debugState = LiveAlertDebugState.empty();

  @override
  void initState() {
    super.initState();
    _places = List<RiskyPlace>.from(widget.places);
    _debugState = LivePlaceAlertService.instance.getDebugState();
    _refreshLiveAlertDebugState();
  }

  Future<void> _refreshLiveAlertDebugState() async {
    await LivePlaceAlertService.instance.syncMonitoredPlaces(
      premiumState: widget.premiumState,
      riskyPlaces: _places,
      riskyTimeInsight: widget.riskyTimeInsight,
    );

    if (!mounted) {
      return;
    }

    setState(() {
      _debugState = LivePlaceAlertService.instance.getDebugState();
    });
  }

  String _placeDebugStatus(String placeId) {
    for (final item in _debugState.placeItems) {
      if (item.placeId == placeId) {
        return item.status;
      }
    }
    return 'Status unavailable';
  }

  String _sourceBadgeLabel(String source) {
    switch (source) {
      case 'search':
        return 'Search';
      case 'currentLocation':
        return 'Current location';
      case 'adjustedOnMap':
        return 'Adjusted on map';
      default:
        return 'Manual';
    }
  }

  String _confidenceHint({
    required String source,
    required int radiusMeters,
    required bool hasCoordinates,
  }) {
    if (!hasCoordinates) {
      return 'Save a location before relying on live alerts.';
    }

    String base;
    switch (source) {
      case 'search':
        base = 'Usually good — check the pin near clustered stores.';
        break;
      case 'currentLocation':
        base = 'Best when captured at the exact stop.';
        break;
      case 'adjustedOnMap':
        base = 'User-confirmed on map.';
        break;
      default:
        base = 'Review carefully before relying on live alerts.';
        break;
    }

    if (radiusMeters <= 150) {
      return '$base Tighter radius.';
    }
    if (radiusMeters >= 500) {
      return '$base Wider alert area.';
    }
    return base;
  }

  String _statusHeadline() {
    if (_debugState.isArmed && _debugState.eligiblePlaceCount > 0) {
      return 'Live alerts are ready to help';
    }

    final blocker = _debugState.topBlocker;
    if (blocker == 'Finish live alerts in Android settings') {
      return 'Live alerts are almost ready';
    }
    if (blocker == 'Save a location for at least one place') {
      return 'Save one place location to keep going';
    }
    if (blocker == 'Turn on live alerts for a saved place') {
      return 'Live alerts are ready to set up';
    }
    if (blocker == 'Need Premium') {
      return 'Premium unlocks live alerts';
    }
    return 'Live alerts need one more step';
  }

  String _statusActionLine() {
    final blocker = _debugState.topBlocker;
    if (blocker != null && blocker.isNotEmpty) {
      return blocker;
    }

    if (_debugState.isArmed && _debugState.eligiblePlaceCount > 0) {
      return 'Everything is set up for live alerts.';
    }

    return 'Finish one place setup to turn live alerts on.';
  }

  String _statusDiagnosticsLine() {
    return 'Permission: ${_debugState.permissionLabel} • Armed: ${_debugState.eligiblePlaceCount} • Blocked: ${_debugState.blockedPlaceCount}';
  }

  String? _setupProgressNote() {
    if (_places.isEmpty) {
      return null;
    }

    if (_debugState.eligiblePlaceCount > 0) {
      return _debugState.eligiblePlaceCount == 1
          ? '1 place is ready for live alerts.'
          : '${_debugState.eligiblePlaceCount} places are ready for live alerts.';
    }

    final placesWithLocation = _places
        .where((place) => place.latitude != null && place.longitude != null)
        .length;

    if (placesWithLocation > 0) {
      return placesWithLocation == 1
          ? '1 place already has a saved location.'
          : '$placesWithLocation places already have saved locations.';
    }

    return _places.length == 1
        ? '1 place saved — now finish its setup.'
        : '${_places.length} places saved — finish one setup next.';
  }

  String _saveSuccessMessage({
    required int beforePlaceCount,
    required int beforeReadyCount,
    required RiskyPlace savedPlace,
  }) {
    final afterPlaceCount = _places.length;
    final afterReadyCount = _debugState.eligiblePlaceCount;
    final hasLocation =
        savedPlace.latitude != null && savedPlace.longitude != null;

    if (beforeReadyCount == 0 && afterReadyCount == 1) {
      return 'Nice work — your first place is ready for live alerts.';
    }

    if (afterReadyCount > beforeReadyCount) {
      return afterReadyCount == 1
          ? 'This place is ready for live alerts.'
          : '$afterReadyCount places are ready for live alerts.';
    }

    if (beforePlaceCount == 0 && afterPlaceCount == 1) {
      return hasLocation
          ? 'First risky place saved — location included.'
          : 'First risky place saved — now add its location.';
    }

    if (hasLocation) {
      return 'Location saved — this place is getting close.';
    }

    return 'Place saved — now add its location.';
  }

  String? _primaryActionLabel() {
    final blocker = _debugState.topBlocker;

    if (blocker == 'Need Premium') {
      return 'Start Premium';
    }
    if (blocker == 'Finish live alerts in Android settings') {
      return 'Finish live alerts';
    }
    if (blocker == 'Save a location for at least one place') {
      return 'Add place location';
    }
    if (blocker == 'Turn on live alerts for a saved place') {
      return 'Choose a place';
    }
    if (_debugState.isArmed && _debugState.eligiblePlaceCount > 0) {
      return 'Refresh status';
    }

    return null;
  }

  Future<void> _runPrimaryAction() async {
    final blocker = _debugState.topBlocker;

    if (blocker == 'Need Premium') {
      widget.onStartPremiumTrial();
      await _refreshLiveAlertDebugState();
      return;
    }

    if (blocker == 'Finish live alerts in Android settings') {
      await widget.onEnableLivePlaceAlertsBackground();
      await _refreshLiveAlertDebugState();
      return;
    }

    if (blocker == 'Save a location for at least one place') {
      final placeNeedingLocation = _places.cast<RiskyPlace?>().firstWhere(
        (place) =>
            place != null &&
            place.locationAlertsEnabled &&
            (place.latitude == null || place.longitude == null),
        orElse: () => null,
      );
      if (placeNeedingLocation != null && mounted) {
        await _openEditPlace(context, placeNeedingLocation);
      }
      return;
    }

    if (blocker == 'Turn on live alerts for a saved place') {
      final placeWithAlertsOff = _places.cast<RiskyPlace?>().firstWhere(
        (place) => place != null && !place.locationAlertsEnabled,
        orElse: () => null,
      );
      if (placeWithAlertsOff != null && mounted) {
        await _openEditPlace(context, placeWithAlertsOff);
        return;
      }
      if (mounted) {
        await _openAddPlace(context);
      }
      return;
    }

    await _refreshLiveAlertDebugState();
  }

  String _friendlyPlaceState(String rawStatus) {
    switch (rawStatus) {
      case 'Armed':
        return 'Ready';
      case 'Needs one more Android permission step':
        return 'Almost ready';
      case 'Save this place’s location first':
        return 'Location needed';
      case 'Turn on live alerts for this place':
        return 'Live alerts off';
      case 'Start Premium to arm this place':
        return 'Premium needed';
      default:
        return 'Needs attention';
    }
  }

  String _friendlyPlaceDetail(String rawStatus) {
    switch (rawStatus) {
      case 'Armed':
        return 'This place is ready for live alerts.';
      case 'Needs one more Android permission step':
        return 'Finish the Android step to turn live alerts on for this place.';
      case 'Save this place’s location first':
        return 'Save this place’s location first.';
      case 'Turn on live alerts for this place':
        return 'Turn on live alerts for this place.';
      case 'Start Premium to arm this place':
        return 'Start Premium to turn live alerts on for this place.';
      default:
        return rawStatus;
    }
  }

  String _primarySetupState(RiskyPlace place) {
    return _friendlyPlaceState(_placeDebugStatus(place.id));
  }

  String _secondarySetupExplanation(RiskyPlace place) {
    return _friendlyPlaceDetail(_placeDebugStatus(place.id));
  }

  String _editCue(RiskyPlace place) {
    return _primarySetupState(place) == 'Ready'
        ? 'Tap to edit'
        : 'Tap to finish setup';
  }

  String _confidenceBadgeLabel(RiskyPlace place) {
    final hasCoordinates = place.latitude != null && place.longitude != null;
    if (!hasCoordinates) {
      return 'Confidence: Low';
    }

    switch (place.locationSource) {
      case 'adjustedOnMap':
        return 'Confidence: High';
      case 'search':
      case 'currentLocation':
        return 'Confidence: Medium';
      default:
        return 'Confidence: Review';
    }
  }

  Widget _buildSignalChip(String label, {bool accent = false}) {
    final Color borderColor =
        accent ? AppTheme.accent : AppTheme.mutedText.withOpacity(0.18);
    final Color fillColor = accent
        ? AppTheme.accent.withOpacity(0.12)
        : AppTheme.mutedText.withOpacity(0.08);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: fillColor,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: borderColor),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: accent ? AppTheme.accent : AppTheme.mutedText,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  bool _hasEnabledPlaces() {
    return _places.any((place) => place.locationAlertsEnabled);
  }

  bool _hasEnabledPlaceWithSavedLocation() {
    return _places.any(
      (place) =>
          place.locationAlertsEnabled &&
          place.latitude != null &&
          place.longitude != null,
    );
  }

  bool _backgroundReady() {
    return widget.premiumState.livePlaceAlertAccess == 'fullBackground';
  }

  String _setupHeadline() {
    if (!widget.premiumState.isPremium) {
      return 'Start Premium to unlock live alerts';
    }
    if (_debugState.isArmed && _debugState.eligiblePlaceCount > 0) {
      return 'Live alerts are ready to help';
    }
    if (widget.premiumState.livePlaceAlertAccess == 'foregroundOnly') {
      return 'One more step and live alerts will be ready';
    }
    return 'Set up live alerts in 3 steps';
  }

  String _setupBody() {
    if (!widget.premiumState.isPremium) {
      return 'Premium adds live alerts for the risky places you save.';
    }
    if (_debugState.isArmed && _debugState.eligiblePlaceCount > 0) {
      return 'ScratchLess can now watch your saved risky places and nudge you before a stop becomes automatic.';
    }
    if (_places.isEmpty) {
      return 'Start with one place and build from there.';
    }
    return 'These three steps are the quickest way to get live alerts working.';
  }

  bool _isFirstPlaceFlow() {
    return _places.isEmpty;
  }

  String _emptyStateHeadline() {
    return 'Add the first place that tends to turn into a ticket';
  }

  String _emptyStateBody() {
    return 'Start with one gas station, store, or stop you usually talk yourself into.';
  }

  String _emptyStateBenefitLine() {
    return 'ScratchLess can only help with the places you name first.';
  }

  String _addPlaceButtonLabel() {
    return _isFirstPlaceFlow()
        ? 'Add your first risky place'
        : 'Add risky place';
  }

  Widget _setupStepRow({
    required String title,
    required String detail,
    required bool done,
    required bool active,
  }) {
    final IconData icon = done
        ? Icons.check_circle_rounded
        : active
            ? Icons.radio_button_checked_rounded
            : Icons.circle_outlined;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Icon(
              icon,
              size: 18,
              color: done || active ? AppTheme.accent : AppTheme.mutedText,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  detail,
                  style: const TextStyle(
                    color: AppTheme.mutedText,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _eventTimeLabel(DateTime time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  List<RiskyPlace> get _sortedPlaces {
    final items = [..._places];
    items.sort((a, b) {
      if (a.isTopRisk == b.isTopRisk) {
        return a.label.toLowerCase().compareTo(b.label.toLowerCase());
      }
      return a.isTopRisk ? -1 : 1;
    });
    return items;
  }

  Future<void> _openAddPlace(BuildContext context) async {
    final beforePlaceCount = _places.length;
    final beforeReadyCount = _debugState.eligiblePlaceCount;

    final result = await Navigator.of(context).push<_EditRiskyPlaceResult>(
      MaterialPageRoute(
        builder: (_) => const _EditRiskyPlaceScreen(),
        fullscreenDialog: true,
      ),
    );

    if (result == null || result.savedPlace == null) {
      return;
    }

    final place = result.savedPlace!;

    setState(() {
      _places = [
        place,
        ..._places.where((item) => item.id != place.id),
      ];
    });

    widget.onAddPlace(place);
    await _refreshLiveAlertDebugState();

    if (mounted) {
      ScaffoldMessenger.maybeOf(context)?.showSnackBar(
        SnackBar(
          content: Text(
            _saveSuccessMessage(
              beforePlaceCount: beforePlaceCount,
              beforeReadyCount: beforeReadyCount,
              savedPlace: place,
            ),
          ),
        ),
      );
    }
  }

  Future<void> _openEditPlace(BuildContext context, RiskyPlace place) async {
    final beforePlaceCount = _places.length;
    final beforeReadyCount = _debugState.eligiblePlaceCount;

    final result = await Navigator.of(context).push<_EditRiskyPlaceResult>(
      MaterialPageRoute(
        builder: (_) => _EditRiskyPlaceScreen(initialPlace: place),
        fullscreenDialog: true,
      ),
    );

    if (result == null) {
      return;
    }

    if (result.deletedId != null) {
      final deletedId = result.deletedId!;

      setState(() {
        _places = _places.where((item) => item.id != deletedId).toList();
      });

      widget.onDeletePlace(deletedId);
      await _refreshLiveAlertDebugState();
      return;
    }

    if (result.savedPlace != null) {
      final updatedPlace = result.savedPlace!;

      setState(() {
        _places = _places.map((item) {
          if (item.id != updatedPlace.id) {
            return item;
          }
          return updatedPlace;
        }).toList();
      });

      widget.onEditPlace(updatedPlace);
      await _refreshLiveAlertDebugState();

      if (mounted) {
        ScaffoldMessenger.maybeOf(context)?.showSnackBar(
          SnackBar(
            content: Text(
              _saveSuccessMessage(
                beforePlaceCount: beforePlaceCount,
                beforeReadyCount: beforeReadyCount,
                savedPlace: updatedPlace,
              ),
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final displayPlaces = _sortedPlaces;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Risky places'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Risky-stop watchlist',
                  style: TextStyle(
                    color: AppTheme.mutedText,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'Keep the stops that can quietly turn into a ticket purchase visible.',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'This watchlist helps you notice the places that are easiest to shrug off and hardest to resist in the moment.',
                  style: TextStyle(
                    color: AppTheme.mutedText,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          AppCard(
            child: Builder(
              builder: (context) {
                final step1Done = _hasEnabledPlaces();
                final step2Done = _hasEnabledPlaceWithSavedLocation();
                final step3Done = _backgroundReady();

                final step1Active = !step1Done;
                final step2Active = step1Done && !step2Done;
                final step3Active = step1Done && step2Done && !step3Done;

                final step1Detail = step1Done
                    ? 'At least one saved place is turned on for live alerts.'
                    : (_places.isEmpty
                        ? 'Add your first risky place to begin.'
                        : 'Turn on live alerts for one saved place.');

                final step2Detail = step2Done
                    ? 'One saved place already has a location.'
                    : 'Use your current location at the stop, search for it, or enter coordinates manually.';

                final step3Detail = !widget.premiumState.isPremium
                    ? 'Premium unlocks the final Android permission step.'
                    : step3Done
                        ? 'Android permission is ready.'
                        : widget.premiumState.livePlaceAlertAccess == 'foregroundOnly'
                            ? 'Finish the Android settings step to turn live alerts on.'
                            : 'This step comes after you save a place and its location.';

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Live alert setup path',
                      style: TextStyle(
                        color: AppTheme.mutedText,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _setupHeadline(),
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _setupBody(),
                      style: const TextStyle(
                        color: AppTheme.mutedText,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _setupStepRow(
                      title: 'Choose a risky place',
                      detail: step1Detail,
                      done: step1Done,
                      active: step1Active,
                    ),
                    _setupStepRow(
                      title: 'Save its location',
                      detail: step2Detail,
                      done: step2Done,
                      active: step2Active,
                    ),
                    _setupStepRow(
                      title: 'Finish Android live alerts',
                      detail: step3Detail,
                      done: step3Done,
                      active: step3Active,
                    ),
                  ],
                );
              },
            ),
          ),
          const SizedBox(height: 12),
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Live alert progress',
                  style: TextStyle(
                    color: AppTheme.mutedText,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _statusHeadline(),
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _statusActionLine(),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                if (_setupProgressNote() != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    _setupProgressNote()!,
                    style: const TextStyle(
                      color: AppTheme.mutedText,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
                if (_primaryActionLabel() != null) ...[
                  const SizedBox(height: 12),
                  AppButton(
                    label: _primaryActionLabel()!,
                    icon: Icons.arrow_forward_rounded,
                    onPressed: _runPrimaryAction,
                  ),
                ],
                const SizedBox(height: 8),
                Text(
                  _statusDiagnosticsLine(),
                  style: const TextStyle(
                    color: AppTheme.mutedText,
                    fontSize: 13,
                  ),
                ),
                if (_debugState.lastEventMessage != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    'Last event: ${_debugState.lastEventMessage}',
                    style: const TextStyle(
                      color: AppTheme.mutedText,
                      fontSize: 14,
                    ),
                  ),
                ],
                const SizedBox(height: 12),
                AppButton(
                  label: 'Refresh live alert status',
                  icon: Icons.sync_rounded,
                  isPrimary: false,
                  onPressed: _refreshLiveAlertDebugState,
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Recent live alert activity',
                  style: TextStyle(
                    color: AppTheme.mutedText,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                if (_debugState.recentEvents.isEmpty)
                  const Text(
                    'No live alert activity yet.',
                    style: TextStyle(
                      color: AppTheme.mutedText,
                      fontSize: 14,
                    ),
                  )
                else
                  ..._debugState.recentEvents.map((event) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Text(
                        '${_eventTimeLabel(event.createdAt)} — ${event.message}',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    );
                  }),
              ],
            ),
          ),
          const SizedBox(height: 12),
          AppButton(
            label: _addPlaceButtonLabel(),
            icon: Icons.add_location_alt_rounded,
            onPressed: () => _openAddPlace(context),
          ),
          const SizedBox(height: 12),
          if (displayPlaces.isEmpty)
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Start here',
                    style: TextStyle(
                      color: AppTheme.mutedText,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _emptyStateHeadline(),
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _emptyStateBody(),
                    style: const TextStyle(
                      color: AppTheme.mutedText,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _emptyStateBenefitLine(),
                    style: const TextStyle(
                      color: AppTheme.mutedText,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 12),
                  AppButton(
                    label: 'Add your first risky place',
                    icon: Icons.add_location_alt_rounded,
                    onPressed: () => _openAddPlace(context),
                  ),
                ],
              ),
            )
          else
            ...displayPlaces.map((place) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: AppCard(
                  onTap: () => _openEditPlace(context, place),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              place.label,
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                          if (place.isTopRisk)
                            _buildSignalChip('Top risk', accent: true),
                        ],
                      ),
                      if (place.note.trim().isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Text(
                          place.note,
                          style: const TextStyle(
                            color: AppTheme.mutedText,
                            fontSize: 14,
                          ),
                        ),
                      ],
                      const SizedBox(height: 12),
                      Text(
                        _primarySetupState(place),
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _secondarySetupExplanation(place),
                        style: const TextStyle(
                          color: AppTheme.mutedText,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _buildSignalChip(
                            'Radius: ${DistanceFormatterService.usPlaceRadiusLabel(place.radiusMeters)}',
                          ),
                          _buildSignalChip(
                            'Source: ${_sourceBadgeLabel(place.locationSource)}',
                          ),
                          _buildSignalChip(
                            _confidenceBadgeLabel(place),
                          ),
                          _buildSignalChip(
                            place.locationAlertsEnabled
                                ? 'Live alerts on'
                                : 'Live alerts off',
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text(
                        _editCue(place),
                        style: const TextStyle(
                          color: AppTheme.mutedText,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
        ],
      ),
    );
  }
}

class _EditRiskyPlaceScreen extends StatefulWidget {
  final RiskyPlace? initialPlace;

  const _EditRiskyPlaceScreen({
    this.initialPlace,
  });

  @override
  State<_EditRiskyPlaceScreen> createState() => _EditRiskyPlaceScreenState();
}

class _EditRiskyPlaceScreenState extends State<_EditRiskyPlaceScreen> {
  static const List<_RadiusPreset> _radiusPresets = <_RadiusPreset>[
    _RadiusPreset(label: 'Small', meters: 150),
    _RadiusPreset(label: 'Medium', meters: 300),
    _RadiusPreset(label: 'Large', meters: 500),
  ];

  late final TextEditingController _labelController;
  late final TextEditingController _noteController;
  late final TextEditingController _latitudeController;
  late final TextEditingController _longitudeController;
  late bool _isTopRisk;
  late int _radiusMeters;
  late bool _locationAlertsEnabled;
  late String _locationSource;
  bool _capturingLocation = false;
  String? _selectedPlaceAddress;

  bool get _isEditing => widget.initialPlace != null;

  @override
  void initState() {
    super.initState();
    _labelController = TextEditingController(
      text: widget.initialPlace?.label ?? '',
    );
    _noteController = TextEditingController(
      text: widget.initialPlace?.note ?? '',
    );
    _latitudeController = TextEditingController(
      text: _formatCoordinate(widget.initialPlace?.latitude),
    );
    _longitudeController = TextEditingController(
      text: _formatCoordinate(widget.initialPlace?.longitude),
    );
    _isTopRisk = widget.initialPlace?.isTopRisk ?? false;
    _radiusMeters = widget.initialPlace?.radiusMeters ?? 300;
    _locationSource = widget.initialPlace?.locationSource ?? 'manual';
    _selectedPlaceAddress = null;
    _locationAlertsEnabled =
        widget.initialPlace?.locationAlertsEnabled ?? false;
  }

  @override
  void dispose() {
    _labelController.dispose();
    _noteController.dispose();
    _latitudeController.dispose();
    _longitudeController.dispose();
    super.dispose();
  }

  String _formatCoordinate(double? value) {
    if (value == null) {
      return '';
    }
    return value.toStringAsFixed(6);
  }

  String _sourceBadgeLabel(String source) {
    switch (source) {
      case 'search':
        return 'Search';
      case 'currentLocation':
        return 'Current location';
      case 'adjustedOnMap':
        return 'Adjusted on map';
      default:
        return 'Manual';
    }
  }

  String _confidenceHint() {
    final hasCoordinates =
        _parseCoordinate(_latitudeController.text) != null &&
        _parseCoordinate(_longitudeController.text) != null;

    if (!hasCoordinates) {
      return 'Save a location before relying on live alerts.';
    }

    String base;
    switch (_locationSource) {
      case 'search':
        base = 'Usually good — check the pin near clustered stores.';
        break;
      case 'currentLocation':
        base = 'Best when captured at the exact stop.';
        break;
      case 'adjustedOnMap':
        base = 'User-confirmed on map.';
        break;
      default:
        base = 'Review carefully before relying on live alerts.';
        break;
    }

    if (_radiusMeters <= 150) {
      return '$base Tighter radius.';
    }
    if (_radiusMeters >= 500) {
      return '$base Wider alert area.';
    }
    return base;
  }

  double? _parseCoordinate(String raw) {
    final normalized = raw.trim();
    if (normalized.isEmpty) {
      return null;
    }
    return double.tryParse(normalized);
  }

  LatLng? _currentDraftLatLng() {
    final latitude = _parseCoordinate(_latitudeController.text);
    final longitude = _parseCoordinate(_longitudeController.text);

    if (latitude == null || longitude == null) {
      return null;
    }

    return LatLng(latitude, longitude);
  }

  Future<void> _searchForPlace() async {
    final selection = await Navigator.of(context).push<PlaceSearchSelection>(
      MaterialPageRoute<PlaceSearchSelection>(
        builder: (_) => const PlaceSearchScreen(),
        fullscreenDialog: true,
      ),
    );

    if (selection == null || !mounted) {
      return;
    }

    setState(() {
      _labelController.text = selection.label;
      _latitudeController.text = _formatCoordinate(selection.latitude);
      _longitudeController.text = _formatCoordinate(selection.longitude);
      _selectedPlaceAddress = selection.address;
      _locationSource = 'search';
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Place selected — now give it a quick map check.'),
      ),
    );
  }

  Future<void> _confirmOnMap() async {
    final draftPoint = _currentDraftLatLng();
    if (draftPoint == null) {
      return;
    }

    final confirmed =
        await Navigator.of(context).push<PlacePinConfirmResult>(
      MaterialPageRoute<PlacePinConfirmResult>(
        builder: (_) => PlacePinConfirmScreen(
          initialPoint: draftPoint,
          placeLabel: _labelController.text.trim(),
          radiusMeters: _radiusMeters,
        ),
        fullscreenDialog: true,
      ),
    );

    if (confirmed == null || !mounted) {
      return;
    }

    setState(() {
      _latitudeController.text =
          _formatCoordinate(confirmed.point.latitude);
      _longitudeController.text =
          _formatCoordinate(confirmed.point.longitude);
      _radiusMeters = confirmed.radiusMeters;
      _locationSource = 'adjustedOnMap';
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Nice — map location and alert radius updated.'),
      ),
    );
  }

  Future<void> _useCurrentLocation() async {
    setState(() {
      _capturingLocation = true;
    });

    try {
      final coordinate =
          await LivePlaceAlertService.instance.captureCurrentPosition();

      if (!mounted) {
        return;
      }

      if (coordinate == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Location permission was not granted.'),
          ),
        );
        return;
      }

      setState(() {
        _latitudeController.text = _formatCoordinate(coordinate.latitude);
        _longitudeController.text = _formatCoordinate(coordinate.longitude);
        _locationSource = 'currentLocation';
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Current location saved — this place is getting close (${coordinate.accuracy.toStringAsFixed(0)}m accuracy).',
          ),
        ),
      );
    } catch (_) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not capture the current location.'),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _capturingLocation = false;
        });
      }
    }
  }

  void _save() {
    final label = _labelController.text.trim();
    if (label.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Enter the stop or place name before saving.'),
        ),
      );
      return;
    }

    final note = _noteController.text.trim();
    final latitude = _parseCoordinate(_latitudeController.text);
    final longitude = _parseCoordinate(_longitudeController.text);

    if (_latitudeController.text.trim().isNotEmpty && latitude == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Enter a valid latitude.'),
        ),
      );
      return;
    }

    if (_longitudeController.text.trim().isNotEmpty && longitude == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Enter a valid longitude.'),
        ),
      );
      return;
    }

    if (latitude != null && (latitude < -90 || latitude > 90)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Latitude must be between -90 and 90.'),
        ),
      );
      return;
    }

    if (longitude != null && (longitude < -180 || longitude > 180)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Longitude must be between -180 and 180.'),
        ),
      );
      return;
    }

    final place = RiskyPlace(
      id: widget.initialPlace?.id ??
          DateTime.now().microsecondsSinceEpoch.toString(),
      label: label,
      note: note,
      isTopRisk: _isTopRisk,
      radiusMeters: _radiusMeters,
      locationAlertsEnabled: _locationAlertsEnabled,
      latitude: latitude,
      longitude: longitude,
      locationSource: _locationSource.isEmpty ? 'manual' : _locationSource,
    );

    Navigator.of(context).pop(
      _EditRiskyPlaceResult(savedPlace: place),
    );
  }

  Future<void> _delete() async {
    if (!_isEditing) {
      return;
    }

    final confirmed = await showDialog<bool>(
          context: context,
          builder: (dialogContext) {
            return AlertDialog(
              title: const Text('Delete risky place?'),
              content: const Text(
                'This removes the place from your watchlist.',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(false),
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(true),
                  child: const Text('Delete'),
                ),
              ],
            );
          },
        ) ??
        false;

    if (!confirmed) {
      return;
    }

    Navigator.of(context).pop(
      _EditRiskyPlaceResult(
        deletedId: widget.initialPlace!.id,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final previewPoint = _currentDraftLatLng();

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit risky place' : 'Add risky place'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Place details',
                  style: TextStyle(
                    color: AppTheme.mutedText,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Name the stop you want to keep front of mind.',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _labelController,
                  decoration: const InputDecoration(
                    labelText: 'Place name',
                    hintText: 'Gas station by work or store near home',
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _noteController,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Optional note',
                    hintText:
                        'Usually risky after payday, after work, or when I feel stressed.',
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Choose a location',
                  style: TextStyle(
                    color: AppTheme.mutedText,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Search for the place, use your current spot, or enter coordinates manually.',
                  style: TextStyle(
                    color: AppTheme.mutedText,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 12),
                AppButton(
                  label: 'Search for a place',
                  icon: Icons.search_rounded,
                  isPrimary: false,
                  onPressed: _searchForPlace,
                ),
                if (_selectedPlaceAddress != null &&
                    _selectedPlaceAddress!.trim().isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Text(
                    'Selected place: $_selectedPlaceAddress',
                    style: const TextStyle(
                      color: AppTheme.mutedText,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
                const SizedBox(height: 12),
                AppButton(
                  label: _capturingLocation
                      ? 'Capturing current location...'
                      : 'Use my current location',
                  icon: Icons.my_location_rounded,
                  isPrimary: false,
                  onPressed: _capturingLocation ? null : _useCurrentLocation,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _latitudeController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                    signed: true,
                  ),
                  decoration: const InputDecoration(
                    labelText: 'Latitude',
                    hintText: '35.2271',
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _longitudeController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                    signed: true,
                  ),
                  decoration: const InputDecoration(
                    labelText: 'Longitude',
                    hintText: '-80.8431',
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Manual coordinates are here when search or current location are not enough.',
                  style: TextStyle(
                    color: AppTheme.mutedText,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (previewPoint != null) ...[
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton(
                      onPressed: () {
                        setState(() {
                          _latitudeController.clear();
                          _longitudeController.clear();
                          _locationSource = 'manual';
                        });
                      },
                      child: const Text('Clear saved location'),
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (previewPoint != null) ...[
            const SizedBox(height: 12),
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Confirm on map',
                    style: TextStyle(
                      color: AppTheme.mutedText,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Take one last look at the pin and alert area before saving.',
                    style: TextStyle(
                      color: AppTheme.mutedText,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 180,
                    child: PlaceMapPreview(
                      latitude: previewPoint.latitude,
                      longitude: previewPoint.longitude,
                      radiusMeters: _radiusMeters,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Source: ${_sourceBadgeLabel(_locationSource)}',
                    style: const TextStyle(
                      color: AppTheme.mutedText,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Confidence: ${_confidenceHint()}',
                    style: const TextStyle(
                      color: AppTheme.mutedText,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Alert radius: ${DistanceFormatterService.usPlaceRadiusLabel(_radiusMeters)}',
                    style: const TextStyle(
                      color: AppTheme.mutedText,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Use map confirm if this stop is large or close to other stores.',
                    style: TextStyle(
                      color: AppTheme.mutedText,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 12),
                  AppButton(
                    label: 'Confirm on map',
                    icon: Icons.place_rounded,
                    isPrimary: false,
                    onPressed: _confirmOnMap,
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 12),
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Alert size',
                  style: TextStyle(
                    color: AppTheme.mutedText,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Choose how tight or wide the alert area should feel.',
                  style: TextStyle(
                    color: AppTheme.mutedText,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: _radiusPresets.map((preset) {
                    return ChoiceChip(
                      label: Text(
                        '${preset.label} • ${DistanceFormatterService.usPlaceRadiusLabel(preset.meters)}',
                      ),
                      selected: _radiusMeters == preset.meters,
                      onSelected: (_) {
                        setState(() {
                          _radiusMeters = preset.meters;
                        });
                      },
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Options',
                  style: TextStyle(
                    color: AppTheme.mutedText,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Live place alerts'),
                  subtitle: const Text(
                    'Use this stop for live alerts when Premium and Android permissions are ready.',
                  ),
                  value: _locationAlertsEnabled,
                  onChanged: (value) {
                    setState(() {
                      _locationAlertsEnabled = value;
                    });
                  },
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Mark as top risk'),
                  subtitle: const Text(
                    'Keep this place surfaced first and use stronger support wording later.',
                  ),
                  value: _isTopRisk,
                  onChanged: (value) {
                    setState(() {
                      _isTopRisk = value;
                    });
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          AppButton(
            label: _isEditing ? 'Save changes' : 'Save risky place',
            icon: Icons.save_rounded,
            onPressed: _save,
          ),
          if (_isEditing) ...[
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: TextButton(
                onPressed: _delete,
                child: const Text('Delete risky place'),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _EditRiskyPlaceResult {
  final RiskyPlace? savedPlace;
  final String? deletedId;

  const _EditRiskyPlaceResult({
    this.savedPlace,
    this.deletedId,
  });
}

class _RadiusPreset {
  final String label;
  final int meters;

  const _RadiusPreset({
    required this.label,
    required this.meters,
  });
}
