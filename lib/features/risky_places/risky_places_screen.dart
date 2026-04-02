import 'package:flutter/material.dart';

import '../../app/app_theme.dart';
import '../../core/models/risky_place.dart';
import '../../shared/widgets/app_button.dart';
import '../../shared/widgets/app_card.dart';

class RiskyPlacesScreen extends StatefulWidget {
  final List<RiskyPlace> places;
  final ValueChanged<RiskyPlace> onAddPlace;
  final ValueChanged<RiskyPlace> onEditPlace;
  final void Function(String id) onDeletePlace;

  const RiskyPlacesScreen({
    super.key,
    required this.places,
    required this.onAddPlace,
    required this.onEditPlace,
    required this.onDeletePlace,
  });

  @override
  State<RiskyPlacesScreen> createState() => _RiskyPlacesScreenState();
}

class _RiskyPlacesScreenState extends State<RiskyPlacesScreen> {
  late List<RiskyPlace> _places;

  @override
  void initState() {
    super.initState();
    _places = List<RiskyPlace>.from(widget.places);
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
  }

  Future<void> _openEditPlace(BuildContext context, RiskyPlace place) async {
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
                  'Keep the stores, routes, and stops most likely to turn into a ticket purchase visible.',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'Use this watchlist to flag the stops that are easiest to rationalize and hardest to ignore in the moment.',
                  style: TextStyle(
                    color: AppTheme.mutedText,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          AppButton(
            label: 'Add risky place',
            icon: Icons.add_location_alt_rounded,
            onPressed: () => _openAddPlace(context),
          ),
          const SizedBox(height: 12),
          if (displayPlaces.isEmpty)
            const AppCard(
              child: Text(
                'No risky places saved yet. Add the stops most likely to turn into a ticket purchase so ScratchLess can keep them visible.',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
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
                      Text(
                        place.label,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                        ),
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
                      const SizedBox(height: 8),
                      Text(
                        place.isTopRisk ? 'Top risk place on your watchlist' : 'Open to edit details',
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
  late bool _isTopRisk;
  late int _radiusMeters;

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
    _isTopRisk = widget.initialPlace?.isTopRisk ?? false;
    _radiusMeters = widget.initialPlace?.radiusMeters ?? 300;
  }

  @override
  void dispose() {
    _labelController.dispose();
    _noteController.dispose();
    super.dispose();
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

    final place = RiskyPlace(
      id: widget.initialPlace?.id ??
          DateTime.now().microsecondsSinceEpoch.toString(),
      label: label,
      note: note,
      isTopRisk: _isTopRisk,
      radiusMeters: _radiusMeters,
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
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit risky place' : 'Add risky place'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
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
              hintText: 'Usually risky after payday, after work, or when I feel stressed.',
            ),
          ),
          const SizedBox(height: 12),
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Future smart place-alert radius',
                  style: TextStyle(
                    color: AppTheme.mutedText,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'This does not trigger location alerts yet. It sets up the distance you may want later for smarter place warnings.',
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
                      label: Text('${preset.label} • ${preset.meters}m'),
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
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Mark as top risk'),
            subtitle: const Text(
              'Use this for the stop most likely to turn into an automatic ticket purchase.',
            ),
            value: _isTopRisk,
            onChanged: (value) {
              setState(() {
                _isTopRisk = value;
              });
            },
          ),
          const SizedBox(height: 16),
          AppButton(
            label: _isEditing ? 'Save changes' : 'Save place',
            icon: Icons.check_rounded,
            onPressed: _save,
          ),
          if (_isEditing) ...[
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: TextButton.icon(
                onPressed: _delete,
                icon: const Icon(Icons.delete_outline_rounded),
                label: const Text('Delete place'),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _RadiusPreset {
  final String label;
  final int meters;

  const _RadiusPreset({
    required this.label,
    required this.meters,
  });
}

class _EditRiskyPlaceResult {
  final RiskyPlace? savedPlace;
  final String? deletedId;

  const _EditRiskyPlaceResult({
    this.savedPlace,
    this.deletedId,
  });
}
