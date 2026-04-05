import 'dart:async';

import 'package:flutter/material.dart';

import '../../app/app_theme.dart';
import '../../core/services/place_search_service.dart';
import '../../shared/widgets/app_card.dart';

class PlaceSearchScreen extends StatefulWidget {
  const PlaceSearchScreen({super.key});

  @override
  State<PlaceSearchScreen> createState() => _PlaceSearchScreenState();
}

class _PlaceSearchScreenState extends State<PlaceSearchScreen> {
  final TextEditingController _controller = TextEditingController();

  Timer? _debounce;
  bool _loading = false;
  String? _error;
  String? _loadingPlaceId;
  List<PlaceSearchSuggestion> _results = const <PlaceSearchSuggestion>[];

  @override
  void initState() {
    super.initState();
    PlaceSearchService.instance.beginSession();
    _controller.addListener(_scheduleSearch);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.removeListener(_scheduleSearch);
    _controller.dispose();
    super.dispose();
  }

  void _scheduleSearch() {
    _debounce?.cancel();
    final query = _controller.text.trim();

    if (query.length < 2) {
      setState(() {
        _loading = false;
        _error = null;
        _results = const <PlaceSearchSuggestion>[];
      });
      return;
    }

    _debounce = Timer(const Duration(milliseconds: 250), () {
      _runSearch(query);
    });
  }

  Future<void> _runSearch(String query) async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final results = await PlaceSearchService.instance.autocomplete(query);
      if (!mounted) {
        return;
      }
      setState(() {
        _results = results;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _error = error.toString();
        _results = const <PlaceSearchSuggestion>[];
      });
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  Future<void> _selectSuggestion(PlaceSearchSuggestion suggestion) async {
    setState(() {
      _loadingPlaceId = suggestion.placeId;
      _error = null;
    });

    try {
      final selection =
          await PlaceSearchService.instance.fetchPlaceSelection(
        suggestion.placeId,
      );

      if (!mounted) {
        return;
      }

      Navigator.of(context).pop(selection);
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _error = error.toString();
        _loadingPlaceId = null;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final configured = PlaceSearchService.instance.isConfigured;
    final query = _controller.text.trim();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Search for a place'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (!configured)
            const AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Places search is not configured in this build.',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Add a Google Places API key later and this search flow will work without changing the rest of the risky-place setup.',
                    style: TextStyle(
                      color: AppTheme.mutedText,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            )
          else ...[
            TextField(
              controller: _controller,
              autofocus: true,
              decoration: const InputDecoration(
                labelText: 'Search by place name or address',
                hintText: '7-Eleven, Circle K, gas station near work',
              ),
            ),
            const SizedBox(height: 12),
            if (_loading)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: CircularProgressIndicator(),
                ),
              ),
            if (_error != null)
              AppCard(
                child: Text(
                  _error!,
                  style: const TextStyle(
                    color: AppTheme.mutedText,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            if (!_loading && _error == null && query.length < 2)
              const AppCard(
                child: Text(
                  'Type at least 2 characters to search.',
                  style: TextStyle(
                    color: AppTheme.mutedText,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            if (!_loading &&
                _error == null &&
                query.length >= 2 &&
                _results.isEmpty)
              const AppCard(
                child: Text(
                  'No matching places found yet.',
                  style: TextStyle(
                    color: AppTheme.mutedText,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ..._results.map((result) {
              final selecting = _loadingPlaceId == result.placeId;
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: AppCard(
                  onTap: selecting ? null : () => _selectSuggestion(result),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        result.primaryText,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      if (result.secondaryText.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Text(
                          result.secondaryText,
                          style: const TextStyle(
                            color: AppTheme.mutedText,
                            fontSize: 14,
                          ),
                        ),
                      ],
                      if (selecting) ...[
                        const SizedBox(height: 10),
                        const Text(
                          'Fetching place details...',
                          style: TextStyle(
                            color: AppTheme.mutedText,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              );
            }),
          ],
        ],
      ),
    );
  }
}
