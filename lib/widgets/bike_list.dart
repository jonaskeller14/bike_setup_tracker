import 'package:flutter/material.dart';
import '../models/bike.dart';

class BikeList extends StatelessWidget {
  final List<Bike> bikes;
  final void Function(Bike bike) editBike;
  final void Function(Bike bike) removeBike;

  const BikeList({
    super.key,
    required this.bikes,
    required this.editBike,
    required this.removeBike,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: bikes.length,
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      itemBuilder: (context, index) {
        final bike = bikes[index];
        return Card(
          margin: const EdgeInsets.symmetric(vertical: 4.0),
          child: ListTile(
            leading: const Icon(Icons.pedal_bike),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 8,
            ),
            title: Text(
              bike.name,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            subtitle: null,
            trailing: PopupMenuButton<String>(
              onSelected: (value) {
                if (value == 'edit') {
                  editBike(bike);
                } else if (value == 'remove') {
                  removeBike(bike);
                }
              },
              itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                const PopupMenuItem<String>(
                  value: 'edit',
                  child: Row(
                    children: [
                      Icon(Icons.edit, size: 20),
                      SizedBox(width: 10),
                      Text('Edit'),
                    ],
                  ),
                ),
                const PopupMenuItem<String>(
                  value: 'remove',
                  child: Row(
                    children: [
                      Icon(Icons.delete, size: 20),
                      SizedBox(width: 10),
                      Text('Remove'),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
