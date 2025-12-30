import 'package:flutter/material.dart';

class FAQPage extends StatelessWidget {
  const FAQPage({super.key});
  static const Map<String, Map<String, String>> faqSections = {
    'General': {
      'What is this app about?': 'This app helps you track and manage your bike setup adjustments.',
      'Can I export my data?': "Yes, you can export your bike setup data as a json file. Select 'Export' in top right menu and set file path.",
      'Is my data stored locally?': 'Yes, all your data is stored locally on your device. We do not collect or store any personal data.',
    },
    'Bike': {
      'How do I add a new bike?': 'Go to the Bikes tab and tap the "+" button to add a new bike.',
    },
    "Component": {
      'How do I add components to my bike?': 'Go to the Components tab, and tap the "+" button to add components. Select your previously added bike in the process.',
      'What is an adjustment?': 'An adjustment is part of a bike component that can be modified, such as tire pressure or suspension dials. Adjustments define the rules—like limits and units—not the actual values. Values are set in a setup entry.',
    },
    'Setup': {
      'What is a setup?': 'is a current snapshot of all components of one bike. It captures the specific values of your adjustments and automatically adds context (e.g. location, weather, trail conditions).',
      'How do I record a new setup?': 'Go to the Setups tab, and tap the "+" button to record a new setup for your bike.',
    },
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Frequently asked Questions'),
      ),
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
