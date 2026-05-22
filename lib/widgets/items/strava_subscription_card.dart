import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../models/app_settings.dart';
import '../../services/subscription_service.dart';

class StravaSubscriptionCard extends StatelessWidget {
  final Color? backgroundColor;

  const StravaSubscriptionCard({super.key, this.backgroundColor});

  @override
  Widget build(BuildContext context) {
    const activeColor = Color(0xFF1F8A5B);
    const activeBgColor = Color(0xFFE7F6EE);

    final appSettings = context.watch<AppSettings>();
    final subscription = context.watch<SubscriptionService>();
    final entitlement = subscription.entitlement;
    final isActive = entitlement?.isActive ?? false;

    final statusLabel = isActive ? "ACTIVE" : "EXPIRED";
    final statusColor = isActive ? activeColor : Theme.of(context).colorScheme.error;
    final statusBgColor = isActive ? activeBgColor : Theme.of(context).colorScheme.errorContainer;

    final plan = entitlement?.plan;
    final price = plan != null ? (subscription.localizedPrice(plan) ?? plan.price) : "—";
    final period = plan?.period ?? "";
    final renewLabel = (entitlement?.autoRenewing ?? false) ? "Renews" : "Expires";
    final renewDate = entitlement != null
        ? DateFormat(kDebugMode ? '${appSettings.dateFormat} HH:mm:ss' : appSettings.dateFormat).format(entitlement.expiresAt)
        : "—";
    final billing = entitlement?.billingSource ?? "—";

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: backgroundColor ?? Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'STRAVA SYNC',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: statusBgColor,
                  borderRadius: BorderRadius.circular(100),
                ),
                child: Text(
                  statusLabel,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: statusColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                price,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
              if (period.isNotEmpty) ...[
                const SizedBox(width: 6),
                Text(
                  period,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ],
          ),
          Divider(height: 24, color: Theme.of(context).colorScheme.outlineVariant),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                renewLabel,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              Text(renewDate, style: Theme.of(context).textTheme.labelMedium),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Billing',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              Text(billing, style: Theme.of(context).textTheme.labelMedium),
            ],
          ),
        ],
      ),
    );
  }
}
