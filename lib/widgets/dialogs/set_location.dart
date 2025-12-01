import 'package:flutter/material.dart';
import 'package:location/location.dart';
import 'package:geocoding/geocoding.dart' as geo;
import '../../services/location_service.dart';
import '../../services/address_service.dart';


Future<List<dynamic>?> showSetLocationDialog({required BuildContext context, required LocationData? location, required geo.Placemark? address}) async {
  return await showDialog<List<dynamic>?>(
    context: context,
    builder: (BuildContext context) => ShowSetLocationDialog(location: location, address: address),
  );
}

class ShowSetLocationDialog extends StatefulWidget {
  final LocationData? location;
  final geo.Placemark? address;

  const ShowSetLocationDialog({
    super.key,
    this.location,
    this.address,
  });

  @override
  State<StatefulWidget> createState() => _ShowSetLocationDialogState();
}

class _ShowSetLocationDialogState extends State<ShowSetLocationDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _controller;
  bool _error = false;

  final LocationService _locationService = LocationService();
  LocationData? _location;

  final AddressService _addressService = AddressService();
  geo.Placemark? _address;

  @override
  void initState() {
    _controller = TextEditingController();
    _location = widget.location;
    _address = widget.address;
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
    _controller.dispose();
  }

  void _save() async {
    _onFieldSubmitted(_controller.text.trim());
    if (_location == null || _address == null) {
      setState(() {
        _error = true;
      });
      return;
    }
    if (!mounted) return;
    Navigator.of(context).pop([_location, _address]);
  }

  void _onFieldSubmitted(String text) async {
    if (!_formKey.currentState!.validate()) return;
    final newLocation = await _locationService.locationFromAddress(text.trim());

    setState(() {
      _location = newLocation;
      _error = newLocation == null ? true : false;
    });
    if (_location == null) return;
    final newAddress = await _addressService.fetchAddress(lat: _location!.latitude!, lon: _location!.longitude!);

    setState(() {
      _address = newAddress;
      _error = newAddress == null ? true : false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      scrollable: true,
      title: const Text('Set Location by Address'),
      content: Form(
        key: _formKey,
        child: Column(
          children: <Widget>[
            const Text("Enter the street address, city, or landmark for this setup."),
            const SizedBox(height: 16),
            TextFormField(
              textInputAction: TextInputAction.search,
              controller: _controller,
              autofocus: true,
              decoration: InputDecoration(
                border: OutlineInputBorder(),
                isDense: true,
                hintText: 'Address',
                contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                icon: Icon(Icons.pin_drop),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) return 'Please enter an address';
                return null;
              },
              onFieldSubmitted: _onFieldSubmitted,
            ),
            if (_error) 
              Text("Could not find location.", style: TextStyle(color: Theme.of(context).colorScheme.error)),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: DataTable(
                  columnSpacing: 25,
                  horizontalMargin: 10,
                  dataRowMinHeight: 25,
                  dataRowMaxHeight: 25,
                  headingRowHeight: 25,
                  columns: const <DataColumn>[
                    DataColumn(
                      label: Text('')
                    ),
                    DataColumn(
                      label: Text(
                        'Current',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    DataColumn(
                      label: Text(
                        'New',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],

                  rows: <DataRow>[
                    DataRow(
                      cells: <DataCell>[
                        DataCell(Text('Latitude', style: TextStyle(fontWeight: FontWeight.bold))),
                        DataCell(Text(widget.location?.latitude?.toStringAsFixed(3) ?? '-')),
                        DataCell(Text(_location?.latitude?.toStringAsFixed(3) ?? '-')),
                      ],
                    ),
                    DataRow(
                      cells: <DataCell>[
                        DataCell(Text('Longitude', style: TextStyle(fontWeight: FontWeight.bold))),
                        DataCell(Text(widget.location?.longitude?.toStringAsFixed(3) ?? '-')),
                        DataCell(Text(_location?.longitude?.toStringAsFixed(3) ?? '-')),
                      ],
                    ),
                    DataRow(
                      cells: <DataCell>[
                        DataCell(Text('Altitude', style: TextStyle(fontWeight: FontWeight.bold))),
                        DataCell(Text(widget.location?.altitude?.round().toString() ?? '-')),
                        DataCell(Text(_location?.altitude?.round().toString() ?? '-')),
                      ],
                    ),
                    DataRow(
                      cells: <DataCell>[
                        DataCell(Text('Street', style: TextStyle(fontWeight: FontWeight.bold))),
                        DataCell(SizedBox(width: 100, child: Text("${widget.address?.thoroughfare ?? '-'} ${widget.address?.subThoroughfare ?? ''}", overflow: TextOverflow.ellipsis,))),
                        DataCell(SizedBox(width: 100, child: Text("${_address?.thoroughfare ?? '-'} ${_address?.subThoroughfare ?? ''}", overflow: TextOverflow.ellipsis,))),
                      ],
                    ),
                    DataRow(
                      cells: <DataCell>[
                        DataCell(Text('Locality', style: TextStyle(fontWeight: FontWeight.bold))),
                        DataCell(SizedBox(width: 100, child: Text(widget.address?.locality ?? '-', overflow: TextOverflow.ellipsis,))),
                        DataCell(SizedBox(width: 100, child: Text(_address?.locality ?? '-', overflow: TextOverflow.ellipsis,))),
                      ],
                    ),
                    DataRow(
                      cells: <DataCell>[
                        DataCell(Text('Country', style: TextStyle(fontWeight: FontWeight.bold))),
                        DataCell(SizedBox(width: 100, child: Text(widget.address?.isoCountryCode ?? '-', overflow: TextOverflow.ellipsis,))),
                        DataCell(SizedBox(width: 100, child: Text(_address?.isoCountryCode ?? '-', overflow: TextOverflow.ellipsis,))),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const Text("Note: Altitude data is only available via GPS and will be lost here.", style: TextStyle(color: Colors.grey),)
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {Navigator.of(context).pop(null);},
          child: const Text("Cancel"),
        ),
        ElevatedButton(
          onPressed: !_error && _location != widget.location ? _save : null,
          child: const Text("Submit"),
        ),
      ],
    );
  }
}
