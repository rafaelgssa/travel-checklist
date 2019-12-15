import 'package:flutter/material.dart';
import 'package:flutter_datetime_picker/flutter_datetime_picker.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:intl/intl.dart';
import 'package:place_picker/place_picker.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:travel_checklist/models/Trip.dart';
import 'package:travel_checklist/screens/MapScreen.dart';
import 'package:travel_checklist/services/DatabaseHelper.dart';
import 'package:travel_checklist/services/EventDispatcher.dart';
import 'package:travel_checklist/enums.dart';

class TripFormScreen extends StatefulWidget {
  final Trip trip;
  final Template template;

  TripFormScreen({Key key, this.trip, this.template}) : super(key: key);

  @override
  _TripFormScreenState createState() => _TripFormScreenState();
}

class _TripFormScreenState extends State<TripFormScreen> {
  DateFormat _dateFormat;
  bool _isCreating = true;
  String _title = '';
  String _destinationCoordinates = '';
  DateTime _departureDate;
  DateTime _returnDate;
  Template _template = Template.Outro;

  final _dbHelper = DatabaseHelper.instance;
  final _eDispatcher = EventDispatcher.instance;

  GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  TextEditingController _nameController = TextEditingController();
  TextEditingController _destinationController = TextEditingController();
  TextEditingController _departureTimestampController = TextEditingController();
  TextEditingController _returnTimestampController = TextEditingController();

  @override
  void initState() {
    super.initState();
    timeago.setLocaleMessages('pt_BR', timeago.PtBrMessages());
    _dateFormat = DateFormat.yMd('pt_BR').add_Hm();
    _resetFields();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _destinationController.dispose();
    _departureTimestampController.dispose();
    _returnTimestampController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    DateTime now = DateTime.now();
    return Scaffold(
      appBar: AppBar(
        title: Text(_title),
        actions: <Widget>[
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: () {
              _resetFields();
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Form(
          child: Column(
            children: <Widget> [
              Icon(
                Icons.flight,
                size: 50,
              ),
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(
                  errorStyle: TextStyle(fontSize: 15.0),
                  labelStyle: TextStyle(color: Colors.blueAccent),
                  labelText: 'Nome',
                ),
                keyboardType: TextInputType.text,
                style: TextStyle(
                  color: Colors.blueAccent,
                  fontSize: 20.0,
                ),
                textAlign: TextAlign.left,
                validator: (value) {
                  if (value.isEmpty) {
                    return 'O nome não pode ser vazio!';
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: _destinationController,
                decoration: InputDecoration(
                  errorStyle: TextStyle(fontSize: 15.0),
                  labelStyle: TextStyle(color: Colors.blueAccent),
                  labelText: 'Destino',
                ),
                keyboardType: TextInputType.text,
                style: TextStyle(
                  color: Colors.blueAccent,
                  fontSize: 20.0,
                ),
                textAlign: TextAlign.left,
                validator: (value) {
                  if (value.isEmpty) {
                    return 'Selecione um destino!';
                  }
                  if (_destinationCoordinates.isEmpty) {
                    return 'Destino inválido!';
                  }
                  return null;
                },
              ),
              FlatButton.icon(
                color: Colors.blueAccent,
                textColor: Colors.white,
                icon: Icon(Icons.place),
                label: Text('Selecionar Destino'),
                onPressed: () async {
                  double latitude = 0.0;
                  double longitude = 0.0;
                  if (_destinationCoordinates.isNotEmpty) {
                    List<String> latlng = _destinationCoordinates.split(',');
                    latitude = double.parse(latlng[0]);
                    longitude = double.parse(latlng[1]);
                  }
                  LocationResult result = await Navigator.push(context, MaterialPageRoute(
                    builder: (_context) => MapScreen(
                      initialLocation: _destinationCoordinates.isNotEmpty ? LatLng(latitude, longitude) : null,
                    ),
                  ));
                  if (result != null) {
                    latitude = result.latLng.latitude;
                    longitude = result.latLng.longitude;
                    setState(() {
                      _destinationController.text = result.name;
                      _destinationCoordinates = '$latitude,$longitude';
                    });
                  }
                },
              ),
              TextFormField(
                controller: _departureTimestampController,
                decoration: InputDecoration(
                  errorStyle: TextStyle(fontSize: 15.0),
                  labelStyle: TextStyle(color: Colors.blueAccent),
                  labelText: 'Data de Ida',
                ),
                keyboardType: TextInputType.text,
                style: TextStyle(
                  color: Colors.blueAccent,
                  fontSize: 20.0,
                ),
                textAlign: TextAlign.left,
                validator: (value) {
                  if (value.isEmpty) {
                    return 'Selecione uma data!';
                  }
                  try {
                    _dateFormat.parse(_departureTimestampController.text);
                  } catch (err) {
                    return 'Data inválida!';
                  }
                  return null;
                },
              ),
              FlatButton.icon(
                color: Colors.blueAccent,
                textColor: Colors.white,
                icon: Icon(Icons.calendar_today),
                label: Text('Selecionar Data'),
                onPressed: () {
                  DatePicker.showDateTimePicker(
                    context,
                    currentTime: _departureDate.millisecondsSinceEpoch <= now.millisecondsSinceEpoch ? now.add(Duration(minutes: 1)) : _departureDate,
                    locale: LocaleType.pt,
                    minTime: now,
                    onConfirm: (date) {
                      setState(() {
                        _departureDate = date;
                        _departureTimestampController.text = _dateFormat.format(_departureDate);
                        if (_returnDate.millisecondsSinceEpoch <= _departureDate.millisecondsSinceEpoch) {
                          _returnDate = _departureDate.add(Duration(minutes: 2));
                        }
                      });
                    },
                    showTitleActions: true,
                  );
                },
              ),
              TextFormField(
                controller: _returnTimestampController,
                decoration: InputDecoration(
                  errorStyle: TextStyle(fontSize: 15.0),
                  labelStyle: TextStyle(color: Colors.blueAccent),
                  labelText: 'Data de Volta',
                ),
                keyboardType: TextInputType.text,
                style: TextStyle(
                  color: Colors.blueAccent,
                  fontSize: 20.0,
                ),
                textAlign: TextAlign.left,
                validator: (value) {
                  if (value.isEmpty) {
                    return 'Selecione uma data!';
                  }
                  try {
                    _dateFormat.parse(_returnTimestampController.text);
                  } catch (err) {
                    return 'Data inválida!';
                  }
                  return null;
                },
              ),
              FlatButton.icon(
                color: Colors.blueAccent,
                textColor: Colors.white,
                icon: Icon(Icons.calendar_today),
                label: Text('Selecionar Data'),
                onPressed: () {
                  DatePicker.showDateTimePicker(
                    context,
                    currentTime: _returnDate,
                    locale: LocaleType.pt,
                    minTime: _departureDate.add(Duration(minutes: 1)),
                    onConfirm: (date) {
                      setState(() {
                        _returnDate = date;
                        _returnTimestampController.text = _dateFormat.format(_returnDate);
                      });
                    },
                    showTitleActions: true,
                  );
                },
              ),
              _buildButton(),
            ],
            crossAxisAlignment: CrossAxisAlignment.stretch,
          ),
          key: _formKey,
        ),
        padding: EdgeInsets.all(20.0),
      ),
    );
  }

  Widget _buildButton() {
    return Container(
      child: RaisedButton(
        child: Text(
          _isCreating ? 'Criar' : 'Editar',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20.0,
          ),
        ),
        color: Colors.blueAccent,
        onPressed: () async {
          if (_formKey.currentState.validate()) {
            if (_isCreating) {
              Trip trip = Trip();
              trip.name = _nameController.text;
              trip.destination = _destinationController.text;
              trip.destinationCoordinates = _destinationCoordinates;
              trip.departureTimestamp = _departureDate.millisecondsSinceEpoch;
              trip.returnTimestamp = _returnDate.millisecondsSinceEpoch;
              trip.id = await _dbHelper.insertTrip(trip, _template);
              _eDispatcher.emit(Event.TripAdded, { 'trip': trip});
            } else {
              widget.trip.name = _nameController.text;
              widget.trip.destination = _destinationController.text;
              widget.trip.destinationCoordinates = _destinationCoordinates;
              widget.trip.departureTimestamp = _departureDate.millisecondsSinceEpoch;
              widget.trip.returnTimestamp = _returnDate.millisecondsSinceEpoch;
              await _dbHelper.updateTrip(widget.trip);
            }
            Navigator.pop(context);
          }
        },
      ),
      height: 50.0,
      margin: EdgeInsets.only(
        bottom: 20.0,
        top: 20.0,
      ),
    );
  }

  void _resetFields() {
    setState(() {
      if (widget.trip == null) {
        _isCreating = true;
        if (widget.template != null) {
          _template = widget.template;
          _title = 'Criar Viagem - ${_template.toString().split('.').last}';
        } else {
          _template = Template.Outro;
          _title = 'Criar Viagem';
        }
        _nameController.text = '';
        _destinationController.text = '';
        _destinationCoordinates = '';
        _departureDate = DateTime.now().add(Duration(minutes: 1));
        _returnDate = _departureDate.add(Duration(minutes: 2));
        _departureTimestampController.text = '';
        _returnTimestampController.text = '';
      } else {
        _isCreating = false;
        _template = Template.Outro;
        _title = 'Editar Viagem - ${widget.trip.name}';
        _nameController.text = widget.trip.name;
        _destinationController.text = widget.trip.destination;
        _destinationCoordinates = widget.trip.destinationCoordinates;
        _departureDate = DateTime.fromMillisecondsSinceEpoch(widget.trip.departureTimestamp);
        _returnDate = DateTime.fromMillisecondsSinceEpoch(widget.trip.returnTimestamp);
        _departureTimestampController.text = _dateFormat.format(_departureDate);
        _returnTimestampController.text = _dateFormat.format(_returnDate);
      }
    });
  }
}
