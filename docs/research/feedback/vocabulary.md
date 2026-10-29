# Feedback vocabulary (issue #85, Phase 0)

Researched: 2026-10-22. Approach **C** (data-driven core), chosen over
per-component scales with a rule table; see `comparison.md`. Scenarios and
flows: `scenarios.md`.

Working notes: nothing here ships in the app. This is the input for the
vocabulary in Phase 2 and the form in Phase 6.

## Principles

- The rider reports **perception** (how the bike felt) and **preference**
  (better or worse), never a diagnosis ("rebound too fast").
- The form is the **same for every bike**. Installed components only decide
  which knobs a test session can tune.
- The engine is **black-box**: it uses a knob's min/max/step and better/worse
  answers, not the knob's meaning. The rider supplies the meaning by choosing
  knobs and a goal.
- No hand-written rules from feel to adjuster in v1.

## Form elements

### 1. Overall comparison

| | |
|---|---|
| Question | "Compared to *S6*:" with the delta from that setup to this one (e.g. *fork pressure +5 psi*) |
| Steps | Worse · Slightly worse · Same · Slightly better · Better (−2 … +2) |
| Reference | Previous setup on this bike. In a session: the previous run. Any earlier setup or run can be picked instead |
| Shown when | An earlier setup exists on this bike. Repeating it on later rides of the same setup is allowed: each ride is another data point |
| Stored | `FeedbackComparisons` row, aspect `overall` |
| Used by | Setup ranking (Bradley-Terry), bracketing engine |

### 2. Feel attributes

Five attributes for each **end** of the bike (`front`, `rear`), always both,
whatever is installed. The quality label is used for goals and comparisons;
the problem label is the everyday chip.

| Key | Quality label | Problem chip | Hint |
|---|---|---|---|
| `grip` | Grip | Low grip | Wheel slides or lets go |
| `comfort` | Comfort | Harsh | Hits come through to hands or feet |
| `support` | Support | Sinks / dives | Sits low, dives under braking, wallows in berms |
| `calm` | Calm | Unsettled | Bouncy, kicks, doesn't settle after hits |
| `bottoming` | Bottoming | Bottoms out | Hits the end of travel hard or often |

An **aspect** is end + attribute: `front.calm`, `rear.grip`, … (10 in total).

Wording came from the symptoms used by FOX and RockShox tuning material (harsh,
packs down, dives, wallows, bucks/kicks, bottoms out, poor traction), grouped
into what a rider can feel without knowing the cause.

### 3. Everyday: "Anything stand out?"

- Ten optional problem chips, grouped Front / Rear, plus **Nothing stood out**.
- A chip stores `issue.<end>.<attribute>` = 1. "Nothing stood out" stores
  `issue.none` = 1, so "didn't bother" (nothing tapped) stays distinguishable
  from "felt right".

### 4. Follow-up on open issues

When the reference setup has open issues, each is asked again against that
reference: *"Front harsh — now: worse · same · better"*. It is stored as a
`FeedbackComparisons` row with aspect `front.comfort` and outcome −1 / 0 / +1
(+1 = the problem got smaller). This tells whether the change fixed it, without
any heuristic.

### 5. Test-session run

- At session start the rider picks the knobs (ordered, any adjustment) and an
  optional **goal**: 1–3 aspects to improve.
- Each run debrief: overall comparison vs. the previous run, one
  worse · same · better row per goal aspect, **Something else changed ▸**
  (opens all 10 aspects as rows), lap time when tracked, notes.

### 6. Notes

Free text with the helper "Not used for ranking or proposals."

### 7. Measurement presets (Phase 8)

| Preset | Type | Direction |
|---|---|---|
| Lap time | Duration | lower is better |
| Travel used | Numerical, mm (O-ring reading) | neutral |
| Bottom-outs | Numerical, count | neutral |
| Arm pump | Yes/no | lower is better |

## Keys

| Meaning | Stored as |
|---|---|
| Overall preference vs. a reference setup | `FeedbackComparisons` (aspect `overall`, outcome −2 … +2) |
| Aspect better/worse vs. a reference setup | `FeedbackComparisons` (aspect `<end>.<attribute>`, outcome −1 … +1) |
| Problem felt | observation `issue.<end>.<attribute>` = 1 |
| Nothing stood out | observation `issue.none` = 1 |
| Custom measurement | observation `custom:<measurementId>` |

`FeedbackComparisons` therefore gets an `aspect` column and the primary key
`{feedbackId, referenceSetupId, aspect}`. Ranking reads only `overall`.

## Derived states

- **Open issues** of a setup: the `issue.*` flags of the latest feedback that
  resolves to it, shown as chips (*Front: harsh*).
- **Dialled in**: the latest feedback says "Nothing stood out".
- No internal score from attributes; the B3 index is dropped.

## Engine inputs (Phase 11)

- Decision per step: the overall outcome; on "same", the sum of the goal-aspect
  outcomes; on 0, a lap-time difference above the noise threshold (start at
  1.5 %); otherwise equal.
- A knob is **locked** when bracketing converged (smallest step, neither
  neighbour better) or when the rider taps **Lock**. Then the next knob starts.
- Order of tuning in the sources is spring → rebound → compression. This is a
  hint for the knob picker's default order, not a rule.

## Dropped from the first draft

Per-component "just right" scales, 56 symptom chips, the tyre position from the
installation tree, bike-level balance/steering scales and the 15-rule table. The
v2 presets map onto the attributes (harshness → comfort, wallowing → support,
bucking → calm, squirm/pinging → grip/comfort, bottom out → bottoming, travel
usage → Travel used measurement, laptime → Lap time measurement). Fit and
geometry presets (steering, pinky pain, centre of gravity, front-end grip)
go to notes.

A beginner helper (goal → which knob to try) and a learned per-rider map
(which knob moved which aspect) are follow-ups, not part of this plan.

## Sources

- FOX, Suspension Tuning Tips (owner's manual):
  <https://tech.ridefox.com/fox_tech_center/owners_manuals/09/Eng/Content/Suspension_Tuning_Tips.htm>
- Flow Mountain Bike, FOX shock setup guide:
  <https://flowmountainbike.com/features/fox-float-dps-x2-shock-setup-guide-tuning-tips/>
- NSMB, RockShox tuning camp: <https://nsmb.com/rock-shox-tuning-camp/>
- SRAM / RockShox suspension welcome guide:
  <https://www.sram.com/en/rockshox/learn/suspension-welcome-guide>
- Jordi Cortes (FOX): bracketing how-to (Vital MTB), "Dialed" (Pinkbike), read
  only through search summaries; the bracketing loop (change, compare, go on
  or go back) and the tuning order match the engine.
