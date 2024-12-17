import 'package:flutter/material.dart';

// ignore: must_be_immutable
class BillCard extends StatefulWidget {
  String title;
  String subTitle;
  // ignore: non_constant_identifier_names
  int is_paid;
  // ignore: non_constant_identifier_names
  BillCard({super.key, required this.title, required this.subTitle, required this.is_paid});

  @override
  State<BillCard> createState() => _BillCardState();
}

class _BillCardState extends State<BillCard> {
  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.white24,
      margin: EdgeInsets.all(8.0),
      child: ListTile(
        leading: Padding(
          padding: EdgeInsets.only(top: 8.0, bottom: 5.0, left: 1.0),
          child: Container(
            padding: EdgeInsets.all(5.0),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(5.0),
              color: widget.is_paid == 0 ? Colors.greenAccent : Colors.redAccent,
            ),
            child: widget.is_paid == 0 ? Icon(Icons.check_box_outlined, color:Colors.blue) : Icon(Icons.warning, color:Colors.yellow),
          ),
        ),
        trailing: GestureDetector(
           onTap: () {
           },
          child: Padding(
            padding: EdgeInsets.only(top: 8.0, bottom: 5.0, left: 1.0),
            child: Container(
              padding: const EdgeInsets.all(5.0),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(5.0),
                color: Colors.blue.shade100,
              ),
              child: Icon(Icons.open_in_new, color:Colors.green),
            ),
          ),
        ),
        title: Text(
          widget.title,
          style: TextStyle(fontSize: 18,color: Theme.of(context).colorScheme.surface),
        ),
        subtitle: Text(
          widget.subTitle,
          maxLines: 6,
          overflow: TextOverflow.fade,
          style: TextStyle(fontSize: 12,color: Theme.of(context).colorScheme.surface),
        ),
      ),
    );
  }
}
