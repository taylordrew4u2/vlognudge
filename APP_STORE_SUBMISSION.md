# VlogNudge App Store Submission

## App Review Notes

VlogNudge helps users capture short video moments by sending contextual reminders when an appropriate filming opportunity occurs.

Location is used only for user-created Place Nudges. The app monitors geographic regions and significant location changes so it can send a local notification when the user arrives at or leaves a saved place. It does not request continuous GPS updates and does not declare the `location` background mode.

To review Place Nudges:

1. Complete onboarding. Optional permissions may be skipped.
2. Open Settings and enable Place Nudges.
3. Add a place and choose an arrival or departure reminder.
4. Grant location permission when prompted. Always authorization enables reliable region events when the app is not open.
5. Enter or leave the configured region to receive the filming nudge.

Other optional context permissions—Motion, Calendar, Health, and Focus—help avoid poorly timed reminders or identify useful filming moments. The app remains usable when optional permissions are declined.

Camera and microphone access are used only to record clips. Photo Library access is used to save recorded clips and, with sufficient access, organize them in the Daily Vlogs album. Notifications deliver the nudges configured by the user.

## Submission Checklist

- [ ] Create a Release archive in Xcode Organizer and run Validate App.
- [ ] Confirm version and build are `1.0 (4)` in the uploaded build.
- [ ] Confirm the production CloudKit schema is deployed.
- [ ] Verify App Groups, iCloud/CloudKit, HealthKit, and Time Sensitive Notifications are enabled for the App ID and distribution profile.
- [ ] Add the public privacy-policy URL in App Store Connect and expose the same policy from the app.
- [ ] Complete App Privacy answers for data synchronized through the user's private CloudKit database, including saved-place coordinates, ideas, clip metadata, settings, and nudge history.
- [ ] Add support and marketing URLs.
- [ ] Complete age rating, content rights, export-compliance, and review contact fields.
- [ ] Upload current iPhone screenshots for each required display size.
- [ ] Test the archived build on a physical device with fresh permission states.
- [ ] Verify camera, microphone, Photos saving, local notifications, Place Nudges, Calendar, Motion, HealthKit, widgets, Control Widget, and Live Activity.
- [ ] Paste the App Review Notes above into App Review Information.

## Current Automated Evidence

- 49 unit tests pass with no failures or skips.
- The app and extension build successfully in Xcode.
- The source declares background fetch only; remote-notification and persistent-location background modes are absent.
- The unused Communication Notifications entitlement is absent.
