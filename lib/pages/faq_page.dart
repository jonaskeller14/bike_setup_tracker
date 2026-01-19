import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/app_settings.dart';

class FAQPage extends StatelessWidget {
  const FAQPage({super.key});
  static const Map<String, Map<String, String>> _faqSections = {
    'General': {
      'What is this app about?':
          'This app helps you track, manage, and optimize your bike setup adjustments for better performance.',
      // 'What makes a good bike setup?':
      //     'A "good" bike setup is a balance between the laws of physics and the rider’s personal feel. It should provide maximum traction and stability while minimizing rider fatigue. To evaluate a setup, you need to look at Objective Data (e.g. laptimes) and Subjective Feedback (what the rider is feeling).',
      'Can I export my data?':
          'Yes. You can export your bike setup as a JSON file by selecting "Export" from the top-right menu. The default save location is your Downloads folder.',
      'Is my data stored locally?':
          'Yes, all your data is stored locally on your device. We do not collect or store any of your personal information.',
      'I accidentally deleted something. Can I recover it?':
          'Yes. Open the menu in the top-right corner of the home page and select "Trash." You can restore items deleted within the last 30 days. After 30 days, items are permanently deleted.',
      'How do I move my data to a new device?':
          'Data is typically restored by your operating system if you have cloud backups enabled. To move data manually: Export your data as a JSON file from the home page menu, transfer that file to your new device (via cloud or cable), and select "Import" from the menu on the new device.',
      'Can I sync data between devices?':
          'Yes. Turn on "Google Drive Sync" in App Settings → Experimental Features. A cloud icon will appear on the home screen — tap it to sign in and authorize. Once enabled, changes sync automatically and daily backups are saved to your Google Drive so you can access them from any device.',
    },
    'Bike': {
      'How do I add a new bike?':
          'Navigate to the "Bikes" tab and tap the "+" button to create a new bike.',
      'How do I reorder my bikes?':
          'In the "Bikes" tab, long-press and drag a bike card to your preferred position. This order will be reflected throughout the app.',
    },
    'Components': {
      'How do I add components to my bike?':
          'Go to the "Components" tab and tap the "+" button. A page opens that lets you assign the component to any of your existing bikes.',
      'How do I move a component to a different bike?':
          'In the "Components" tab, tap the three-dot menu on a specific component and select "Edit." Change the assigned bike in the dropdown menu and save your changes.',
      'How do I reorder components?':
          'In the "Components" tab, long-press and drag a component card to change its position. This order persists across all component lists.',
      'What is an "Adjustment"?':
          'An Adjustment defines a specific part of a component that can be modified (e.g., tire pressure or suspension rebound). It sets the rules, such as units and limits, while the actual values are recorded within a "Setup."',
    },
    'Setup': {
      'What is a "Setup"?':
          'A Setup is a snapshot of your entire bike configuration. It captures the specific values of all your adjustments alongside context like location, weather, and trail conditions.',
      'How do I record a new setup?':
          'Go to the "Setups" tab and tap the "+" button to record a new setup for your bike.',
    },
    "Person": {
      'Why?':
          'Adding a person profile allows you to link bikes to individual riders for a better overview. You can also track personal data (like body weight) that directly influences bike component behavior. Having personal data as context makes finding the optimal setup easier.',
      'How to add a Person?':
          'Go to the "Person" tab and tap the "+" button to add a new person.',
      "How to link a Person to a Bike?":
          'Navigate to the "Bikes" tab and select the bike you want to link. Tap the three-dot menu, select "Edit", and choose the person from the dropdown menu.',
    },
    "Rating": {
      'What is a Rating?':
          'A Rating defines a fixed procedure to evaluate setups. By knowing whether a setup was good or bad, you can find the optimal configuration easier.',
      'How to add a Rating?':
          'Go to the "Rating" tab and tap the "+" button to add a new rating. You can define the rating name and the rating procedure items.',
    },
  };

  @override
  Widget build(BuildContext context) {
    final appSettings = context.read<AppSettings>();

    final faqSections = Map.fromEntries(_faqSections.entries.where((entry) {
        switch (entry.key) {
        case "Person": return appSettings.enablePerson;
        case "Rating": return appSettings.enableRating;
        default: return true;
        }
    }));

    return Scaffold(
      appBar: AppBar(title: const Text('Frequently asked Questions')),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: faqSections.entries.map((faqSection) => Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(left: 16.0, top: 8.0, bottom: 8.0),
                child: Text(
                  faqSection.key,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
              ...faqSection.value.entries.map((faq) => ListTile(
                title: Text(faq.key, style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text(faq.value),
                dense: true,
              )),
              const Divider(height: 32.0),
            ],
          )).toList(),
        ),
      ),
    );
  }
}
