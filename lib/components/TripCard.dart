import 'package:flutter/material.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../models/Trip.dart';

class TripCard extends StatelessWidget {
  final Trip trip;

  TripCard(this.trip);

  @override
  build(BuildContext context) {
    double percentage = this.trip.progress.current / this.trip.progress.total;
    Color progressColor;
    Color backgroundColor;
    if (percentage < 0.3) {
      progressColor = Colors.redAccent;
      backgroundColor = Color(0x55FF5252);
    } else if (percentage < 0.6) {
      progressColor = Colors.orangeAccent;
      backgroundColor = Color(0x55FFAB40);
    } else if (percentage < 1.0) {
      progressColor = Colors.blueAccent;
      backgroundColor = Color(0x55448AFF);
    } else {
      progressColor = Colors.green;
      backgroundColor = Colors.green;
    }
    return Card(
      child: Column(
        children: <Widget>[
          Container(
            child: Row(
              children: <Widget>[
                Text(
                  this.trip.title,
                  style: TextStyle(
                    fontSize: 18.0,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  timeago.format(DateTime.fromMillisecondsSinceEpoch(this.trip.timestamp), locale: 'pt_BR', allowFromNow: true),
                ),
              ],
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
            ),
            padding: EdgeInsets.all(10.0),
          ),
          LinearProgressIndicator(
            value: percentage,
            valueColor: AlwaysStoppedAnimation<Color>(progressColor),
            backgroundColor: backgroundColor,
          )
        ],
        crossAxisAlignment: CrossAxisAlignment.start,
      ),
      margin: EdgeInsets.all(10.0),
    );
  }
}