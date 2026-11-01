import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../l10n/enum_labels.dart';
import '../../l10n/l10n.dart';
import '../../models/app_settings.dart';
import '../../models/strava/strava_plan.dart';
import '../../services/subscription_service.dart';
import '../sheets/strava.dart';

class StravaSubscriptionCard extends StatelessWidget {
  final Color? backgroundColor;

  const StravaSubscriptionCard({super.key, this.backgroundColor});

  @override
  Widget build(BuildContext context) {
    final subscription = context.watch<SubscriptionService>();
    final appSettings = context.watch<AppSettings>();

    final entitlement = subscription.entitlement;
    final plan = entitlement?.plan ?? StravaPlan.monthly;
    final price = subscription.localizedPrice(plan) ?? '—';
    final dateFormat = appSettings.dateFormat;

    final Widget content = switch (entitlement) {
      null => _notSubscribed(context, price),
      final e when e.isActive => _status(context, e, price, dateFormat, isActive: true),
      final e => _status(context, e, price, dateFormat, isActive: false),
    };

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: backgroundColor ?? Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
      ),
      child: content,
    );
  }

  Widget _notSubscribed(BuildContext context, String price) {
    final colors = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _header(context, label: context.l10n.stravaCardNotSubscribed.toUpperCase(), color: colors.onSurfaceVariant, bgColor: colors.surfaceContainerHighest),
        const SizedBox(height: 8),
        Text(
          context.l10n.stravaCardPitch,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(color: colors.onSurfaceVariant, height: 1.4),
        ),
        const SizedBox(height: 10),
        _priceRow(context, price: context.l10n.stravaCardFromPrice(price), period: StravaPlan.monthly.period(context.l10n)),
        const SizedBox(height: 14),
        _viewPlansButton(context, context.l10n.viewPlans),
      ],
    );
  }

  Widget _status(
    BuildContext context,
    StravaEntitlement entitlement,
    String price,
    String dateFormat, {
    required bool isActive,
  }) {
    const activeColor = Color(0xFF1F8A5B);
    const activeBgColor = Color(0xFFE7F6EE);
    final colors = Theme.of(context).colorScheme;

    final isTrial = entitlement.billingPhase == StravaBillingPhase.trial;
    final renewLabel = isTrial
        ? entitlement.autoRenewing ? context.l10n.stravaCardFirstCharge : context.l10n.stravaCardTrialEnds
        : entitlement.autoRenewing ? context.l10n.stravaCardRenews : context.l10n.stravaCardExpires;
    final renewDate = DateFormat(context.read<AppSettings>().developerMode ? '$dateFormat HH:mm:ss' : dateFormat, context.l10n.localeName).format(entitlement.expiresAt);

    return Column(
      children: [
        _header(
          context,
          label: (isActive
                  ? isTrial ? context.l10n.stravaCardTrial : context.l10n.stravaCardActive
                  : context.l10n.stravaCardExpired)
              .toUpperCase(),
          color: isActive ? activeColor : colors.error,
          bgColor: isActive ? activeBgColor : colors.errorContainer,
        ),
        const SizedBox(height: 6),
        _priceRow(context, price: price, period: entitlement.plan.period(context.l10n)),
        Divider(height: 24, color: colors.outlineVariant),
        _detailRow(context, label: renewLabel, value: renewDate),
        const SizedBox(height: 4),
        _detailRow(context, label: context.l10n.stravaCardBilling, value: entitlement.billingSource),
        if (!isActive) ...[
          const SizedBox(height: 14),
          _viewPlansButton(context, context.l10n.viewPlans),
        ],
      ],
    );
  }

  Widget _header(BuildContext context, {required String label, required Color color, required Color bgColor}) {
    final textTheme = Theme.of(context).textTheme;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Flexible(
          child: Text(
            context.l10n.stravaCardTitle.toUpperCase(),
            style: textTheme.bodySmall?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant, fontWeight: FontWeight.bold),
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(100)),
          child: Text(label, style: textTheme.bodySmall?.copyWith(color: color, fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }

  Widget _priceRow(BuildContext context, {required String price, required String period}) {
    final textTheme = Theme.of(context).textTheme;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.baseline,
      textBaseline: TextBaseline.alphabetic,
      children: [
        Flexible(
          child: Text(
            price,
            overflow: TextOverflow.ellipsis,
            style: textTheme.titleLarge,
          ),
        ),
        const SizedBox(width: 6),
        Text(period, style: textTheme.bodyMedium?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant)),
      ],
    );
  }

  Widget _detailRow(BuildContext context, {required String label, required String value}) {
    final textTheme = Theme.of(context).textTheme;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: textTheme.bodySmall?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant)),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.end,
            overflow: TextOverflow.ellipsis,
            style: textTheme.labelMedium,
          ),
        ),
      ],
    );
  }

  Widget _viewPlansButton(BuildContext context, String label) {
    return SizedBox(
      width: double.infinity,
      child: FilledButton.icon(
        icon: const Icon(Icons.auto_awesome, size: 18),
        label: Text(label),
        onPressed: () => showStravaSheet(context: context),
      ),
    );
  }
}
