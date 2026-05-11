enum StravaPlan {
  monthly(
    label: 'Monthly',
    tagline: 'Try it month to month',
    price: '€0.99',
    period: '/ month',
  ),
  yearly(
    label: 'Yearly',
    tagline: 'Best for the full season',
    price: '€8.99',
    period: '/ year',
    perMonth: '€0.75',
    save: '25%',
  );
  final String label;
  final String tagline;
  final String price;
  final String period;
  final String? perMonth;
  final String? save;
  const StravaPlan({
    required this.label,
    required this.tagline,
    required this.price,
    required this.period,
    this.perMonth,
    this.save,
  });
}
