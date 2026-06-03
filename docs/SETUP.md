# Setup & Troubleshooting

Detailed reference for building VlogNudge under your own Apple Developer account. For the project overview, see the [README](../README.md).

## Targets

| Target | Folder | Min iOS | Purpose |
|---|---|---|---|
| `vlognudgee` | `vlognudgee/` | 17.0 | Main app |
| `vlogExtension` | `vlog/` | 18.0 | Widgets + Live Activity |

The repo uses Xcode **file-system synchronized folders**, so a file's target membership follows its folder. The one exception is the top-level `Shared/` folder, which is a synchronized member of **both** targets — that's how [`VlogNudgeActivityAttributes`](../Shared/VlogNudgeActivityAttributes.swift) is shared without duplication.

## Capabilities (main app target)

Signing & Capabilities → `+ Capability`:

- **App Groups** — `group.com.taylordrew.vlognudge`
- **iCloud → CloudKit** — container `iCloud.com.taylordrew.vlognudge`
- **Push Notifications**
- **Background Modes** — Location updates, Background fetch, Background processing
- **HealthKit**

The App Group and CloudKit container IDs are the source of truth in [`AppConstants.swift`](../vlognudgee/Shared/AppConstants.swift). If you build under your own team, change them in **both** places (capabilities *and* `AppConstants.swift`) so they match a container your team owns.

The widget extension needs the **App Groups** capability with the same ID.

## Permission strings

These are configured as `INFOPLIST_KEY_*` build settings on the main app target:

| Key | Purpose |
|---|---|
| `NSCameraUsageDescription` | Filming vlog clips |
| `NSMicrophoneUsageDescription` | Recording audio with clips |
| `NSPhotoLibraryAddUsageDescription` | Saving to the Daily Vlogs album |
| `NSPhotoLibraryUsageDescription` | Reading saved clips for the timeline |
| `NSMotionUsageDescription` | Avoiding nudges while driving; arrival detection |
| `NSLocationWhenInUseUsageDescription` | Adding saved places |
| `NSLocationAlwaysAndWhenInUseUsageDescription` | Place nudges while backgrounded |
| `NSCalendarsUsageDescription` / `NSCalendarsFullAccessUsageDescription` | Event-aware nudging |
| `NSHealthShareUsageDescription` | Post-workout nudge moments |
| `NSFocusStatusUsageDescription` | Respecting Focus / Do Not Disturb |

Also registered: the background task identifier `com.taylordrew.vlognudge.refresh` (see [`NudgeScheduler.bgTaskIdentifier`](../vlognudgee/Services/NudgeScheduler.swift)).

## Custom notification sound (optional)

Add a short (~0.4s), distinctive `NudgeSound.caf` to the main app bundle:

```bash
afconvert input.wav -f caff -d ima4 NudgeSound.caf
```

Drag it into Xcode with "Copy items if needed" checked and the main app target selected.

## First-run smoke test

1. Run on a real device (the Simulator is unreliable for Live Activities, HealthKit, Focus, and location).
2. Walk through onboarding — grant camera/mic/photos/notifications; motion/location/calendar/health are optional but power the smart nudging.
3. Tap **Record now** and confirm a clip lands in the Photos "Daily Vlogs" album.
4. Add a geofence (Settings → Geofences) for somewhere you visit.
5. Lock the phone — the Live Activity should show the next nudge time, and the widget should show today's clip count.

## Known gotchas

- **Live Activities are flaky in the Simulator.** Test on device.
- **`BGAppRefreshTask` runs when iOS decides**, not on demand. Pre-scheduled notifications are the reliable backbone; background refresh only extends the queue into tomorrow.
- **Geofence monitoring has a ~20-region OS limit.** `LocationService` trims to the nearest handful.
- **SwiftData + CloudKit requires every `@Model` property to have a default value.** The models already satisfy this.
- **Significant-location changes are intentionally slow** (battery). Expect minutes, not seconds.

## Xcode-side errors (not repo problems)

### `#Preview` macro fails: "external macro implementation type 'PreviewsMacros.Common' could not be found"

The `#Preview` macro implementation ships only with **Xcode's default toolchain**. This error means a non-default (e.g. Swift.org or beta) toolchain is selected.

1. **Xcode → Toolchains → Xcode Default** (and ensure `TOOLCHAINS` isn't set in your environment).
2. Confirm `xcode-select -p` points to `/Applications/Xcode.app/Contents/Developer`.
3. Clean Build Folder (⇧⌘K) and clear DerivedData.

### "The source control operation failed… revision could not be found"

Xcode's local working copy can't resolve a SHA/remote it cached — the commit almost always exists on GitHub.

```bash
git fetch origin
git status
git log -1 origin/main
```

Then: **Source Control → Fetch Changes**, quit Xcode, `rm -rf vlognudgee.xcodeproj/xcuserdata` (gitignored), clear DerivedData, reopen.

### "LLDB RPC Server has exited" (IDEDebugSessionErrorDomain code 28)

A debugger detach, usually because the app itself went away. Check in order:

1. **Console.app → device → filter by process name** for a crash log — code 28 often follows a `fatalError` or a watchdog/jetsam kill.
2. **Wireless debugging drop** — tether via cable for long runs.
3. **Signing / entitlement mismatch** — the project pins `DEVELOPMENT_TEAM`; set your own. App Group / CloudKit / HealthKit mismatches can surface as a silent launch failure.
4. **CloudKit container not linked to your team** — [`SharedModelContainer`](../vlognudgee/Shared/SharedModelContainer.swift) needs the container enabled for your team; otherwise enable it in the Developer portal (or temporarily fall back to a non-CloudKit configuration while bootstrapping).
