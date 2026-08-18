import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/app_settings.dart';
import '../../widgets/text/section_title.dart';

class FAQPage extends StatelessWidget {
  const FAQPage({super.key});

  /// Adjustments are configured per component and are managed from Bikes.
  static const Map<String, String> _adjustmentFAQs = {
    'What is an "Adjustment"?':
        'An Adjustment defines a specific part of a component that can be modified (e.g., tire pressure or suspension rebound). It sets the rules — the type, the unit, and the allowed range — while the actual values are recorded within a "Setup."',
    'Which adjustment types can I choose from?':
        'Numerical for measured values with a unit (e.g. 22.5 psi), Step for click-based dials (e.g. rebound 8 of 15), Categorical for a fixed list of options, and On/Off for things like a lockout. Text, for free-form entries, appears once you enable it under Settings → Features → Text Adjustment.\n\n'
        'You pick the type when adding the adjustment — it decides how you enter values in a Setup later. Above the types, the "Add Adjustment" sheet also suggests ready-made templates for the component you are on, which are the quickest way to get started.',
    'Can I read or enter a value in a different unit?':
        'Yes — tap the unit label next to the value (the small "psi", "bar", "mm" … text). Each tap cycles to the next compatible unit and converts the number for you. This works both when reading a setup and when typing a value into one. While a converted unit is active, a small line shows what the value is in the unit the adjustment is actually stored in.\n\n'
        'This only changes what you see: the adjustment and the stored value stay untouched, and the display resets when you leave the page. To change the unit permanently, edit the adjustment.',
    'What is "SAG"?':
        'SAG is not a type of its own — it is a special flavour of the Numerical adjustment, made for suspension sag. It is always stored as a percentage between 0 and 100 %.\n\n'
        'What it adds is the reference travel: fill in the "Fork Travel" or "Shock Stroke" of the component and the app can convert that percentage into an absolute length. Tap the unit label on the value to cycle % → mm → in. That way you can measure sag with a ruler on the stanchion or shock shaft and let the app do the math — in either direction.',
    'How do I add a SAG adjustment?':
        'You will not find SAG in the list of adjustment types. Add it from the "SAG" template that the "Add Adjustment" sheet suggests for a fork or a shock, then enter the travel or stroke.\n\n'
        'If you already track sag as a plain numerical adjustment in %, you do not have to start over: edit it, and as long as its name contains "sag" and its unit is %, a "Convert to SAG adjustment" banner appears. All recorded values and the full history stay attached, and it is reversible — on a SAG adjustment, use the three-dot menu → "Convert to plain numerical".',
    'What happens to my recorded values if I change an adjustment’s unit?':
        'If the old and the new unit measure the same thing (e.g. bar → psi), the app asks you when saving:\n\n'
        '"Convert values" recalculates every previously recorded value into the new unit (10 bar becomes 145 psi). Use this when your old values were correct and you just want to read them differently.\n\n'
        '"Keep numbers" leaves the numbers untouched and only relabels them (10 bar becomes 10 psi). Use this when the values had been recorded in the wrong unit all along.\n\n'
        'If the units are not compatible (e.g. psi → mm), no conversion is possible — the numbers stay and are reinterpreted in the new unit. Min and max are always kept exactly as you typed them.',
  };

  static const Map<String, Map<String, String>> _faqSections = {
    'General': {
      'What is this app about?':
          'This app helps you track, manage, and optimize your bike setup adjustments for better performance.',
      // 'What makes a good bike setup?':
      //     'A "good" bike setup is a balance between the laws of physics and the rider’s personal feel. It should provide maximum traction and stability while minimizing rider fatigue. To evaluate a setup, you need to look at Objective Data (e.g. laptimes) and Subjective Feedback (what the rider is feeling).',
      'Can I export or share my data?':
          'Yes. Use "Export" to save your entire database as a JSON file. You choose where to save it in your device’s file picker. This file is intended for backups and can be reimported later. \n\nUse "Share" to send a snapshot of your data directly to another app (like Mail, Cloud, or Messenger). You can choose between multiple formats: JSON (reimportable), Excel, CSV, or plain text.',
      'Is my data stored locally?':
          'Yes, all your data is stored locally on your device. We do not collect or store any of your personal information.',
      'I accidentally deleted something. Can I recover it?':
          'Yes. Open the menu in the top-right corner of the home page and select "Trash." You can restore items deleted within the last 30 days. After 30 days, items are permanently deleted.',
      'How do I move my data to a new device?':
          'Data is typically restored by your operating system if you have cloud backups enabled. To move data manually: Export your data as a JSON file from the home page menu, transfer that file to your new device (via cloud or cable), and select "Import" from the menu on the new device.',
      // Only on Android:
      // 'Can I sync data between devices?':
      //     'Yes. Turn on "Google Drive Sync" in App Settings → Experimental Features. A cloud icon will appear on the home screen — tap it to sign in and authorize. Once enabled, changes sync automatically and daily backups are saved to your Google Drive so you can access them from any device.',
    },
    'Bikes': {
      'How do I add a new bike?': 'Tap the "+" button in the "Bikes" tab to create a new bike.',
      'Where are my components?':
          'Components are listed directly under the bike they are installed on. Tap a component to see its details and make adjustments.',
      'How do I edit or delete a component?':
          'Tap on a component to open its detailed view, then tap the three-dot menu in the top-right corner to edit, duplicate, or delete it.',
      'How do I move a component to a different bike?':
          'Long-press a component and drag it onto the card of the bike you want to move it to.',
      'How do I reorder my components?':
          'Long-press and drag a component icon to change its position within a bike or list.',
      'What is the "Uninstalled" section?':
          'This section at the bottom of the "Bikes" tab lists components that are currently not assigned to any bike. You can drag them from here onto a bike to install them.',
      'What is the difference between "Uninstalled" and "Archived"?':
          'Both states mean a component is off the bike, but they serve different purposes.\n\n'
          '"Uninstalled" means the component is off the bike but still usable. It stays visible in the Uninstalled section and can be reinstalled at any time — for example, a spare wheelset you swap in for race day, or a saddle you temporarily moved to another bike.\n\n'
          '"Archived" means the component is retired and will never be used again. It is hidden from the main view to keep your garage clean, but all its history and statistics are preserved. Use this for worn-out brake pads or tires, broken or sold parts, or anything you no longer ride. You can still find archived components in the Archived section and restore them if needed.',
      ..._adjustmentFAQs,
      'How do I reorder my bikes?': 'Long-press and drag a bike card to move it up or down in the list.',
    },
    'Setup': {
      'What is a "Setup"?':
          'A Setup is a snapshot of your entire bike configuration. It captures the specific values of all your adjustments alongside context like location, weather, and trail conditions.',
      'How do I record a new setup?':
          'Go to the "Setups" tab and tap the "+" button to record a new setup for your bike.',
      'What do the green and orange highlights on a value mean?':
          'They show how a value compares to the setup you last recorded.\n\n'
          'Green means the value is recorded for the first time — there was no earlier value to compare it to.\n\n'
          'Orange means you changed the value: the previous one is shown underneath, crossed out, so you can see at a glance what you actually touched.',
      'What does the ↺ icon next to a value do?':
          'It restores the value the adjustment had when you opened the setup — usually the one carried over from your last setup. Use it to undo a change you are not happy with, without leaving the page.',
      'Can I enter a value in a different unit than the adjustment uses?':
          'Yes. Tap the unit label next to the input field to cycle through the compatible units — type in whichever one you measured in, and the app converts and stores it in the adjustment’s own unit. A small line below the field shows the value as it will be stored. See the Adjustment questions above for the full details.',
      'I recorded a setup without GPS. Can I add the location later?':
          'Yes. Edit the setup, tap the location chip (showing a pin or "Location Context"), and use the search bar in the sheet to find the address. Alternatively, you can manually enter the Latitude and Longitude.',
      'I recorded a setup without Internet. How do I update address and weather?':
          'Edit the setup and open the location sheet (tap the location chip) to manually fetch the address from Latitude and Longitude. Then, open the weather sheet (tap the weather chip) and tap "Update Weather by Location".',
      'Can I see a raw data overview of all my setups?':
          'Yes. Open the detailed view of a component (by tapping its icon in "Bikes" tab) and then tap on the large card representing the component. This opens a table view where you can compare setups, select which columns to show, and sort the data for deeper analysis.',
      'What does the "Restore" option do?':
          'It duplicates the selected setup, copying all adjustment values, but sets the date and time to now. It also automatically updates the location and weather to your current position. \n\nThis is especially useful if you made changes that feel worse than before and want to easily go back to a previous, known good setup.',
    },
    "Person": {
      'Why?':
          'Adding a person profile allows you to link bikes to individual riders for a better overview. You can also track personal data (like body weight) that directly influences bike component behavior. Having personal data as context makes finding the optimal setup easier.',
      'How to add a Person?': 'Go to the "Person" tab and tap the "+" button to add a new person.',
      "How to link a Person to a Bike?":
          'Navigate to the "Bikes" tab and select the bike you want to link. Tap the three-dot menu, select "Edit", and choose the person from the dropdown menu.',
    },
    "Rating": {
      'What is a Rating?':
          'A Rating defines a fixed procedure to evaluate setups. By knowing whether a setup was good or bad, you can find the optimal configuration easier.',
      'How to add a Rating?':
          'Go to the "Rating" tab and tap the "+" button to add a new rating. You can define the rating name and the rating procedure items.',
    },
    "Strava Sync": {
      'What is Strava Sync?':
          'Strava Sync is a paid subscription that automatically imports your Strava activities into the app. New, updated, and deleted activities are synced in real time so you can see which setup you ran on every ride. You can also trigger a manual sync at any time — up to once per hour.',
      'How do I cancel my subscription?':
          'You can cancel at any time directly through the App Store or Google Play — not through the app itself.\n\n'
          'On iPhone: Settings → [your name] → Subscriptions → Bike Setup Tracker → Cancel.\n\n'
          'On Android: Google Play → Profile icon → Payments & subscriptions → Subscriptions → Bike Setup Tracker → Cancel.\n\n'
          'Your access remains active until the end of the current billing period.',
      'How do I request a refund?':
          'Refunds are handled by Apple or Google, not by us.\n\n'
          'On iPhone: Visit reportaproblem.apple.com, find the charge, and request a refund.\n\n'
          'On Android: Open Google Play → Profile icon → Payments & subscriptions → Subscriptions or Order history → tap the purchase → Request a refund.',
      'How do I restore a previous subscription?':
          'Open the Strava Sync sheet (tap the Strava icon in the top bar) and tap "Restore previous purchase." The app will contact the store and restore your active subscription automatically.',
      'I resubscribed but the app still shows the paywall. What do I do?':
          'Tap "Restore previous purchase" on the paywall screen. The app will check your current subscription status with the store and unlock access.',
      'What happens to my data when my subscription expires?':
          'Your synced activities are removed from the app to respect your privacy. Your bike and component configurations are unaffected. If you resubscribe and reconnect Strava, a fresh sync will restore your activity history.',
    },
    "Tasks": {
      'What is a Task?':
          'A Task is a piece of maintenance or an action you want to track for your bike or a specific component.',
      'What is a "Task Rule"?':
          'Think of a Task Rule as a "Plan" or "Template." It defines what needs to happen (e.g., "Bleed Brakes"), its priority, and which bike or component it applies to. It sets the foundation for tracking when something should be done.',
      'What is a "Task Entry"?':
          'A Task Entry is a "Log" or "Record" of work actually performed. When you complete a task defined by a Task Rule, you create a Task Entry to save exactly when it happened and any notes you want to keep.',
      'How do they work together?':
          'The Task Rule defines the goal, and Task Entries track your history. Every time you finish a task, a new Entry is added to that Rule. This allows the app to show you a complete timeline of when the task was performed in the past.',
      'What is the difference between "Due" and "Overdue"?':
          'Both statuses mean the task needs your attention, but at different urgency levels.\n\n'
          '"Due" (shown in orange) means the task has reached 100% of its interval — it\'s time to do it.\n\n'
          '"Overdue" (shown in red) means the task has exceeded the interval by more than 10%. There is a small grace window before a task escalates from Due to Overdue, so a minor overshoot will not immediately turn red.',
    },
  };

  @override
  Widget build(BuildContext context) {
    final appSettings = context.read<AppSettings>();

    final faqSections = Map.fromEntries(
      _faqSections.entries.where((entry) {
        switch (entry.key) {
          case "Person":
            return appSettings.enablePerson;
          case "Rating":
            return appSettings.enableRating;
          case "Tasks":
            return appSettings.enableTask;
          case "Strava Sync":
            return appSettings.enableStrava;
          default:
            return true;
        }
      }),
    );

    return Scaffold(
      appBar: AppBar(title: const Text('Frequently asked Questions')),
      body: CustomScrollView(
        slivers: [
          SliverSafeArea(
            top: false,
            sliver: SliverMainAxisGroup(
              slivers: [
                ...faqSections.entries.map(
                  (faqSection) => SliverMainAxisGroup(
                    slivers: [
                      PinnedHeaderSliver(
                        child: Container(
                          color: Theme.of(context).colorScheme.surface,
                          child: SectionTitle(title: faqSection.key),
                        ),
                      ),
                      SliverList.list(
                        children: faqSection.value.entries
                            .map(
                              (faq) => ListTile(
                                title: SelectableText(faq.key, style: const TextStyle(fontWeight: FontWeight.bold)),
                                subtitle: SelectableText(faq.value),
                                dense: true,
                              ),
                            )
                            .toList(),
                      ),
                      const SliverToBoxAdapter(child: Divider()),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
