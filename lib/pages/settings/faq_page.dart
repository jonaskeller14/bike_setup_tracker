import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../l10n/l10n.dart';
import '../../models/app_settings.dart';
import '../../widgets/text/section_title.dart';

typedef _Faq = ({String question, String answer});
typedef _FaqSection = ({String title, bool visible, List<_Faq> faqs});

class FAQPage extends StatelessWidget {
  const FAQPage({super.key});

  /// Adjustments are configured per component and are managed from Bikes.
  static List<_Faq> _adjustmentFAQs(AppLocalizations l10n) => [
    (question: l10n.faqAdjustmentWhatQuestion, answer: l10n.faqAdjustmentWhatAnswer),
    (question: l10n.faqAdjustmentTypesQuestion, answer: l10n.faqAdjustmentTypesAnswer),
    (question: l10n.faqAdjustmentOtherUnitQuestion, answer: l10n.faqAdjustmentOtherUnitAnswer),
    (question: l10n.faqAdjustmentSagQuestion, answer: l10n.faqAdjustmentSagAnswer),
    (question: l10n.faqAdjustmentSagAddQuestion, answer: l10n.faqAdjustmentSagAddAnswer),
    (question: l10n.faqAdjustmentChangeUnitQuestion, answer: l10n.faqAdjustmentChangeUnitAnswer),
  ];

  static List<_FaqSection> _faqSections(AppLocalizations l10n, AppSettings appSettings) => [
    (
      title: l10n.faqSectionGeneral,
      visible: true,
      faqs: [
        (question: l10n.faqGeneralAboutQuestion, answer: l10n.faqGeneralAboutAnswer),
        // 'What makes a good bike setup?':
        //     'A "good" bike setup is a balance between the laws of physics and the rider’s personal feel. It should provide maximum traction and stability while minimizing rider fatigue. To evaluate a setup, you need to look at Objective Data (e.g. laptimes) and Subjective Feedback (what the rider is feeling).',
        (question: l10n.faqGeneralExportQuestion, answer: l10n.faqGeneralExportAnswer),
        (question: l10n.faqGeneralLocalQuestion, answer: l10n.faqGeneralLocalAnswer),
        (question: l10n.faqGeneralRecoverQuestion, answer: l10n.faqGeneralRecoverAnswer),
        (question: l10n.faqGeneralMoveQuestion, answer: l10n.faqGeneralMoveAnswer),
        // Only on Android:
        // 'Can I sync data between devices?':
        //     'Yes. Turn on "Google Drive Sync" in App Settings → Experimental Features. A cloud icon will appear on the home screen — tap it to sign in and authorize. Once enabled, changes sync automatically and daily backups are saved to your Google Drive so you can access them from any device.',
      ],
    ),
    (
      title: l10n.faqSectionBikes,
      visible: true,
      faqs: [
        (question: l10n.faqBikesAddQuestion, answer: l10n.faqBikesAddAnswer),
        (question: l10n.faqBikesComponentsQuestion, answer: l10n.faqBikesComponentsAnswer),
        (question: l10n.faqBikesEditDeleteQuestion, answer: l10n.faqBikesEditDeleteAnswer),
        (question: l10n.faqBikesMoveComponentQuestion, answer: l10n.faqBikesMoveComponentAnswer),
        (question: l10n.faqBikesReorderComponentsQuestion, answer: l10n.faqBikesReorderComponentsAnswer),
        (question: l10n.faqBikesUninstalledQuestion, answer: l10n.faqBikesUninstalledAnswer),
        (
          question: l10n.faqBikesUninstalledVsArchivedQuestion,
          answer: l10n.faqBikesUninstalledVsArchivedAnswer,
        ),
        ..._adjustmentFAQs(l10n),
        (question: l10n.faqBikesReorderBikesQuestion, answer: l10n.faqBikesReorderBikesAnswer),
      ],
    ),
    (
      title: l10n.faqSectionSetup,
      visible: true,
      faqs: [
        (question: l10n.faqSetupWhatQuestion, answer: l10n.faqSetupWhatAnswer),
        (question: l10n.faqSetupRecordQuestion, answer: l10n.faqSetupRecordAnswer),
        (question: l10n.faqSetupHighlightsQuestion, answer: l10n.faqSetupHighlightsAnswer),
        (question: l10n.faqSetupRestoreIconQuestion, answer: l10n.faqSetupRestoreIconAnswer),
        (question: l10n.faqSetupOtherUnitQuestion, answer: l10n.faqSetupOtherUnitAnswer),
        (question: l10n.faqSetupLocationLaterQuestion, answer: l10n.faqSetupLocationLaterAnswer),
        (question: l10n.faqSetupOfflineQuestion, answer: l10n.faqSetupOfflineAnswer),
        (question: l10n.faqSetupRawDataQuestion, answer: l10n.faqSetupRawDataAnswer),
        (question: l10n.faqSetupRestoreQuestion, answer: l10n.faqSetupRestoreAnswer),
      ],
    ),
    (
      title: l10n.faqSectionRider,
      visible: appSettings.enablePerson,
      faqs: [
        (question: l10n.faqRiderWhyQuestion, answer: l10n.faqRiderWhyAnswer),
        (question: l10n.faqRiderAddQuestion, answer: l10n.faqRiderAddAnswer),
        (question: l10n.faqRiderLinkQuestion, answer: l10n.faqRiderLinkAnswer),
        (question: l10n.faqRiderWeightQuestion, answer: l10n.faqRiderWeightAnswer),
      ],
    ),
    (
      title: l10n.faqSectionStrava,
      visible: appSettings.enableStrava,
      faqs: [
        (question: l10n.faqStravaWhatQuestion, answer: l10n.faqStravaWhatAnswer),
        (question: l10n.faqStravaCancelQuestion, answer: l10n.faqStravaCancelAnswer),
        (question: l10n.faqStravaRefundQuestion, answer: l10n.faqStravaRefundAnswer),
        (question: l10n.faqStravaRestoreQuestion, answer: l10n.faqStravaRestoreAnswer),
        (question: l10n.faqStravaPaywallQuestion, answer: l10n.faqStravaPaywallAnswer),
        (question: l10n.faqStravaExpireQuestion, answer: l10n.faqStravaExpireAnswer),
      ],
    ),
    (
      title: l10n.faqSectionTasks,
      visible: appSettings.enableTask,
      faqs: [
        (question: l10n.faqTasksWhatQuestion, answer: l10n.faqTasksWhatAnswer),
        (question: l10n.faqTasksRuleQuestion, answer: l10n.faqTasksRuleAnswer),
        (question: l10n.faqTasksEntryQuestion, answer: l10n.faqTasksEntryAnswer),
        (question: l10n.faqTasksTogetherQuestion, answer: l10n.faqTasksTogetherAnswer),
        (question: l10n.faqTasksDueOverdueQuestion, answer: l10n.faqTasksDueOverdueAnswer),
      ],
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final appSettings = context.read<AppSettings>();

    final faqSections = _faqSections(l10n, appSettings).where((section) => section.visible);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.faqTitle)),
      body: CustomScrollView(
        slivers: [
          SliverSafeArea(
            top: false,
            sliver: SliverMainAxisGroup(
              slivers: [
                ...faqSections.map(
                  (faqSection) => SliverMainAxisGroup(
                    slivers: [
                      PinnedHeaderSliver(
                        child: Container(
                          color: Theme.of(context).colorScheme.surface,
                          child: SectionTitle(title: faqSection.title),
                        ),
                      ),
                      SliverList.list(
                        children: faqSection.faqs
                            .map(
                              (faq) => ListTile(
                                title: SelectableText(faq.question, style: const TextStyle(fontWeight: FontWeight.bold)),
                                subtitle: SelectableText(faq.answer),
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
