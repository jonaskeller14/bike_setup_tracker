# Feedback scenarios (issue #85, Phase 0 discussion)

Drafted: 2026-10-22. Approach C chosen (`comparison.md`); vocabulary in
`vocabulary.md`.

Shows the **data-driven core** direction: the feedback form asks for the overall
comparison plus optional feel attributes per end of the bike. Components only
decide which knobs a test session can tune. Differences from the first plan
are listed at the end.

## 1. Everyday feedback (no test session)

```mermaid
flowchart TD
    A["Rider opens Feedback<br/>from a setup, the timeline or a synced Strava ride"] --> B{"Test session running<br/>on this bike?"}
    B -- yes --> S["Run debrief<br/>(diagram 2)"]
    B -- no --> C{"Is there an earlier setup<br/>on this bike?"}
    C -- "yes" --> D["Overall comparison vs. previous setup<br/>shows the delta, e.g. fork +5 psi<br/>worse · slightly worse · same · slightly better · better"]
    C -- "no, first setup" --> E["No comparison"]
    D --> O{"Reference setup<br/>has open issues?"}
    O -- yes --> P["Follow-up per issue<br/>e.g. Front harsh: worse · same · better"]
    O -- no --> F
    P --> F
    E --> F["Anything stand out? (optional)<br/>Front: Low grip · Harsh · Sinks/dives · Unsettled · Bottoms out<br/>Rear: same five<br/>or: Nothing stood out"]
    F --> H["More: active measurements<br/>Notes"]
    H --> I[("Save: Feedback<br/>+ comparison + observations")]
```

The same comparison rows feed the setup ranking (Bradley-Terry). Attribute
flags become the "open issues" shown on the setup (*Front: comfort*), and
"Nothing stood out" shows **Dialled in**.

## 2. Test session

```mermaid
flowchart TD
    A["Start test session"] --> B["Pick knobs to test, in order<br/>any adjustment of the bike's components or the rider<br/>e.g. fork LSR, then fork HSR"]
    B --> C["Optional goal: what should improve?<br/>e.g. Front · Calm"]
    C --> D["Run 1 = copy of the current setup, stamped now"]
    D --> E["Ride the run"]
    E --> F["Run debrief<br/>Overall vs. previous run<br/>goal attributes: less · same · more<br/>lap time (if tracked) · Something else changed"]
    F --> G{"Engine: bracketing<br/>on the current knob"}
    G -- "not converged" --> H["Proposal: knob ± n clicks<br/>rider applies it or deviates"]
    H --> I["Next run = new setup, stamped now"]
    I --> E
    G -- "converged, or rider taps Lock" --> J{"More knobs<br/>in the list?"}
    J -- yes --> K["Lock the best value<br/>switch to the next knob"]
    K --> H
    J -- no --> L["A-B-A: repeat the best run<br/>to check for fatigue or track drift"]
    L --> M["End session<br/>best run marked, session measurements archived"]
```

## 3. Bike configurations

```mermaid
flowchart LR
    subgraph bikes["Bike as modelled in the app"]
        B0["No components"]
        B1["Rigid bike, 1 tyre"]
        B2["Hardtail: fork + 2 tyres on wheels"]
        B3["Full suspension: fork + shock<br/>each pressure + LSC/HSC/LSR/HSR<br/>+ 2 tyres on wheels"]
    end
    subgraph form["Everyday form"]
        F["Same for all bikes:<br/>comparison + Front/Rear attributes + notes"]
    end
    subgraph knobs["Knobs a test session can tune"]
        K0["Only rider adjustments<br/>none → no session offered"]
        K1["Tyre pressure"]
        K2["Fork pressure + 4 dampers<br/>front and rear tyre pressure"]
        K3["Fork 5 + shock 5 + 2 tyres = 12 knobs<br/>rider picks 1-2 per session"]
    end
    B0 --> F
    B1 --> F
    B2 --> F
    B3 --> F
    B0 --> K0
    B1 --> K1
    B2 --> K2
    B3 --> K3
```

## User stories

| # | Story | Form | What the engine does |
|---|---|---|---|
| 1 | Synced Strava ride, setup unchanged since the last feedback | Comparison vs. previous setup again (optional), follow-ups, attributes, notes | Another ranking edge for the same pair; flags update open issues |
| 2 | First ride after changing fork pressure +5 psi | Comparison vs. previous setup with "fork +5 psi" shown | One ranking edge: new setup vs. previous |
| 3 | First feedback on a new bike | No comparison, attributes, notes | No ranking yet |
| 4 | Several rides on the same setup, different trails | One feedback per ride, all resolve to the same setup | Comparisons on each count for that setup |
| 5 | Session, one knob (fork LSR), 6 runs | Run debrief: comparison vs. previous run, goal attributes, lap time | Bracketing proposes the next clicks, A-B-A at the end |
| 6 | Session, two knobs (fork LSR then HSR) | Same; the goal attributes may stay the same | LSR is locked when converged (or by the rider), then HSR is bracketed |
| 7 | Rigid bike or bike without components | Same everyday form as any bike | Session only if there is something adjustable (tyre, rider) |
| 8 | Setup inserted afterwards between setup and feedback | Feedback shows the drift warning with Relink | Ranking edge moves to the inserted setup |

## Changes versus the first plan

- Per-component scales (`scale.fork.rebound`, …) and `FeedbackScaleResolver` are
  replaced by per-end feel attributes. The form no longer depends on the
  installed components.
- Test sessions get an optional **goal** (attributes to improve) and a **Lock**
  action per knob.
- The hand-written symptom/attribute → adjuster rule table (Phase 12) moves to an
  optional follow-up: a beginner helper that suggests which knob to put into a
  session.
