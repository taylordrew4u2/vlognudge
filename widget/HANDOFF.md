# VlogNudge Widget Handoff Spec

Developer handoff for the four widget surfaces designed in `widget/src/*.jsx` and rendered via `widget/widgets.html`. Target stack: **SwiftUI + WidgetKit + ActivityKit**, embedded in the `vlogExtension` target (`vlog/`).

---

## Design Tokens

Single source of truth. Define once in a shared `WidgetTokens.swift` consumed by every widget view.

### Color

| Token | Light/Dark | Hex | Usage |
|-------|------------|-----|-------|
| `record` | both | `#E53935` | Record button fill, "now" cursor, app accent |
| `recordSoft` | both | `rgba(229,57,53,0.16)` | Record button glow ring |
| `pace.green` | both | `#6E8F6A` | "On pace" — muted, calming |
| `pace.yellow` | both | `#C7A45A` | "Behind" — warm, not alarming |
| `pace.orange` | both | `#C98A5A` | "Well behind" — escalated, not red |
| `surfaceDark` | dark | `rgba(28,28,30,0.92)` | Home Screen widget card |
| `glassLight` | dark | `rgba(255,255,255,0.12)` | Lock Screen glass card |
| `glassActivity` | dark | `rgba(20,20,22,0.78)` | Live Activity glass card |
| `text` | dark | `#FFFFFF` | Primary text on dark |
| `textDim` | dark | `rgba(255,255,255,0.55–0.72)` | Captions, secondary |
| `textFaint` | dark | `rgba(255,255,255,0.4–0.5)` | Tertiary, denominator |
| `hairline` | dark | `rgba(255,255,255,0.06–0.10)` | Borders, dividers |

**Forbidden:** Red (`systemRed`) anywhere as a pace/state color. Pace tops out at orange. Punishment-style red breaks the ADHD-brain tone target.

### Typography

Use `.system(.rounded, design: .rounded)` everywhere except numerals.

| Token | Spec | Usage |
|-------|------|-------|
| `numeralXL` | SF Rounded, 88–290pt, weight `.heavy`, `tnum` on, kerning `-0.035em` | Hero count (StandBy, Large Home) |
| `numeralL` | SF Rounded, 44–64pt, weight `.heavy`, `tnum` | Live Activity count, Med Home |
| `numeralM` | SF Rounded, 22–28pt, weight `.bold`, `tnum` | Lock rect/circ, Small Home secondary |
| `titleM` | SF Rounded, 16–22pt, weight `.semibold` | Prompt text, "Next" time |
| `body` | SF Rounded, 13–14pt, weight `.medium` | Captions like "in 13m · long gap" |
| `eyebrow` | SF Rounded, 9–11pt, weight `.semibold`, kern `+0.14em`, uppercase | "TODAY", "NEXT NUDGE" labels |
| `meta` | SF Rounded, 10–11pt, weight `.medium` | Timestamps, "next 3:15 PM" |

**Numerals:** Always enable `featureSettings: [.init(.tabularNumbers)]` so the count doesn't reflow when digits change.

### Spacing & Radius

| Token | Value | Usage |
|-------|-------|-------|
| `padXS` / `padS` / `padM` / `padL` | 4 / 8 / 14 / 20 | Internal padding |
| `gapS` / `gapM` / `gapL` | 6 / 10 / 16 | Between elements |
| `radiusButton` | 11–14 | Action buttons |
| `radiusCard` | 16–22 | Widget cards |
| `radiusPill` | 999 | Dynamic Island compact |

### Motion

| Token | Spec |
|-------|------|
| `easeStandard` | `cubic-bezier(0.2, 0.7, 0.3, 1)` (matches design canvas) |
| `durationCount` | 240ms — count digit changes (use `.contentTransition(.numericText())`) |
| `durationPace` | 600ms — pace color transitions (slow on purpose; never jarring) |
| `durationPulse` | 1.4s — pre-nudge pulse on Dynamic Island compact |

---

## Shared Components

Implement once in `vlog/Shared/` and reuse across widgets.

### `ProgressDots(done: Int, total: Int, size: CGFloat, color: Color)`
Inline filled-circle row. Used in Lock rect A, Live Activity B, Inline B.

### `ProgressBar(progress: Double, height: CGFloat, color: Color)`
Solid horizontal bar with rounded caps. Used in Live Activity A/C, Home Med B.

### `CellStrip(done: Int, total: Int, color: Color)`
Bar split into N cells with gaps. Used in Lock rect B, Home Small C / Med B / Large A.

### `SegmentedRing(done: Int, total: Int, size: CGFloat, stroke: CGFloat, color: Color)`
Donut split into N arcs with gaps. Used in Lock circ B, Home Small B / Med C, StandBy B.

### `ProgressRing(progress: Double, size: CGFloat, stroke: CGFloat, color: Color)`
Solid donut. Used in Lock circ A, Home Large A, StandBy B.

### `RecordButton(size: ButtonSize, intent: RecordIntent)`
Red filled circle with white center dot. Wraps `Button(intent:)`. Sizes: `.small` (30pt), `.medium` (40pt), `.large` (54pt).

### `WidgetHeader(label: String = "VlogNudge", trailing: View?)`
App mark + name on leading, optional trailing meta. Used across all Home variants.

---

## App Intents

All interactive buttons are `AppIntent`s registered in the extension.

| Intent | Purpose | Already in `vlog/AppIntent.swift`? |
|--------|---------|------------------------------------|
| `RecordClipIntent` | Open app to capture (or trigger background record if iOS 18+) | Verify |
| `NotNowIntent` | Snooze current nudge 30min | Add |
| `SkipHourIntent` | Suppress nudges for the next hour | Add |
| `OpenIdeaMemoIntent` | Open Idea Memo capture | Add |

All buttons must use `Button(intent:)`, not `Link(destination:)`, on iOS 17+. Falls back to `widgetURL(_:)` deep link on iOS 16.

---

## Surface 1 — Live Activity (Priority 1)

**Source:** `widget/src/liveactivity.jsx`
**Implementation file:** `vlog/vlogLiveActivity.swift`
**Type:** `ActivityConfiguration<VlogNudgeAttributes>`

### Lifecycle

| Phase | Trigger | Action |
|-------|---------|--------|
| Start | `10:00 AM` (active window opens) | `Activity.request(...)` from app or BGTask |
| Update | clip saved, nudge fires, pace drifts, prompt changes | `activity.update(content:)` |
| Pre-nudge tell | ~10 min before next scheduled nudge | Pulse Dynamic Island compact (alpha 0.6 → 1.0 over 1.4s, 3 cycles) |
| End | `10:00 PM` (window closes) | `activity.end(dismissalPolicy: .default)` |

### Activity Attributes

```swift
struct VlogNudgeAttributes: ActivityAttributes {
  struct ContentState: Codable, Hashable {
    let done: Int            // clips today
    let total: Int           // baseline target
    let nextAt: Date         // next scheduled nudge
    let pace: Pace           // .green | .yellow | .orange
    let prompt: String       // current prompt copy
    let lastClipAt: Date?    // for "last 2h ago"
    let recentClipTimes: [Date]  // up to `total` thumbnails
  }
}
```

### Lock Screen presentations

Three variants — pick one for shipping; spec all three so the choice is informed.

| Variant | Width | Height | Use when |
|---------|-------|--------|----------|
| **A · Full** (MVP recommended) | full content width | ~140pt | Default — count + next + bar + 3 actions |
| **B · Prompt-forward** | full | ~120pt | If prompts are core to the value prop |
| **C · Minimal glass** | full | ~64pt | Quiet-hours mode, or user-selected |

**Variant A layout:**
- Header strip (24pt): record glyph (14×14, `record` color) + "VLOGNUDGE" eyebrow + "LIVE · 3:02 PM" right-aligned
- Body row (54pt): count block (`44pt heavy/45 lineheight`) | 1pt vertical divider | next block (eyebrow "NEXT NUDGE" + `22pt bold` time + meta) | `.large` `RecordButton`
- Progress bar (5pt, 12pt top margin), pace color
- Action row: `Record` (primary, fills), `Not now`, `Skip hour` — equal flex, 11pt semibold, 10pt radius

### Dynamic Island states

Three required states. Each must avoid the camera cutout — center column is decorative space only.

| State | Trigger | Spec |
|-------|---------|------|
| **Compact** | Active window, no other activity | Pill 37pt tall, leading: 14pt record glyph in pace color, trailing: `done/total` in pace color, `tnum`, weight `.heavy` |
| **Minimal** | Sharing with another activity | 38pt circle, black, contains 14pt pace-color square with center dot |
| **Expanded** | Long-press | Four regions: `leading` count block, `trailing` next block, `center` skipped (cutout), `bottomPriority`: prompt card → recent clips strip → progress bar + 3 actions |

**Expanded recent clips strip:** 8 slots (one per `total`). Filled slots are `linear-gradient(180°, rgba(255,255,255,0.10), rgba(255,255,255,0.02))` 34×44pt, 7pt radius, with the `HH:MM` of that clip in 8pt 0.6-alpha at the bottom-left. Empty slots: 1pt dashed border `rgba(255,255,255,0.12)`.

### Actions

All three buttons are `AppIntent` `Button`s. iOS 17+ only — no fallback (Live Activity Buttons require iOS 17).

### Never

- Never red, never streaks, never guilt copy
- No sound from the Live Activity itself (notifications can; the activity cannot)
- No count-up timer ("Recording for 0:42") — keep tone calm
- Quiet hours + Focus modes: still update silently, never flash

---

## Surface 2 — Lock Screen widget (Priority 2)

**Source:** `widget/src/lockscreen.jsx`
**Families:** `.accessoryRectangular`, `.accessoryCircular`, `.accessoryInline`

iOS forces monochrome on Lock Screen widgets. Pace color is **not available** here — use `AccentRenderingMode.tinted` or `.fullColor` and let iOS do its thing. Designs reflect this: pace dots in mockups are decorative; production drops pace color and relies on layout.

### Rectangular (172×80pt — but iOS sizes this; design at this aspect)

| Variant | Layout | Pick when |
|---------|--------|-----------|
| **A** | top: video glyph + "4/8" + "clips" right; mid: 8 dots; bottom: "Next · 3:15 PM" | Default — most info, still readable |
| **B** | top: "VlogNudge" + "4/8" right; mid: cell strip; bottom: "next 3:15 PM · 13m" | Brand-leading |
| **C** | leading: 60pt segmented ring; trailing: stacked num + next + "last 2h ago" | Visual-leading, denser |
| **D** | top: "4/8" + "10A → 10P"; mid: 8-pin timeline with red "now" cursor; bottom: next time | Day-context — best for power users |

### Circular (72pt)

| Variant | Spec |
|---------|------|
| **A** | 56pt progress ring, "4/8" centered (14pt bold) |
| **B** | 58pt segmented ring (8 segments), "4" centered (18pt bold) |
| **C** | Stacked: "4" (26pt) / 18pt rule / "8" (15pt 0.6 alpha) |
| **D** | 8 dots arranged on circle r=26, "4" centered (16pt bold) |

### Inline (text-only, single line above clock)

| Variant | Copy |
|---------|------|
| **A** | `[video icon] Vlog 4/8 · next 3:15 PM` |
| **B** | `[5pt dots: 4 filled, 4 empty] next 3:15 PM` |
| **C** | `[6pt pace dot] 4 of 8 · 13m until nudge` |

### Tap behavior
All Lock Screen variants → `widgetURL(URL(string: "vlognudge://record")!)` (no `Button(intent:)` — Lock Screen disallows interactive buttons).

---

## Surface 3 — Home Screen widget (Priority 3)

**Source:** `widget/src/homescreen.jsx`
**Families:** `.systemSmall` (156×156), `.systemMedium` (336×156), `.systemLarge` (336×336)

iOS 17+ allows interactive buttons on Home Screen. Use `Button(intent: RecordClipIntent())` for the record action.

### Small (156×156)

| Variant | Layout |
|---------|--------|
| **A** (recommended MVP) | Header / count `54pt heavy` over "clips today" / dots row + 30pt RecordButton |
| **B** | Header / centered 90pt segmented ring with "4/8" inside / "next 3:15 PM" caption |
| **C** | Header / "4/8" `42pt` / cell strip + "next 3:15 PM" / "in 13m" |

### Medium (336×156)

| Variant | Layout |
|---------|--------|
| **A** (recommended MVP) | Left col: header + "4/8" `64pt` + next/in-13m caption · Right col: dots row + filled `Record` button (12pt vert padding) |
| **B** | Header with date · "4 of 8 clips" · 6pt cell strip · meta + small Record button |
| **C** | Left: 124pt segmented ring with "4/8" centered · Right: header + next + last + Record |

### Large (336×336)

| Variant | Layout |
|---------|--------|
| **A** (recommended MVP) | Header + time · count `88pt` + 80pt progress ring with "50%" · 8pt cell strip + 10A/now/10P axis · next caption · `Record` (2fr) + `Idea` (1fr) bottom |
| **B** | Header · "4 of 8" · day timeline (slots at non-uniform x positions matching real schedule, "NOW" cursor) · upcoming list "3:15 PM, then 4:30, 6:00" · Record + Idea |
| **C** | Header · giant `220pt` "4" · "out of 8" · dots (10pt) · next caption · floating Record button bottom-right |

### Tap targets (all sizes)
- Card body → `widgetURL("vlognudge://today")`
- Record button → `Button(intent: RecordClipIntent())`
- Idea button (large only) → `Button(intent: OpenIdeaMemoIntent())`

### Refresh policy
`TimelineProvider` returns entries at:
1. `now`
2. Each scheduled nudge time today (so "next" updates the moment a nudge fires)
3. Midnight rollover (resets `done` to 0)
Use `.atEnd` for the next reload after the last entry.

---

## Surface 4 — StandBy (Priority 4)

**Source:** `widget/src/standby.jsx`
**Family:** `.systemExtraLarge` (or detect `widgetRenderingMode == .vibrant`) at the StandBy size (~580×332 design units).

StandBy targets across-the-room legibility. **No interactive buttons** — user is at the nightstand, not touching the phone.

### Variants

| Variant | Spec | Pick when |
|---------|------|-----------|
| **A** (recommended MVP) | Giant "4" (`290pt`, pace color) centered, bottom row: "of 8 clips" leading + "next · 3:15 PM" trailing | Maximum legibility |
| **B** | 240pt progress ring (14pt stroke, pace) with `140pt` "4" + "of 8" inside; "next 3:15 PM" bottom-right | Visual + numeric |
| **C** | 8 large bead row (filled = pace color, empty = 0.18-alpha border); "4 of 8 · next 3:15 PM" caption | Discreet, calmer |
| **D** | Half-arc gauge with tick marks + "4/8" `140pt` centered + "next 3:15 PM" | Dial-as-metaphor |

### Vibrant rendering mode
StandBy at night switches to red-only vibrant mode. All variants must collapse gracefully — design assumes single-color renderable shapes (no gradients except subtle progress fades).

### No record action
No `widgetURL`, no `Button(intent:)`. Purely informational.

---

## Edge Cases (apply to every surface)

| Case | Behavior |
|------|----------|
| `done == 0`, before window opens | Show "—/8" or empty state copy "Window opens 10 AM"; pace = green |
| `done >= total` | Show "8/8 today" in green; suppress "next" line; ring/dots full |
| `total == 0` (user disabled goal) | Hide widget content; show "Set a daily target in Settings" |
| `nextAt > 22:00` | Replace "next 3:15 PM" with "see you tomorrow" |
| `lastClipAt == nil` | Drop "last · 2h ago" lines entirely (don't show "—") |
| Pace transition | Animate over `durationPace` (600ms ease) — never instant |
| Localized long strings (German, Russian) | Eyebrow labels truncate with `…`; numerals are always digits so safe; "Record" → use SF Symbol fallback `record.circle.fill` if string > 8 chars |
| Dark/Light Lock Screen wallpaper | Always assume dark; iOS handles tinting on Lock Screen |
| Reduce Motion | Disable pre-nudge pulse; pace transitions become instant |
| Reduce Transparency | Glass cards lose blur, fall back to solid `surfaceDark` |

---

## Accessibility

| Surface | Requirement |
|---------|-------------|
| All | `accessibilityLabel`: "VlogNudge. {done} of {total} clips today. Next nudge {nextAt, formatted}. Pace: {pace}." |
| Live Activity | Each action button: `accessibilityLabel("Start recording")`, `("Snooze nudge")`, `("Skip next hour")` |
| Home Screen | Card: `accessibilityElement(children: .combine)`; record button separately labelled |
| Dynamic Long-press | Expanded actions reachable via VoiceOver swipe; verify with `.accessibilityActions` |
| Color contrast | All text ≥ 4.5:1 against card background. Pace colors against dark card all pass at the chosen alphas; verify before merge with `Color Contrast Analyzer`. |
| Dynamic Type | Widgets use fixed-size text by design (Apple constraint), but `.accessibilityShowsLargeContentViewer()` on cards lets long-press magnify |
| VoiceOver | Pace conveyed in label, never color-only |

---

## Animation Spec

| Element | Trigger | Animation | Duration | Easing |
|---------|---------|-----------|----------|--------|
| Count digit | `done` changes | `.contentTransition(.numericText())` | 240ms | `easeStandard` |
| Progress ring/bar | `done` changes | `.animation(.easeOut(duration: 0.4))` on `trim` | 400ms | ease-out |
| Pace color | pace changes | `.animation(.easeInOut(duration: 0.6))` on tint | 600ms | ease-in-out |
| Pre-nudge pulse | ~10min before nudge (LA compact only) | Opacity 0.6 to 1.0 and back, 3 cycles | 1.4s/cycle | ease-in-out |
| Record button press | tap | Scale 1.0 → 0.95 → 1.0 | 180ms | spring(0.4, 0.8) |

---

## Refresh & Data Flow

```
App writes to:
  AppGroup container → SharedModelContainer (SwiftData)
    -> TodayState { done, total, nextAt, pace, prompt, lastClipAt, recentClips }

Widgets read via:
  TimelineProvider → reads SharedModelContainer
  Live Activity → driven by Activity.update from app or BGTask

Update triggers:
  - clip saved          → app posts AppGroup notification, BGTask refreshes widgets
  - nudge fires         → NudgeScheduler updates SharedModelContainer + LA
  - pace recompute      → every 15 min via BGTask, plus on clip-save
  - midnight            → BGTask reset
```

---

## Implementation Checklist

- [ ] `WidgetTokens.swift` with all colors, fonts, spacing
- [ ] Shared components in `vlog/Shared/`: `ProgressDots`, `ProgressBar`, `CellStrip`, `SegmentedRing`, `ProgressRing`, `RecordButton`, `WidgetHeader`
- [ ] `vlog/AppIntent.swift`: `RecordClipIntent`, `NotNowIntent`, `SkipHourIntent`, `OpenIdeaMemoIntent`
- [ ] `vlogLiveActivity.swift`: variant A lock + 3 DI states
- [ ] `vlogLockScreen.swift`: rect A + circ A + inline A (others as variants behind a build flag)
- [ ] `vlogHome.swift`: small A + medium A + large A
- [ ] `vlogStandBy.swift`: variant A
- [ ] Edge-case unit tests: empty / overflow / no-last-clip / off-window
- [ ] Snapshot tests for each variant in light/dark + tinted Lock Screen + StandBy vibrant
- [ ] Accessibility audit pass with VoiceOver and Reduce Motion

---

## Notes for the implementer

- The mockups intentionally over-specify variants. Ship MVP picks (marked **recommended MVP**) first; ship others as user-selectable from Settings.
- Pace color is the single emotional signal across all surfaces — get its 600ms transition right and the rest follows.
- The "never red" rule is load-bearing for the brand. If you find yourself reaching for `.red`, stop and ask. Orange is the ceiling.
- The design canvas (`widget/widgets.html`) is interactive — open it in a browser, toggle variants, and grab measurements directly from the rendered DOM if anything here is ambiguous.
