import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/tip_product.dart';
import '../../services/tip_service.dart';
import 'sheet_header.dart';

Future<void> showTipJarSheet({required BuildContext context}) async {
  await showModalBottomSheet<void>(
    useSafeArea: true,
    isScrollControlled: true,
    context: context,
    builder: (BuildContext context) => const TipJarSheet(),
  );
  // Reset the one-shot thank-you flag so reopening the sheet starts fresh,
  if (context.mounted) context.read<TipService>().acknowledgeThanks();
}

class TipJarSheet extends StatelessWidget {
  const TipJarSheet({super.key});

  @override
  Widget build(BuildContext context) {
    final tipService = context.watch<TipService>();

    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SheetHeader(
            title: 'Buy me a coffee',
            leadingIcon: Icon(
              Icons.local_cafe_outlined,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
          const SizedBox(height: 16),
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: tipService.justTipped
                  ? const _ThankYou()
                  : _TipBody(tipService: tipService),
            ),
          ),
        ],
      ),
    );
  }
}

class _TipBody extends StatelessWidget {
  const _TipBody({required this.tipService});

  final TipService tipService;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colors = Theme.of(context).colorScheme;
    final isBusy = tipService.isBusy;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Bike Setup Tracker is free — and stays that way.',
          style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 8),
        Text(
          'Building and maintaining it takes a lot of work, and the costs add up '
          '— store fees, servers, and more total over €100 a year. I\'m '
          'grateful for any support, big or small.',
          style: textTheme.bodyMedium?.copyWith(
            color: colors.onSurfaceVariant,
            height: 1.45,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'Feedback and feature wishes are very welcome too — I try to implement '
          'them as soon as I can.',
          style: textTheme.bodyMedium?.copyWith(
            color: colors.onSurfaceVariant,
            height: 1.45,
          ),
        ),
        const SizedBox(height: 20),
        ...TipProduct.values.map(
          (tip) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Card.outlined(
              margin: EdgeInsets.zero,
              clipBehavior: Clip.antiAlias,
              child: ListTile(
                enabled: !isBusy,
                onTap: isBusy ? null : () => tipService.buyTip(tip),
                contentPadding: const EdgeInsets.fromLTRB(10, 6, 16, 6),
                leading: Container(
                  width: 44,
                  height: 44,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: colors.primary.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(tip.emoji, style: const TextStyle(fontSize: 22)),
                ),
                title: Text(tip.label, style: textTheme.titleSmall),
                trailing: Text(
                  tipService.localizedPrice(tip) ?? tip.fallbackPrice,
                  style: textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
        ),
        if (isBusy)
          const Padding(
            padding: EdgeInsets.only(top: 8),
            child: Center(
              child: SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          ),
        if (tipService.errorMessage != null)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: SelectableText(
              tipService.errorMessage!,
              textAlign: TextAlign.center,
              style: textTheme.bodySmall?.copyWith(color: colors.error),
            ),
          ),
        const SizedBox(height: 4),
        Center(
          child: Text(
            'A one-time tip — no subscription.',
            style: textTheme.bodySmall?.copyWith(color: colors.onSurfaceVariant),
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }
}

class _ThankYou extends StatelessWidget {
  const _ThankYou();

  static const _successFgColor = Color(0xFF1F8A5B);
  static const _successBgColor = Color(0xFFE7F6EE);

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colors = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.only(top: 24, bottom: 16),
      child: Column(
        children: [
          Container(
            width: 84,
            height: 84,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: _successBgColor,
            ),
            child: const Icon(
              Icons.check_rounded,
              size: 48,
              color: _successFgColor,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Thank you so much! ❤️',
            style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'Your support genuinely helps keep Bike Setup Tracker going.',
            style: textTheme.bodyMedium?.copyWith(color: colors.onSurfaceVariant),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: FilledButton(
              onPressed: () {
                context.read<TipService>().acknowledgeThanks();
                Navigator.pop(context);
              },
              child: const Text('Close'),
            ),
          ),
        ],
      ),
    );
  }
}
