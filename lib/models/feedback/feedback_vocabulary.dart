enum FeedbackEnd { front, rear }

/// What the rider can feel without knowing the cause (issue #85, Phase 0).
/// The labels are in `lib/l10n/enum_labels.dart`: `qualityLabel` is used for
/// session goals and aspect comparisons, `problemLabel` for the everyday problem
/// chip and open issues.
enum FeedbackAttribute { grip, comfort, support, calm, bottoming }
