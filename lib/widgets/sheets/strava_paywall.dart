import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../icons/simple_icons.dart';
import '../../l10n/enum_labels.dart';
import '../../l10n/l10n.dart';
import '../../l10n/markup_text.dart';
import '../../models/strava/strava_plan.dart';
import '../../services/subscription_service.dart';
import '../../utils/app_info.dart';
import '../../utils/url.dart';
import 'sheet_header.dart';

class StravaPaywall extends StatefulWidget {
  const StravaPaywall({super.key});

  @override
  State<StravaPaywall> createState() => _StravaPaywallState();
}

class _StravaPaywallState extends State<StravaPaywall> with SingleTickerProviderStateMixin {
  StravaPlan _selectedPlan = StravaPlan.yearly;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final subscription = context.watch<SubscriptionService>();
    final isBusy = subscription.isBusy;
    final selectedOffer = subscription.offerFor(_selectedPlan);
    final offersReady = subscription.offersReady;
    final yearlySavingsPercent = subscription.yearlySavingsPercent;

    final isIOS = Theme.of(context).platform == TargetPlatform.iOS;
    final storeSettings = isIOS ? l10n.paywallStoreSettingsIos : l10n.paywallStoreSettingsAndroid;
    final bullets = [l10n.paywallNoteAffiliation, l10n.paywallNoteCosts, l10n.paywallNoteData];
    final features = [
      (icon: Icons.show_chart_rounded, title: l10n.paywallFeature1Title, body: l10n.paywallFeature1Body),
      (icon: Icons.map_outlined, title: l10n.paywallFeature2Title, body: l10n.paywallFeature2Body),
      (icon: Icons.sync_rounded, title: l10n.paywallFeature3Title, body: l10n.paywallFeature3Body),
    ];
    final manageSubscriptionUrl = isIOS
        ? 'https://apps.apple.com/account/subscriptions'
        : 'https://play.google.com/store/account/subscriptions'
              '?sku=strava_sync'
              '&package=com.jonaskeller14.bike_setup_tracker';

    final eulaRecognizer = TapGestureRecognizer()..onTap = () => launchAppUrl(context, url: AppInfo.eulaUrl);
    final privacyRecognizer = TapGestureRecognizer()
      ..onTap = () => launchAppUrl(context, url: AppInfo.privacyPolicyUrl);
    final storeSettingsRecognizer = TapGestureRecognizer()
      ..onTap = () => launchAppUrl(
        context,
        url: manageSubscriptionUrl,
        launchMode: LaunchMode.externalApplication,
      );

    TextSpan linkSpan(String text, GestureRecognizer recognizer) => TextSpan(
      text: text,
      style: Theme.of(context).textTheme.bodySmall?.copyWith(
        color: Theme.of(context).colorScheme.primary,
        fontWeight: FontWeight.bold,
        decoration: TextDecoration.underline,
        decorationColor: Theme.of(context).colorScheme.primary,
        letterSpacing: 0.4,
      ),
      recognizer: recognizer,
    );

    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SheetHeader(
            title: l10n.stravaSheetTitle,
            leadingIcon: const Icon(SimpleIcons.strava, color: Color(0xFFFC4C02)),
          ),
          const SizedBox(height: 16),
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsetsGeometry.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: const Alignment(-0.4, -1.0),
                        end: const Alignment(0.4, 1.0),
                        colors: [const Color(0xFF0D4F5D), Theme.of(context).colorScheme.primary],
                      ),
                      borderRadius: const BorderRadius.all(Radius.circular(16)),
                    ),
                    child: ClipRRect(
                      borderRadius: const BorderRadius.all(Radius.circular(16)),
                      child: Stack(
                        children: [
                          Positioned.fill(child: CustomPaint(painter: _TopoPainter())),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  l10n.paywallHeroTitle,
                                  style: const TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                    height: 1.2,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  l10n.paywallHeroSubtitle,
                                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: Colors.white.withAlpha(235),
                                    height: 1.5,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Padding(
                    padding: const EdgeInsets.only(left: 4),
                    child: Text(
                      l10n.paywallChoosePlan.toUpperCase(),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      RadioGroup<StravaPlan>(
                        groupValue: _selectedPlan,
                        onChanged: (StravaPlan? stravaPlan) {
                          if (stravaPlan == null) return;
                          setState(() => _selectedPlan = stravaPlan);
                        },
                        child: Column(
                          children: StravaPlan.values.map((plan) {
                            return Card.outlined(
                              shape: RoundedRectangleBorder(
                                side: BorderSide(
                                  color: _selectedPlan == plan
                                      ? Theme.of(context).colorScheme.primary
                                      : Theme.of(context).colorScheme.outlineVariant,
                                  width: 2.0,
                                ),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              margin: const EdgeInsets.symmetric(vertical: 4.0),
                              clipBehavior: Clip.antiAlias,
                              child: InkWell(
                                onTap: () => setState(() => _selectedPlan = plan),
                                child: RadioListTile<StravaPlan>(
                                  horizontalTitleGap: 8,
                                  value: plan,
                                  selected: _selectedPlan == plan,
                                  title: Row(
                                    spacing: 8,
                                    children: [
                                      Flexible(
                                        child: Text(
                                          plan.label(context.l10n),
                                          overflow: TextOverflow.ellipsis,
                                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                      if (plan == StravaPlan.yearly && yearlySavingsPercent != null)
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 7,
                                            vertical: 3,
                                          ),
                                          decoration: BoxDecoration(
                                            color: Theme.of(context).colorScheme.primary,
                                            borderRadius: BorderRadius.circular(100),
                                          ),
                                          child: Text(
                                            l10n.paywallSavePercent(yearlySavingsPercent),
                                            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                              color: Colors.white,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                  subtitle: Text(
                                    plan.tagline(context.l10n),
                                    overflow: TextOverflow.ellipsis,
                                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                  secondary: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Row(
                                        mainAxisSize: MainAxisSize.min,
                                        crossAxisAlignment: CrossAxisAlignment.baseline,
                                        textBaseline: TextBaseline.alphabetic,
                                        children: [
                                          Flexible(
                                            child: Text(
                                              subscription.localizedPrice(plan) ?? '—',
                                              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                                letterSpacing: -0.3,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 3),
                                          Flexible(
                                            child: Text(
                                              plan.period(context.l10n).replaceAll('/ ', '/'),
                                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                                color: Theme.of(context).colorScheme.onSurfaceVariant,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      if (subscription.offerFor(plan)?.isTrialEligible == true)
                                        Text(
                                          l10n.paywallTrialBadge,
                                          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                            color: Theme.of(context).colorScheme.primary,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemBuilder: (BuildContext context, int index) {
                      final feature = features[index];
                      return ListTile(
                        contentPadding: const EdgeInsets.only(left: 4),
                        leading: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.05),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(feature.icon, color: Theme.of(context).colorScheme.primary),
                        ),
                        title: Text(
                          feature.title,
                          style: Theme.of(context).textTheme.titleSmall,
                        ),
                        subtitle: Text(
                          feature.body,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                        ),
                      );
                    },
                    separatorBuilder: (BuildContext context, int index) => const Divider(),
                    itemCount: features.length,
                  ),
                  const SizedBox(height: 16),
                  Card.outlined(
                    margin: const EdgeInsets.symmetric(vertical: 4.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsetsGeometry.all(12),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                l10n.paywallHowItWorks.toUpperCase(),
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              ConstrainedBox(
                                constraints: const BoxConstraints(
                                  maxHeight: 48,
                                  maxWidth: 80,
                                ),
                                child: Image.asset(
                                  'assets/strava/1.2-Strava-API-Logos/1.2-Strava-API-Logos/Powered by Strava/pwrdBy_strava_orange/api_logo_pwrdBy_strava_stack_orange.png',
                                  fit: BoxFit.contain,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Divider(height: 1),
                        Container(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            children: bullets.indexed
                                .map(
                                  (e) => Padding(
                                    padding: EdgeInsets.only(
                                      bottom: e.$1 < bullets.length - 1 ? 8 : 0,
                                    ),
                                    child: Row(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          '·',
                                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            e.$2,
                                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                                              height: 1.45,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                )
                                .toList(),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsetsGeometry.symmetric(horizontal: 16),
            child: Text.rich(
              TextSpan(
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                children: [
                  markupTextSpan(
                    selectedOffer?.isTrialEligible == true
                        ? l10n.paywallLegalTrial(
                            selectedOffer!.localizedRecurringPrice,
                            _selectedPlan.period(l10n),
                            storeSettings,
                          )
                        : l10n.paywallLegalAuto(storeSettings),
                    tags: {
                      'store': (text) => linkSpan(text, storeSettingsRecognizer),
                      'terms': (text) => linkSpan(text, eulaRecognizer),
                      'privacy': (text) => linkSpan(text, privacyRecognizer),
                    },
                  ),
                ],
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 12),
          if (subscription.failure != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 8, left: 16, right: 16),
              child: SelectableText(
                subscription.failure!.message(l10n),
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.error,
                ),
              ),
            ),
          Container(
            padding: const EdgeInsetsGeometry.symmetric(horizontal: 16),
            height: 56,
            width: double.infinity,
            child: FilledButton.icon(
              icon: isBusy
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.auto_awesome),
              label: Text(
                selectedOffer == null
                    ? l10n.paywallLoadingPrice
                    : selectedOffer.isTrialEligible
                    ? l10n.paywallStartTrial
                    : l10n.paywallSubscribe(
                        selectedOffer.localizedRecurringPrice,
                        _selectedPlan.period(l10n).replaceAll('/ ', '/'),
                      ),
              ),
              onPressed: isBusy || !offersReady ? null : () => subscription.buy(_selectedPlan),
              style: FilledButton.styleFrom(
                iconSize: 18,
                textStyle: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsetsGeometry.symmetric(horizontal: 16),
            child: TextButton.icon(
              onPressed: isBusy ? null : () => subscription.restorePurchases(),
              icon: const Icon(Icons.history_rounded),
              label: Text(l10n.paywallRestore),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Topographic wave pattern painter ─────────────────────────────────────────
class _TopoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white
          .withAlpha(26) // 10% opacity
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;

    // 5 wave lines from SVG viewBox 360×200, scaled to actual size
    final sx = size.width / 360;
    final sy = size.height / 200;

    for (final yBase in [20.0, 55.0, 90.0, 125.0, 160.0]) {
      final y = yBase * sy;
      final controlY = (yBase - 25) * sy;
      final path = Path()
        ..moveTo(0, y)
        ..quadraticBezierTo(90 * sx, controlY, 180 * sx, y)
        // T (smooth quadratic): reflect control point about (180*sx, y)
        ..quadraticBezierTo(270 * sx, y + (y - controlY), 360 * sx, y);
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(_TopoPainter _) => false;

  @override
  bool hitTest(Offset position) => false;
}
