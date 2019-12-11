import 'dart:async';
import 'package:flutter/material.dart';
import 'package:travel_checklist/models/ChecklistItem.dart';
import 'package:travel_checklist/screens/ChecklistItemFormScreen.dart';
import 'package:travel_checklist/services/DatabaseHelper.dart';
import 'package:travel_checklist/services/EventDispatcher.dart';

class ChecklistItemCard extends StatefulWidget {
  final ChecklistItem item;

  ChecklistItemCard({ Key key, this.item }) : super(key: key);

  @override
  _ChecklistItemCardState createState() => _ChecklistItemCardState();
}

class _ChecklistItemCardState extends State<ChecklistItemCard> {
  ChecklistItem _item;

  StreamSubscription _itemEditedSubscription;
  StreamSubscription _itemCheckedSubscription;

  final _dbHelper = DatabaseHelper.instance;
  final _eDispatcher = EventDispatcher.instance;

  @override
  void initState() {
    super.initState();
    _itemEditedSubscription = _eDispatcher.listen('${EventDispatcher.eventChecklistItemEdited}_${widget.item.id}', _onItemEdited);
    _itemCheckedSubscription = _eDispatcher.listen('${EventDispatcher.eventChecklistItemChecked}_${widget.item.id}', _onItemChecked);
    setState(() {
      _item = widget.item;
    });
  }

  @override
  void dispose() {
    super.dispose();
    _itemEditedSubscription.cancel();
    _itemCheckedSubscription.cancel();
  }

  @override
  build(BuildContext context) {
    return GestureDetector(
      child: Card(
        child: Row(
          children: <Widget> [
            Checkbox(
              onChanged: (bool isChecked) {
                if (isChecked) {
                  widget.item.check();
                } else {
                  widget.item.uncheck();
                }
                _updateChecked();
              },
              value: _item.isChecked,
            ),
            Text(
              _item.title,
              style: TextStyle(
                fontSize: 18.0,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
      onLongPress: () {
        _openItemMenu();
      },
      onTap: () {
        widget.item.toggle();
        _updateChecked();
      },
    );
  }

  void _onItemEdited(Map<String, dynamic> data) {
    if (mounted) {
      setState(() {
        _item = data['item'];
      });
    }
  }

  void _onItemChecked(Map<String, dynamic> data) {
    if (mounted) {
      setState(() {
        _item = data['item'];
      });
    }
  }

  void _updateChecked() async {
    await _dbHelper.updateChecklistItem(widget.item);
    _eDispatcher.emit(EventDispatcher.eventChecklistItemChecked, { 'item': widget.item });
    _eDispatcher.emit('${EventDispatcher.eventChecklistItemChecked}_${widget.item.id}', { 'item': widget.item });
  }

  void _openItemMenu() {
    showDialog(
      builder: (BuildContext _context) => SimpleDialog(
        children: <Widget> [
          FlatButton.icon(
            icon: Icon(
              Icons.edit,
              color: Colors.green,
              size: 20.0
            ),
            label: Text('Editar Item'),
            onPressed: () async {
              await Navigator.push(_context, MaterialPageRoute(builder: (_context) => ChecklistItemFormScreen(item: widget.item)));
              Navigator.pop(_context);
            },
            padding: EdgeInsets.all(0.0),
          ),
          FlatButton.icon(
            icon: Icon(
              Icons.delete,
              color: Colors.red,
              size: 20.0
            ),
            label: Text('Deletar Item'),
            onPressed: () async {
              await _dbHelper.deleteChecklistItem(_item.id);
              _eDispatcher.emit(EventDispatcher.eventChecklistItemRemoved, { 'item': _item });
              Navigator.pop(_context);
            },
            padding: EdgeInsets.all(0.0),
          ),
        ],
        contentPadding: EdgeInsets.all(0.0),
      ),
      context: context,
    );
  }
}