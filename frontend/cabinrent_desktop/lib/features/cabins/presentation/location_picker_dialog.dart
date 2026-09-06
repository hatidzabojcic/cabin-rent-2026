import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';

class LocationSelection {
  const LocationSelection(this.latitude, this.longitude);
  final double latitude;
  final double longitude;
}

class LocationPickerDialog extends StatefulWidget {
  const LocationPickerDialog({
    super.key,
    this.initialLatitude,
    this.initialLongitude,
  });

  final double? initialLatitude;
  final double? initialLongitude;

  @override
  State<LocationPickerDialog> createState() => _LocationPickerDialogState();
}

class _LocationPickerDialogState extends State<LocationPickerDialog> {
  static const _bosniaAndHerzegovinaCenter = LatLng(44.15, 17.68);
  LatLng? _selected;

  @override
  void initState() {
    super.initState();
    if (widget.initialLatitude != null && widget.initialLongitude != null) {
      _selected = LatLng(widget.initialLatitude!, widget.initialLongitude!);
    }
  }

  @override
  Widget build(BuildContext context) {
    final initialCenter = _selected ?? _bosniaAndHerzegovinaCenter;
    return Dialog(
      child: SizedBox(
        width: 900,
        height: 680,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 18, 12, 14),
              child: Row(
                children: [
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Odaberite lokaciju',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Kliknite na kartu kako biste postavili ili pomjerili marker.',
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: FlutterMap(
                options: MapOptions(
                  initialCenter: initialCenter,
                  initialZoom: _selected == null ? 7.2 : 14,
                  minZoom: 5,
                  maxZoom: 19,
                  onTap: (_, point) => setState(() => _selected = point),
                ),
                children: [
                  TileLayer(
                    urlTemplate:
                        'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName: 'ba.fit.cabinrent.desktop',
                    maxZoom: 19,
                  ),
                  if (_selected != null)
                    MarkerLayer(
                      markers: [
                        Marker(
                          point: _selected!,
                          width: 52,
                          height: 52,
                          alignment: Alignment.topCenter,
                          child: const Icon(
                            Icons.location_pin,
                            size: 48,
                            color: Color(0xFF087F6B),
                          ),
                        ),
                      ],
                    ),
                  SimpleAttributionWidget(
                    source: const Text('OpenStreetMap contributors'),
                    onTap: () => launchUrl(
                      Uri.parse('https://www.openstreetmap.org/copyright'),
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      _selected == null
                          ? 'Lokacija još nije odabrana.'
                          : 'Odabrano: ${_selected!.latitude.toStringAsFixed(6)}, '
                                '${_selected!.longitude.toStringAsFixed(6)}',
                    ),
                  ),
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Odustani'),
                  ),
                  const SizedBox(width: 10),
                  FilledButton.icon(
                    onPressed: _selected == null
                        ? null
                        : () => Navigator.pop(
                            context,
                            LocationSelection(
                              _selected!.latitude,
                              _selected!.longitude,
                            ),
                          ),
                    icon: const Icon(Icons.check),
                    label: const Text('Potvrdi lokaciju'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
