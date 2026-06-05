# App Review Notes: Background Location

## Where to find the feature

Main screen → Settings tab → Permissions & Places → Location / Background Location.

## Why persistent background location is required

VlogNudge uses background location for Place Nudges. When the user explicitly enables this feature, the app monitors saved places and sends a recording reminder when the user arrives at or leaves those places, even if VlogNudge is not open.

## Exact steps to test

1. Open VlogNudge and complete onboarding if needed.
2. Go to Settings → Location / Background Location.
3. Read the Place Nudges explanation on the screen.
4. Tap Add demo review geofence to create a sample saved place.
5. Tap Enable Background Location.
6. Grant location permissions when prompted.
7. Confirm the status changes from Background location is off or Location permission needed to Background location is active after Always permission is granted.

## Expected permission prompts

1. The app asks for When In Use location first.
2. After the user enables Place Nudges background location, the app asks for Always location.

The permission text explains that location is used to add saved places and to send Place Nudges when arriving at or leaving saved places while the app is not open.

## How to turn the feature off

Go to Settings → Location / Background Location and tap Turn Off Background Location or turn off Place Nudges use background location. The status should return to Background location is off.
