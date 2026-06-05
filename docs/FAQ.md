# VlogNudge — FAQ

Short answers to the questions people ask most. For setup/build details, see [SETUP.md](SETUP.md); for the project overview, see the [README](../README.md).

## The basics

### What does VlogNudge do?
It nudges you to film short "day‑in‑the‑life" vlog clips at moments that are actually good — and stays quiet when they aren't. Clips save to a **Daily Vlogs** album in Photos, ready to drop into a CapCut (or any) editing workflow.

### Who is it for?
Anyone who wants to vlog consistently but forgets in the moment — built with an ADHD‑aware, low‑pressure tone (gentle reminders, no guilt, no punishment‑red UI).

### What do I need to run it?
An iPhone on **iOS 17 or later**. iPad is supported too. Live Activities, HealthKit, location, and Focus features work best on a real device.

## How the nudges work

### How does it decide *when* to nudge me?
Each potential moment is scored on‑device. First, **hard blocks** can cancel a nudge entirely; if none apply, **positive signals** are added up and compared against a sensitivity threshold set by your chosen frequency.

**It will not nudge you when:**
- you're driving (detected via motion),
- you're on a phone call,
- a Focus mode you've chosen to respect is on,
- it's inside your Quiet Hours or outside your active window,
- you just filmed a clip (within ~30 min),
- it's been less than your minimum gap since the last nudge,
- you've tapped **Bad day** or hit a cool‑down.

**It's more likely to nudge you when:**
- you just arrived at or left a saved place,
- you became stationary / just settled somewhere,
- a calendar event just ended (or one's starting soon),
- it's been a long stretch since your last clip,
- your phone is charging.

### What are the frequency options?
- **Chill** — ~4 baseline nudges/day plus strong context triggers.
- **Normal** — ~6 baseline, medium context sensitivity.
- **Aggressive** — ~10 baseline, fires on almost any context trigger.
- **Context Only** — no scheduled nudges; only fires when something happens.

You can always tap **Record now** yourself regardless of frequency.

### Can I pick my own exact notification times?
Yes. **Settings → Custom schedule → Set days & times.** Add specific times for specific weekdays, and those exact times replace the frequency‑based schedule. Context‑triggered nudges still apply on top.

### Why didn't I get a nudge when I expected one?
Almost always one of the hard blocks above — most commonly the **minimum gap**, **just‑filmed**, **Quiet Hours / outside your active window**, **driving**, or a **cool‑down** after dismissing several nudges. Settings → **Nudge analytics** shows how nudges are converting.

### What's the "active window" and Quiet Hours?
The **active window** (default 10:00 AM–10:00 PM) is when nudges are allowed. **Quiet Hours** is an optional do‑not‑disturb range. Both are in Settings → Active Window / Quiet Hours.

### I'm having a rough day — can I turn it off without losing my streak?
Yes. **Settings → "Bad day — mute nudges for today."** It silences the rest of the day's nudges, no guilt, and tomorrow resets normally.

## Recording & clips

### Where do my clips go?
To a **Daily Vlogs** album in your Photos library (you can create and switch between albums on the Home tab). VlogNudge doesn't store your videos itself — they live in Photos.

### Can I change how long clips can be?
There's a soft length cap (default 60s) in Settings → Capture. It's a gentle guide, not a hard cutoff.

## Ideas

### What's the Ideas tab for?
Jotting down **video ideas** as text, so you always have something to film. Tap **New idea** (or **Add a video idea** on the Today screen) to write one, tap an idea to edit it, and swipe to **delete** or **mark it used**.

## Notifications, Live Activity & widgets

### What are the buttons on a nudge notification?
**Record** (opens the camera), **Not now** (dismiss), and **Skip this hour** (pause nudges for an hour).

### What's the sound?
A custom camera‑style cue. You can switch to **Haptic only (silent)** or toggle the custom sound in Settings → Notifications, and there's a **Send test notification** button to preview it.

### What's the Live Activity / widget?
A glanceable view of your day's pace — clips filmed vs. target and your next nudge time — on the Lock Screen (Live Activity) and Home/Lock Screen (widgets).

## Privacy

### Where does my data go?
Everything is processed **on your device**. Your settings, clip metadata, ideas, and saved places sync only through **your own private iCloud (CloudKit)** account. There's **no VlogNudge server, no analytics SDK, and no third‑party tracking.** Your videos stay in your Photos library.

### Why does it ask for so many permissions?
- **Camera / Microphone / Photos / Notifications** — required to film clips, save them, and remind you.
- **Motion / Location / Calendar / Health / Focus** — all optional. Each one only makes the timing smarter (e.g., avoid nudging while driving, nudge after a workout or when you get home). Turn any of them off in Settings → Context Signals with no loss of core function.

### Do "Place Nudges" track me in the background?
Only if you explicitly turn on **Background Location** (Settings → Location / Background Location). It's used solely to notice when you arrive at or leave places *you* saved, and you can turn it off anytime.

## Troubleshooting

### Does it work without internet?
Yes. Nudges are scheduled as local notifications, so they fire offline. iCloud sync just keeps things consistent across your devices when you're online.

### Notifications stopped showing up.
Check that notifications are still allowed (Settings → Permissions status), that you're not in Quiet Hours / outside your active window, and that **Bad day** or a cool‑down isn't active. A force‑quit can also delay re‑scheduling — reopen the app once.

### Is there an Apple Watch app?
Not yet — it's on the roadmap.
