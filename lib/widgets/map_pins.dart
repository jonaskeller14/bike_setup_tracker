import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';

import '../models/strava/strava_activity.dart';

class SetupMapPin extends StatelessWidget {
  final bool isCurrent;
  final String? label;

  const SetupMapPin._({super.key, this.isCurrent = false, this.label});

  factory SetupMapPin.icon({Key? key, bool isCurrent = false}) =>
    SetupMapPin._(key: key, isCurrent: isCurrent);

  factory SetupMapPin.label({Key? key, required String label}) =>
    SetupMapPin._(key: key, label: label);

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        ImageFiltered(
          imageFilter: ImageFilter.blur(sigmaX: 3, sigmaY: 3),
          child: const Icon(Icons.location_pin, size: 40, color: Colors.black38),
        ),
        Icon(
          Icons.location_pin,
          size: 40,
          color: Theme.of(context).colorScheme.primary,
        ),
        if (isCurrent)
          Align(
            alignment: const Alignment(0, -0.4),
            child: Container(
              width: 16,
              height: 16,
              alignment: Alignment.center,
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.flag,
                size: 12,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
          ),
        if (label != null)
          Align(
            alignment: const Alignment(0, -0.3),
            child: Container(
              width: 16,
              height: 16,
              alignment: Alignment.center,
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
              child: Text(
                label ?? "",
                style: TextStyle(
                  color: Theme.of(context).colorScheme.primary,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  height: 1,
                ),
              ),
            ),
          ),
      ],
    );
  }
}


class StravaActivityMapPin extends StatelessWidget {
  final StravaWorkoutType workoutType;

  const StravaActivityMapPin({super.key, this.workoutType = StravaWorkoutType.none});

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        ImageFiltered(
          imageFilter: ImageFilter.blur(sigmaX: 3, sigmaY: 3),
          child: const Icon(Icons.location_pin, size: 40, color: Colors.black38),
        ),
        const Icon(
          Icons.location_pin,
          size: 40,
          color: Color(0xFFFC5200),
        ),
        if (workoutType.isNotable)
          Align(
            alignment: const Alignment(0, -0.4),
            child: Container(
              width: 16,
              height: 16,
              alignment: Alignment.center,
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
              child: Icon(
                workoutType.icon,
                size: 12,
                color: const Color(0xFFFC5200),
              ),
            ),
          ),
      ],
    );
  }
}

class RatingEntryMapPin extends StatelessWidget {
  const RatingEntryMapPin({super.key});

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        ImageFiltered(
          imageFilter: ImageFilter.blur(sigmaX: 3, sigmaY: 3),
          child: const Icon(Icons.location_pin, size: 40, color: Colors.black38),
        ),
        const Icon(
          Icons.location_pin,
          size: 40,
          color: Color(0xFFF9A825), // amber — rating entries (matches calendar)
        ),
      ],
    );
  }
}
