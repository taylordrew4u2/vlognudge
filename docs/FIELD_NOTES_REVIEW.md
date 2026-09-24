# Field Notes redesign and bug fixes

## Native iOS changes

- Cream/teal adaptive color tokens; serif headings and Dynamic Type text styles.
- Capture-first Home, daily moment count, adaptive album grid, visible selected collection.
- Native tab/navigation bars follow system appearance. Onboarding displays the new vector mark.
- Xcode app icon catalogs for both targets, vector mark imageset, matching widget action tint.
- Editable SVG masters and a reproducible icon export script. Separate downloadable package includes all legacy sizes and 1x/2x/3x marks.

## Defects addressed

1. Skip-hour removed all future notifications. Cancellation now has an upper bound and the persisted cooldown also blocks immediate context nudges and rescheduling within the pause.
2. Baseline scheduling bypassed quiet hours, bad-day mute, cooldown and the post-recording gap. Both initial and post-capture scheduling apply a shared eligibility policy.
3. Photos requested add-only while trying to fetch/manage albums. Read/write authorization is requested; limited or existing add-only access saves to Photos without album operations, with collection membership retained in-app.
4. Reopening capture repeatedly reconfigured an existing session; setup is now idempotent with errors surfaced. Configuration and camera position mutations stay on the session queue; recording callbacks are delivered on main.
5. Capture could flip/close during a recording, record before the session was ready, leak its timer, and silently dismiss on save failure. Controls now guard transitions, timers are invalidated, saves show errors and support retry without duplicating successfully created assets. Temporary files are removed only after Photos and model saves succeed.
6. Store initialization deleted the database on any error. That destructive fallback is removed. Initialization still stops if the store cannot open; explicit recovery/migration UI remains necessary.

## Verification and limits

This environment has no Xcode, Apple SDK, Swift compiler or iOS Simulator. Native build, XCTest and device runtime checks were **not run**. Source review and asset validation are not a substitute for those checks.

Completed: asset catalog JSON parsing, every referenced generated asset exists, exact PNG pixel dimensions, opaque app icons, PDF vector presence, SVG rendering/visual review, light/dark primary text and button contrast checks, `git diff --check`.

Added XCTest regressions for reminder cancellation bounds and scheduling gates. Run the `vlognudgee` scheme in Xcode on a configured iOS simulator, then check capture/Photos on a physical device.

Device checks before merging:
- Clean build app + widget extension, run XCTest.
- Record twice, reopen camera, flip before recording, background during recording, deny permissions, retry a failed save; verify no duplicate Photos asset or Clip.
- Limited vs full Photos access; confirm album behavior matches the permission copy.
- Skip one hour, then relaunch; later reminders remain and no reminder fires inside the pause.
- Light/dark/tinted home-screen icons, all widget sizes, small iPhone/iPad layouts and largest accessibility text sizes.

Known pre-existing areas outside this patch: overnight/DST baseline timing, incomplete live context snapshots, dismissal analytics, orientation/clip-length settings not fully wired, and delivery beyond today's queue if background refresh never runs. This patch does not certify the whole app as bug-free.

## Apple references

- https://developer.apple.com/documentation/photos/phaccesslevel
- https://developer.apple.com/videos/play/wwdc2020/10641/
- https://developer.apple.com/documentation/xcode/configuring-your-app-icon
