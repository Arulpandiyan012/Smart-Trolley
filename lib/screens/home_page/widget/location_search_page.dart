import 'package:flutter/material.dart';
import 'package:flutter_google_places_sdk/flutter_google_places_sdk.dart' as places;
import 'package:bagisto_app_demo/screens/home_page/widget/location_map_page.dart';

class LocationSearchPage extends StatefulWidget {
  const LocationSearchPage({super.key});

  @override
  State<LocationSearchPage> createState() => _LocationSearchPageState();
}

class _LocationSearchPageState extends State<LocationSearchPage> {
  late final places.FlutterGooglePlacesSdk _places;
  final _searchCtrl = TextEditingController();
  List<places.AutocompletePrediction> _predictions = [];
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _places = places.FlutterGooglePlacesSdk("YOUR_GOOGLE_PLACES_API_KEY");
    _searchCtrl.addListener(_onChanged);
  }

  @override
  void dispose() {
    _searchCtrl.removeListener(_onChanged);
    _searchCtrl.dispose();
    super.dispose();
  }

  void _onChanged() {
    final q = _searchCtrl.text.trim();
    if (q.isEmpty) {
      setState(() => _predictions = []);
      return;
    }
    _fetch(q);
  }

  Future<void> _fetch(String query) async {
    setState(() => _loading = true);
    try {
      final res = await _places.findAutocompletePredictions(
        query,
        // Optional: restrict to a country
        // countries: ['IN'],
      );
      if (!mounted) return;
      setState(() => _predictions = res.predictions);
    } catch (_) {
      // silently ignore
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _openMapForPrediction(places.AutocompletePrediction p) async {
    // Get place details to obtain lat/lng
    try {
      final details = await _places.fetchPlace(
        p.placeId,
        fields: [
          places.PlaceField.Location,
          places.PlaceField.Name,
          places.PlaceField.AddressComponents,
        ],
      );

      final place = details.place;
      final loc = place?.latLng;
      if (loc == null) return;

      // Navigate to map page with the selected coordinates & name
      final result = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => LocationMapPage(
            initialLat: loc.lat,
            initialLng: loc.lng,
            initialLabel: place?.name ?? p.fullText,
          ),
        ),
      );

      // If user confirmed/selected, bubble the result back to caller
      if (!mounted) return;
      if (result != null) Navigator.pop(context, result);
    } catch (_) {
      // silently ignore
    }
  }

  @override
  Widget build(BuildContext context) {
    final titleStyle = Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700);

    return Scaffold(
      appBar: AppBar(title: const Text('Select delivery location')),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Heading
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text('Search for an area or landmark', style: titleStyle),
          ),

          // Search field
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: TextField(
              controller: _searchCtrl,
              decoration: InputDecoration(
                hintText: 'Try "Chennai Central" or "Airport"',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                isDense: true,
                suffixIcon: _loading
                    ? const Padding(
                        padding: EdgeInsets.all(12),
                        child: SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)),
                      )
                    : (_searchCtrl.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () => setState(() {
                              _searchCtrl.clear();
                              _predictions = [];
                            }),
                          )
                        : null),
              ),
            ),
          ),

          const SizedBox(height: 8),

          // Predictions list
          Expanded(
            child: _predictions.isEmpty
                ? const Center(child: Text('Start typing to see suggestions...'))
                : ListView.separated(
                    itemCount: _predictions.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (ctx, i) {
                      final pred = _predictions[i];
                      return ListTile(
                        leading: const Icon(Icons.place_outlined),
                        title: Text(pred.primaryText),
                        subtitle: Text(pred.secondaryText!),
                        onTap: () => _openMapForPrediction(pred),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
